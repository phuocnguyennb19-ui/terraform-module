module "log_group" {
  for_each = local.log_groups
  source   = "git::https://github.com/terraform-aws-modules/terraform-aws-cloudwatch.git//modules/log-group?ref=v5.7.0"

  name              = lookup(each.value, "name", "/aws/${local.name_prefix}/${each.key}")
  retention_in_days = lookup(each.value, "retention_in_days", 30)
  kms_key_id        = lookup(each.value, "kms_key_id", null)

  tags = local.tags
}

module "metric_alarm" {
  for_each = local.metric_alarms
  source   = "git::https://github.com/terraform-aws-modules/terraform-aws-cloudwatch.git//modules/metric-alarm?ref=v5.7.0"

  alarm_name          = lookup(each.value, "alarm_name", "${local.name_prefix}-${each.key}")
  alarm_description   = lookup(each.value, "alarm_description", null)
  comparison_operator = lookup(each.value, "comparison_operator", "GreaterThanOrEqualToThreshold")
  evaluation_periods  = lookup(each.value, "evaluation_periods", 1)
  metric_name         = lookup(each.value, "metric_name", null)
  namespace           = lookup(each.value, "namespace", null)
  period              = lookup(each.value, "period", 60)
  statistic           = lookup(each.value, "statistic", "Average")
  threshold           = lookup(each.value, "threshold", null)
  treat_missing_data  = lookup(each.value, "treat_missing_data", "missing")

  dimensions = lookup(each.value, "dimensions", {})

  alarm_actions             = lookup(each.value, "alarm_actions", [])
  ok_actions                = lookup(each.value, "ok_actions", [])
  insufficient_data_actions = lookup(each.value, "insufficient_data_actions", [])

  tags = local.tags
}

resource "aws_cloudwatch_dashboard" "this" {
  for_each = local.dashboards

  dashboard_name = lookup(each.value, "name", "${local.name_prefix}-${each.key}")
  dashboard_body = each.value.body
}
