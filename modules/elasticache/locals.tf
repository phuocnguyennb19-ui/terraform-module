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

    automatic_failover_enabled = lookup(local.raw_ec_cfg, "automatic_failover_enabled", local.env == "prod")
    multi_az_enabled           = lookup(local.raw_ec_cfg, "multi_az_enabled", local.env == "prod")
    maintenance_window         = lookup(local.raw_ec_cfg, "maintenance_window", "sun:05:00-sun:06:00")
    snapshot_retention_limit   = lookup(local.raw_ec_cfg, "snapshot_retention_limit", local.env == "prod" ? 7 : 1)
    snapshot_window            = lookup(local.raw_ec_cfg, "snapshot_window", "03:00-04:00")
    apply_immediately          = lookup(local.raw_ec_cfg, "apply_immediately", local.env != "prod")
    auto_minor_version_upgrade = lookup(local.raw_ec_cfg, "auto_minor_version_upgrade", true)
    num_node_groups            = lookup(local.raw_ec_cfg, "num_node_groups", null)
    replicas_per_node_group    = lookup(local.raw_ec_cfg, "replicas_per_node_group", null)
    parameter_group_name       = lookup(local.raw_ec_cfg, "parameter_group_name", null)
    security_group_ids         = lookup(local.raw_ec_cfg, "security_group_ids", [])

    # full upstream surface
    # Remaining upstream arguments with a simple literal default, mapped with
    # that same default as the fallback: omitting a key behaves as before.
    auth_token                                = try(local.raw_ec_cfg.auth_token, null)
    auth_token_update_strategy                = try(local.raw_ec_cfg.auth_token_update_strategy, null)
    availability_zone                         = try(local.raw_ec_cfg.availability_zone, null)
    az_mode                                   = try(local.raw_ec_cfg.az_mode, null)
    cluster_mode_enabled                      = try(local.raw_ec_cfg.cluster_mode_enabled, false)
    create                                    = try(local.raw_ec_cfg.create, true)
    create_cluster                            = try(local.raw_ec_cfg.create_cluster, false)
    create_parameter_group                    = try(local.raw_ec_cfg.create_parameter_group, false)
    create_primary_global_replication_group   = try(local.raw_ec_cfg.create_primary_global_replication_group, false)
    create_replication_group                  = try(local.raw_ec_cfg.create_replication_group, true)
    create_secondary_global_replication_group = try(local.raw_ec_cfg.create_secondary_global_replication_group, false)
    create_security_group                     = try(local.raw_ec_cfg.create_security_group, true)
    create_subnet_group                       = try(local.raw_ec_cfg.create_subnet_group, true)
    data_tiering_enabled                      = try(local.raw_ec_cfg.data_tiering_enabled, null)
    description                               = try(local.raw_ec_cfg.description, null)
    final_snapshot_identifier                 = try(local.raw_ec_cfg.final_snapshot_identifier, null)
    global_replication_group_id               = try(local.raw_ec_cfg.global_replication_group_id, null)
    ip_discovery                              = try(local.raw_ec_cfg.ip_discovery, null)
    network_type                              = try(local.raw_ec_cfg.network_type, null)
    notification_topic_arn                    = try(local.raw_ec_cfg.notification_topic_arn, null)
    num_cache_clusters                        = try(local.raw_ec_cfg.num_cache_clusters, null)
    outpost_mode                              = try(local.raw_ec_cfg.outpost_mode, null)
    parameter_group_description               = try(local.raw_ec_cfg.parameter_group_description, null)
    parameter_group_family                    = try(local.raw_ec_cfg.parameter_group_family, "")
    parameters                                = try(local.raw_ec_cfg.parameters, [])
    preferred_availability_zones              = try(local.raw_ec_cfg.preferred_availability_zones, [])
    preferred_cache_cluster_azs               = try(local.raw_ec_cfg.preferred_cache_cluster_azs, [])
    preferred_outpost_arn                     = try(local.raw_ec_cfg.preferred_outpost_arn, null)
    replication_group_id                      = try(local.raw_ec_cfg.replication_group_id, null)
    security_group_description                = try(local.raw_ec_cfg.security_group_description, null)
    security_group_name                       = try(local.raw_ec_cfg.security_group_name, null)
    security_group_names                      = try(local.raw_ec_cfg.security_group_names, [])
    security_group_rules                      = try(local.raw_ec_cfg.security_group_rules, {})
    security_group_tags                       = try(local.raw_ec_cfg.security_group_tags, {})
    security_group_use_name_prefix            = try(local.raw_ec_cfg.security_group_use_name_prefix, true)
    snapshot_arns                             = try(local.raw_ec_cfg.snapshot_arns, [])
    snapshot_name                             = try(local.raw_ec_cfg.snapshot_name, null)
    subnet_group_description                  = try(local.raw_ec_cfg.subnet_group_description, null)
    subnet_group_name                         = try(local.raw_ec_cfg.subnet_group_name, null)
    user_group_ids                            = try(local.raw_ec_cfg.user_group_ids, null)
    vpc_id                                    = try(local.raw_ec_cfg.vpc_id, null)
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
