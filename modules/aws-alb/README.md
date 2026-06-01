# aws-alb

Wraps [`terraform-aws-modules/alb/aws ~> 9.0`](https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest).

Creates an internet-facing Application Load Balancer with HTTP→HTTPS redirect, HTTPS listener, and ECS target group.

---

## Inputs

| Key | Type | Default | Required | Description |
|-----|------|---------|----------|-------------|
| `name` | string | — | ✅ | Name prefix |
| `environment` | string | — | ✅ | Environment label |
| `vpc_id` | string | — | ✅ | VPC ID — from `dependency.vpc` |
| `public_subnets` | list(string) | — | ✅ | Public subnet IDs — from `dependency.vpc` |
| `vpc_cidr_block` | string | — | ✅ | VPC CIDR — used for SG egress rule |
| `acm_certificate_arn` | string | — | ✅ | ACM cert ARN — from `dependency.acm` |
| `create` | bool | `true` | — | Master toggle |
| `create_security_group` | bool | `true` | — | Auto-create SG. `false` = BYO |
| `ip_address_type` | string | `"ipv4"` | — | `ipv4` or `dualstack` (IPv6) |
| `enable_deletion_protection` | bool | `true` | — | Prevent accidental delete (set `false` to destroy) |
| `idle_timeout` | number | `60` | — | Connection idle timeout (seconds) |
| `container_port` | number | `8080` | — | Backend container port |
| `health_check_path` | string | `"/health"` | — | ALB health check path |
| `health_check.healthy_threshold` | number | `2` | — | Healthy threshold count |
| `health_check.unhealthy_threshold` | number | `3` | — | Unhealthy threshold count |
| `health_check.interval` | number | `30` | — | Health check interval (seconds) |
| `health_check.timeout` | number | `10` | — | Health check timeout (seconds) |
| `health_check.matcher` | string | `"200-299"` | — | HTTP status matcher |
| `access_logs.enabled` | bool | `false` | — | Send ALB access logs to S3 |
| `access_logs.bucket` | string | `""` | — | S3 bucket name for access logs |
| `access_logs.prefix` | string | `""` | — | S3 key prefix |
| `tags` | map(string) | `{}` | — | Tags on all resources |

## Outputs

| Key | Description |
|-----|-------------|
| `alb_dns_name` | ALB DNS name — use in Route53 A alias record |
| `alb_zone_id` | ALB canonical hosted zone ID |
| `alb_arn` | ALB ARN |
| `security_group_id` | ALB security group ID — used in ECS ingress rule |
| `target_group_arn` | ECS target group ARN — used in ECS service |

## values.yaml example

```yaml
name:        "myapp"
environment: "prod"

container_port:    8080
health_check_path: "/health"

health_check:
  healthy_threshold:   2
  unhealthy_threshold: 3
  interval:            30
  timeout:             10
  matcher:             "200-299"

enable_deletion_protection: true

access_logs:
  enabled: false   # set true + bucket to enable

tags:
  Project:   "myapp"
  ManagedBy: "terragrunt"
```
