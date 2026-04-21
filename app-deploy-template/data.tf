data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket  = local.config_all.global.terraform_state_bucket
    key     = "platform/${local.env}/vpc/terraform.tfstate"
    region  = local.region
    profile = local.profile
  }
}

data "terraform_remote_state" "ecs" {
  backend = "s3"
  config = {
    bucket  = local.config_all.global.terraform_state_bucket
    key     = "platform/${local.env}/ecs-cluster/terraform.tfstate"
    region  = local.region
    profile = local.profile
  }
}

data "terraform_remote_state" "alb" {
  backend = "s3"
  config = {
    bucket  = local.config_all.global.terraform_state_bucket
    key     = "platform/${local.env}/alb/terraform.tfstate"
    region  = local.region
    profile = local.profile
  }
}
