output "web_acl_arn" { value = { for k, v in module.wafv2 : k => v.web_acl_arn } }
