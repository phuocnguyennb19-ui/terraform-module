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
}
