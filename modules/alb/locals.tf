locals {
  # 1. Base Config Loading
  config_all = try(yamldecode(file("${path.module}/../../platform_config.yml")), {})
  
  # 2. Local Module Config
  config_local = try(
    yamldecode(file("${path.cwd}/config.yml")),
    try(yamldecode(file("${path.cwd}/config.yaml")), {})
  )

  # 3. Context
  env      = try(local.config_all.global.environment, local.config_local.environment, "dev")
  region   = try(local.config_all.global.region, "us-east-1")
  project  = try(local.config_all.global.project, "SM-Platform")
  profile  = try(local.config_all.global.aws_profile, "personal-dev")
  app_name = try(local.config_local.app_name, "base")
  service_type = try(local.config_local.service_type, "infra")
  name_prefix = local.app_name == "base" ? "${local.env}-${local.project}" : "${local.env}-${local.app_name}-${local.service_type}"

  # 4. Smart Defaults for alb
  alb_defaults = {
    name = "${local.name_prefix}-alb"
    internal = false
  }
  alb_config = merge(local.alb_defaults, try(local.config_local.alb, {}))

  # 5. Global Alias
  config = local.config_local
  tags   = { Environment = local.env, Project = local.project, ManagedBy = "DylanDevOps" }
}
