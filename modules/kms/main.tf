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
}

