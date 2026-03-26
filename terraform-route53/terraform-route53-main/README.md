
# AWS Route 53 Record Terraform Module

A Terraform module to create an AWS Route 53 DNS record with an alias target. This module simplifies the management of DNS records that point to AWS resources via alias records, such as CloudFront distributions, ELBs, or S3 websites.

---

## Features

- Create Route 53 DNS records with support for alias targets.
- Control evaluation of target health for the alias.
- Outputs key attributes of the created record for easy reference.

---

## Usage

Below is an example of how to use this module to create a Route 53 alias record:

```hcl
module "route53_record" {
  source = "./aws_route53_record"

  zone_id                = "Z1234567890"               # The hosted zone ID where the record will be created
  name                   = "terraform-test.example.com" # The DNS record name
  type                   = "A"                         # Record type (A, AAAA, CNAME, etc.)
  alias_name             = "target.example.com"        # The DNS name of the alias target
  alias_zone_id          = "Z0987654321"               # The hosted zone ID of the alias target
  evaluate_target_health = true                        # Whether to evaluate the health of the alias target
}
```

---

## Inputs

| Name                   | Description                                                         | Type   | Default | Required |
|------------------------|---------------------------------------------------------------------|--------|---------|----------|
| `zone_id`              | The ID of the hosted zone where the record will be created          | string | n/a     | yes      |
| `name`                 | The DNS record name to create                                       | string | n/a     | yes      |
| `type`                 | The DNS record type, e.g., `A`, `AAAA`, `CNAME`                     | string | n/a     | yes      |
| `alias_name`           | The DNS name of the AWS resource that the alias points to           | string | n/a     | yes      |
| `alias_zone_id`        | The hosted zone ID of the alias target resource                      | string | n/a     | yes      |
| `evaluate_target_health` | Whether Route 53 should evaluate the health of the alias target      | bool   | `true`  | no       |

---

## Outputs

| Name             | Description                          |
|------------------|------------------------------------|
| `record_name`    | The fully qualified domain name of the created record |
| `record_type`    | The DNS record type (e.g., `A`, `CNAME`)               |
| `record_zone_id` | The ID of the hosted zone where the record was created  |
| `alias_name`     | The DNS name of the alias target                       |

---

## How it works

This module uses the `aws_route53_record` resource to create an alias record. Alias records allow you to point your DNS name to AWS resources such as CloudFront distributions, Elastic Load Balancers (ELBs), or S3 static websites without using an IP address.

The key attribute is the `alias` block, which specifies:

- `name`: The DNS name of the AWS resource you're pointing to.
- `zone_id`: The hosted zone ID of the target AWS resource.
- `evaluate_target_health`: Whether Route 53 should check the health of the alias target before responding to DNS queries.

---

## When to use alias records

- To point your domain to AWS-managed resources that provide an alias target.
- To take advantage of Route 53’s ability to automatically update DNS based on resource IP changes.
- To avoid hardcoding IP addresses which may change over time.

---

## Notes

- The module currently only supports alias records.
- The `type` variable should typically be `A` or `AAAA` when creating alias records.
- Make sure the `alias_zone_id` corresponds to the hosted zone ID of the alias target resource, which varies by resource type.

---

## Example with AWS Elastic Load Balancer

```hcl
module "elb_alias" {
  source = "./aws_route53_record"

  zone_id                = "Z2P70J7EXAMPLE"
  name                   = "app.example.com"
  type                   = "A"
  alias_name             = aws_lb.app.dns_name
  alias_zone_id          = aws_lb.app.zone_id
  evaluate_target_health = true
}
```

---
