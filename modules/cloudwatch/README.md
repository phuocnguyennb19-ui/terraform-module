# cloudwatch

CloudWatch log groups, metric alarms and dashboards.

Wraps `terraform-aws-cloudwatch//modules/log-group` (v5.7.0), `terraform-aws-cloudwatch//modules/metric-alarm` (v5.7.0). Configuration comes from the `cloudwatch:` block of a YAML file.

## Usage

```hcl
module "cloudwatch" {
  source = "../../modules/cloudwatch"

  config_file = "config.yml"

  global_config = {
    environment = "dev"
    region      = "ap-southeast-1"
    project     = "SM-Platform"
  }
}
```

```yaml
# config.yml
app_name: "base"
service_type: "infra"

cloudwatch:
  enabled: false
  log_groups:
    app:
      name: "/ecs/dev-infra"
      retention_in_days: 30
      kms_key_id: null
  metric_alarms:
    ecs_cpu_high:
      alarm_name: "dev-infra-ecs-cpu-high"
      alarm_description: "ECS service CPU above 80% for 5 minutes"
      namespace: "AWS/ECS"
      metric_name: "CPUUtilization"
      statistic: "Average"
      comparison_operator: "GreaterThanOrEqualToThreshold"
      threshold: 80
      period: 60
      evaluation_periods: 5
      treat_missing_data: "notBreaching"
      dimensions:
        ClusterName: "dev-infra-cluster"
        ServiceName: "dev-infra"
      # No module-to-module wiring exists (README §8.3). Paste the ARN from
      # `terraform output sns_topic_arns`. Empty means the alarm notifies nobody.
      alarm_actions: ["arn:aws:sns:ap-southeast-1:111122223333:dev-infra-alerts"]
      ok_actions: []
  # … full list in examples/modules/cloudwatch.yml
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0, < 6.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0, < 6.0 |

Configured by the caller. This module declares no `provider` and no `backend`.

## Modules

| Name | Source | Version |
|------|--------|---------|
| `terraform-aws-cloudwatch` | `terraform-aws-cloudwatch//modules/log-group` | `v5.7.0` |
| `terraform-aws-cloudwatch` | `terraform-aws-cloudwatch//modules/metric-alarm` | `v5.7.0` |

## Resources

| Name | Type |
|------|------|
| `aws_cloudwatch_dashboard` | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `global_config` | Environment context shared by every module: environment, region and project, plus optional managed_by, cost_center and tags. `environment` is validated against dev, test, staging, preprod, prod. | `object` | n/a | **yes** |
| `config_file` | Path to the YAML config, resolved against `path.cwd` — the directory Terraform is run from, not the module directory. | `string` | `"config.yml"` | no |
| `manual_config` | Configuration merged over the decoded YAML at the top level. The root composition uses this to pass a layered config; leave unset when calling the module directly. | `any` | `{}` | no |
| `tags` | Extra tags, merged over the ones derived from `global_config`. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `log_group_arns` | Map of log group ARNs |
| `log_group_names` | Map of log group names |
| `metric_alarm_arns` | Map of metric alarm ARNs |
| `metric_alarm_ids` | Map of metric alarm IDs |
| `dashboard_arns` | Map of CloudWatch dashboard ARNs |
