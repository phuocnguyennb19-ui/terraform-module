module "kms" {
  source  = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=v2.2.1"

  description             = try(local.kms_config.description, "Production KMS Key")
  deletion_window_in_days = try(local.kms_config.deletion_window_in_days, 30)
  
  # Security: Key Rotation (Mandatory)
  enable_key_rotation     = true

  aliases = try(local.kms_config.aliases, [])

  key_users          = try(local.kms_config.key_users, [])
  key_administrators = try(local.kms_config.key_administrators, [])

  tags = local.tags
}

