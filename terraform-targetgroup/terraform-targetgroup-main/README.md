# Load Balancer Target Group Module

## Overview

This module provisions an **AWS Application Load Balancer Target Group** configured for HTTP traffic. It supports health checks, deregistration delays, slow start, and other advanced settings.

## Module Source

```hcl
source = "./aws_lb_target_group"
```

## Example Usage

```hcl
module "lb_target_group" {
  source = "./aws_lb_target_group"

  name                       = "my-target-group"
  port                       = 80
  protocol                   = "HTTP"
  vpc_id                     = "vpc-12345678"
  target_type                = "instance"
  health_check_interval      = 30
  health_check_path          = "/health"
  health_check_port          = "traffic-port"
  health_check_protocol      = "HTTP"
  health_check_timeout       = 5
  health_check_healthy_threshold   = 3
  health_check_unhealthy_threshold = 2
  deregistration_delay       = 300
  slow_start                 = 60
  connection_termination     = true
  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}
```

## Input Variables

| Name                          | Type     | Description                                                  | Default | Required |
|-------------------------------|----------|--------------------------------------------------------------|---------|----------|
| `name`                        | string   | Name of the target group                                     | n/a     | Yes      |
| `port`                        | number   | Port on which targets receive traffic                        | n/a     | Yes      |
| `protocol`                    | string   | Protocol for routing traffic (e.g., `HTTP`, `HTTPS`)         | n/a     | Yes      |
| `vpc_id`                      | string   | VPC ID where the target group is created                     | n/a     | Yes      |
| `target_type`                | string   | Type of target (`instance`, `ip`, `lambda`)                  | n/a     | Yes      |
| `health_check_interval`       | number   | Time between health checks                                   | 30      | No       |
| `health_check_path`           | string   | Endpoint path to check                                       | `"/"`   | No       |
| `health_check_port`           | string   | Port for health checks (`traffic-port` or number)            | `"traffic-port"` | No |
| `health_check_protocol`       | string   | Protocol for health checks (`HTTP`, `HTTPS`, `TCP`)          | `"HTTP"`| No       |
| `health_check_timeout`        | number   | Timeout for each health check attempt                        | 5       | No       |
| `health_check_healthy_threshold` | number | Number of successful checks before healthy state             | 3       | No       |
| `health_check_unhealthy_threshold` | number | Number of failed checks before unhealthy state             | 2       | No       |
| `deregistration_delay`        | number   | Time to wait before deregistering a target                   | 300     | No       |
| `slow_start`                  | number   | Time to gradually increase traffic to a newly registered target | 60   | No       |
| `connection_termination`      | bool     | Whether to terminate connections at deregistration           | true    | No       |
| `tags`                        | map      | Tags to assign to the target group                           | {}      | No       |

## Outputs

This module may export outputs like:

- `target_group_arn` – ARN of the created target group.
- `target_group_name` – Name of the target group.

> Refer to the actual module for the complete output list.

## Notes

- Make sure your VPC ID and target instances are valid and within the same region.
- Health check parameters must align with the application’s response behavior to avoid false negatives.
