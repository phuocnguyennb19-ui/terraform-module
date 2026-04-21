# ==============================================================================
# MASTER ORCHESTRATOR - THE 13-SERVICE UNIFIED ENGINE
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

# 6. Load Balancing (ALB) — Wired to VPC
module "alb" {
  count  = try(local.config.alb.enabled, false) ? 1 : 0
  source = "../modules/alb"

  vpc_id         = try(module.vpc[0].vpc_id, null)
  public_subnets = try(module.vpc[0].public_subnets, null)
}

# 7. Compute (ECS Cluster) — Wired to VPC
module "ecs_cluster" {
  count  = try(local.config.ecs_cluster.enabled, false) ? 1 : 0
  source = "../modules/ecs-cluster"
  vpc_id = try(module.vpc[0].vpc_id, null)
}

# 8. Web Application Firewall
module "waf" {
  count  = try(local.config.waf.enabled, false) ? 1 : 0
  source = "../modules/waf"
}

# 9. Database (RDS) — Wired to VPC
module "rds" {
  count  = try(local.config.rds.enabled, false) ? 1 : 0
  source = "../modules/rds"

  vpc_id          = try(module.vpc[0].vpc_id, null)
  vpc_cidr_block  = try(module.vpc[0].vpc_cidr_block, "10.0.0.0/16")
  private_subnets = try(module.vpc[0].private_subnets, null)
}

# 10. Cache (ElastiCache) — Wired to VPC
module "elasticache" {
  count  = try(local.config.elasticache.enabled, false) ? 1 : 0
  source = "../modules/elasticache"

  vpc_id          = try(module.vpc[0].vpc_id, null)
  private_subnets = try(module.vpc[0].private_subnets, null)
}

# 11. Application Runner (ECS Service) — Fully Wired
module "ecs_service" {
  count  = try(local.config.service.enabled, false) ? 1 : 0
  source = "../modules/ecs-service"

  # Full Orchestration Wiring (Fix: dùng account_id thật)
  vpc_id          = try(module.vpc[0].vpc_id, null)
  private_subnets = try(module.vpc[0].private_subnets, null)
  vpc_cidr_block  = try(module.vpc[0].vpc_cidr_block, "10.0.0.0/16")
  cluster_arn     = try(module.ecs_cluster[0].cluster_arn, null)
  listener_arn    = try(module.alb[0].http_tcp_listener_arns[0], null)
}
