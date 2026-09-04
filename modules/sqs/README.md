# sqs

SQS queues with redrive policies.

Wraps `terraform-aws-sqs` (v4.2.1). Configuration comes from the `sqs:` block of a YAML file.

## Usage

```hcl
module "sqs" {
  source = "../../modules/sqs"

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

sqs:
  enabled: false
  queues:
    jobs:
      name: "dev-infra-jobs"
      fifo_queue: false
      content_based_deduplication: false
      visibility_timeout_seconds: 30
      message_retention_seconds: 345600          # 4 days
      max_message_size: 262144
      delay_seconds: 0
      receive_wait_time_seconds: 20              # long polling
      kms_master_key_id: null
      kms_data_key_reuse_period_seconds: 300
      redrive_policy: |
        { "deadLetterTargetArn": "arn:aws:sqs:ap-southeast-1:111122223333:dev-infra-jobs-dlq",
          "maxReceiveCount": 5 }
      redrive_allow_policy: null
      queue_policy_statements: {}
      policy: null
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
| `terraform-aws-sqs` | `terraform-aws-sqs` | `v4.2.1` |

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
| `sqs_queue_arns` | Map of SQS queue ARNs |
| `sqs_queue_ids` | Map of SQS queue URLs (IDs) |
| `sqs_queue_urls` | Map of SQS queue URLs |
| `sqs_queue_names` | Map of SQS queue names |
