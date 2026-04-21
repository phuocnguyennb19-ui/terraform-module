# ==============================================================================
# INFRASTRUCTURE ENGINE - FOUNDATIONAL RESOURCES
# ==============================================================================

# 1. Identity & Access (IAM)
module "iam" {
  count  = try(local.config.iam.enabled, false) ? 1 : 0
  source = "../modules/iam"
}

# 2. Network Layer (VPC)
module "vpc" {
  count  = try(local.config.vpc.enabled, false) ? 1 : 0
  source = "../modules/vpc"
}

# 3. Security (KMS & Secrets Manager)
module "kms" {
  count  = try(local.config.kms.enabled, false) ? 1 : 0
  source = "../modules/kms"
}

module "secrets_manager" {
  count  = try(local.config.secrets_manager.enabled, false) ? 1 : 0
  source = "../modules/secrets-manager"
}

# 4. Storage (S3)
module "s3" {
  count  = try(local.config.s3.enabled, false) ? 1 : 0
  source = "../modules/s3"
}

# 5. Domain & SSL (Route53 & ACM)
module "route53" {
  count  = try(local.config.route53.enabled, false) ? 1 : 0
  source = "../modules/route53"
}

module "acm" {
  count  = try(local.config.acm.enabled, false) ? 1 : 0
  source = "../modules/acm"
}

# 6. Container Registry (ECR)
module "ecr" {
  count  = try(local.config.ecr.enabled, false) ? 1 : 0
  source = "../modules/ecr"
}

# Outputs for Platform Engine
output "vpc_id" {
  value = try(module.vpc[0].vpc_id, null)
}

output "public_subnets" {
  value = try(module.vpc[0].public_subnets, null)
}

output "private_subnets" {
  value = try(module.vpc[0].private_subnets, null)
}

output "vpc_cidr_block" {
  value = try(module.vpc[0].vpc_cidr_block, null)
}
