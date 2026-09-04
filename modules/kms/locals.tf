locals {

  # 2. Local Module Config (Support dynamic config file name)
  config_local = merge(
    try(yamldecode(file("${path.cwd}/${var.config_file}")), {}),
    var.manual_config
  )

  # 3. Context & Naming (Strict mapping from config.yml)
  env          = lookup(var.global_config, "environment", "dev")
  region       = lookup(var.global_config, "region", "ap-southeast-1")
  project      = lookup(var.global_config, "project", "core")
  app_name     = lookup(local.config_local, "app_name", null)
  service_type = lookup(local.config_local, "service_type", "infra")
  name_prefix  = join("-", compact([local.env, local.app_name == "base" ? null : local.app_name, local.service_type]))

  # 4. Smart Defaults for kms
  raw_kms_cfg = try(local.config_local.kms, {})
  kms_defaults = {
    aliases                  = lookup(local.raw_kms_cfg, "aliases", ["alias/${local.name_prefix}-key"])
    description              = lookup(local.raw_kms_cfg, "description", "Master key for ${local.name_prefix}")
    deletion_window_in_days  = lookup(local.raw_kms_cfg, "deletion_window_in_days", 30)
    key_users                = lookup(local.raw_kms_cfg, "key_users", [])
    key_administrators       = lookup(local.raw_kms_cfg, "key_administrators", [])
    key_usage                = lookup(local.raw_kms_cfg, "key_usage", "ENCRYPT_DECRYPT")
    customer_master_key_spec = lookup(local.raw_kms_cfg, "customer_master_key_spec", "SYMMETRIC_DEFAULT")
    multi_region             = lookup(local.raw_kms_cfg, "multi_region", false)
    rotation_period_in_days  = lookup(local.raw_kms_cfg, "rotation_period_in_days", 365)
    policy                   = lookup(local.raw_kms_cfg, "policy", null)
  }
  kms_config = merge(local.kms_defaults, try(local.config_local.kms, {}))

  # 5. Global Alias & Tags
  config = local.config_local
  tags = merge(
    {
      Environment = local.env,
      Project     = local.project,
      ManagedBy   = lookup(var.global_config, "managed_by", "DylanDevOps"),
      CostCenter  = lookup(var.global_config, "cost_center", "shared-services"),
      Terraform   = "true"
    },
    var.tags, try(var.global_config.tags, {})
  )
}
