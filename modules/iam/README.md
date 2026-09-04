# iam

IAM roles, policies, groups, users and instance profiles.

Wraps `terraform-aws-iam//modules/iam-assumable-role` (v5.44.0), `terraform-aws-iam//modules/iam-assumable-role` (v5.44.0). Configuration comes from the `iam:` block of a YAML file.

## Usage

```hcl
module "iam" {
  source = "../../modules/iam"

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

iam:
  enabled: false
  # Map keys become the resource names.
  policies:
    dev-infra-s3-read:
      path: "/"
      description: "Read-only access to the artifacts bucket"
      policy: |
        {
          "Version": "2012-10-17",
          "Statement": [{
            "Effect": "Allow",
            "Action": ["s3:GetObject", "s3:ListBucket"],
            "Resource": ["arn:aws:s3:::sm-platform-dev-artifacts",
                         "arn:aws:s3:::sm-platform-dev-artifacts/*"]
          }]
        }
  roles:
    dev-infra-ecs-task:
      trusted_role_services: ["ecs-tasks.amazonaws.com"]
      custom_role_policy_arns:
        - "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
      custom_policy_names: ["dev-infra-s3-read"]   # resolved to ARNs by the module
      role_requires_mfa: false
      create_instance_profile: false               # true only for EC2 roles
      # assume_role_policy: |                      # raw JSON replaces the trust policy
  # … full list in examples/modules/iam.yml
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
| `terraform-aws-iam` | `terraform-aws-iam//modules/iam-assumable-role` | `v5.44.0` |
| `terraform-aws-iam` | `terraform-aws-iam//modules/iam-assumable-role` | `v5.44.0` |

## Resources

| Name | Type |
|------|------|
| `aws_iam_instance_profile` | resource |
| `aws_iam_policy` | resource |

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
| `iam_role_arn` | ARN of the primary IAM role (single-role mode) |
| `iam_role_name` | Name of the primary IAM role (single-role mode) |
| `all_role_arns` | Map of all role names to ARNs created by the factory (key = role name) |
| `all_role_names` | Map of all role names created by the factory |
| `policy_arns` | Map of custom policy names to ARNs |
| `instance_profile_arns` | Map of IAM instance profile ARNs (for EC2 roles) |
| `instance_profile_names` | Map of IAM instance profile names |
