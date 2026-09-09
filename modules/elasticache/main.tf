# ELASTICACHE (REDIS) REPLICATION GROUP
#
# Placed in the foundation's cache subnet group — which spans the database
# subnets — and the platform's cache security group. Both are inputs.
#
# Written against the provider directly. The replication group is one resource
# plus a parameter group, and the community module's main value is defaults this
# platform sets explicitly anyway.
#
# Encryption at rest and in transit default to on. Both are immutable after
# creation on the engine versions in common use, so turning them on later means
# building a new cache and cutting over.

data "aws_secretsmanager_secret_version" "auth_token" {
  count = var.auth_token_secret_arn != null ? 1 : 0

  secret_id = var.auth_token_secret_arn
}

resource "aws_elasticache_parameter_group" "this" {
  name        = "${var.name}-${replace(var.parameter_group_family, ".", "")}"
  family      = var.parameter_group_family
  description = "Parameter group for ${var.name}"

  dynamic "parameter" {
    for_each = var.parameters

    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(var.tags, { Name = "${var.name}-params" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = var.name
  description          = var.description

  engine         = "redis"
  engine_version = var.engine_version
  node_type      = var.node_type
  port           = var.port

  parameter_group_name = aws_elasticache_parameter_group.this.name

  # ---- Placement, from the foundation -------------------------------------
  subnet_group_name  = var.subnet_group_name
  security_group_ids = var.security_group_ids

  # ---- Topology -----------------------------------------------------------
  # num_cache_clusters and num_node_groups are mutually exclusive: the first
  # describes a non-sharded group, the second a sharded one.
  num_cache_clusters      = var.cluster_mode_enabled ? null : var.num_cache_clusters
  num_node_groups         = var.cluster_mode_enabled ? var.num_node_groups : null
  replicas_per_node_group = var.cluster_mode_enabled ? var.replicas_per_node_group : null

  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.automatic_failover_enabled ? var.multi_az_enabled : false

  # ---- Encryption ---------------------------------------------------------
  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = var.transit_encryption_enabled
  kms_key_id                 = var.at_rest_encryption_enabled ? var.kms_key_arn : null

  auth_token = var.auth_token_secret_arn != null ? data.aws_secretsmanager_secret_version.auth_token[0].secret_string : null

  # ---- Backup and maintenance --------------------------------------------
  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = var.snapshot_retention_limit > 0 ? var.snapshot_window : null
  maintenance_window       = var.maintenance_window

  apply_immediately          = var.apply_immediately
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  notification_topic_arn = var.notification_topic_arn

  dynamic "log_delivery_configuration" {
    for_each = var.log_delivery

    content {
      destination      = log_delivery_configuration.value.destination
      destination_type = log_delivery_configuration.value.destination_type
      log_format       = log_delivery_configuration.value.log_format
      log_type         = log_delivery_configuration.key
    }
  }

  tags = merge(var.tags, { Name = var.name })

  lifecycle {
    # The auth token is read from Secrets Manager at plan time. Rotating the
    # secret would otherwise show as a diff on every plan after rotation and
    # trigger a modification of the replication group; rotation is handled
    # through the ElastiCache AUTH rotation strategy, not by Terraform.
    ignore_changes = [auth_token]
  }
}
