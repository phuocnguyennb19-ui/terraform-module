terraform_version_constraint  = ">= 1.6.0, < 2.0.0"
terragrunt_version_constraint = ">= 0.55.0"

locals {
  # Đọc region + account từ values.base.yml của env hiện tại
  env_path   = split("/", path_relative_to_include())
  env_name   = local.env_path[0]

  # values.base.yml nằm trong live/{env}/
  base_file  = "${get_terragrunt_dir()}/live/${local.env_name}/values.base.yml"
  base       = fileexists(local.base_file) ? yamldecode(file(local.base_file)) : {}

  region     = try(local.base.global.region,     "ap-southeast-1")
  account_id = try(local.base.global.account_id, get_aws_account_id())
  role_arn   = try(local.base.global.deploy_role_arn, "")
}

remote_state {
  backend = "s3"

  config = {
    bucket         = "tf-state-${local.account_id}-${local.region}"
    key            = "${local.env_name}/${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    encrypt        = true
    dynamodb_table = "tf-locks-${local.account_id}"

    skip_bucket_versioning   = false
    skip_bucket_ssencryption = false
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<-EOF
    terraform {
      required_version = ">= 1.6.0, < 2.0.0"
      required_providers {
        aws = { source = "hashicorp/aws", version = "~> 5.0" }
      }
    }

    provider "aws" {
      region = "${local.region}"

      %{ if local.role_arn != "" ~}
      assume_role { role_arn = "${local.role_arn}" }
      %{ endif ~}

      default_tags {
        tags = {
          ManagedBy   = "terragrunt"
          Environment = "${local.env_name}"
        }
      }
    }
  EOF
}
