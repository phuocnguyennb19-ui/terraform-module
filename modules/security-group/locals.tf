locals {
  # 1. Base Config Loading
  config_all = try(yamldecode(file("${path.module}/../../platform_config.yml")), {})

  # 2. Local Module Config
  config_local = try(
    yamldecode(file("${path.cwd}/config.yml")),
    try(yamldecode(file("${path.cwd}/config.yaml")), {})
  )

  # 3. Context & Naming
  env      = try(local.config_all.global.environment, local.config_local.environment, "dev")
  region   = try(local.config_all.global.region, "us-east-1")
  project  = try(local.config_all.global.project, "SM-Platform")
  app_name = try(local.config_local.app_name, "security")
  service_type = try(local.config_local.service_type, "infra")
  name_prefix = local.app_name == "base" ? "${local.env}-${local.project}" : "${local.env}-${local.app_name}-${local.service_type}"

  # 4. Security Group Configuration
  sg_default_name = "${local.name_prefix}-sg"
  
  sg_config = merge({
    name        = local.sg_default_name
    description = "Security group managed by Terraform"
    # Default rules (Example: Allow all egress)
    egress_rules = ["all-all"]
    ingress_rules = []
    ingress_with_cidr_blocks = []
  }, try(local.config_local.security_group, {}))

  # 5. Global Tags
  tags = merge(
    {
      Environment = local.env
      Project     = local.project
      ManagedBy   = "DylanDevOps"
      Module      = "security-group"
    },
    try(local.config_all.global.tags, {}),
    var.tags
  )
}
