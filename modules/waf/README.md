# waf

WAFv2 web ACL and its ALB associations.

Wraps `terraform-aws-wafv2` (v1.1.0). Configuration comes from the `waf:` block of a YAML file.

## Usage

```hcl
module "waf" {
  source = "../../modules/waf"

  config_file = "config.yml"

  global_config = {
    environment = "dev"
    region      = "ap-southeast-1"
    project     = "SM-Platform"
  }
}
```

```yaml
# config.yml
app_name: "base"
service_type: "infra"

waf:
  enabled: false
  scope: "REGIONAL"                              # REGIONAL for ALB, CLOUDFRONT for CDN
  description: "Edge protection for dev-infra"
  default_action: "allow"                        # allow | block
  token_domains: ["dev.platform.example.com"]
  associate_alb_arns:
    - "arn:aws:elasticloadbalancing:ap-southeast-1:111122223333:loadbalancer/app/dev-alb/abc"
  rules:
    - name: "AWSManagedRulesCommonRuleSet"
      priority: 1
      override_action: "none"
      statement:
        managed_rule_group_statement:
          name:        "AWSManagedRulesCommonRuleSet"
          vendor_name: "AWS"
      visibility_config:
        cloudwatch_metrics_enabled: true
        metric_name: "common-rule-set"
        sampled_requests_enabled: true
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
| `terraform-aws-wafv2` | `terraform-aws-wafv2` | `v1.1.0` |

## Resources

| Name | Type |
|------|------|
| `aws_wafv2_web_acl_association` | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `global_config` | Environment context shared by every module: environment, region and project, plus optional managed_by, cost_center and tags. `environment` is validated against dev, test, staging, preprod, prod. | `object` | n/a | **yes** |
| `config_file` | Path to the YAML config, resolved against `path.cwd` — the directory Terraform is run from, not the module directory. | `string` | `"config.yml"` | no |
| `manual_config` | Configuration merged over the decoded YAML at the top level. The root composition uses this to pass a layered config; leave unset when calling the module directly. | `any` | `{}` | no |
| `tags` | Extra tags, merged over the ones derived from `global_config`. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `web_acl_arn` | ARN of the WAFv2 Web ACL |
| `web_acl_id` | ID of the WAFv2 Web ACL |
| `web_acl_capacity` | Web ACL capacity units consumed |
