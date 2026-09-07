# Standardised: use the security-group module rather than inline rules
module "rds_sg" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-security-group.git?ref=v5.1.0"

  name        = "${local.name_prefix}-rds-sg"
  description = "Security group for RDS ${local.name_prefix}"
  vpc_id      = var.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = local.rds_config.port
      to_port     = local.rds_config.port
      protocol    = "tcp"
      description = "Allow inbound traffic from VPC"
      cidr_blocks = var.vpc_cidr_block
    }
  ]

  egress_rules = ["all-all"]

  tags = local.tags
}

module "db" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-rds.git?ref=v6.10.0"

  identifier = local.rds_config.identifier

  engine                = local.rds_config.engine
  engine_version        = local.rds_config.engine_version
  family                = local.rds_config.family
  major_engine_version  = local.rds_config.major_engine_version
  instance_class        = local.rds_config.instance_class
  allocated_storage     = local.rds_config.allocated_storage
  max_allocated_storage = local.rds_config.max_allocated_storage
  storage_type          = local.rds_config.storage_type
  iops                  = local.rds_config.iops
  storage_throughput    = local.rds_config.storage_throughput

  db_name  = replace(local.name_prefix, "-", "")
  username = local.rds_config.username
  port     = local.rds_config.port

  manage_master_user_password = true

  # Network
  db_subnet_group_name   = "${local.name_prefix}-sng"
  create_db_subnet_group = true
  subnet_ids             = var.private_subnets
  vpc_security_group_ids = [module.rds_sg.security_group_id]

  # Backup & Maintenance
  maintenance_window      = local.rds_config.maintenance_window
  backup_window           = local.rds_config.backup_window
  backup_retention_period = local.rds_config.backup_retention_period
  skip_final_snapshot     = local.rds_config.skip_final_snapshot
  copy_tags_to_snapshot   = local.rds_config.copy_tags_to_snapshot

  # High Availability & Security
  multi_az                        = local.rds_config.multi_az
  performance_insights_enabled    = local.rds_config.performance_insights_enabled
  monitoring_interval             = local.rds_config.monitoring_interval
  enabled_cloudwatch_logs_exports = local.rds_config.enabled_cloudwatch_logs_exports

  # Security Enforcements
  storage_encrypted                   = true
  publicly_accessible                 = false
  deletion_protection                 = local.env == "prod" ? true : local.rds_config.deletion_protection
  kms_key_id                          = local.rds_config.kms_key_id
  iam_database_authentication_enabled = local.rds_config.iam_database_authentication_enabled
  ca_cert_identifier                  = local.rds_config.ca_cert_identifier

  # Operational
  apply_immediately          = local.rds_config.apply_immediately
  auto_minor_version_upgrade = local.rds_config.auto_minor_version_upgrade

  tags = local.tags

  # full upstream surface
  allow_major_version_upgrade                            = local.rds_config.allow_major_version_upgrade
  availability_zone                                      = local.rds_config.availability_zone
  blue_green_update                                      = local.rds_config.blue_green_update
  character_set_name                                     = local.rds_config.character_set_name
  cloudwatch_log_group_class                             = local.rds_config.cloudwatch_log_group_class
  cloudwatch_log_group_kms_key_id                        = local.rds_config.cloudwatch_log_group_kms_key_id
  cloudwatch_log_group_retention_in_days                 = local.rds_config.cloudwatch_log_group_retention_in_days
  cloudwatch_log_group_skip_destroy                      = local.rds_config.cloudwatch_log_group_skip_destroy
  cloudwatch_log_group_tags                              = local.rds_config.cloudwatch_log_group_tags
  create_cloudwatch_log_group                            = local.rds_config.create_cloudwatch_log_group
  create_db_instance                                     = local.rds_config.create_db_instance
  create_db_option_group                                 = local.rds_config.create_db_option_group
  create_db_parameter_group                              = local.rds_config.create_db_parameter_group
  create_monitoring_role                                 = local.rds_config.create_monitoring_role
  custom_iam_instance_profile                            = local.rds_config.custom_iam_instance_profile
  db_instance_role_associations                          = local.rds_config.db_instance_role_associations
  db_instance_tags                                       = local.rds_config.db_instance_tags
  db_option_group_tags                                   = local.rds_config.db_option_group_tags
  db_parameter_group_tags                                = local.rds_config.db_parameter_group_tags
  db_subnet_group_description                            = local.rds_config.db_subnet_group_description
  db_subnet_group_tags                                   = local.rds_config.db_subnet_group_tags
  db_subnet_group_use_name_prefix                        = local.rds_config.db_subnet_group_use_name_prefix
  dedicated_log_volume                                   = local.rds_config.dedicated_log_volume
  delete_automated_backups                               = local.rds_config.delete_automated_backups
  domain                                                 = local.rds_config.domain
  domain_auth_secret_arn                                 = local.rds_config.domain_auth_secret_arn
  domain_dns_ips                                         = local.rds_config.domain_dns_ips
  domain_fqdn                                            = local.rds_config.domain_fqdn
  domain_iam_role_name                                   = local.rds_config.domain_iam_role_name
  domain_ou                                              = local.rds_config.domain_ou
  engine_lifecycle_support                               = local.rds_config.engine_lifecycle_support
  final_snapshot_identifier_prefix                       = local.rds_config.final_snapshot_identifier_prefix
  instance_use_identifier_prefix                         = local.rds_config.instance_use_identifier_prefix
  license_model                                          = local.rds_config.license_model
  manage_master_user_password_rotation                   = local.rds_config.manage_master_user_password_rotation
  master_user_password_rotate_immediately                = local.rds_config.master_user_password_rotate_immediately
  master_user_password_rotation_automatically_after_days = local.rds_config.master_user_password_rotation_automatically_after_days
  master_user_password_rotation_duration                 = local.rds_config.master_user_password_rotation_duration
  master_user_password_rotation_schedule_expression      = local.rds_config.master_user_password_rotation_schedule_expression
  master_user_secret_kms_key_id                          = local.rds_config.master_user_secret_kms_key_id
  monitoring_role_arn                                    = local.rds_config.monitoring_role_arn
  monitoring_role_description                            = local.rds_config.monitoring_role_description
  monitoring_role_name                                   = local.rds_config.monitoring_role_name
  monitoring_role_permissions_boundary                   = local.rds_config.monitoring_role_permissions_boundary
  monitoring_role_use_name_prefix                        = local.rds_config.monitoring_role_use_name_prefix
  nchar_character_set_name                               = local.rds_config.nchar_character_set_name
  network_type                                           = local.rds_config.network_type
  option_group_description                               = local.rds_config.option_group_description
  option_group_name                                      = local.rds_config.option_group_name
  option_group_skip_destroy                              = local.rds_config.option_group_skip_destroy
  option_group_timeouts                                  = local.rds_config.option_group_timeouts
  option_group_use_name_prefix                           = local.rds_config.option_group_use_name_prefix
  options                                                = local.rds_config.options
  parameter_group_description                            = local.rds_config.parameter_group_description
  parameter_group_name                                   = local.rds_config.parameter_group_name
  parameter_group_skip_destroy                           = local.rds_config.parameter_group_skip_destroy
  parameter_group_use_name_prefix                        = local.rds_config.parameter_group_use_name_prefix
  parameters                                             = local.rds_config.parameters
  password                                               = local.rds_config.password
  performance_insights_kms_key_id                        = local.rds_config.performance_insights_kms_key_id
  performance_insights_retention_period                  = local.rds_config.performance_insights_retention_period
  putin_khuylo                                           = local.rds_config.putin_khuylo
  replica_mode                                           = local.rds_config.replica_mode
  replicate_source_db                                    = local.rds_config.replicate_source_db
  restore_to_point_in_time                               = local.rds_config.restore_to_point_in_time
  s3_import                                              = local.rds_config.s3_import
  snapshot_identifier                                    = local.rds_config.snapshot_identifier
  timeouts                                               = local.rds_config.timeouts
  timezone                                               = local.rds_config.timezone
  upgrade_storage_config                                 = local.rds_config.upgrade_storage_config
}
