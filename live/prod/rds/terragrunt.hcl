include "root" { path = find_in_parent_folders() }

terraform { source = "../../../modules//aws-rds" }

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    vpc_id                = "vpc-00000000mock"
    database_subnet_group = "mock-db-subnet-group"
  }
}

dependency "ecs" {
  config_path = "../ecs"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = { ecs_service_security_group_id = "sg-00000000mock" }
}

locals { cfg = yamldecode(file("${get_terragrunt_dir()}/values.yaml")) }

inputs = {
  name        = local.cfg.name
  environment = local.cfg.environment
  db_name     = local.cfg.db_name
  username    = local.cfg.username

  vpc_id                = dependency.vpc.outputs.vpc_id
  db_subnet_group_name  = dependency.vpc.outputs.database_subnet_group
  ecs_security_group_id = dependency.ecs.outputs.ecs_service_security_group_id

  engine         = local.cfg.engine
  engine_version = local.cfg.engine_version
  family         = local.cfg.family

  instance_class        = local.cfg.instance_class
  allocated_storage     = local.cfg.allocated_storage
  max_allocated_storage = local.cfg.max_allocated_storage

  multi_az          = local.cfg.multi_az
  storage_encrypted = local.cfg.storage_encrypted
  kms_key_id        = local.cfg.kms_key_id

  backup_retention_period    = local.cfg.backup_retention_period
  backup_window              = local.cfg.backup_window
  maintenance_window         = local.cfg.maintenance_window
  deletion_protection        = local.cfg.deletion_protection
  skip_final_snapshot        = local.cfg.skip_final_snapshot
  auto_minor_version_upgrade = local.cfg.auto_minor_version_upgrade

  performance_insights = local.cfg.performance_insights
  monitoring           = local.cfg.monitoring

  tags = local.cfg.tags
}
