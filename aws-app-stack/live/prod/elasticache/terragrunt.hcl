include "root" { path = find_in_parent_folders() }

terraform { source = "../../../modules//aws-elasticache" }

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    vpc_id          = "vpc-00000000mock"
    private_subnets = ["subnet-mock1", "subnet-mock2", "subnet-mock3"]
  }
}

dependency "ecs" {
  config_path = "../ecs"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = { ecs_service_security_group_id = "sg-00000000mock" }
}

locals {
  all = yamldecode(file("${get_terragrunt_dir()}/../values.base.yml"))
  cfg = local.all[basename(get_terragrunt_dir())]
}

inputs = {
  name        = local.cfg.name
  environment = local.cfg.environment

  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.private_subnets
  allowed_security_group_ids = [
    dependency.ecs.outputs.ecs_service_security_group_id
  ]

  engine         = local.cfg.engine
  engine_version = local.cfg.engine_version
  node_type      = local.cfg.node_type

  cluster_mode   = local.cfg.cluster_mode
  num_cache_nodes = local.cfg.num_cache_nodes

  automatic_failover_enabled = local.cfg.automatic_failover_enabled
  multi_az_enabled           = local.cfg.multi_az_enabled
  at_rest_encryption_enabled = local.cfg.at_rest_encryption_enabled
  transit_encryption_enabled = local.cfg.transit_encryption_enabled

  tags = local.cfg.tags
}
