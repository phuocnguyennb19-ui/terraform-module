# aws-ecs

Wraps [`terraform-aws-modules/ecs/aws ~> 5.0`](https://registry.terraform.io/modules/terraform-aws-modules/ecs/aws/latest).

Creates an ECS Fargate cluster + service with capacity provider strategy (FARGATE / SPOT / MIXED / EC2), autoscaling, deployment circuit breaker, and CloudWatch logging.

---

## Inputs

### Required

| Key | Type | Description |
|-----|------|-------------|
| `app_name` | string | Application name — used as cluster name, service name, container name |
| `environment` | string | Environment label |
| `container_image` | string | Full ECR image URI with tag |
| `vpc_id` | string | VPC ID — from `dependency.vpc` |
| `private_subnets` | list(string) | Private subnet IDs — from `dependency.vpc` |
| `alb_target_group_arn` | string | Target group ARN — from `dependency.alb` |
| `alb_security_group_id` | string | ALB security group ID — from `dependency.alb` |

### Capacity

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `capacity_type` | string | `"FARGATE"` | `FARGATE` \| `FARGATE_SPOT` \| `MIXED` \| `EC2` |
| `asg_capacity_providers` | map(object) | `{}` | EC2 ASG config — only when `capacity_type = EC2` |

**MIXED strategy:** base=1 task on Fargate (stable), remaining 70% on Spot (cost saving).

### Container

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `container_port` | number | `8080` | Port the container listens on |
| `cpu` | number | `256` | Task CPU units (256=0.25vCPU) |
| `memory` | number | `512` | Task memory (MiB) |
| `desired_count` | number | `2` | Target running task count |
| `readonly_root_filesystem` | bool | `false` | Make container filesystem read-only |
| `environment_vars` | map(string) | `{}` | Plain-text env vars |
| `secrets_vars` | map(string) | `{}` | Env vars pulled from SSM/Secrets Manager ARNs |

### Deployment

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `force_new_deployment` | bool | `true` | Force new task on every apply |
| `health_check_grace_period_seconds` | number | `60` | Grace period before ALB health checks count |
| `enable_execute_command` | bool | `false` | Enable ECS Exec (debug shell) |
| `deployment_maximum_percent` | number | `200` | Max % of tasks during rolling deploy |
| `deployment_minimum_healthy_percent` | number | `66` | Min % healthy during rolling deploy |

### Autoscaling

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `autoscaling_min_capacity` | number | `1` | Minimum task count |
| `autoscaling_max_capacity` | number | `10` | Maximum task count |
| `autoscaling_cpu_target` | number | `70` | Scale-out when CPU exceeds (%) |
| `autoscaling_memory_target` | number | `80` | Scale-out when Memory exceeds (%) |
| `scale_in_cooldown` | number | `300` | Cooldown after scale-in (seconds) |
| `scale_out_cooldown` | number | `60` | Cooldown after scale-out (seconds) |

### Observability

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `container_insights` | bool | `true` | Enable CloudWatch Container Insights |
| `log_retention_days` | number | `90` | CloudWatch log retention |

## Outputs

| Key | Description |
|-----|-------------|
| `cluster_arn` | ECS cluster ARN |
| `cluster_name` | ECS cluster name |
| `service_name` | ECS service name |
| `service_id` | ECS service ARN |
| `ecs_service_security_group_id` | Service security group ID — used by RDS ingress |

## values.yaml example

```yaml
app_name:        "api-service"
environment:     "prod"
container_image: "123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/api-service:v1.0"

capacity_type: "MIXED"   # FARGATE | FARGATE_SPOT | MIXED | EC2

container_port: 8080
cpu:            512
memory:         1024
desired_count:  3

environment_vars:
  APP_ENV:   "production"
  LOG_LEVEL: "info"

secrets_vars:
  DB_PASSWORD: "arn:aws:ssm:ap-southeast-1:123456789012:parameter/prod/db_password"

autoscaling_min_capacity: 2
autoscaling_max_capacity: 10
autoscaling_cpu_target:   70

enable_execute_command: false   # true to debug via `aws ecs execute-command`

tags:
  Project:   "myapp"
  ManagedBy: "terragrunt"
```
