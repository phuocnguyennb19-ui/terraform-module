module "eks" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=v20.31.6"

  cluster_name    = local.eks_config.cluster_name
  cluster_version = local.eks_config.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = local.eks_config.subnet_ids

  cluster_endpoint_private_access      = local.eks_config.endpoint_private_access
  cluster_endpoint_public_access       = local.eks_config.endpoint_public_access
  cluster_endpoint_public_access_cidrs = local.eks_config.public_access_cidrs

  cluster_enabled_log_types              = local.eks_config.enabled_log_types
  create_cloudwatch_log_group            = local.eks_config.create_cloudwatch_log_group
  cloudwatch_log_group_retention_in_days = local.eks_config.cloudwatch_log_group_retention_in_days

  # Access entries, not the aws-auth ConfigMap. No kubernetes provider required.
  authentication_mode                      = local.eks_config.authentication_mode
  enable_cluster_creator_admin_permissions = local.eks_config.enable_cluster_creator_admin_permissions
  access_entries                           = local.eks_config.access_entries

  enable_irsa = local.eks_config.enable_irsa

  # Envelope encryption for Kubernetes secrets at rest.
  create_kms_key            = local.eks_config.create_kms_key
  cluster_encryption_config = local.eks_config.cluster_encryption_config
  kms_key_administrators    = []

  cluster_addons = local.eks_config.addons

  eks_managed_node_group_defaults = local.eks_config.node_group_defaults
  eks_managed_node_groups         = local.eks_config.node_groups

  fargate_profiles = local.eks_config.fargate_profiles

  cluster_security_group_additional_rules = local.eks_config.security_group_additional_rules
  node_security_group_additional_rules    = local.eks_config.node_security_group_additional_rules

  tags = local.tags

  # full upstream surface
  attach_cluster_encryption_policy             = local.eks_config.attach_cluster_encryption_policy
  bootstrap_self_managed_addons                = local.eks_config.bootstrap_self_managed_addons
  cloudwatch_log_group_class                   = local.eks_config.cloudwatch_log_group_class
  cloudwatch_log_group_kms_key_id              = local.eks_config.cloudwatch_log_group_kms_key_id
  cloudwatch_log_group_tags                    = local.eks_config.cloudwatch_log_group_tags
  cluster_additional_security_group_ids        = local.eks_config.cluster_additional_security_group_ids
  cluster_addons_timeouts                      = local.eks_config.cluster_addons_timeouts
  cluster_compute_config                       = local.eks_config.cluster_compute_config
  cluster_encryption_policy_description        = local.eks_config.cluster_encryption_policy_description
  cluster_encryption_policy_name               = local.eks_config.cluster_encryption_policy_name
  cluster_encryption_policy_path               = local.eks_config.cluster_encryption_policy_path
  cluster_encryption_policy_tags               = local.eks_config.cluster_encryption_policy_tags
  cluster_encryption_policy_use_name_prefix    = local.eks_config.cluster_encryption_policy_use_name_prefix
  cluster_identity_providers                   = local.eks_config.cluster_identity_providers
  cluster_ip_family                            = local.eks_config.cluster_ip_family
  cluster_remote_network_config                = local.eks_config.cluster_remote_network_config
  cluster_security_group_description           = local.eks_config.cluster_security_group_description
  cluster_security_group_id                    = local.eks_config.cluster_security_group_id
  cluster_security_group_name                  = local.eks_config.cluster_security_group_name
  cluster_security_group_tags                  = local.eks_config.cluster_security_group_tags
  cluster_security_group_use_name_prefix       = local.eks_config.cluster_security_group_use_name_prefix
  cluster_service_ipv4_cidr                    = local.eks_config.cluster_service_ipv4_cidr
  cluster_service_ipv6_cidr                    = local.eks_config.cluster_service_ipv6_cidr
  cluster_tags                                 = local.eks_config.cluster_tags
  cluster_timeouts                             = local.eks_config.cluster_timeouts
  cluster_upgrade_policy                       = local.eks_config.cluster_upgrade_policy
  cluster_zonal_shift_config                   = local.eks_config.cluster_zonal_shift_config
  control_plane_subnet_ids                     = local.eks_config.control_plane_subnet_ids
  create                                       = local.eks_config.create
  create_cluster_primary_security_group_tags   = local.eks_config.create_cluster_primary_security_group_tags
  create_cluster_security_group                = local.eks_config.create_cluster_security_group
  create_cni_ipv6_iam_policy                   = local.eks_config.create_cni_ipv6_iam_policy
  create_iam_role                              = local.eks_config.create_iam_role
  create_node_iam_role                         = local.eks_config.create_node_iam_role
  create_node_security_group                   = local.eks_config.create_node_security_group
  custom_oidc_thumbprints                      = local.eks_config.custom_oidc_thumbprints
  dataplane_wait_duration                      = local.eks_config.dataplane_wait_duration
  enable_auto_mode_custom_tags                 = local.eks_config.enable_auto_mode_custom_tags
  enable_efa_support                           = local.eks_config.enable_efa_support
  enable_kms_key_rotation                      = local.eks_config.enable_kms_key_rotation
  enable_security_groups_for_pods              = local.eks_config.enable_security_groups_for_pods
  fargate_profile_defaults                     = local.eks_config.fargate_profile_defaults
  iam_role_additional_policies                 = local.eks_config.iam_role_additional_policies
  iam_role_arn                                 = local.eks_config.iam_role_arn
  iam_role_description                         = local.eks_config.iam_role_description
  iam_role_name                                = local.eks_config.iam_role_name
  iam_role_path                                = local.eks_config.iam_role_path
  iam_role_permissions_boundary                = local.eks_config.iam_role_permissions_boundary
  iam_role_tags                                = local.eks_config.iam_role_tags
  iam_role_use_name_prefix                     = local.eks_config.iam_role_use_name_prefix
  include_oidc_root_ca_thumbprint              = local.eks_config.include_oidc_root_ca_thumbprint
  kms_key_aliases                              = local.eks_config.kms_key_aliases
  kms_key_deletion_window_in_days              = local.eks_config.kms_key_deletion_window_in_days
  kms_key_description                          = local.eks_config.kms_key_description
  kms_key_enable_default_policy                = local.eks_config.kms_key_enable_default_policy
  kms_key_override_policy_documents            = local.eks_config.kms_key_override_policy_documents
  kms_key_owners                               = local.eks_config.kms_key_owners
  kms_key_service_users                        = local.eks_config.kms_key_service_users
  kms_key_source_policy_documents              = local.eks_config.kms_key_source_policy_documents
  kms_key_users                                = local.eks_config.kms_key_users
  node_iam_role_additional_policies            = local.eks_config.node_iam_role_additional_policies
  node_iam_role_description                    = local.eks_config.node_iam_role_description
  node_iam_role_name                           = local.eks_config.node_iam_role_name
  node_iam_role_path                           = local.eks_config.node_iam_role_path
  node_iam_role_permissions_boundary           = local.eks_config.node_iam_role_permissions_boundary
  node_iam_role_tags                           = local.eks_config.node_iam_role_tags
  node_iam_role_use_name_prefix                = local.eks_config.node_iam_role_use_name_prefix
  node_security_group_description              = local.eks_config.node_security_group_description
  node_security_group_enable_recommended_rules = local.eks_config.node_security_group_enable_recommended_rules
  node_security_group_id                       = local.eks_config.node_security_group_id
  node_security_group_name                     = local.eks_config.node_security_group_name
  node_security_group_tags                     = local.eks_config.node_security_group_tags
  node_security_group_use_name_prefix          = local.eks_config.node_security_group_use_name_prefix
  openid_connect_audiences                     = local.eks_config.openid_connect_audiences
  outpost_config                               = local.eks_config.outpost_config
  prefix_separator                             = local.eks_config.prefix_separator
  putin_khuylo                                 = local.eks_config.putin_khuylo
  self_managed_node_group_defaults             = local.eks_config.self_managed_node_group_defaults
  self_managed_node_groups                     = local.eks_config.self_managed_node_groups
}
