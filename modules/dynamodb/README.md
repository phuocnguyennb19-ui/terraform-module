# dynamodb

DynamoDB tables.

Wraps `terraform-aws-dynamodb-table` (v4.1.0). Configuration comes from the `dynamodb:` block of a YAML file.

## Usage

```hcl
module "dynamodb" {
  source = "../../modules/dynamodb"

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

dynamodb:
  enabled: false
  tables:
    sessions:
      name: "dev-infra-sessions"
      billing_mode: "PAY_PER_REQUEST"            # or PROVISIONED + read/write_capacity
      hash_key:  "pk"
      range_key: "sk"
      attributes:
        - { name: "pk", type: "S" }
        - { name: "sk", type: "S" }
      ttl_attribute_name: "expires_at"
      point_in_time_recovery_enabled: true
      deletion_protection_enabled: true
      server_side_encryption_enabled: true
      kms_key_arn: null
      stream_enabled: true
      stream_view_type: "NEW_AND_OLD_IMAGES"
      global_secondary_indexes: []
      local_secondary_indexes: []
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
| `terraform-aws-dynamodb-table` | `terraform-aws-dynamodb-table` | `v4.1.0` |

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
| `dynamodb_table_arns` | Map of DynamoDB table ARNs |
| `dynamodb_table_ids` | Map of DynamoDB table IDs |
| `dynamodb_table_names` | Map of DynamoDB table names |
| `dynamodb_table_stream_arns` | Map of DynamoDB table stream ARNs (null when stream not enabled) |
