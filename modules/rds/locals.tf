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

    # full upstream surface
    # Remaining upstream arguments with a simple literal default, mapped with
    # that same default as the fallback: omitting a key behaves as before.
    allow_major_version_upgrade                            = try(local.raw_rds_cfg.allow_major_version_upgrade, false)
    availability_zone                                      = try(local.raw_rds_cfg.availability_zone, null)
    blue_green_update                                      = try(local.raw_rds_cfg.blue_green_update, {})
    character_set_name                                     = try(local.raw_rds_cfg.character_set_name, null)
    cloudwatch_log_group_class                             = try(local.raw_rds_cfg.cloudwatch_log_group_class, null)
    cloudwatch_log_group_kms_key_id                        = try(local.raw_rds_cfg.cloudwatch_log_group_kms_key_id, null)
    cloudwatch_log_group_retention_in_days                 = try(local.raw_rds_cfg.cloudwatch_log_group_retention_in_days, 7)
    cloudwatch_log_group_skip_destroy                      = try(local.raw_rds_cfg.cloudwatch_log_group_skip_destroy, null)
    cloudwatch_log_group_tags                              = try(local.raw_rds_cfg.cloudwatch_log_group_tags, {})
    create_cloudwatch_log_group                            = try(local.raw_rds_cfg.create_cloudwatch_log_group, false)
    create_db_instance                                     = try(local.raw_rds_cfg.create_db_instance, true)
    create_db_option_group                                 = try(local.raw_rds_cfg.create_db_option_group, true)
    create_db_parameter_group                              = try(local.raw_rds_cfg.create_db_parameter_group, true)
    create_monitoring_role                                 = try(local.raw_rds_cfg.create_monitoring_role, false)
    custom_iam_instance_profile                            = try(local.raw_rds_cfg.custom_iam_instance_profile, null)
    db_instance_role_associations                          = try(local.raw_rds_cfg.db_instance_role_associations, {})
    db_instance_tags                                       = try(local.raw_rds_cfg.db_instance_tags, {})
    db_option_group_tags                                   = try(local.raw_rds_cfg.db_option_group_tags, {})
    db_parameter_group_tags                                = try(local.raw_rds_cfg.db_parameter_group_tags, {})
    db_subnet_group_description                            = try(local.raw_rds_cfg.db_subnet_group_description, null)
    db_subnet_group_tags                                   = try(local.raw_rds_cfg.db_subnet_group_tags, {})
    db_subnet_group_use_name_prefix                        = try(local.raw_rds_cfg.db_subnet_group_use_name_prefix, true)
    dedicated_log_volume                                   = try(local.raw_rds_cfg.dedicated_log_volume, false)
    delete_automated_backups                               = try(local.raw_rds_cfg.delete_automated_backups, true)
    domain                                                 = try(local.raw_rds_cfg.domain, null)
    domain_auth_secret_arn                                 = try(local.raw_rds_cfg.domain_auth_secret_arn, null)
    domain_dns_ips                                         = try(local.raw_rds_cfg.domain_dns_ips, null)
    domain_fqdn                                            = try(local.raw_rds_cfg.domain_fqdn, null)
    domain_iam_role_name                                   = try(local.raw_rds_cfg.domain_iam_role_name, null)
    domain_ou                                              = try(local.raw_rds_cfg.domain_ou, null)
    engine_lifecycle_support                               = try(local.raw_rds_cfg.engine_lifecycle_support, null)
    final_snapshot_identifier_prefix                       = try(local.raw_rds_cfg.final_snapshot_identifier_prefix, "final")
    instance_use_identifier_prefix                         = try(local.raw_rds_cfg.instance_use_identifier_prefix, false)
    license_model                                          = try(local.raw_rds_cfg.license_model, null)
    manage_master_user_password_rotation                   = try(local.raw_rds_cfg.manage_master_user_password_rotation, false)
    master_user_password_rotate_immediately                = try(local.raw_rds_cfg.master_user_password_rotate_immediately, null)
    master_user_password_rotation_automatically_after_days = try(local.raw_rds_cfg.master_user_password_rotation_automatically_after_days, null)
    master_user_password_rotation_duration                 = try(local.raw_rds_cfg.master_user_password_rotation_duration, null)
    master_user_password_rotation_schedule_expression      = try(local.raw_rds_cfg.master_user_password_rotation_schedule_expression, null)
    master_user_secret_kms_key_id                          = try(local.raw_rds_cfg.master_user_secret_kms_key_id, null)
    monitoring_role_arn                                    = try(local.raw_rds_cfg.monitoring_role_arn, null)
    monitoring_role_description                            = try(local.raw_rds_cfg.monitoring_role_description, null)
    monitoring_role_name                                   = try(local.raw_rds_cfg.monitoring_role_name, "rds-monitoring-role")
    monitoring_role_permissions_boundary                   = try(local.raw_rds_cfg.monitoring_role_permissions_boundary, null)
    monitoring_role_use_name_prefix                        = try(local.raw_rds_cfg.monitoring_role_use_name_prefix, false)
    nchar_character_set_name                               = try(local.raw_rds_cfg.nchar_character_set_name, null)
    network_type                                           = try(local.raw_rds_cfg.network_type, null)
    option_group_description                               = try(local.raw_rds_cfg.option_group_description, null)
    option_group_name                                      = try(local.raw_rds_cfg.option_group_name, null)
    option_group_skip_destroy                              = try(local.raw_rds_cfg.option_group_skip_destroy, null)
    option_group_timeouts                                  = try(local.raw_rds_cfg.option_group_timeouts, {})
    option_group_use_name_prefix                           = try(local.raw_rds_cfg.option_group_use_name_prefix, true)
    options                                                = try(local.raw_rds_cfg.options, [])
    parameter_group_description                            = try(local.raw_rds_cfg.parameter_group_description, null)
    parameter_group_name                                   = try(local.raw_rds_cfg.parameter_group_name, null)
    parameter_group_skip_destroy                           = try(local.raw_rds_cfg.parameter_group_skip_destroy, null)
    parameter_group_use_name_prefix                        = try(local.raw_rds_cfg.parameter_group_use_name_prefix, true)
    parameters                                             = try(local.raw_rds_cfg.parameters, [])
    password                                               = try(local.raw_rds_cfg.password, null)
    performance_insights_kms_key_id                        = try(local.raw_rds_cfg.performance_insights_kms_key_id, null)
    performance_insights_retention_period                  = try(local.raw_rds_cfg.performance_insights_retention_period, 7)
    putin_khuylo                                           = try(local.raw_rds_cfg.putin_khuylo, true)
    replica_mode                                           = try(local.raw_rds_cfg.replica_mode, null)
    replicate_source_db                                    = try(local.raw_rds_cfg.replicate_source_db, null)
    restore_to_point_in_time                               = try(local.raw_rds_cfg.restore_to_point_in_time, null)
    s3_import                                              = try(local.raw_rds_cfg.s3_import, null)
    snapshot_identifier                                    = try(local.raw_rds_cfg.snapshot_identifier, null)
    timeouts                                               = try(local.raw_rds_cfg.timeouts, {})
    timezone                                               = try(local.raw_rds_cfg.timezone, null)
    upgrade_storage_config                                 = try(local.raw_rds_cfg.upgrade_storage_config, null)
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
