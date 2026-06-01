include "root" { path = find_in_parent_folders() }

terraform { source = "../../../modules//aws-vpc" }

locals { cfg = yamldecode(file("${get_terragrunt_dir()}/values.yaml")) }

inputs = {
  name        = local.cfg.name
  environment = local.cfg.environment

  vpc_cidr              = local.cfg.vpc_cidr
  availability_zones    = local.cfg.availability_zones
  private_subnet_cidrs  = local.cfg.private_subnet_cidrs
  public_subnet_cidrs   = local.cfg.public_subnet_cidrs
  database_subnet_cidrs = local.cfg.database_subnet_cidrs

  single_nat_gateway = local.cfg.single_nat_gateway
  enable_flow_log    = local.cfg.enable_flow_log

  tags = local.cfg.tags
}
