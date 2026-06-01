locals {
  # Auto-derive family + major_engine_version nếu không truyền
  engine_defaults = {
    postgres          = { family = "postgres17",       major = "17" }
    mysql             = { family = "mysql8.0",         major = "8.0" }
    mariadb           = { family = "mariadb10.6",      major = "10.6" }
    "aurora-postgresql" = { family = "aurora-postgresql16", major = "16" }
    "aurora-mysql"    = { family = "aurora-mysql8.0",  major = "8.0" }
  }

  family               = coalesce(var.family, local.engine_defaults[var.engine].family)
  major_engine_version = coalesce(var.major_engine_version, local.engine_defaults[var.engine].major)
}

module "rds_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name   = "${var.name}-${var.environment}-rds-sg"
  vpc_id = var.vpc_id

  ingress_with_source_security_group_id = [{
    rule                     = contains(["mysql", "aurora-mysql", "mariadb"], var.engine) ? "mysql-tcp" : "postgresql-tcp"
    source_security_group_id = var.ecs_security_group_id
  }]

  egress_rules = ["all-all"]
  tags         = var.tags
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "${var.name}-${var.environment}"

  engine               = var.engine
  engine_version       = var.engine_version
  family               = local.family
  major_engine_version = local.major_engine_version
  instance_class       = var.instance_class
  allocated_storage    = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage

  db_name                     = var.db_name
  username                    = var.username
  manage_master_user_password = true

  vpc_security_group_ids = [module.rds_sg.security_group_id]
  db_subnet_group_name   = var.db_subnet_group_name

  multi_az          = var.multi_az
  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id

  backup_retention_period    = var.backup_retention_period
  backup_window              = var.backup_window
  maintenance_window         = var.maintenance_window
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  copy_tags_to_snapshot      = true

  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot

  performance_insights_enabled          = var.performance_insights.enabled
  performance_insights_retention_period = var.performance_insights.retention_period

  monitoring_interval    = var.monitoring.interval
  monitoring_role_name   = coalesce(var.monitoring.role_name, "${var.name}-${var.environment}-rds-monitoring")
  create_monitoring_role = var.monitoring.create_role

  tags = var.tags
}
