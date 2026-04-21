locals {
  # Load the unified config file from a dynamic path
  config = yamldecode(file(var.config_path))

  # Global Context
  env     = try(local.config.global.environment, "dev")
  region  = try(local.config.global.region, "us-east-1")
  project = try(local.config.global.project, "SM-Platform")
  profile = try(local.config.global.aws_profile, "personal-dev")

  # Standard Tags
  tags = {
    Environment = local.env
    Project     = local.project
    ManagedBy   = "DylanDevOps"
    Terraform   = "true"
  }
}
