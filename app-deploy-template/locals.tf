locals {
  # 1. Load Central Platform Config (Base Layer)
  config_all = try(
    yamldecode(file("${path.module}/../platform_config.yml")),
    try(yamldecode(file("${path.module}/../../platform_config.yml")), {})
  )
  
  # 2. Load Local Module Config
  config_local = try(
    yamldecode(file("${path.cwd}/config.yml")),
    try(yamldecode(file("${path.cwd}/config.yaml")), {})
  )

  # 3. Global Context
  env      = try(local.config_all.global.environment, local.config_local.environment, "dev")
  region   = try(local.config_all.global.region, local.config_local.region, "us-east-1")
  project  = try(local.config_all.global.project, local.config_local.project, "SM-Platform")
  profile  = try(local.config_all.global.aws_profile, "personal-dev")

  # 4. App Context
  app_name     = try(local.config_local.app_name, "base")
  service_type = try(local.config_local.service_type, "infra")
  
  name_prefix = local.app_name == "base" ? "${local.env}-${local.project}" : "${local.env}-${local.app_name}-${local.service_type}"
}
