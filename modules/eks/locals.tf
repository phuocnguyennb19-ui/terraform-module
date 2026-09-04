locals {
  config_local = merge(
    try(yamldecode(file("${path.cwd}/${var.config_file}")), {}),
    var.manual_config
  )

  env          = lookup(var.global_config, "environment", "dev")
  region       = lookup(var.global_config, "region", "ap-southeast-1")
  project      = lookup(var.global_config, "project", "core")
  app_name     = lookup(local.config_local, "app_name", null)
  service_type = lookup(local.config_local, "service_type", "infra")

  name_prefix = join("-", compact([local.env, local.app_name == "base" ? null : local.app_name, local.service_type]))

  raw_eks_cfg = try(local.config_local.eks, {})

  eks_config = {
    cluster_name    = try(local.raw_eks_cfg.cluster_name, "${local.name_prefix}-eks")
    cluster_version = try(local.raw_eks_cfg.cluster_version, "1.31")

    # Endpoint exposure. Public access defaults to false: an EKS API server open to
    # 0.0.0.0/0 is the most common misconfiguration on this service.
    endpoint_private_access = try(local.raw_eks_cfg.endpoint_private_access, true)
    endpoint_public_access  = try(local.raw_eks_cfg.endpoint_public_access, false)
    public_access_cidrs     = try(local.raw_eks_cfg.public_access_cidrs, [])

    # Control-plane logging. All five types on in prod, the two cheap ones elsewhere.
    enabled_log_types = try(
      local.raw_eks_cfg.enabled_log_types,
      local.env == "prod"
      ? ["api", "audit", "authenticator", "controllerManager", "scheduler"]
      : ["api", "audit"]
    )

    # Access entries replace the aws-auth ConfigMap (upstream v20+).
    authentication_mode                      = try(local.raw_eks_cfg.authentication_mode, "API")
    enable_cluster_creator_admin_permissions = try(local.raw_eks_cfg.enable_cluster_creator_admin_permissions, true)
    access_entries                           = try(local.raw_eks_cfg.access_entries, {})

    enable_irsa                            = try(local.raw_eks_cfg.enable_irsa, true)
    kms_key_arn                            = try(local.raw_eks_cfg.kms_key_arn, null)
    create_kms_key                         = try(local.raw_eks_cfg.create_kms_key, try(local.raw_eks_cfg.kms_key_arn, null) == null)
    cluster_encryption_config              = try(local.raw_eks_cfg.cluster_encryption_config, { resources = ["secrets"] })
    create_cloudwatch_log_group            = try(local.raw_eks_cfg.create_cloudwatch_log_group, true)
    cloudwatch_log_group_retention_in_days = try(local.raw_eks_cfg.cloudwatch_log_group_retention_in_days, local.env == "prod" ? 90 : 30)

    addons           = try(local.raw_eks_cfg.addons, {})
    node_groups      = try(local.raw_eks_cfg.node_groups, {})
    fargate_profiles = try(local.raw_eks_cfg.fargate_profiles, {})

    node_group_defaults = try(local.raw_eks_cfg.node_group_defaults, {})

    security_group_additional_rules      = try(local.raw_eks_cfg.security_group_additional_rules, {})
    node_security_group_additional_rules = try(local.raw_eks_cfg.node_security_group_additional_rules, {})

    subnet_ids = length(try(local.raw_eks_cfg.subnet_ids, [])) > 0 ? local.raw_eks_cfg.subnet_ids : var.private_subnets
  }

  tags = merge(
    {
      Environment = local.env,
      Project     = local.project,
      ManagedBy   = lookup(var.global_config, "managed_by", "DylanDevOps"),
      CostCenter  = lookup(var.global_config, "cost_center", "shared-services"),
      Terraform   = "true"
    },
    var.tags,
    try(var.global_config.tags, {})
  )
}
