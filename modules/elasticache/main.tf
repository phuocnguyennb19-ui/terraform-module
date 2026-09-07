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

  # full upstream surface
  auth_token                                = local.elasticache_config.auth_token
  auth_token_update_strategy                = local.elasticache_config.auth_token_update_strategy
  availability_zone                         = local.elasticache_config.availability_zone
  az_mode                                   = local.elasticache_config.az_mode
  cluster_mode_enabled                      = local.elasticache_config.cluster_mode_enabled
  create                                    = local.elasticache_config.create
  create_cluster                            = local.elasticache_config.create_cluster
  create_parameter_group                    = local.elasticache_config.create_parameter_group
  create_primary_global_replication_group   = local.elasticache_config.create_primary_global_replication_group
  create_replication_group                  = local.elasticache_config.create_replication_group
  create_secondary_global_replication_group = local.elasticache_config.create_secondary_global_replication_group
  create_security_group                     = local.elasticache_config.create_security_group
  create_subnet_group                       = local.elasticache_config.create_subnet_group
  data_tiering_enabled                      = local.elasticache_config.data_tiering_enabled
  description                               = local.elasticache_config.description
  final_snapshot_identifier                 = local.elasticache_config.final_snapshot_identifier
  global_replication_group_id               = local.elasticache_config.global_replication_group_id
  ip_discovery                              = local.elasticache_config.ip_discovery
  network_type                              = local.elasticache_config.network_type
  notification_topic_arn                    = local.elasticache_config.notification_topic_arn
  num_cache_clusters                        = local.elasticache_config.num_cache_clusters
  outpost_mode                              = local.elasticache_config.outpost_mode
  parameter_group_description               = local.elasticache_config.parameter_group_description
  parameter_group_family                    = local.elasticache_config.parameter_group_family
  parameters                                = local.elasticache_config.parameters
  preferred_availability_zones              = local.elasticache_config.preferred_availability_zones
  preferred_cache_cluster_azs               = local.elasticache_config.preferred_cache_cluster_azs
  preferred_outpost_arn                     = local.elasticache_config.preferred_outpost_arn
  replication_group_id                      = local.elasticache_config.replication_group_id
  security_group_description                = local.elasticache_config.security_group_description
  security_group_name                       = local.elasticache_config.security_group_name
  security_group_names                      = local.elasticache_config.security_group_names
  security_group_rules                      = local.elasticache_config.security_group_rules
  security_group_tags                       = local.elasticache_config.security_group_tags
  security_group_use_name_prefix            = local.elasticache_config.security_group_use_name_prefix
  snapshot_arns                             = local.elasticache_config.snapshot_arns
  snapshot_name                             = local.elasticache_config.snapshot_name
  subnet_group_description                  = local.elasticache_config.subnet_group_description
  subnet_group_name                         = local.elasticache_config.subnet_group_name
  user_group_ids                            = local.elasticache_config.user_group_ids
  vpc_id                                    = local.elasticache_config.vpc_id
}
