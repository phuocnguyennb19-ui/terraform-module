# acm

ACM certificate with DNS or email validation.

Wraps `terraform-aws-acm` (v4.3.2). Configuration comes from the `acm:` block of a YAML file.

## Usage

```hcl
module "acm" {
  source = "../../modules/acm"

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

acm:
  enabled: false
  domain_name: "dev.platform.example.com"
  subject_alternative_names: ["*.dev.platform.example.com"]
  validation_method: "DNS"                       # DNS | EMAIL
  wait_for_validation: true                      # false in CI so apply does not block
  key_algorithm: "RSA_2048"
  certificate_transparency_logging_preference: "ENABLED"

# 13 further upstream arguments are listed, grouped and commented out,
# in examples/module-config/acm.yml
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
| `terraform-aws-acm` | `terraform-aws-acm` | `v4.3.2` |

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
| `acm_certificate_arn` | ARN of the ACM certificate |
| `acm_certificate_domain_validation_options` | Domain validation options (CNAME records to create) |
| `acm_certificate_status` | Status of the certificate (PENDING_VALIDATION, ISSUED, etc.) |
| `acm_certificate_domain` | Primary domain name of the certificate |
