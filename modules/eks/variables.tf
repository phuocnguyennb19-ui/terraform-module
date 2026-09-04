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
    error_message = "environment must be one of: dev, test, staging, preprod, prod."
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

# ---- wiring inputs, supplied by the caller -----------------------------------

variable "vpc_id" {
  type    = string
  default = null
}

variable "private_subnets" {
  description = "Subnets for the control plane ENIs and the node groups."
  type        = list(string)
  default     = []
}

variable "public_subnets" {
  description = "Only used when a node group is explicitly placed in public subnets."
  type        = list(string)
  default     = []
}
