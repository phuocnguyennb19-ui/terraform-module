# vpc

VPC, subnets, routing, NAT gateways and flow logs.

Wraps `terraform-aws-modules/vpc/aws` (5.13.0). Configuration comes from the `vpc:` block of a YAML file.

## Usage

```hcl
module "vpc" {
  source = "../../modules/vpc"

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

vpc:
  enabled: false
  cidr: "10.10.0.0/16"
  azs: ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  public_subnets:   ["10.10.0.0/20",   "10.10.16.0/20",  "10.10.32.0/20"]
  private_subnets:  ["10.10.64.0/19",  "10.10.96.0/19",  "10.10.128.0/19"]
  database_subnets: ["10.10.160.0/24", "10.10.161.0/24", "10.10.162.0/24"]
  intra_subnets: []                   # no route to the internet at all
  enable_nat_gateway: true
  single_nat_gateway: true            # prod: false, with one_nat_gateway_per_az true
  one_nat_gateway_per_az: false
  enable_dns_hostnames: true
  enable_dns_support: true
  enable_vpn_gateway: false
  create_database_subnet_group: true
  create_database_subnet_route_table: false
  enable_flow_log: true
  flow_log_traffic_type: "REJECT"     # ALL | ACCEPT | REJECT
  flow_log_max_aggregation_interval: 60
  public_subnet_tags:   { Tier: "Public" }
  private_subnet_tags:  { Tier: "Private" }
  database_subnet_tags: { Tier: "Data" }
  intra_subnet_tags:    {}
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
| `aws` | `terraform-aws-modules/vpc/aws` | `5.13.0` |

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
| `vpc_id` | The ID of the VPC |
| `vpc_cidr_block` | The CIDR block of the VPC |
| `private_subnets` | List of IDs of private subnets |
| `public_subnets` | List of IDs of public subnets |
| `private_subnet_arns` | List of ARNs of private subnets |
| `public_subnet_arns` | List of ARNs of public subnets |
| `nat_public_ips` | List of public Elastic IPs created for AWS NAT Gateway(s). Useful for whitelisting IPs in external firewalls. |
| `private_route_table_ids` | List of IDs of private route tables |
| `public_route_table_ids` | List of IDs of public route tables |
| `default_security_group_id` | The ID of the security group created by default on VPC creation |
| `database_subnets` | List of IDs of database subnets |
| `database_subnet_group_name` | Name of the RDS subnet group (empty when not created) |
| `intra_subnets` | List of IDs of intra subnets (no internet access) |
| `vpc_flow_log_id` | ID of the VPC Flow Log (null when flow log disabled) |
| `vpc_flow_log_cloudwatch_iam_role_arn` | ARN of the CloudWatch IAM role for VPC Flow Logs |
| `azs` | List of Availability Zones used |
