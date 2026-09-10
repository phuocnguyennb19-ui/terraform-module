locals {
  # Resolved against the directory Terraform runs from: run it from this root.
  config = yamldecode(file("${path.cwd}/${var.config_file}"))

  project     = local.config.global.project
  environment = local.config.global.environment
  region      = local.config.global.region

  name_prefix = "${local.project}-${local.environment}"
  is_prod     = local.environment == "prod"

  assume_role_arn = try(local.config.global.assume_role_arn, null)

  common_tags = merge(
    {
      Project     = local.project
      Environment = local.environment
      Owner       = try(local.config.global.owner, "platform-engineering")
      CostCenter  = try(local.config.global.cost_center, "platform")
      ManagedBy   = "terraform"
      Repository  = "terraform-aws-platform"
    },
    try(local.config.global.tags, {}),
    var.tags,
  )

  enabled = {
    kms             = try(local.config.kms.enabled, false)
    vpc             = try(local.config.vpc.enabled, false)
    security_groups = try(local.config.security_groups.enabled, false)
    iam             = try(local.config.iam.enabled, false)
    cloudwatch      = try(local.config.cloudwatch.enabled, false)
    ecr             = try(local.config.ecr.enabled, false)
    route53         = try(local.config.route53.enabled, false)
    acm             = try(local.config.acm.enabled, false)
    alb             = try(local.config.alb.enabled, false)
    ecs_cluster     = try(local.config.ecs_cluster.enabled, false)
    eks             = try(local.config.eks.enabled, false)
    ec2             = try(local.config.ec2.enabled, false)
    rds             = try(local.config.rds.enabled, false)
    elasticache     = try(local.config.elasticache.enabled, false)
    lambda          = try(local.config.lambda.enabled, false)
  }

  ecs_services = try(local.config.ecs_services, {})

  existing = try(local.config.existing, {})

  lookup_vpc     = !local.enabled.vpc && try(local.existing.vpc.name_tag, null) != null
  lookup_subnets = !local.enabled.vpc && try(local.existing.private_subnets.tag, null) != null
  lookup_alb     = !local.enabled.alb && try(local.existing.alb.name, null) != null
  lookup_cluster = !local.enabled.ecs_cluster && try(local.existing.ecs_cluster.name, null) != null

  # Production floor: in prod these cannot be weakened from the config.
  hardened = {
    single_nat_gateway      = local.is_prod ? false : try(local.config.vpc.single_nat_gateway, false)
    enable_flow_logs        = local.is_prod ? true : try(local.config.vpc.enable_flow_logs, true)
    flow_log_retention_days = local.is_prod ? max(try(local.config.vpc.flow_log_retention_days, 30), 90) : try(local.config.vpc.flow_log_retention_days, 30)
    log_retention_days      = local.is_prod ? max(try(local.config.cloudwatch.log_retention_days, 30), 90) : try(local.config.cloudwatch.log_retention_days, 30)

    rds_multi_az                = local.is_prod ? true : try(local.config.rds.multi_az, false)
    rds_backup_retention_period = local.is_prod ? max(try(local.config.rds.backup_retention_period, 7), 30) : try(local.config.rds.backup_retention_period, 7)
    rds_deletion_protection     = local.is_prod
    rds_skip_final_snapshot     = !local.is_prod
    rds_apply_immediately       = !local.is_prod

    alb_deletion_protection = local.is_prod

    eks_public_api_access = local.is_prod ? false : try(local.config.eks.public_api_access, false)

    elasticache_num_cache_clusters = local.is_prod ? max(try(local.config.elasticache.num_cache_clusters, 1), 2) : try(local.config.elasticache.num_cache_clusters, 1)
    elasticache_snapshot_retention = local.is_prod ? 7 : 1

    ec2_termination_protection = local.is_prod

    ecs_min_tasks = local.is_prod ? 2 : 1
  }

  eks_cluster_name  = "${local.name_prefix}-eks"
  eks_cluster_names = local.enabled.eks ? [local.eks_cluster_name] : []

  domain_name  = try(local.config.route53.domain_name, null)
  app_hostname = try(local.config.route53.app_hostname, null)

  app_fqdn = local.enabled.route53 && local.domain_name != null ? (
    local.app_hostname != null ? "${local.app_hostname}.${local.domain_name}" : local.domain_name
  ) : null

  application_port = try(local.config.alb.application_port, 8080)
  rds_engine       = try(local.config.rds.engine, "postgres")
  rds_port         = local.rds_engine == "postgres" ? 5432 : 3306
  cache_port       = 6379
  rds_identifier   = "${local.name_prefix}-${local.rds_engine}"

  target_group_type = local.enabled.ecs_cluster || length(local.ecs_services) > 0 || local.enabled.eks ? "ip" : "instance"
}
