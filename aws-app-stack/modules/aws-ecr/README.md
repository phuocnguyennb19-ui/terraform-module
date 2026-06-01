# aws-ecr

Wraps [`terraform-aws-modules/ecr/aws ~> 2.0`](https://registry.terraform.io/modules/terraform-aws-modules/ecr/aws/latest).

Creates a private ECR repository with KMS encryption, image scanning, and lifecycle policies.

---

## Inputs

| Key | Type | Default | Required | Description |
|-----|------|---------|----------|-------------|
| `name` | string | — | ✅ | App name — repository will be `{name}-{environment}` |
| `environment` | string | — | ✅ | Environment label |
| `create` | bool | `true` | — | Master toggle |
| `create_lifecycle_policy` | bool | `true` | — | Create lifecycle policy |
| `repository_type` | string | `"private"` | — | `private` or `public` |
| `image_tag_mutability` | string | `"IMMUTABLE"` | — | `IMMUTABLE` or `MUTABLE` |
| `scan_on_push` | bool | `true` | — | Scan images on push |
| `encryption_type` | string | `"KMS"` | — | `KMS` or `AES256` |
| `kms_key` | string | `null` | — | Custom KMS key ARN. `null` = AWS managed |
| `force_delete` | bool | `false` | — | Allow delete non-empty repo |
| `read_write_access_arns` | list(string) | `[]` | — | IAM ARNs with push/pull access |
| `lifecycle.untagged_expire_days` | number | `1` | — | Days before untagged images expire |
| `lifecycle.tagged_keep_count` | number | `30` | — | Max tagged images to keep |
| `lifecycle.tagged_prefix_list` | list(string) | `["v","release","prod"]` | — | Tag prefixes covered by keep policy |
| `tags` | map(string) | `{}` | — | Tags on all resources |

## Outputs

| Key | Description |
|-----|-------------|
| `repository_url` | Full ECR push/pull URL |
| `repository_arn` | Repository ARN |
| `repository_name` | Repository name |

## values.yaml example

```yaml
name:        "api-service"
environment: "prod"

image_tag_mutability: "IMMUTABLE"
scan_on_push:         true
encryption_type:      "KMS"

lifecycle:
  untagged_expire_days: 1
  tagged_keep_count:    30
  tagged_prefix_list:   ["v", "release"]

tags:
  Project:   "myapp"
  ManagedBy: "terragrunt"
```
