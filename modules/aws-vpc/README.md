# aws-vpc

Wraps [`terraform-aws-modules/vpc/aws ~> 5.0`](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest).

Creates a production-grade VPC with public / private / database subnet tiers, multi-AZ NAT Gateways, and VPC Flow Logs.

---

## Inputs

| Key | Type | Default | Required | Description |
|-----|------|---------|----------|-------------|
| `name` | string | — | ✅ | Name prefix for all resources |
| `environment` | string | — | ✅ | Environment label (prod / staging) |
| `vpc_cidr` | string | — | ✅ | CIDR block for the VPC |
| `availability_zones` | list(string) | — | ✅ | List of AZs |
| `private_subnet_cidrs` | list(string) | — | ✅ | CIDRs for private subnets (ECS tasks) |
| `public_subnet_cidrs` | list(string) | — | ✅ | CIDRs for public subnets (ALB) |
| `database_subnet_cidrs` | list(string) | `[]` | — | CIDRs for database subnets (RDS). Leave empty to skip |
| `intra_subnet_cidrs` | list(string) | `[]` | — | CIDRs for intra subnets (no internet route) |
| `single_nat_gateway` | bool | `false` | — | Use one shared NAT GW (cost saving for non-prod) |
| `one_nat_gateway_per_az` | bool | `false` | — | One NAT GW per AZ (max HA) |
| `enable_dns_hostnames` | bool | `true` | — | Enable DNS hostnames in VPC |
| `enable_dns_support` | bool | `true` | — | Enable DNS resolution |
| `enable_flow_log` | bool | `true` | — | Enable VPC Flow Logs to CloudWatch |
| `flow_log_max_aggregation_interval` | number | `60` | — | Flow log aggregation interval (seconds) |
| `public_subnet_tags` | map(string) | `{kubernetes.io/role/elb=1}` | — | Extra tags on public subnets |
| `private_subnet_tags` | map(string) | `{kubernetes.io/role/internal-elb=1}` | — | Extra tags on private subnets |
| `database_subnet_tags` | map(string) | `{}` | — | Extra tags on database subnets |
| `tags` | map(string) | `{}` | — | Tags applied to all resources |

## Outputs

| Key | Description |
|-----|-------------|
| `vpc_id` | VPC ID |
| `vpc_cidr_block` | VPC CIDR block |
| `private_subnets` | List of private subnet IDs |
| `public_subnets` | List of public subnet IDs |
| `database_subnets` | List of database subnet IDs |
| `database_subnet_group` | RDS DB subnet group name |

## values.yaml example

```yaml
name:        "myapp"
environment: "prod"
vpc_cidr:    "10.0.0.0/16"

availability_zones:
  - "ap-southeast-1a"
  - "ap-southeast-1b"
  - "ap-southeast-1c"

private_subnet_cidrs:  ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnet_cidrs:   ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
database_subnet_cidrs: ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]

single_nat_gateway: false   # prod: false | staging: true
enable_flow_log:    true

tags:
  Project:   "myapp"
  ManagedBy: "terragrunt"
```
