output "log_group_arns" {
  description = "Map of log group ARNs"
  value       = { for k, v in module.log_group : k => v.cloudwatch_log_group_arn }
}

output "log_group_names" {
  description = "Map of log group names"
  value       = { for k, v in module.log_group : k => v.cloudwatch_log_group_name }
}

output "metric_alarm_arns" {
  description = "Map of metric alarm ARNs"
  value       = { for k, v in module.metric_alarm : k => v.cloudwatch_metric_alarm_arn }
}

output "metric_alarm_ids" {
  description = "Map of metric alarm IDs"
  value       = { for k, v in module.metric_alarm : k => v.cloudwatch_metric_alarm_id }
}

output "dashboard_arns" {
  description = "Map of CloudWatch dashboard ARNs"
  value       = { for k, v in aws_cloudwatch_dashboard.this : k => v.dashboard_arn }
}
