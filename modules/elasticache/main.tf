# Fix 4a: Bỏ for_each, dùng trực tiếp elasticache_config (object đơn)
# Đồng thời Fix 1: Xóa fallback vào Remote State
module "elasticache" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-elasticache.git?ref=v1.1.0"

  cluster_id      = try(local.elasticache_config.cluster_id, "${local.name_prefix}-redis")
  engine          = try(local.elasticache_config.engine, "redis")
  node_type       = try(local.elasticache_config.node_type, "cache.t3.micro")
  num_cache_nodes = try(local.elasticache_config.num_cache_nodes, 1)
  engine_version  = try(local.elasticache_config.engine_version, "7.0")
  port            = try(local.elasticache_config.port, 6379)

  # Network — nhận từ orchestrator
  subnet_ids = var.private_subnets

  # Security
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  kms_key_arn                = try(local.elasticache_config.kms_key_arn, null)

  tags = local.tags
}
