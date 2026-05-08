locals {
  # 1. Local Module Config (Support dynamic config file name)
  config_local = merge(
    try(yamldecode(file("${path.cwd}/${var.config_file}")), {}),
    var.manual_config
  )

  # 2. Context & Naming (Strict mapping from config.yml)
  env          = lookup(var.global_config, "environment", "dev")
  region       = lookup(var.global_config, "region", "ap-southeast-1")
  project      = lookup(var.global_config, "project", "core")
  app_name     = lookup(local.config_local, "app_name", null)
  service_type = lookup(local.config_local, "service_type", "infra")
  name_prefix  = join("-", compact([local.env, local.app_name == "base" ? null : local.app_name, local.service_type]))

  # 3. DynamoDB Config Mapping (Key:Value Sync)
  dynamodb_raw = try(local.config_local.dynamodb, {})

  # Factory mapping for tables
  tables = try(local.dynamodb_raw.tables, {})

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
