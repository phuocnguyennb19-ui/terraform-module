# core-service

One HTTPS API deployed end to end:

```
Route53 ──alias──▶ ALB ──HTTPS:443──▶ ECS Service ──▶ RDS
 (dns)             (alb)               (ecs_service)
```

`config.yml` also enables ECR, KMS, IAM, WAF, CloudWatch, SNS and an EKS cluster in the same
VPC. `main.tf` wires the subset that has module-to-module dependencies; the rest are driven
from the same config file by the root composition.

## Usage

```bash
terraform init
terraform plan
```

Run from this directory. Every module resolves `file("${path.cwd}/${var.config_file}")`, so
`config.yml` is read from here.

## What the caller wires, and what stays a literal

Wired in `main.tf`:

| Value | From | To |
|---|---|---|
| `vpc_id`, subnets, `vpc_cidr_block` | `vpc` | `alb`, `ecs_cluster`, `ecs_service` |
| `cluster_arn` | `ecs_cluster` | `ecs_service` |
| `http_tcp_listener_arns[0]` | `alb` | `ecs_service` |
| `lb_dns_name`, `lb_zone_id` | `alb` | `dns` (`alias.target: "alb"`) |

Still literals in `config.yml`, because no wiring exists for them:

| Value | From | Consumed by |
|---|---|---|
| `certificate_arn` | `acm` | `alb.listeners.<k>` |
| `execution_role_arn`, `task_role_arn` | `iam` | `service.task_definition` |
| ALB ARN | `alb` | `waf.associate_alb_arns` |
| SNS topic ARN | `sns` | `cloudwatch.metric_alarms.*.alarm_actions` |

Apply once, read the ARNs from `terraform output`, paste them in, apply again.
