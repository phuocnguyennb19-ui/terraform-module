# ==============================================================================
# ROOT COMPOSITION
# ==============================================================================
# Wires the modules under modules/ into one stack for one environment.
#
#   - Every module is gated by count, because no module has an internal
#     `enabled` flag (CLAUDE.md § "enabled is the caller's flag").
#   - Every module receives the same config_file string and resolves its own
#     block out of that YAML itself. The root does not translate config.
#   - Wiring inputs (vpc_id, subnets, ARNs) are the only values the root passes
#     between modules; everything else travels through config.yml.
#
# Bands below are dependency order. Terraform derives the real order from the
# references — the grouping is for the reader.
# ==============================================================================

# ------------------------------------------------------------------------------
# BAND 1 — FOUNDATION
# ------------------------------------------------------------------------------

module "vpc" {
  count  = local.enabled.vpc ? 1 : 0
  source = "./modules/vpc"

  config_file   = local.config_path
  manual_config = local.manual["vpc"]
  global_config = local.global
  tags          = var.tags
}

module "kms" {
  count  = local.enabled.kms ? 1 : 0
  source = "./modules/kms"

  config_file   = local.config_path
  manual_config = local.manual["kms"]
  global_config = local.global
  tags          = var.tags
}

module "iam" {
  count  = local.enabled.iam ? 1 : 0
  source = "./modules/iam"

  config_file   = local.config_path
  manual_config = local.manual["iam"]
  global_config = local.global
  tags          = var.tags
}

# ------------------------------------------------------------------------------
# BAND 2 — PRIMITIVES
# ------------------------------------------------------------------------------

module "security_group" {
  count  = local.enabled.security_group ? 1 : 0
  source = "./modules/security_group"

  vpc_id = local.vpc_id

  config_file   = local.config_path
  manual_config = local.manual["security_group"]
  global_config = local.global
  tags          = var.tags
}

module "acm" {
  count  = local.enabled.acm ? 1 : 0
  source = "./modules/acm"

  config_file   = local.config_path
  manual_config = local.manual["acm"]
  global_config = local.global
  tags          = var.tags
}

module "waf" {
  count  = local.enabled.waf ? 1 : 0
  source = "./modules/waf"

  config_file   = local.config_path
  manual_config = local.manual["waf"]
  global_config = local.global
  tags          = var.tags
}

module "ecr" {
  count  = local.enabled.ecr ? 1 : 0
  source = "./modules/ecr"

  config_file   = local.config_path
  manual_config = local.manual["ecr"]
  global_config = local.global
  tags          = var.tags
}

module "secrets_manager" {
  count  = local.enabled.secrets_manager ? 1 : 0
  source = "./modules/secrets_manager"

  config_file   = local.config_path
  manual_config = local.manual["secrets_manager"]
  global_config = local.global
  tags          = var.tags
}

module "s3" {
  count  = local.enabled.s3 ? 1 : 0
  source = "./modules/s3"

  config_file   = local.config_path
  manual_config = local.manual["s3"]
  global_config = local.global
  tags          = var.tags
}

module "dynamodb" {
  count  = local.enabled.dynamodb ? 1 : 0
  source = "./modules/dynamodb"

  config_file   = local.config_path
  manual_config = local.manual["dynamodb"]
  global_config = local.global
  tags          = var.tags
}

module "sqs" {
  count  = local.enabled.sqs ? 1 : 0
  source = "./modules/sqs"

  config_file   = local.config_path
  manual_config = local.manual["sqs"]
  global_config = local.global
  tags          = var.tags
}

module "sns" {
  count  = local.enabled.sns ? 1 : 0
  source = "./modules/sns"

  config_file   = local.config_path
  manual_config = local.manual["sns"]
  global_config = local.global
  tags          = var.tags
}

module "cloudwatch" {
  count  = local.enabled.cloudwatch ? 1 : 0
  source = "./modules/cloudwatch"

  config_file   = local.config_path
  manual_config = local.manual["cloudwatch"]
  global_config = local.global
  tags          = var.tags
}

# ------------------------------------------------------------------------------
# BAND 3 — EDGE & DATA
# ------------------------------------------------------------------------------

module "alb" {
  count  = local.enabled.alb ? 1 : 0
  source = "./modules/alb"

  vpc_id          = local.vpc_id
  vpc_cidr_block  = local.vpc_cidr_block
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets

  config_file   = local.config_path
  manual_config = local.manual["alb"]
  global_config = local.global
  tags          = var.tags
}

module "rds" {
  count  = local.enabled.rds ? 1 : 0
  source = "./modules/rds"

  vpc_id          = local.vpc_id
  vpc_cidr_block  = local.vpc_cidr_block
  private_subnets = local.database_subnets

  config_file   = local.config_path
  manual_config = local.manual["rds"]
  global_config = local.global
  tags          = var.tags
}

module "elasticache" {
  count  = local.enabled.elasticache ? 1 : 0
  source = "./modules/elasticache"

  vpc_id          = local.vpc_id
  private_subnets = local.private_subnets

  config_file   = local.config_path
  manual_config = local.manual["elasticache"]
  global_config = local.global
  tags          = var.tags
}

module "dns" {
  count  = local.enabled.dns ? 1 : 0
  source = "./modules/dns"

  # Lets a record declare alias.target = "alb" instead of a value nobody can know
  # before apply. See modules/dns/locals.tf.
  alb_dns_name = local.alb_dns_name
  alb_zone_id  = local.alb_zone_id

  config_file   = local.config_path
  manual_config = local.manual["dns"]
  global_config = local.global
  tags          = var.tags
}

# ------------------------------------------------------------------------------
# BAND 4 — COMPUTE
# ------------------------------------------------------------------------------

module "ecs_cluster" {
  count  = local.enabled.ecs_cluster ? 1 : 0
  source = "./modules/ecs_cluster"

  vpc_id = local.vpc_id

  config_file   = local.config_path
  manual_config = local.manual["ecs_cluster"]
  global_config = local.global
  tags          = var.tags
}

module "eks" {
  count  = local.enabled.eks ? 1 : 0
  source = "./modules/eks"

  vpc_id          = local.vpc_id
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  config_file   = local.config_path
  manual_config = local.manual["eks"]
  global_config = local.global
  tags          = var.tags
}

module "ecs_service" {
  count  = local.enabled.ecs_service ? 1 : 0
  source = "./modules/ecs_service"

  cluster_arn     = local.cluster_arn
  listener_arn    = local.listener_arn
  vpc_id          = local.vpc_id
  vpc_cidr_block  = local.vpc_cidr_block
  private_subnets = local.private_subnets

  config_file   = local.config_path
  manual_config = local.manual["ecs_service"]
  global_config = local.global
  tags          = var.tags
}
