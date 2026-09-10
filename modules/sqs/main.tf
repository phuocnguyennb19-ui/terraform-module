module "sqs" {
  for_each = local.queues
  source   = "git::https://github.com/terraform-aws-modules/terraform-aws-sqs.git?ref=v4.2.1"

  name = lookup(each.value, "name", "${local.name_prefix}-${each.key}")

  fifo_queue                  = lookup(each.value, "fifo_queue", false)
  content_based_deduplication = lookup(each.value, "content_based_deduplication", false)

  visibility_timeout_seconds = lookup(each.value, "visibility_timeout_seconds", 30)
  message_retention_seconds  = lookup(each.value, "message_retention_seconds", 345600)
  max_message_size           = lookup(each.value, "max_message_size", 262144)
  delay_seconds              = lookup(each.value, "delay_seconds", 0)
  receive_wait_time_seconds  = lookup(each.value, "receive_wait_time_seconds", 0)

  kms_master_key_id                 = lookup(each.value, "kms_master_key_id", null)
  kms_data_key_reuse_period_seconds = lookup(each.value, "kms_data_key_reuse_period_seconds", 300)
  sqs_managed_sse_enabled           = lookup(each.value, "kms_master_key_id", null) == null

  redrive_policy       = lookup(each.value, "redrive_policy", {})
  redrive_allow_policy = lookup(each.value, "redrive_allow_policy", {})

  create_queue_policy           = lookup(each.value, "policy", null) != null || lookup(each.value, "queue_policy_statements", null) != null
  source_queue_policy_documents = lookup(each.value, "policy", null) != null ? [each.value.policy] : []
  queue_policy_statements       = lookup(each.value, "queue_policy_statements", {})

  tags = local.tags
}
