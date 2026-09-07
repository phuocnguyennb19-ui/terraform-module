# ecs_service

ECS service, task definition, target group, listener rule and autoscaling.

Wraps `terraform-aws-ecs//modules/service` (v5.11.4). Configuration comes from the `service:` block of a YAML file (legacy key `ecs_service:` is still merged).

## Usage

```hcl
module "ecs_service" {
  source = "../../modules/ecs_service"

  config_file = "config.yml"

  global_config = {
    environment = "dev"
    region      = "ap-southeast-1"
    project     = "SM-Platform"
  }

  cluster_arn = module.ecs_cluster.cluster_arn
  listener_arn = module.alb.http_tcp_listener_arns[0]
  vpc_id = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  vpc_cidr_block = module.vpc.vpc_cidr_block
}
```

```yaml
# config.yml
app_name: "base"
service_type: "infra"

service:                                         # legacy key: ecs_service
  enabled: false
  desired_count: 3
  health_check_path: "/healthz"
  health_check_matcher: "200"
  health_check_grace_period: 30
  priority: 100                                  # ALB listener rule priority
  host_header: "api.dev.platform.example.com"
  deployment_maximum_percent: 200
  deployment_minimum_healthy_percent: 100
  deployment_controller_type: "ECS"
  enable_execute_command: false                  # true in dev for debugging
  force_new_deployment: false
  propagate_tags: "SERVICE"
  platform_version: "LATEST"
  scheduling_strategy: "REPLICA"
  wait_for_steady_state: true                    # prod: apply blocks until healthy
  assign_public_ip: false
  capacity_provider_strategy: []
  load_balancer:
    container_name: "app"
    container_port: 8080
  task_definition:
    family: "dev-infra-task"
    network_mode: "awsvpc"
    requires_compatibilities: ["FARGATE"]
    cpu: 512
    memory: 1024
    execution_role_arn: null                     # null = the cluster's role
    task_role_arn: null
  container_definitions:
    - name: "app"
      image: "111122223333.dkr.ecr.ap-southeast-1.amazonaws.com/core-backend-api:1.4.2"
      essential: true
      cpu: 512
      memory: 1024
      command: []
      port_mappings:
        - { container_port: 8080, protocol: "tcp" }
      environment:                               # map, converted to name/value pairs
        LOG_LEVEL: "info"
        APP_ENV: "dev"
      secrets:                                   # map of NAME -> ARN, never a value
        DB_PASSWORD: "arn:aws:secretsmanager:ap-southeast-1:111122223333:secret:db-abc"
      mount_points: []
      depends_on: []
  volumes: []

autoscaling:                                     # its own block at the YAML root
  enabled: false
  min_capacity: 3
  max_capacity: 12
  target_cpu_utilization: 60                     # 0 disables the CPU policy
  target_memory_utilization: 70                  # 0 disables the memory policy
```

## Nested vs root blocks

`task_definition`, `container_definitions` and `volumes` can each be written **inside**
`service:` or at the **root** of the YAML. The precedence is not the same for all three:

| Key | Written under `service:` | Written at YAML root | Which wins |
|---|---|---|---|
| `task_definition` | yes | yes | **root** overrides nested |
| `container_definitions` | yes | yes | **nested** wins, root is the fallback |
| `volumes` | yes | yes | **nested** wins, root is the fallback |
| `autoscaling` | no | yes | root only |

`task_definition` uses `merge(nested, root)`, and `merge()` lets the later argument win — so a
root-level `task_definition:` silently overrides the one under `service:`. The other two use
`lookup`/`try` with the nested copy first. Pick one placement per environment and keep to it.

`cpu` and `memory` fall back further: `service.task_definition.cpu` → `service.cpu` → `256`,
and the same for `memory` → `512`.

If no `container_definitions` is given at all, the module builds a single container named `app`
from `service.image` and `service.port`.

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
| `terraform-aws-ecs` | `terraform-aws-ecs//modules/service` | `v5.11.4` |

## Resources

| Name | Type |
|------|------|
| `aws_lb_listener_rule` | resource |
| `aws_lb_target_group` | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `cluster_arn` | ARN of the ECS cluster to deploy the service into | `string` | n/a | **yes** |
| `listener_arn` | ARN of the ALB listener to attach listener rules to (optional) | `string` | `null` | no |
| `vpc_id` | VPC ID — required for creating the target group | `string` | `null` | no |
| `private_subnets` | List of private subnet IDs for the ECS service network configuration | `list(string)` | `null` | no |
| `vpc_cidr_block` | VPC CIDR block — used to restrict ingress security group rules | `string` | `"10.0.0.0/16"` | no |
| `global_config` | Environment context shared by every module: environment, region and project, plus optional managed_by, cost_center and tags. `environment` is validated against dev, test, staging, preprod, prod. | `object` | n/a | **yes** |
| `config_file` | Path to the YAML config, resolved against `path.cwd` — the directory Terraform is run from, not the module directory. | `string` | `"config.yml"` | no |
| `manual_config` | Configuration merged over the decoded YAML at the top level. The root composition uses this to pass a layered config; leave unset when calling the module directly. | `any` | `{}` | no |
| `tags` | Extra tags, merged over the ones derived from `global_config`. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `id` | The ID of the service |
| `name` | The name of the service |
| `task_definition_arn` | The ARN of the task definition |
| `iam_role_name` | The name of the IAM service-linked role |
| `iam_role_arn` | The ARN of the IAM service-linked role |
| `target_group_arn` | The ARN of the ALB target group (null when no LB configured) |
| `target_group_name` | The name of the ALB target group (null when no LB configured) |
| `security_group_id` | The ID of the ECS service security group (null when external SG IDs supplied) |
| `security_group_arn` | The ARN of the ECS service security group (null when external SG IDs supplied) |
| `task_exec_iam_role_arn` | ARN of the task execution IAM role |
| `task_iam_role_arn` | ARN of the task IAM role |
