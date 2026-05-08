module "dynamodb_table" {
  for_each = local.tables
  source   = "git::https://github.com/terraform-aws-modules/terraform-aws-dynamodb-table.git?ref=v4.1.0"

  name      = lookup(each.value, "name", "${local.name_prefix}-${each.key}")
  hash_key  = lookup(each.value, "hash_key", "id")
  range_key = lookup(each.value, "range_key", null)

  attributes = lookup(each.value, "attributes", [
    {
      name = "id"
      type = "S"
    }
  ])

  billing_mode   = lookup(each.value, "billing_mode", "PAY_PER_REQUEST")
  read_capacity  = lookup(each.value, "read_capacity", null)
  write_capacity = lookup(each.value, "write_capacity", null)

  # Indexes
  global_secondary_indexes = lookup(each.value, "global_secondary_indexes", [])
  local_secondary_indexes  = lookup(each.value, "local_secondary_indexes", [])

  # TTL
  ttl_attribute_name = lookup(each.value, "ttl_attribute_name", null)
  ttl_enabled        = lookup(each.value, "ttl_attribute_name", null) != null

  # Streams
  stream_enabled   = lookup(each.value, "stream_enabled", false)
  stream_view_type = lookup(each.value, "stream_view_type", null)

  # Encryption
  server_side_encryption_enabled     = lookup(each.value, "server_side_encryption_enabled", true)
  server_side_encryption_kms_key_arn = lookup(each.value, "kms_key_arn", null)

  # Backup
  point_in_time_recovery_enabled = lookup(each.value, "point_in_time_recovery_enabled", local.env == "prod")

  # Deletion protection
  deletion_protection_enabled = lookup(each.value, "deletion_protection_enabled", local.env == "prod")

  tags = local.tags
}
