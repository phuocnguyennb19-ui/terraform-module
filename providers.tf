# ==============================================================================
# PROVIDER CONFIGURATION
# ==============================================================================
# Providers are configured here and only here. No module under modules/ declares
# a provider block, which is what lets the same module serve every environment.
#
# Two targets, one provider. Leaving localstack_endpoint unset talks to real AWS
# through the normal credential chain; setting it redirects every service this
# repository can build to a local emulator and swaps in throwaway credentials.
#
#   terraform plan -var="localstack_endpoint=http://localhost:4566"
#
# ⚠ Every service a module touches must appear in the endpoints block below.
#   A service that is missing does not fail — it silently leaves for REAL AWS.
#   That is how a CreateLogGroup call reached the real account and was stopped
#   only by the credentials being fake. When a module is added to this repo, add
#   its service here in the same change.
#
# The region and tags come from the environment's config.yml, so a run cannot
# target a region the config does not name.
# ==============================================================================

locals {
  use_localstack = var.localstack_endpoint != null
}

provider "aws" {
  region = local.global.region

  access_key = local.use_localstack ? "test" : null
  secret_key = local.use_localstack ? "test" : null

  # Relaxed for the emulator only. Against real AWS every check stays on.
  skip_credentials_validation = local.use_localstack
  skip_metadata_api_check     = local.use_localstack
  skip_region_validation      = local.use_localstack
  skip_requesting_account_id  = local.use_localstack
  s3_use_path_style           = local.use_localstack

  dynamic "endpoints" {
    for_each = local.use_localstack ? [1] : []

    content {
      # Identity and core
      sts = var.localstack_endpoint
      iam = var.localstack_endpoint
      kms = var.localstack_endpoint
      ec2 = var.localstack_endpoint
      s3  = var.localstack_endpoint

      # Observability — `logs` was the one missing before.
      logs       = var.localstack_endpoint
      cloudwatch = var.localstack_endpoint
      events     = var.localstack_endpoint

      # Data and messaging
      secretsmanager = var.localstack_endpoint
      ssm            = var.localstack_endpoint
      dynamodb       = var.localstack_endpoint
      sns            = var.localstack_endpoint
      sqs            = var.localstack_endpoint
      rds            = var.localstack_endpoint
      elasticache    = var.localstack_endpoint

      # Edge and DNS
      elbv2   = var.localstack_endpoint
      elb     = var.localstack_endpoint
      route53 = var.localstack_endpoint
      acm     = var.localstack_endpoint
      wafv2   = var.localstack_endpoint

      # Compute
      ecr            = var.localstack_endpoint
      ecs            = var.localstack_endpoint
      eks            = var.localstack_endpoint
      autoscaling    = var.localstack_endpoint
      appautoscaling = var.localstack_endpoint
    }
  }

  default_tags {
    tags = {
      ManagedBy   = local.global.managed_by
      Environment = local.global.environment
      Project     = local.global.project
    }
  }
}
