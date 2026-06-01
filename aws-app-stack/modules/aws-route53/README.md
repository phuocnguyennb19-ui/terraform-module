# aws-route53

Wraps [`terraform-aws-modules/route53/aws ~> 3.0`](https://registry.terraform.io/modules/terraform-aws-modules/route53/aws/latest) — both `zones` and `records` sub-modules.

Creates a Route53 Hosted Zone and DNS records (A alias to ALB, CNAME, TXT, etc.).

---

## Inputs

| Key | Type | Default | Required | Description |
|-----|------|---------|----------|-------------|
| `zone_name` | string | — | ✅ | DNS zone name (e.g. `example.com`) |
| `records` | map(object) | `{}` | — | Map of DNS records to create (see schema below) |
| `tags` | map(string) | `{}` | — | Tags on zone resources |

### records object schema

```yaml
records:
  api:                        # record name (relative to zone)
    type: "A"
    alias:                    # use alias OR ttl+records, not both
      name:                   "alb-dns-name.ap-southeast-1.elb.amazonaws.com"
      zone_id:                "Z14GRHDCWA56QT"
      evaluate_target_health: true
  www:
    type:    "CNAME"
    ttl:     300
    records: ["api.example.com"]
```

## Outputs

| Key | Description |
|-----|-------------|
| `zone_id` | Route53 Hosted Zone ID — used by ACM for DNS validation |
| `zone_arn` | Zone ARN |
| `zone_name` | Zone name |

## values.yaml example

```yaml
zone_name: "example.com"

records: {}   # populated after ALB is deployed

tags:
  Project:   "myapp"
  ManagedBy: "terragrunt"
```
