# alb

Application Load Balancer, its security group, listeners and target groups.

Wraps `terraform-aws-security-group` (v5.1.0), `terraform-aws-alb` (v9.11.0). Configuration comes from the `alb:` block of a YAML file.

## Usage

```hcl
module "alb" {
  source = "../../modules/alb"

  config_file = "config.yml"

  global_config = {
    environment = "dev"
    region      = "ap-southeast-1"
    project     = "SM-Platform"
  }

  public_subnets = module.vpc.public_subnets
  private_subnets = module.vpc.private_subnets
  vpc_id = module.vpc.vpc_id
  vpc_cidr_block = module.vpc.vpc_cidr_block
}
```

```yaml
# config.yml
app_name: "base"
service_type: "infra"

alb:
  enabled: false
  internal: false                                # true puts it on the private subnets
  idle_timeout: 60
  enable_deletion_protection: true               # prod
  enable_waf_fail_open: false
  drop_invalid_header_fields: true
  preserve_host_header: false
  desync_mitigation_mode: "defensive"
  xff_header_processing_mode: "append"
  security_group_ingress_rules:                  # the module creates the ALB's own SG
    https:
      from_port:   443
      to_port:     443
      ip_protocol: "tcp"
      description: "HTTPS from the internet"
      cidr_ipv4:   "0.0.0.0/0"
  listeners:                                     # MAP (upstream v9)
    https:
      port:            443
      protocol:        "HTTPS"
      certificate_arn: "arn:aws:acm:ap-southeast-1:111122223333:certificate/abc-123"
      forward:
        target_group_key: "app"
  target_groups:                                 # MAP (upstream v9)
    app:
  # … full list in examples/modules/alb.yml
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
| `terraform-aws-security-group` | `terraform-aws-security-group` | `v5.1.0` |
| `terraform-aws-alb` | `terraform-aws-alb` | `v9.11.0` |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `public_subnets` | List of public subnet IDs for internet-facing ALB | `list(string)` | `null` | no |
| `private_subnets` | List of private subnet IDs for internal ALB | `list(string)` | `null` | no |
| `vpc_id` | VPC ID for security group creation | `string` | `null` | no |
| `vpc_cidr_block` | VPC CIDR block — used to scope ingress rules | `string` | `"10.0.0.0/16"` | no |
| `global_config` | Environment context shared by every module: environment, region and project, plus optional managed_by, cost_center and tags. `environment` is validated against dev, test, staging, preprod, prod. | `object` | n/a | **yes** |
| `config_file` | Path to the YAML config, resolved against `path.cwd` — the directory Terraform is run from, not the module directory. | `string` | `"config.yml"` | no |
| `manual_config` | Configuration merged over the decoded YAML at the top level. The root composition uses this to pass a layered config; leave unset when calling the module directly. | `any` | `{}` | no |
| `tags` | Extra tags, merged over the ones derived from `global_config`. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `alb_sg_id` | ID of the ALB security group |
| `alb_sg_arn` | ARN of the ALB security group |
| `lb_id` |  |
| `target_group_arns` |  |
