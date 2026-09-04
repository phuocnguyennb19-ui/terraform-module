module "elasticache" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-elasticache.git?ref=v1.1.0"

  cluster_id      = local.elasticache_config.cluster_id
  engine          = local.elasticache_config.engine
  node_type       = local.elasticache_config.node_type
  num_cache_nodes = local.elasticache_config.num_cache_nodes
  engine_version  = local.elasticache_config.engine_version
  port            = local.elasticache_config.port

  # Network — supplied by the caller
  subnet_ids = var.private_subnets

  # Security
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  kms_key_arn                = local.elasticache_config.kms_key_arn
  security_group_ids         = local.elasticache_config.security_group_ids

  automatic_failover_enabled = local.elasticache_config.automatic_failover_enabled
  multi_az_enabled           = local.elasticache_config.multi_az_enabled

  # Operational
  maintenance_window         = local.elasticache_config.maintenance_window
  snapshot_retention_limit   = local.elasticache_config.snapshot_retention_limit
  snapshot_window            = local.elasticache_config.snapshot_window
  apply_immediately          = local.elasticache_config.apply_immediately
  auto_minor_version_upgrade = local.elasticache_config.auto_minor_version_upgrade
  parameter_group_name       = local.elasticache_config.parameter_group_name

  # Sharding (Redis Cluster Mode)
  num_node_groups         = local.elasticache_config.num_node_groups
  replicas_per_node_group = local.elasticache_config.replicas_per_node_group

  tags = local.tags
}
