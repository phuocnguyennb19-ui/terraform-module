module "sns" {
  for_each = local.topics
  source   = "git::https://github.com/terraform-aws-modules/terraform-aws-sns.git?ref=v6.1.1"

  name = lookup(each.value, "name", "${local.name_prefix}-${each.key}")

  display_name                = lookup(each.value, "display_name", null)
  fifo_topic                  = lookup(each.value, "fifo_topic", false)
  content_based_deduplication = lookup(each.value, "content_based_deduplication", false)
  kms_master_key_id           = lookup(each.value, "kms_master_key_id", null)
  delivery_policy             = lookup(each.value, "delivery_policy", null)
  # terraform-aws-sns v6.1.1 takes delivery-status feedback as objects, not as six
  # flat arguments: application_feedback / firehose_feedback / http_feedback /
  # lambda_feedback / sqs_feedback. Re-wire through those when feedback is needed.
  lambda_feedback = lookup(each.value, "lambda_feedback", {})
  sqs_feedback    = lookup(each.value, "sqs_feedback", {})

  subscriptions = lookup(each.value, "subscriptions", {})

  tags = local.tags
}
