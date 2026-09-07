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

    # full upstream surface
    # Remaining upstream arguments with a simple literal default, mapped with
    # that same default as the fallback: omitting a key behaves as before.
    attach_cluster_encryption_policy             = try(local.raw_eks_cfg.attach_cluster_encryption_policy, true)
    bootstrap_self_managed_addons                = try(local.raw_eks_cfg.bootstrap_self_managed_addons, null)
    cloudwatch_log_group_class                   = try(local.raw_eks_cfg.cloudwatch_log_group_class, null)
    cloudwatch_log_group_kms_key_id              = try(local.raw_eks_cfg.cloudwatch_log_group_kms_key_id, null)
    cloudwatch_log_group_tags                    = try(local.raw_eks_cfg.cloudwatch_log_group_tags, {})
    cluster_additional_security_group_ids        = try(local.raw_eks_cfg.cluster_additional_security_group_ids, [])
    cluster_addons_timeouts                      = try(local.raw_eks_cfg.cluster_addons_timeouts, {})
    cluster_compute_config                       = try(local.raw_eks_cfg.cluster_compute_config, {})
    cluster_encryption_policy_description        = try(local.raw_eks_cfg.cluster_encryption_policy_description, "Cluster encryption policy to allow cluster role to utilize CMK provided")
    cluster_encryption_policy_name               = try(local.raw_eks_cfg.cluster_encryption_policy_name, null)
    cluster_encryption_policy_path               = try(local.raw_eks_cfg.cluster_encryption_policy_path, null)
    cluster_encryption_policy_tags               = try(local.raw_eks_cfg.cluster_encryption_policy_tags, {})
    cluster_encryption_policy_use_name_prefix    = try(local.raw_eks_cfg.cluster_encryption_policy_use_name_prefix, true)
    cluster_identity_providers                   = try(local.raw_eks_cfg.cluster_identity_providers, {})
    cluster_ip_family                            = try(local.raw_eks_cfg.cluster_ip_family, "ipv4")
    cluster_remote_network_config                = try(local.raw_eks_cfg.cluster_remote_network_config, {})
    cluster_security_group_description           = try(local.raw_eks_cfg.cluster_security_group_description, "EKS cluster security group")
    cluster_security_group_id                    = try(local.raw_eks_cfg.cluster_security_group_id, "")
    cluster_security_group_name                  = try(local.raw_eks_cfg.cluster_security_group_name, null)
    cluster_security_group_tags                  = try(local.raw_eks_cfg.cluster_security_group_tags, {})
    cluster_security_group_use_name_prefix       = try(local.raw_eks_cfg.cluster_security_group_use_name_prefix, true)
    cluster_service_ipv4_cidr                    = try(local.raw_eks_cfg.cluster_service_ipv4_cidr, null)
    cluster_service_ipv6_cidr                    = try(local.raw_eks_cfg.cluster_service_ipv6_cidr, null)
    cluster_tags                                 = try(local.raw_eks_cfg.cluster_tags, {})
    cluster_timeouts                             = try(local.raw_eks_cfg.cluster_timeouts, {})
    cluster_upgrade_policy                       = try(local.raw_eks_cfg.cluster_upgrade_policy, {})
    cluster_zonal_shift_config                   = try(local.raw_eks_cfg.cluster_zonal_shift_config, {})
    control_plane_subnet_ids                     = try(local.raw_eks_cfg.control_plane_subnet_ids, [])
    create                                       = try(local.raw_eks_cfg.create, true)
    create_cluster_primary_security_group_tags   = try(local.raw_eks_cfg.create_cluster_primary_security_group_tags, true)
    create_cluster_security_group                = try(local.raw_eks_cfg.create_cluster_security_group, true)
    create_cni_ipv6_iam_policy                   = try(local.raw_eks_cfg.create_cni_ipv6_iam_policy, false)
    create_iam_role                              = try(local.raw_eks_cfg.create_iam_role, true)
    create_node_iam_role                         = try(local.raw_eks_cfg.create_node_iam_role, true)
    create_node_security_group                   = try(local.raw_eks_cfg.create_node_security_group, true)
    custom_oidc_thumbprints                      = try(local.raw_eks_cfg.custom_oidc_thumbprints, [])
    dataplane_wait_duration                      = try(local.raw_eks_cfg.dataplane_wait_duration, "30s")
    enable_auto_mode_custom_tags                 = try(local.raw_eks_cfg.enable_auto_mode_custom_tags, true)
    enable_efa_support                           = try(local.raw_eks_cfg.enable_efa_support, false)
    enable_kms_key_rotation                      = try(local.raw_eks_cfg.enable_kms_key_rotation, true)
    enable_security_groups_for_pods              = try(local.raw_eks_cfg.enable_security_groups_for_pods, true)
    fargate_profile_defaults                     = try(local.raw_eks_cfg.fargate_profile_defaults, {})
    iam_role_additional_policies                 = try(local.raw_eks_cfg.iam_role_additional_policies, {})
    iam_role_arn                                 = try(local.raw_eks_cfg.iam_role_arn, null)
    iam_role_description                         = try(local.raw_eks_cfg.iam_role_description, null)
    iam_role_name                                = try(local.raw_eks_cfg.iam_role_name, null)
    iam_role_path                                = try(local.raw_eks_cfg.iam_role_path, null)
    iam_role_permissions_boundary                = try(local.raw_eks_cfg.iam_role_permissions_boundary, null)
    iam_role_tags                                = try(local.raw_eks_cfg.iam_role_tags, {})
    iam_role_use_name_prefix                     = try(local.raw_eks_cfg.iam_role_use_name_prefix, true)
    include_oidc_root_ca_thumbprint              = try(local.raw_eks_cfg.include_oidc_root_ca_thumbprint, true)
    kms_key_aliases                              = try(local.raw_eks_cfg.kms_key_aliases, [])
    kms_key_deletion_window_in_days              = try(local.raw_eks_cfg.kms_key_deletion_window_in_days, null)
    kms_key_description                          = try(local.raw_eks_cfg.kms_key_description, null)
    kms_key_enable_default_policy                = try(local.raw_eks_cfg.kms_key_enable_default_policy, true)
    kms_key_override_policy_documents            = try(local.raw_eks_cfg.kms_key_override_policy_documents, [])
    kms_key_owners                               = try(local.raw_eks_cfg.kms_key_owners, [])
    kms_key_service_users                        = try(local.raw_eks_cfg.kms_key_service_users, [])
    kms_key_source_policy_documents              = try(local.raw_eks_cfg.kms_key_source_policy_documents, [])
    kms_key_users                                = try(local.raw_eks_cfg.kms_key_users, [])
    node_iam_role_additional_policies            = try(local.raw_eks_cfg.node_iam_role_additional_policies, {})
    node_iam_role_description                    = try(local.raw_eks_cfg.node_iam_role_description, null)
    node_iam_role_name                           = try(local.raw_eks_cfg.node_iam_role_name, null)
    node_iam_role_path                           = try(local.raw_eks_cfg.node_iam_role_path, null)
    node_iam_role_permissions_boundary           = try(local.raw_eks_cfg.node_iam_role_permissions_boundary, null)
    node_iam_role_tags                           = try(local.raw_eks_cfg.node_iam_role_tags, {})
    node_iam_role_use_name_prefix                = try(local.raw_eks_cfg.node_iam_role_use_name_prefix, true)
    node_security_group_description              = try(local.raw_eks_cfg.node_security_group_description, "EKS node shared security group")
    node_security_group_enable_recommended_rules = try(local.raw_eks_cfg.node_security_group_enable_recommended_rules, true)
    node_security_group_id                       = try(local.raw_eks_cfg.node_security_group_id, "")
    node_security_group_name                     = try(local.raw_eks_cfg.node_security_group_name, null)
    node_security_group_tags                     = try(local.raw_eks_cfg.node_security_group_tags, {})
    node_security_group_use_name_prefix          = try(local.raw_eks_cfg.node_security_group_use_name_prefix, true)
    openid_connect_audiences                     = try(local.raw_eks_cfg.openid_connect_audiences, [])
    outpost_config                               = try(local.raw_eks_cfg.outpost_config, {})
    prefix_separator                             = try(local.raw_eks_cfg.prefix_separator, "-")
    putin_khuylo                                 = try(local.raw_eks_cfg.putin_khuylo, true)
    self_managed_node_group_defaults             = try(local.raw_eks_cfg.self_managed_node_group_defaults, {})
    self_managed_node_groups                     = try(local.raw_eks_cfg.self_managed_node_groups, {})
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
