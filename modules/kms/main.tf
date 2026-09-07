module "kms" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=v2.2.1"

  description              = local.kms_config.description
  deletion_window_in_days  = local.kms_config.deletion_window_in_days
  key_usage                = local.kms_config.key_usage
  customer_master_key_spec = local.kms_config.customer_master_key_spec
  multi_region             = local.kms_config.multi_region

  enable_key_rotation = true
  # rotation_period_in_days is not an argument of terraform-aws-kms v2.2.1 — it
  # arrived in v3.x. Rotation stays enabled above at the AWS default (365 days).
  # To make the period configurable, bump the pinned upstream version first.

  policy = local.kms_config.policy

  aliases = local.kms_config.aliases

  key_users          = local.kms_config.key_users
  key_administrators = local.kms_config.key_administrators

  tags = local.tags

  # full upstream surface
  aliases_use_name_prefix                = local.kms_config.aliases_use_name_prefix
  bypass_policy_lockout_safety_check     = local.kms_config.bypass_policy_lockout_safety_check
  computed_aliases                       = local.kms_config.computed_aliases
  create                                 = local.kms_config.create
  create_external                        = local.kms_config.create_external
  create_replica                         = local.kms_config.create_replica
  create_replica_external                = local.kms_config.create_replica_external
  custom_key_store_id                    = local.kms_config.custom_key_store_id
  enable_default_policy                  = local.kms_config.enable_default_policy
  enable_route53_dnssec                  = local.kms_config.enable_route53_dnssec
  grants                                 = local.kms_config.grants
  is_enabled                             = local.kms_config.is_enabled
  key_asymmetric_public_encryption_users = local.kms_config.key_asymmetric_public_encryption_users
  key_asymmetric_sign_verify_users       = local.kms_config.key_asymmetric_sign_verify_users
  key_hmac_users                         = local.kms_config.key_hmac_users
  key_material_base64                    = local.kms_config.key_material_base64
  key_owners                             = local.kms_config.key_owners
  key_service_roles_for_autoscaling      = local.kms_config.key_service_roles_for_autoscaling
  key_service_users                      = local.kms_config.key_service_users
  key_statements                         = local.kms_config.key_statements
  key_symmetric_encryption_users         = local.kms_config.key_symmetric_encryption_users
  override_policy_documents              = local.kms_config.override_policy_documents
  primary_external_key_arn               = local.kms_config.primary_external_key_arn
  primary_key_arn                        = local.kms_config.primary_key_arn
  route53_dnssec_sources                 = local.kms_config.route53_dnssec_sources
  source_policy_documents                = local.kms_config.source_policy_documents
  valid_to                               = local.kms_config.valid_to
}

