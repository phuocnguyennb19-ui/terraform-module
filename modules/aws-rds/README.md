# aws-rds

Wraps [`terraform-aws-modules/rds/aws ~> 6.0`](https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/latest) + [`terraform-aws-modules/security-group/aws ~> 5.0`](https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest).

Creates a PostgreSQL RDS instance with a dedicated security group (ingress only from ECS), automatic password management via Secrets Manager, Multi-AZ, encryption, and Enhanced Monitoring.

---

## Inputs

| Key | Type | Default | Required | Description |
|-----|------|---------|----------|-------------|
| `name` | string | — | ✅ | Name prefix |
| `environment` | string | — | ✅ | Environment label |
| `db_name` | string | — | ✅ | Database name |
| `username` | string | — | ✅ | Master username |
| `vpc_id` | string | — | ✅ | VPC ID — from `dependency.vpc` |
| `db_subnet_group_name` | string | — | ✅ | DB subnet group — from `dependency.vpc` |
| `ecs_security_group_id` | string | — | ✅ | ECS service SG — from `dependency.ecs` |
| `engine` | string | `"postgres"` | — | DB engine |
| `engine_version` | string | `"17"` | — | Engine version |
| `family` | string | `"postgres17"` | — | Parameter group family |
| `instance_class` | string | `"db.t4g.medium"` | — | RDS instance type |
| `allocated_storage` | number | `20` | — | Initial storage (GiB) |
| `max_allocated_storage` | number | `100` | — | Auto-scaling ceiling. `0` = disabled |
| `multi_az` | bool | `true` | — | Enable Multi-AZ standby |
| `storage_encrypted` | bool | `true` | — | Encrypt at rest |
| `kms_key_id` | string | `null` | — | Custom KMS key ARN. `null` = AWS managed |
| `backup_retention_period` | number | `7` | — | Days to retain automated backups |
| `backup_window` | string | `"03:00-04:00"` | — | Backup window (UTC) |
| `maintenance_window` | string | `"Mon:04:00-Mon:05:00"` | — | Maintenance window |
| `deletion_protection` | bool | `true` | — | Prevent accidental deletion |
| `skip_final_snapshot` | bool | `false` | — | Skip snapshot on delete (`true` only for dev) |
| `auto_minor_version_upgrade` | bool | `true` | — | Auto-apply minor version patches |
| `performance_insights.enabled` | bool | `true` | — | Enable Performance Insights |
| `performance_insights.retention_period` | number | `7` | — | Days to retain PI data (7=free, 731=paid) |
| `monitoring.interval` | number | `60` | — | Enhanced Monitoring interval (seconds) |
| `monitoring.create_role` | bool | `true` | — | Create IAM role for Enhanced Monitoring |
| `tags` | map(string) | `{}` | — | Tags on all resources |

## Outputs

| Key | Description |
|-----|-------------|
| `db_instance_endpoint` | Full connection endpoint |
| `db_instance_address` | Hostname only |
| `db_instance_port` | Port number |
| `db_instance_name` | Database name |
| `db_instance_username` | Master username |
| `db_master_user_secret_arn` | Secrets Manager ARN for password |
| `security_group_id` | RDS security group ID |

## values.yaml example

```yaml
name:        "myapp"
environment: "prod"
db_name:     "myapp_prod"
username:    "myapp_admin"

engine:         "postgres"
engine_version: "17"
family:         "postgres17"

instance_class:        "db.t4g.medium"
allocated_storage:     20
max_allocated_storage: 100

multi_az:          true
storage_encrypted: true
kms_key_id:        null

backup_retention_period: 7
deletion_protection:     true
skip_final_snapshot:     false

performance_insights:
  enabled:          true
  retention_period: 7

monitoring:
  interval:    60
  create_role: true

tags:
  Project:   "myapp"
  ManagedBy: "terragrunt"
```
