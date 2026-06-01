include "root" { path = find_in_parent_folders() }

terraform { source = "../../../modules//aws-alb" }

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    vpc_id         = "vpc-00000000mock"
    vpc_cidr_block = "10.0.0.0/16"
    public_subnets = ["subnet-mock1", "subnet-mock2", "subnet-mock3"]
  }
}

dependency "acm" {
  config_path = "../acm"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = { certificate_arn = "arn:aws:acm:ap-southeast-1:123456789012:certificate/mock" }
}

locals { cfg = yamldecode(file("${get_terragrunt_dir()}/values.yaml")) }

inputs = {
  name        = local.cfg.name
  environment = local.cfg.environment

  create                = local.cfg.create
  create_security_group = local.cfg.create_security_group

  vpc_id         = dependency.vpc.outputs.vpc_id
  vpc_cidr_block = dependency.vpc.outputs.vpc_cidr_block
  public_subnets = dependency.vpc.outputs.public_subnets

  acm_certificate_arn = dependency.acm.outputs.certificate_arn

  container_port             = local.cfg.container_port
  health_check_path          = local.cfg.health_check_path
  health_check               = local.cfg.health_check
  enable_deletion_protection = local.cfg.enable_deletion_protection
  access_logs                = try(local.cfg.access_logs, {})

  tags = local.cfg.tags
}
