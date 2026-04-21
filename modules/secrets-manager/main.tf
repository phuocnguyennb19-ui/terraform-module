# Fix 4c: Secrets Manager — Bỏ for_each, tạo 1 secret mặc định từ secrets_manager_config
module "secrets_manager" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=v1.1.0"

  name        = try(local.secrets_manager_config.name, "${local.name_prefix}-secret")
  description = try(local.secrets_manager_config.description, "Managed secret for ${local.name_prefix}")

  recovery_window_in_days = try(local.secrets_manager_config.recovery_window_in_days, 0)

  kms_key_id = try(local.secrets_manager_config.kms_key_id, null)

  tags = local.tags
}
