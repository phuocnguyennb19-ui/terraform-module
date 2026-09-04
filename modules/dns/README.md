# dns

Route53 hosted zones and records, including aliases to an ALB.

Wraps `terraform-aws-route53//modules/zones` (v4.1.0), `terraform-aws-route53//modules/records` (v4.1.0). Configuration comes from the `dns:` block of a YAML file (legacy key `route53:` is still merged).

## Usage

```hcl
module "dns" {
  source = "../../modules/dns"

  config_file = "config.yml"

  global_config = {
    environment = "dev"
    region      = "ap-southeast-1"
    project     = "SM-Platform"
  }

  alb_dns_name = module.alb.lb_dns_name
  alb_zone_id = module.alb.lb_zone_id
  cloudfront_domain_name = null
}
```

```yaml
# config.yml
app_name: "base"
service_type: "infra"

dns:                                             # legacy key: route53
  enabled: false
  zones:
    "dev.platform.example.com":
      comment: "Dev platform zone"
  records:                                       # keyed by ZONE NAME
    "dev.platform.example.com":
      - name: "api"
        type: "A"
        alias:
          name:    "dualstack.dev-alb-123456.ap-southeast-1.elb.amazonaws.com"
          zone_id: "Z1LMS91P8CMLE5"
      - name: ""
        type: "TXT"
        ttl: 300
        records: ["v=spf1 -all"]
```

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
| `terraform-aws-route53` | `terraform-aws-route53//modules/zones` | `v4.1.0` |
| `terraform-aws-route53` | `terraform-aws-route53//modules/records` | `v4.1.0` |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `global_config` | Environment context shared by every module: environment, region and project, plus optional managed_by, cost_center and tags. `environment` is validated against dev, test, staging, preprod, prod. | `object` | n/a | **yes** |
| `config_file` | Path to the YAML config, resolved against `path.cwd` — the directory Terraform is run from, not the module directory. | `string` | `"config.yml"` | no |
| `manual_config` | Configuration merged over the decoded YAML at the top level. The root composition uses this to pass a layered config; leave unset when calling the module directly. | `any` | `{}` | no |
| `tags` | Extra tags, merged over the ones derived from `global_config`. | `map(string)` | `{}` | no |
| `alb_dns_name` | DNS name of the ALB, for records using alias.target = \"alb\". | `string` | `null` | no |
| `alb_zone_id` | Hosted zone ID of the ALB, for records using alias.target = \"alb\". | `string` | `null` | no |
| `cloudfront_domain_name` | CloudFront domain, for records using alias.target = \"cloudfront\". | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| `route53_zone_zone_ids` | Map of Zone IDs |
| `route53_zone_names` | Map of Zone Names |
| `route53_zone_name_servers` | Map of zone name servers |
| `route53_record_names` | Map of zone → record names created |
