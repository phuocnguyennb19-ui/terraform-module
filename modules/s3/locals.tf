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

  # 4. Smart Defaults for s3
  raw_s3_cfg = try(local.config_local.s3, {})
  s3_defaults = {
    bucket              = "${local.name_prefix}-bucket"
    versioning_enabled  = lookup(local.raw_s3_cfg, "versioning_enabled", true)
    kms_key_id          = lookup(local.raw_s3_cfg, "kms_key_id", null)
    block_public_acls   = lookup(local.raw_s3_cfg, "block_public_acls", true)
    block_public_policy = lookup(local.raw_s3_cfg, "block_public_policy", true)
    force_destroy       = lookup(local.raw_s3_cfg, "force_destroy", false)

    lifecycle_rule              = lookup(local.raw_s3_cfg, "lifecycle_rule", [])
    cors_rule                   = lookup(local.raw_s3_cfg, "cors_rule", [])
    logging                     = lookup(local.raw_s3_cfg, "logging", {})
    acceleration_status         = lookup(local.raw_s3_cfg, "acceleration_status", null)
    website                     = lookup(local.raw_s3_cfg, "website", {})
    object_lock_enabled         = lookup(local.raw_s3_cfg, "object_lock_enabled", false)
    object_lock_configuration   = lookup(local.raw_s3_cfg, "object_lock_configuration", {})
    intelligent_tiering         = lookup(local.raw_s3_cfg, "intelligent_tiering", {})
    metric_configuration        = lookup(local.raw_s3_cfg, "metric_configuration", [])
    replication_configuration   = lookup(local.raw_s3_cfg, "replication_configuration", {})
    notification_configurations = lookup(local.raw_s3_cfg, "notification_configurations", {})
  }
  s3_config = merge(local.s3_defaults, try(local.config_local.s3, {}))

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
