# s3

S3 bucket with versioning, encryption, lifecycle and access blocks.

Wraps `terraform-aws-s3-bucket` (v4.2.1). Configuration comes from the `s3:` block of a YAML file.

## Usage

```hcl
module "s3" {
  source = "../../modules/s3"

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

s3:
  enabled: false
  bucket: "sm-platform-dev-artifacts"
  versioning_enabled: true
  kms_key_id: null                               # null = SSE-S3; an ARN = SSE-KMS
  block_public_acls: true
  block_public_policy: true
  force_destroy: false                           # true ONLY in dev
  object_lock_enabled: false
  object_lock_configuration: {}
  acceleration_status: null
  lifecycle_rule:
    - id: "expire-old-artifacts"
      enabled: true
      expiration: { days: 90 }
      noncurrent_version_expiration: { days: 30 }
  cors_rule: []
  logging:
    target_bucket: "sm-platform-dev-logs"
    target_prefix: "s3/"
  website: {}
  intelligent_tiering: {}
  metric_configuration: []
  replication_configuration: {}

# 32 further upstream arguments are listed, grouped and commented out,
# in examples/module-config/s3.yml
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
| `terraform-aws-s3-bucket` | `terraform-aws-s3-bucket` | `v4.2.1` |

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
| `s3_bucket_id` | Name (ID) of the bucket |
| `s3_bucket_arn` | ARN of the bucket |
| `s3_bucket_bucket_domain_name` | Bucket domain name (global) |
| `s3_bucket_regional_domain_name` | Bucket regional domain name (for CloudFront origins) |
| `s3_bucket_hosted_zone_id` | Route 53 hosted zone ID for the bucket (for alias records) |
| `s3_bucket_website_endpoint` | Website endpoint (empty when website not configured) |
| `s3_bucket_website_domain` | Website domain (empty when website not configured) |
