# alb

## Usage

```hcl
module "alb" {
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-module.git//modules/alb?ref=v1.0.0"

  name               = local.name_prefix
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.security_groups.ecs_sg_id]

  tags               = local.tags
}
```

Every input not listed above has a default — 22 of them. See `variables.tf`.

## Required inputs

| Name | Type | Description |
|---|---|---|
| `name` | `string` | Load balancer name. Must be 32 characters or fewer — AWS rejects longer names, and the error arrives at apply time, not plan time. |
| `vpc_id` | `string` | VPC the load balancer and its target groups live in. From the foundation: module.vpc.vpc_id. |
| `subnet_ids` | `list(string)` | Subnets to place the load balancer in — at least two, in different AZs. Public subnets for an internet-facing ALB, private for an internal one. |
| `security_group_ids` | `list(string)` | Security groups for the load balancer. From module.security_groups.alb_sg_id. |

## Outputs

| Name | Description |
|---|---|
| `arn` | Load balancer ARN. |
| `arn_suffix` | ARN suffix in the form app/<name>/<id>. This is the LoadBalancer dimension CloudWatch metrics are published under — an alarm needs this, not the ARN. |
| `dns_name` | Load balancer DNS name. This is the alias target for the Route53 record. |
| `zone_id` | Canonical hosted zone ID of the load balancer. Route53 alias records need this alongside dns_name. |
| `target_group_arn_suffixes` | Map of target group key to ARN suffix, the TargetGroup dimension for CloudWatch metrics. |
| `target_group_arns` | Map of target group key to ARN. An autoscaling group consumes these as target_group_arns; in EKS the Ingress annotation references them by ARN. |
| `target_group_names` | Map of target group key to name. |
| `listener_arns` | Map of listener key to ARN. |
| `https_listener_arn` | ARN of the HTTPS listener, or null when no certificate was supplied. |
| `access_logs_bucket` | S3 bucket receiving access logs, or null when access logs are disabled. |
| `access_logs_bucket_arn` | ARN of the access log bucket, when this module created it. |

## Notes

- Pin a tag in `source`, never a branch.
- A worked, wired-together example is in [`examples/complete`](../../examples/complete).
