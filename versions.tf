# ==============================================================================
# TERRAFORM & PROVIDER CONSTRAINTS — ROOT COMPOSITION
# ==============================================================================
# Floor is 1.3, not 1.0: every module under modules/ uses optional(<type>, <default>)
# inside an object type, which is a Terraform 1.3 feature. See CLAUDE.md § Known defects.
# ==============================================================================

terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
  }
}
