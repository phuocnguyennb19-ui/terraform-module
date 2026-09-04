# ecr

ECR repositories with scanning and lifecycle policies.

Wraps `terraform-aws-ecr` (v2.2.1). Configuration comes from the `ecr:` block of a YAML file.

## Usage

```hcl
module "ecr" {
  source = "../../modules/ecr"

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

ecr:
  enabled: false
  repository_names: ["core-backend-api", "core-frontend-web"]
  image_tag_mutability: "IMMUTABLE"              # MUTABLE in dev
  scan_on_push: true
  encryption_type: "AES256"                      # or KMS, with kms_key set
  kms_key: null
  repository_force_delete: false
  read_access_arns:       ["arn:aws:iam::111122223333:role/dev-infra-ecs-task"]
  read_write_access_arns: ["arn:aws:iam::111122223333:role/ci-deployer"]
  lifecycle_policy: |
    {
      "rules": [{
        "rulePriority": 1,
        "description": "Keep the last 30 images",
        "selection": { "tagStatus": "any", "countType": "imageCountMoreThan", "countNumber": 30 },
        "action": { "type": "expire" }
      }]
    }
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
| `terraform-aws-ecr` | `terraform-aws-ecr` | `v2.2.1` |

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
| `repository_urls` | Map of repository names to their registry URLs |
| `repository_arns` | Map of repository names to their ARNs |
| `repository_registry_ids` | Map of repository names to their registry IDs |
