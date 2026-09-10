terraform {
  required_version = ">= 1.5.7, < 2.0.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # < 6.0: the pinned terraform-aws-modules releases do not support provider 6.x.
      version = ">= 5.80.0, < 6.0.0"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0, < 4.0.0"
    }
  }
}
