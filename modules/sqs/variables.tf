variable "global_config" {
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
    error_message = "Biến environment phải là một trong các giá trị: dev, test, staging, preprod, prod."
  }
}

variable "config_file" {
  type    = string
  default = "config.yml"
}

variable "manual_config" {
  type    = any
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
