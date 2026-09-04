# kms

KMS key with aliases and a grant policy.

Wraps `terraform-aws-kms` (v2.2.1). Configuration comes from the `kms:` block of a YAML file.

## Usage

```hcl
module "kms" {
  source = "../../modules/kms"

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

kms:
  enabled: false
  description: "Master key for dev-infra"
  aliases: ["alias/dev-infra-key"]
  deletion_window_in_days: 30         # 7 is the AWS minimum
  key_usage: "ENCRYPT_DECRYPT"
  customer_master_key_spec: "SYMMETRIC_DEFAULT"
  multi_region: false
  key_administrators: ["arn:aws:iam::111122223333:role/platform-admin"]
  key_users:          ["arn:aws:iam::111122223333:role/dev-infra-ecs-task"]
  policy: null                        # raw JSON overrides everything above
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
| `terraform-aws-kms` | `terraform-aws-kms` | `v2.2.1` |

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
| `key_arn` | ARN of the KMS key |
| `key_id` | ID of the KMS key |
| `key_alias_arn` | ARN of the primary KMS key alias |
| `key_alias_name` | Name of the primary KMS key alias |
| `all_aliases` | Map of all KMS key aliases |
