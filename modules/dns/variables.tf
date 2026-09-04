variable "global_config" {
  description = "Environment context shared by every module: environment, region and project, plus optional managed_by, cost_center and tags. `environment` is validated against dev, test, staging, preprod, prod."
  type = object({
    environment = string
    region      = string
    project     = string
    managed_by  = optional(string, "DylanDevOps")
    cost_center = optional(string, "shared-services")
    tags        = optional(map(string), {})
  })

  validation {
    condition     = contains(["dev", "test", "staging", "preprod", "prod"], var.global_config.environment)
    error_message = "environment must be one of: dev, test, staging, preprod, prod."
  }
}

variable "config_file" {
  description = "Path to the YAML config, resolved against `path.cwd` — the directory Terraform is run from, not the module directory."
  type        = string
  default     = "config.yml"
}

variable "manual_config" {
  description = "Configuration merged over the decoded YAML at the top level. The root composition uses this to pass a layered config; leave unset when calling the module directly."
  type        = any
  default     = {}
}

variable "tags" {
  description = "Extra tags, merged over the ones derived from `global_config`."
  type        = map(string)
  default     = {}
}

# ---- wiring inputs, supplied by the caller -----------------------------------
# A Route53 alias needs the target's DNS name and hosted-zone ID, which are
# outputs of another module, not values anyone can put in YAML. A record declares
# `alias: { target: "alb" }` and the module substitutes what the caller passed in.

variable "alb_dns_name" {
  description = "DNS name of the ALB, for records using alias.target = \"alb\"."
  type        = string
  default     = null
}

variable "alb_zone_id" {
  description = "Hosted zone ID of the ALB, for records using alias.target = \"alb\"."
  type        = string
  default     = null
}

variable "cloudfront_domain_name" {
  description = "CloudFront domain, for records using alias.target = \"cloudfront\"."
  type        = string
  default     = null
}
