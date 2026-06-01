include "root" { path = find_in_parent_folders() }

terraform { source = "../../../modules//aws-lambda" }

# Thêm dependency nếu Lambda cần access VPC resources (RDS, ElastiCache)
# dependency "vpc" { config_path = "../vpc" }
# dependency "ecs" { config_path = "../ecs" }

locals {
  all = yamldecode(file("${get_terragrunt_dir()}/../values.base.yml"))
  cfg = local.all[basename(get_terragrunt_dir())]
}

inputs = {
  name        = local.cfg.name
  environment = local.cfg.environment

  handler     = local.cfg.handler
  runtime     = local.cfg.runtime
  memory_size = local.cfg.memory_size
  timeout     = local.cfg.timeout
  publish     = local.cfg.publish

  source_path         = try(local.cfg.source_path, null)
  s3_existing_package = try(local.cfg.s3_existing_package, null)
  create_package      = try(local.cfg.source_path, null) != null

  environment_variables = try(local.cfg.environment_variables, {})

  vpc_subnet_ids         = try(local.cfg.vpc_subnet_ids, null)
  vpc_security_group_ids = try(local.cfg.vpc_security_group_ids, null)

  create_lambda_function_url      = local.cfg.create_lambda_function_url
  attach_policy_arns              = try(local.cfg.attach_policy_arns, [])
  reserved_concurrent_executions  = local.cfg.reserved_concurrent_executions

  tags = local.cfg.tags
}
