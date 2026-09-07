# Floor is 1.3, not 1.0: every module under modules/ uses optional(<type>, <default>)
# inside an object type, a Terraform 1.3 feature.

terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
  }
}
