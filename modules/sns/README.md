# sns

SNS topics and subscriptions.

Wraps `terraform-aws-sns` (v6.1.1). Configuration comes from the `sns:` block of a YAML file.

## Usage

```hcl
module "sns" {
  source = "../../modules/sns"

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

sns:
  enabled: false
  topics:
    alerts:
      name: "dev-infra-alerts"
      display_name: "Dev infra alerts"
      fifo_topic: false
      content_based_deduplication: false
      kms_master_key_id: null
      delivery_policy: null
      subscriptions:
        oncall_email:
          protocol: "email"
          endpoint: "oncall@example.com"
      lambda_feedback: {}                        # v6.1.1 shape (README §8.6)
      sqs_feedback: {}
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
| `terraform-aws-sns` | `terraform-aws-sns` | `v6.1.1` |

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
| `sns_topic_arns` | Map of SNS topic ARNs |
| `sns_topic_ids` | Map of SNS topic IDs (same as ARN) |
| `sns_topic_owners` | Map of SNS topic owners (AWS account ID) |
