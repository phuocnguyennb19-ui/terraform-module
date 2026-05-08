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

  # 4. Smart Defaults for elasticache
  raw_ec_cfg = try(local.config_local.elasticache, {})
  elasticache_defaults = {
    cluster_id      = "${local.name_prefix}-redis"
    node_type       = lookup(local.raw_ec_cfg, "node_type", "cache.t3.micro")
    engine          = lookup(local.raw_ec_cfg, "engine", "redis")
    engine_version  = lookup(local.raw_ec_cfg, "engine_version", "7.0")
    num_cache_nodes = lookup(local.raw_ec_cfg, "num_cache_nodes", 1)
    port            = lookup(local.raw_ec_cfg, "port", 6379)
    kms_key_arn     = lookup(local.raw_ec_cfg, "kms_key_arn", null)

    automatic_failover_enabled    = lookup(local.raw_ec_cfg, "automatic_failover_enabled", local.env == "prod")
    multi_az_enabled              = lookup(local.raw_ec_cfg, "multi_az_enabled", local.env == "prod")
    maintenance_window            = lookup(local.raw_ec_cfg, "maintenance_window", "sun:05:00-sun:06:00")
    snapshot_retention_limit      = lookup(local.raw_ec_cfg, "snapshot_retention_limit", local.env == "prod" ? 7 : 1)
    snapshot_window               = lookup(local.raw_ec_cfg, "snapshot_window", "03:00-04:00")
    apply_immediately             = lookup(local.raw_ec_cfg, "apply_immediately", local.env != "prod")
    auto_minor_version_upgrade    = lookup(local.raw_ec_cfg, "auto_minor_version_upgrade", true)
    num_node_groups               = lookup(local.raw_ec_cfg, "num_node_groups", null)
    replicas_per_node_group       = lookup(local.raw_ec_cfg, "replicas_per_node_group", null)
    parameter_group_name          = lookup(local.raw_ec_cfg, "parameter_group_name", null)
    security_group_ids            = lookup(local.raw_ec_cfg, "security_group_ids", [])
  }
  elasticache_config = merge(local.elasticache_defaults, try(local.config_local.elasticache, {}))

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
