data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# count = 0 data sources are still schema-validated, hence the placeholder fallbacks.
data "aws_vpc" "existing" {
  count = local.lookup_vpc ? 1 : 0

  filter {
    name   = "tag:Name"
    values = [try(local.existing.vpc.name_tag, "unset")]
  }
}

data "aws_subnets" "private" {
  count = local.lookup_subnets ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [try(data.aws_vpc.existing[0].id, "vpc-unset")]
  }

  dynamic "filter" {
    for_each = try(local.existing.private_subnets.tags, {})

    content {
      name   = "tag:${filter.key}"
      values = [filter.value]
    }
  }
}

data "aws_security_group" "ecs" {
  count = local.lookup_vpc && try(local.existing.ecs_security_group.name, null) != null ? 1 : 0

  vpc_id = try(data.aws_vpc.existing[0].id, null)
  name   = try(local.existing.ecs_security_group.name, "unset")
}

data "aws_lb" "existing" {
  count = local.lookup_alb ? 1 : 0

  name = try(local.existing.alb.name, "unset")
}

data "aws_lb_target_group" "existing" {
  for_each = local.lookup_alb ? try(local.existing.alb.target_group_names, {}) : {}

  name = each.value
}

data "aws_ecs_cluster" "existing" {
  count = local.lookup_cluster ? 1 : 0

  cluster_name = try(local.existing.ecs_cluster.name, "unset")
}

data "aws_kms_key" "existing" {
  for_each = local.enabled.kms ? {} : try(local.existing.kms_aliases, {})

  key_id = each.value
}

locals {
  vpc_id = local.enabled.vpc ? module.vpc[0].vpc_id : try(data.aws_vpc.existing[0].id, null)

  vpc_cidr_block = local.enabled.vpc ? module.vpc[0].vpc_cidr_block : try(data.aws_vpc.existing[0].cidr_block, null)

  private_subnet_ids = local.enabled.vpc ? module.vpc[0].private_subnet_ids : try(data.aws_subnets.private[0].ids, [])

  public_subnet_ids = local.enabled.vpc ? module.vpc[0].public_subnet_ids : []

  database_subnet_group_name = local.enabled.vpc ? module.vpc[0].database_subnet_group_name : try(local.existing.database_subnet_group_name, null)

  elasticache_subnet_group_name = local.enabled.vpc ? module.vpc[0].elasticache_subnet_group_name : try(local.existing.elasticache_subnet_group_name, null)

  kms_key_arns = local.enabled.kms ? module.kms[0].key_arns : { for k, v in data.aws_kms_key.existing : k => v.arn }

  ecs_security_group_ids = compact(
    local.enabled.security_groups
    ? [try(module.security_groups[0].ecs_sg_id, null)]
    : [try(data.aws_security_group.ecs[0].id, null)]
  )

  cluster_arn = local.enabled.ecs_cluster ? module.ecs_cluster[0].arn : try(data.aws_ecs_cluster.existing[0].arn, null)

  target_group_arns = merge(
    local.enabled.alb ? module.alb[0].target_group_arns : {},
    { for k, v in data.aws_lb_target_group.existing : k => v.arn },
  )
}
