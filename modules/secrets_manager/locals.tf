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

  # 4. Smart Defaults for secrets-manager
  raw_sm_cfg = try(local.config_local.secrets_manager, {})

  secrets_manager_defaults = {
    name                    = "${local.name_prefix}-secret"
    description             = lookup(local.raw_sm_cfg, "description", "Secret managed by Terraform for ${local.name_prefix}")
    recovery_window_in_days = lookup(local.raw_sm_cfg, "recovery_window_in_days", 7)
    kms_key_id              = lookup(local.raw_sm_cfg, "kms_key_id", null)
    ignore_secret_changes   = lookup(local.raw_sm_cfg, "ignore_secret_changes", false)
    rotation_lambda_arn     = lookup(local.raw_sm_cfg, "rotation_lambda_arn", null)
    rotation_rules          = lookup(local.raw_sm_cfg, "rotation_rules", null)
  }

  # Factory: each entry in secrets_manager.secrets becomes one secret resource.
  # Falls back to a single default secret when no secrets map is defined.
  secrets = try(
    { for k, v in local.raw_sm_cfg.secrets : k => merge(local.secrets_manager_defaults, v, {
      name = lookup(v, "name", "${local.name_prefix}-${k}-secret")
    }) },
    { default = local.secrets_manager_defaults }
  )

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
