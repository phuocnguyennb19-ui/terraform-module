# rds

RDS instance, its subnet group and security group.

Wraps `terraform-aws-security-group` (v5.1.0), `terraform-aws-rds` (v6.10.0). Configuration comes from the `rds:` block of a YAML file.

## Usage

```hcl
module "rds" {
  source = "../../modules/rds"

  config_file = "config.yml"

  global_config = {
    environment = "dev"
    region      = "ap-southeast-1"
    project     = "SM-Platform"
  }

  vpc_id = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  vpc_cidr_block = module.vpc.vpc_cidr_block
}
```

```yaml
# config.yml
app_name: "base"
service_type: "infra"

rds:
  enabled: false
  engine: "postgres"
  engine_version: "16.3"
  major_engine_version: "16"
  family: "postgres16"
  instance_class: "db.t4g.micro"                 # prod: db.m6g.large
  allocated_storage: 20
  max_allocated_storage: 100                     # 0 disables storage autoscaling
  storage_type: "gp3"
  storage_throughput: null
  iops: null
  multi_az: false                                # true in prod
  port: 5432
  username: "appuser"                            # password is an AWS-managed secret
  backup_retention_period: 7                     # 0 disables backups — never in prod
  backup_window: "17:00-18:00"                   # UTC
  maintenance_window: "Sun:18:00-Sun:19:00"
  deletion_protection: true
  skip_final_snapshot: false
  final_snapshot_identifier_prefix: "final"
  copy_tags_to_snapshot: true
  apply_immediately: false                       # true restarts outside the window
  auto_minor_version_upgrade: true
  performance_insights_enabled: true
  monitoring_interval: 60                        # 0 disables enhanced monitoring
  # … full list in examples/modules/rds.yml
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
| `terraform-aws-rds` | `terraform-aws-rds` | `v6.10.0` |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `vpc_id` | VPC ID for same-stack orchestration | `string` | `null` | no |
| `private_subnets` | Subnet IDs for same-stack orchestration | `list(string)` | `null` | no |
| `vpc_cidr_block` | VPC CIDR block for security group ingress rules | `string` | `"10.0.0.0/16"` | no |
| `global_config` | Environment context shared by every module: environment, region and project, plus optional managed_by, cost_center and tags. `environment` is validated against dev, test, staging, preprod, prod. | `object` | n/a | **yes** |
| `config_file` | Path to the YAML config, resolved against `path.cwd` — the directory Terraform is run from, not the module directory. | `string` | `"config.yml"` | no |
| `manual_config` | Configuration merged over the decoded YAML at the top level. The root composition uses this to pass a layered config; leave unset when calling the module directly. | `any` | `{}` | no |
| `tags` | Extra tags, merged over the ones derived from `global_config`. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `db_instance_address` | Hostname of the RDS instance |
| `db_instance_arn` | ARN of the RDS instance |
| `db_instance_endpoint` | Connection endpoint (host:port) |
| `db_instance_id` | Identifier of the RDS instance |
| `db_instance_port` | Port of the RDS instance |
| `db_instance_name` | Database name |
| `db_master_user_secret_arn` | ARN of the Secrets Manager secret holding the master user credentials |
| `db_security_group_id` | ID of the RDS security group |
| `db_subnet_group_name` | Name of the DB subnet group |
