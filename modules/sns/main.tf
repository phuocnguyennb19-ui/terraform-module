module "sns" {
  for_each = local.topics
  source   = "git::https://github.com/terraform-aws-modules/terraform-aws-sns.git?ref=v6.1.1"

  name = lookup(each.value, "name", "${local.name_prefix}-${each.key}")

  display_name                    = lookup(each.value, "display_name", null)
  fifo_topic                      = lookup(each.value, "fifo_topic", false)
  content_based_deduplication     = lookup(each.value, "content_based_deduplication", false)
  kms_master_key_id               = lookup(each.value, "kms_master_key_id", null)
  delivery_policy                 = lookup(each.value, "delivery_policy", null)
  lambda_success_feedback_role_arn   = lookup(each.value, "lambda_success_feedback_role_arn", null)
  lambda_failure_feedback_role_arn   = lookup(each.value, "lambda_failure_feedback_role_arn", null)
  lambda_success_feedback_sample_rate = lookup(each.value, "lambda_success_feedback_sample_rate", null)
  sqs_success_feedback_role_arn    = lookup(each.value, "sqs_success_feedback_role_arn", null)
  sqs_failure_feedback_role_arn    = lookup(each.value, "sqs_failure_feedback_role_arn", null)
  sqs_success_feedback_sample_rate = lookup(each.value, "sqs_success_feedback_sample_rate", null)

  subscriptions = lookup(each.value, "subscriptions", {})

  tags = local.tags
}
