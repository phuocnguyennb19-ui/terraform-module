# Upstream always creates a secret version: each secret needs secret_string or create_random_password.
module "secrets_manager" {
  for_each = local.secrets
  source   = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=v1.1.0"

  name        = each.value.name
  description = each.value.description

  recovery_window_in_days = each.value.recovery_window_in_days
  kms_key_id              = each.value.kms_key_id
  ignore_secret_changes   = each.value.ignore_secret_changes

  secret_string          = each.value.secret_string
  create_random_password = each.value.create_random_password
  random_password_length = each.value.random_password_length

  enable_rotation     = each.value.enable_rotation
  rotation_lambda_arn = each.value.rotation_lambda_arn
  rotation_rules      = each.value.rotation_rules

  tags = local.tags
}
