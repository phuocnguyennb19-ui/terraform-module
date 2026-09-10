provider "aws" {
  region = local.region

  dynamic "assume_role" {
    for_each = local.assume_role_arn != null ? [1] : []

    content {
      role_arn     = local.assume_role_arn
      session_name = "terraform-${local.project}-${local.environment}"
    }
  }

  default_tags {
    tags = {
      Project     = local.project
      Environment = local.environment
      ManagedBy   = "terraform"
    }
  }
}
