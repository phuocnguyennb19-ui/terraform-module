module "elasticache_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name   = "${var.name}-${var.environment}-cache-sg"
  vpc_id = var.vpc_id

  ingress_with_source_security_group_id = [
    for sg_id in var.allowed_security_group_ids : {
      rule                     = var.engine == "redis" ? "redis-tcp" : "memcached-tcp"
      source_security_group_id = sg_id
    }
  ]

  egress_rules = ["all-all"]
  tags         = var.tags
}

module "elasticache" {
  source  = "terraform-aws-modules/elasticache/aws"
  version = "~> 1.0"

  cluster_id = "${var.name}-${var.environment}"
  engine     = var.engine

  engine_version       = var.engine_version
  node_type            = var.node_type
  port                 = var.port
  parameter_group_name = var.parameter_group_name

  subnet_ids         = var.subnet_ids
  security_group_ids = [module.elasticache_sg.security_group_id]

  # Cluster mode (Redis sharding)
  num_node_groups         = var.cluster_mode.enabled ? var.cluster_mode.num_node_groups : null
  replicas_per_node_group = var.cluster_mode.enabled ? var.cluster_mode.replicas_per_node_group : null
  num_cache_nodes         = var.cluster_mode.enabled ? null : var.num_cache_nodes

  automatic_failover_enabled = var.engine == "redis" ? var.automatic_failover_enabled : null
  multi_az_enabled           = var.engine == "redis" ? var.multi_az_enabled : null

  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = var.engine == "redis" ? var.transit_encryption_enabled : null

  tags = var.tags
}
