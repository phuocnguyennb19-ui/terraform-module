# EKS CLUSTER
#
# Consumes the foundation. vpc_id and subnet_ids are inputs; this module has no
# aws_vpc, aws_subnet, aws_nat_gateway or aws_route_table in it and never will.
# That is what lets an EKS cluster, an EC2 fleet and an RDS instance share one
# network boundary instead of three parallel ones.
#
# Upstream: terraform-aws-modules/eks/aws v20, which is the last line that
# supports the 5.x AWS provider. v21 requires provider 6.x and restructures the
# node group and access entry inputs — a coordinated upgrade, not a bump.

locals {
  # Decided from a plain bool when the caller supplies one. Inferring it from
  # kms_key_arn == null fails at plan whenever the key is built in the same
  # configuration: the ARN is unknown until apply, so the count of the upstream
  # KMS submodule is unknown too. Null keeps the old inference for callers that
  # pass a literal ARN.
  create_kms_key = var.create_kms_key != null ? var.create_kms_key : var.kms_key_arn == null

  # Managed node groups need a launch template to enforce IMDSv2 and encrypt the
  # root volume; the module builds one when given these settings.
  node_group_defaults = {
    # IMDSv2 required, hop limit 1. Hop limit 1 means a process inside a
    # container cannot reach the instance metadata service, so a compromised pod
    # cannot mint credentials for the node's instance role. Workloads that need
    # AWS permissions get them through IRSA instead. Raising this to 2 to "fix"
    # a pod that cannot reach IMDS re-opens exactly that path.
    metadata_options = {
      http_endpoint               = "enabled"
      http_tokens                 = "required"
      http_put_response_hop_limit = 1
      instance_metadata_tags      = "disabled"
    }

    ebs_optimized     = true
    enable_monitoring = true

    iam_role_attach_cni_policy = true

    # A fixed role name rather than a name_prefix. AWS caps name_prefix at 38
    # characters, and the upstream role name is "<cluster>-<group>-eks-node-group"
    # — "platform-dev-eks-general" already overflows it. A full name has 64.
    iam_role_use_name_prefix = false
  }

  node_groups = {
    for k, g in var.node_groups : k => {
      name = "${var.cluster_name}-${k}"

      instance_types = g.instance_types
      capacity_type  = g.capacity_type
      ami_type       = g.ami_type

      min_size     = g.min_size
      max_size     = g.max_size
      desired_size = g.desired_size

      subnet_ids = coalesce(g.subnet_ids, var.subnet_ids)

      block_device_mappings = {
        root = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = g.disk_size
            volume_type           = g.disk_type
            encrypted             = true
            kms_key_id            = var.kms_key_arn
            delete_on_termination = true
          }
        }
      }

      labels = g.labels
      taints = g.taints

      update_config = {
        max_unavailable = g.max_unavailable
      }

      force_update_version = g.force_update_version

      vpc_security_group_ids = var.node_security_group_ids

      tags = merge(var.tags, g.tags)
    }
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.37.2"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  # ---- Networking, all from the foundation --------------------------------
  vpc_id                   = var.vpc_id
  subnet_ids               = var.subnet_ids
  control_plane_subnet_ids = var.control_plane_subnet_ids

  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access ? var.cluster_endpoint_public_access_cidrs : []

  cluster_additional_security_group_ids = var.cluster_security_group_ids

  # ---- Encryption ---------------------------------------------------------
  # Envelope encryption for Kubernetes Secrets. Without it, a Secret in etcd is
  # base64, which is an encoding, not a protection.
  create_kms_key = local.create_kms_key

  # merge() rather than a conditional: the two branches of a conditional must
  # have identical object types, and provider_key_arn is present in only one.
  cluster_encryption_config = merge(
    { resources = ["secrets"] },
    local.create_kms_key ? {} : { provider_key_arn = var.kms_key_arn },
  )

  # ---- Control plane logging ---------------------------------------------
  cluster_enabled_log_types              = var.cluster_enabled_log_types
  create_cloudwatch_log_group            = true
  cloudwatch_log_group_retention_in_days = var.cluster_log_retention_days
  cloudwatch_log_group_kms_key_id        = var.cluster_log_kms_key_arn

  # ---- Access -------------------------------------------------------------
  authentication_mode                      = var.authentication_mode
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
  access_entries                           = var.access_entries

  enable_irsa = var.enable_irsa

  # ---- Addons -------------------------------------------------------------
  cluster_addons = var.cluster_addons

  # ---- Node groups --------------------------------------------------------
  eks_managed_node_group_defaults = local.node_group_defaults
  eks_managed_node_groups         = local.node_groups

  tags = var.tags
}

# ---------------------------------------------------------------------------
# IRSA roles
#
# A pod that needs AWS permissions gets its own role through the cluster's OIDC
# provider. The alternative — attaching the permission to the node's instance
# role — grants it to every pod on that node, including anything that lands
# there later.
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "irsa_trust" {
  for_each = var.enable_irsa ? var.irsa_roles : {}

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = [for sa in each.value.namespace_service_accounts : "system:serviceaccount:${sa}"]
    }

    # Without the aud condition the trust policy accepts a token minted for a
    # different audience by the same provider.
    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "irsa" {
  for_each = var.enable_irsa ? var.irsa_roles : {}

  name               = "${var.cluster_name}-irsa-${each.key}"
  description        = each.value.description
  assume_role_policy = data.aws_iam_policy_document.irsa_trust[each.key].json

  tags = merge(var.tags, { Name = "${var.cluster_name}-irsa-${each.key}" })
}

resource "aws_iam_role_policy_attachment" "irsa" {
  for_each = merge([
    for role_key, role in(var.enable_irsa ? var.irsa_roles : {}) : {
      for arn in role.managed_policy_arns :
      "${role_key}:${arn}" => { role = role_key, arn = arn }
    }
  ]...)

  role       = aws_iam_role.irsa[each.value.role].name
  policy_arn = each.value.arn
}

resource "aws_iam_role_policy" "irsa_inline" {
  for_each = {
    for k, v in(var.enable_irsa ? var.irsa_roles : {}) : k => v
    if v.inline_policy != null
  }

  name   = "${var.cluster_name}-irsa-${each.key}"
  role   = aws_iam_role.irsa[each.key].id
  policy = each.value.inline_policy
}

data "aws_region" "current" {}
