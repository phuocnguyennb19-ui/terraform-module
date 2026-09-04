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

  # 4. Smart Defaults for rds
  raw_rds_cfg = try(local.config_local.rds, {})

  # Per-engine default port map
  engine_default_ports = {
    postgres      = 5432
    mysql         = 3306
    mariadb       = 3306
    oracle-ee     = 1521
    sqlserver-ex  = 1433
    sqlserver-se  = 1433
    sqlserver-ee  = 1433
    sqlserver-web = 1433
  }

  _engine = try(local.raw_rds_cfg.engine, "postgres")

  rds_defaults = {
    identifier                          = "${local.name_prefix}-db"
    engine                              = local._engine
    engine_version                      = try(local.raw_rds_cfg.engine_version, "15")
    instance_class                      = try(local.raw_rds_cfg.instance_class, null)
    allocated_storage                   = try(local.raw_rds_cfg.allocated_storage, 20)
    max_allocated_storage               = try(local.raw_rds_cfg.max_allocated_storage, 100)
    storage_type                        = try(local.raw_rds_cfg.storage_type, "gp3")
    iops                                = try(local.raw_rds_cfg.iops, null)
    storage_throughput                  = try(local.raw_rds_cfg.storage_throughput, null)
    username                            = try(local.raw_rds_cfg.username, "dbadmin")
    port                                = try(local.raw_rds_cfg.port, lookup(local.engine_default_ports, local._engine, 5432))
    family                              = try(local.raw_rds_cfg.family, null)
    major_engine_version                = try(local.raw_rds_cfg.major_engine_version, null)
    backup_retention_period             = try(local.raw_rds_cfg.backup_retention_period, 7)
    skip_final_snapshot                 = try(local.raw_rds_cfg.skip_final_snapshot, false)
    final_snapshot_identifier_prefix    = lookup(local.raw_rds_cfg, "final_snapshot_identifier_prefix", "${local.name_prefix}-final-snapshot")
    multi_az                            = try(local.raw_rds_cfg.multi_az, local.env == "prod")
    performance_insights_enabled        = try(local.raw_rds_cfg.performance_insights_enabled, local.env == "prod")
    monitoring_interval                 = try(local.raw_rds_cfg.monitoring_interval, 0)
    enabled_cloudwatch_logs_exports     = try(local.raw_rds_cfg.enabled_cloudwatch_logs_exports, [])
    deletion_protection                 = try(local.raw_rds_cfg.deletion_protection, local.env == "prod")
    apply_immediately                   = try(local.raw_rds_cfg.apply_immediately, local.env != "prod")
    auto_minor_version_upgrade          = try(local.raw_rds_cfg.auto_minor_version_upgrade, true)
    copy_tags_to_snapshot               = try(local.raw_rds_cfg.copy_tags_to_snapshot, true)
    iam_database_authentication_enabled = try(local.raw_rds_cfg.iam_database_authentication_enabled, false)
    kms_key_id                          = try(local.raw_rds_cfg.kms_key_id, null)
    ca_cert_identifier                  = try(local.raw_rds_cfg.ca_cert_identifier, null)
    maintenance_window                  = try(local.raw_rds_cfg.maintenance_window, "Mon:00:00-Mon:03:00")
    backup_window                       = try(local.raw_rds_cfg.backup_window, "03:00-06:00")
  }
  rds_config = merge(local.rds_defaults, try(local.config_local.rds, {}))

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
