# Worked example: one HTTPS API end to end.
#
#   terraform init
#   terraform plan
#
# config.yml beside this file is read by every module, because each resolves
# file("${path.cwd}/${var.config_file}") and Terraform is run from here.

terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
  }
}

provider "aws" {
  region = local.global.region
}

locals {
  config = yamldecode(file("${path.cwd}/config.yml"))

  global = {
    environment = local.config.global.environment
    region      = local.config.global.region
    project     = local.config.global.project
  }
}

module "vpc" {
  source        = "../../modules/vpc"
  config_file   = "config.yml"
  global_config = local.global
}

module "alb" {
  source          = "../../modules/alb"
  config_file     = "config.yml"
  global_config   = local.global
  vpc_id          = module.vpc.vpc_id
  vpc_cidr_block  = module.vpc.vpc_cidr_block
  public_subnets  = module.vpc.public_subnets
  private_subnets = module.vpc.private_subnets
}

module "ecs_cluster" {
  source        = "../../modules/ecs_cluster"
  config_file   = "config.yml"
  global_config = local.global
  vpc_id        = module.vpc.vpc_id
}

module "ecs_service" {
  source          = "../../modules/ecs_service"
  config_file     = "config.yml"
  global_config   = local.global
  cluster_arn     = module.ecs_cluster.cluster_arn
  listener_arn    = module.alb.http_tcp_listener_arns[0]
  vpc_id          = module.vpc.vpc_id
  vpc_cidr_block  = module.vpc.vpc_cidr_block
  private_subnets = module.vpc.private_subnets
}

module "dns" {
  source        = "../../modules/dns"
  config_file   = "config.yml"
  global_config = local.global

  # alias.target = "alb" in config.yml resolves from these.
  alb_dns_name = module.alb.lb_dns_name
  alb_zone_id  = module.alb.lb_zone_id
}
