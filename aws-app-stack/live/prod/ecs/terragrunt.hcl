include "root" { path = find_in_parent_folders() }

terraform { source = "../../../modules//aws-ecs" }

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    vpc_id          = "vpc-00000000mock"
    private_subnets = ["subnet-mock1", "subnet-mock2", "subnet-mock3"]
  }
}

dependency "alb" {
  config_path = "../alb"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    target_group_arn  = "arn:aws:elasticloadbalancing:mock"
    security_group_id = "sg-00000000mock"
  }
}

locals {
  stack = basename(get_terragrunt_dir())   # "ecs"
  base  = yamldecode(file("${get_terragrunt_dir()}/../values.base.yml"))[local.stack]

  # values.override.yml là optional — không có file thì {} (không lỗi)
  _override_path = "${get_terragrunt_dir()}/values.override.yml"
  override       = fileexists(local._override_path) ? yamldecode(file(local._override_path)) : {}

  # Shallow merge: override thắng | tags: deep-merge giữ cả 2 bên
  cfg = merge(local.base, local.override, {
    tags = merge(try(local.base.tags, {}), try(local.override.tags, {}))
  })
}

inputs = {
  app_name        = local.cfg.app_name
  environment     = local.cfg.environment
  container_image = local.cfg.container_image

  vpc_id                = dependency.vpc.outputs.vpc_id
  private_subnets       = dependency.vpc.outputs.private_subnets
  alb_target_group_arn  = dependency.alb.outputs.target_group_arn
  alb_security_group_id = dependency.alb.outputs.security_group_id

  capacity_type          = local.cfg.capacity_type
  asg_capacity_providers = try(local.cfg.asg_capacity_providers, {})

  container_port   = local.cfg.container_port
  cpu              = local.cfg.cpu
  memory           = local.cfg.memory
  desired_count    = local.cfg.desired_count
  environment_vars = try(local.cfg.environment_vars, {})
  secrets_vars     = try(local.cfg.secrets_vars, {})

  force_new_deployment               = local.cfg.force_new_deployment
  health_check_grace_period_seconds  = local.cfg.health_check_grace_period_seconds
  enable_execute_command             = local.cfg.enable_execute_command
  deployment_maximum_percent         = local.cfg.deployment_maximum_percent
  deployment_minimum_healthy_percent = local.cfg.deployment_minimum_healthy_percent

  autoscaling_min_capacity  = local.cfg.autoscaling_min_capacity
  autoscaling_max_capacity  = local.cfg.autoscaling_max_capacity
  autoscaling_cpu_target    = local.cfg.autoscaling_cpu_target
  autoscaling_memory_target = local.cfg.autoscaling_memory_target
  scale_in_cooldown         = local.cfg.scale_in_cooldown
  scale_out_cooldown        = local.cfg.scale_out_cooldown

  container_insights = local.cfg.container_insights
  log_retention_days = local.cfg.log_retention_days

  tags = local.cfg.tags
}
