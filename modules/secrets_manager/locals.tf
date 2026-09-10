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
  name_prefix  = join("-", compact([local.env, local.app_name == "base" ? null : local.app_name, local.service_type]))

  raw_sm_cfg = try(local.config_local.secrets_manager, {})

  secrets_manager_defaults = {
    name                    = "${local.name_prefix}-secret"
    description             = lookup(local.raw_sm_cfg, "description", "Secret managed by Terraform for ${local.name_prefix}")
    recovery_window_in_days = lookup(local.raw_sm_cfg, "recovery_window_in_days", 7)
    kms_key_id              = lookup(local.raw_sm_cfg, "kms_key_id", null)
    ignore_secret_changes   = lookup(local.raw_sm_cfg, "ignore_secret_changes", false)
    rotation_lambda_arn     = lookup(local.raw_sm_cfg, "rotation_lambda_arn", null)
    rotation_rules          = lookup(local.raw_sm_cfg, "rotation_rules", null)

    secret_string          = lookup(local.raw_sm_cfg, "secret_string", null)
    create_random_password = lookup(local.raw_sm_cfg, "create_random_password", false)
    random_password_length = lookup(local.raw_sm_cfg, "random_password_length", 32)
    enable_rotation        = lookup(local.raw_sm_cfg, "enable_rotation", false)
  }

  secrets = try(
    { for k, v in local.raw_sm_cfg.secrets : k => merge(local.secrets_manager_defaults, v, {
      name = lookup(v, "name", "${local.name_prefix}-${k}-secret")
    }) },
    { default = local.secrets_manager_defaults }
  )

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

check "every_secret_has_an_initial_value" {
  assert {
    condition = alltrue([
      for k, v in local.secrets : v.secret_string != null || v.create_random_password
    ])
    error_message = format(
      "secrets_manager: %v set neither secret_string nor create_random_password. Upstream always creates a version, so one of them is required.",
      [for k, v in local.secrets : k if v.secret_string == null && !v.create_random_password],
    )
  }
}
