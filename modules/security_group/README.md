# security_group

Security group with ingress and egress rules.

Wraps `terraform-aws-modules/security-group/aws` (~> 5.0). Configuration comes from the `security_group:` block of a YAML file.

## Usage

```hcl
module "security_group" {
  source = "../../modules/security_group"

  config_file = "config.yml"

  global_config = {
    environment = "dev"
    region      = "ap-southeast-1"
    project     = "SM-Platform"
  }

  vpc_id = module.vpc.vpc_id
}
```

```yaml
# config.yml
app_name: "base"
service_type: "infra"

security_group:
  enabled: false
  description: "Shared application security group"
  ingress_rules: ["https-443-tcp"]               # named rules from the upstream module
  ingress_cidr_blocks: ["10.10.0.0/16"]
  ingress_with_cidr_blocks:
    - from_port: 8080
      to_port: 8080
      protocol: "tcp"
      description: "App port from inside the VPC"
      cidr_blocks: "10.10.0.0/16"
  ingress_with_source_security_group_id:
    - from_port: 5432
      to_port: 5432
      protocol: "tcp"
      description: "Postgres from the app SG"
      source_security_group_id: "sg-0123456789abcdef0"
  egress_rules: ["all-all"]                      # prod: ["https-443-tcp"]
  egress_cidr_blocks: ["0.0.0.0/0"]
  egress_with_source_security_group_id: []
  revoke_rules_on_delete: false

# 41 further upstream arguments are listed, grouped and commented out,
# in examples/module-config/security_group.yml
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
| `aws` | `terraform-aws-modules/security-group/aws` | `~> 5.0` |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `vpc_id` | The VPC ID where the security group will be created | `string` | `null` | no |
| `global_config` | Environment context shared by every module: environment, region and project, plus optional managed_by, cost_center and tags. `environment` is validated against dev, test, staging, preprod, prod. | `object` | n/a | **yes** |
| `config_file` | Path to the YAML config, resolved against `path.cwd` — the directory Terraform is run from, not the module directory. | `string` | `"config.yml"` | no |
| `manual_config` | Configuration merged over the decoded YAML at the top level. The root composition uses this to pass a layered config; leave unset when calling the module directly. | `any` | `{}` | no |
| `tags` | Extra tags, merged over the ones derived from `global_config`. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `security_group_id` | The ID of the security group |
| `security_group_vpc_id` | The VPC ID |
| `security_group_name` | The name of the security group |
| `security_group_arn` | The ARN of the security group |
