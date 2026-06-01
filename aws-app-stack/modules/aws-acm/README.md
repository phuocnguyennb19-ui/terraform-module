# aws-acm

Wraps [`terraform-aws-modules/acm/aws ~> 4.0`](https://registry.terraform.io/modules/terraform-aws-modules/acm/aws/latest).

Provisions an ACM certificate with automatic DNS validation via Route53.

---

## Inputs

| Key | Type | Default | Required | Description |
|-----|------|---------|----------|-------------|
| `domain_name` | string | — | ✅ | Primary domain (e.g. `api.example.com`) |
| `zone_id` | string | — | ✅ | Route53 Hosted Zone ID for DNS validation |
| `subject_alternative_names` | list(string) | `[]` | — | Additional domains (e.g. `*.example.com`) |
| `wait_for_validation` | bool | `true` | — | Block until cert is ISSUED |
| `tags` | map(string) | `{}` | — | Tags on all resources |

## Outputs

| Key | Description |
|-----|-------------|
| `certificate_arn` | ACM certificate ARN — pass to ALB listener |
| `certificate_status` | `ISSUED` / `PENDING_VALIDATION` |

## values.yaml example

```yaml
domain_name: "api.example.com"
subject_alternative_names:
  - "*.example.com"

wait_for_validation: true

tags:
  Project:   "myapp"
  ManagedBy: "terragrunt"
```

> **Note:** `zone_id` is not in values.yaml — it comes from `dependency "route53"` in terragrunt.hcl.
