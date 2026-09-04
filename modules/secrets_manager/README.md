# secrets_manager

Secrets Manager secrets and rotation configuration.

Wraps `terraform-aws-secrets-manager` (v1.1.0). Configuration comes from the `secrets_manager:` block of a YAML file.

## Usage

```hcl
module "secrets_manager" {
  source = "../../modules/secrets_manager"

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

secrets_manager:
  enabled: false
  # Create the secret here; set its VALUE out of band and reference it by ARN.
  # Never put a secret value in this file.
  secrets:
    db_password:
      description: "Application database password"
      kms_key_id: null
      recovery_window_in_days: 30                # 0 deletes immediately — dev only
      ignore_secret_changes: true                # rotation happens outside Terraform
      rotation_lambda_arn: null
      rotation_rules: {}
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
| `terraform-aws-secrets-manager` | `terraform-aws-secrets-manager` | `v1.1.0` |

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
| `secret_arns` | Map of secret keys to their ARNs |
| `secret_ids` | Map of secret keys to their IDs |
| `secret_names` | Map of secret keys to their names |
| `secret_version_ids` | Map of secret keys to their current version IDs |
