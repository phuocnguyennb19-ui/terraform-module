variable "config_file" {
  description = "Path to the environment config, relative to the directory Terraform is run from."
  type        = string
  default     = "config.yaml"

  validation {
    condition     = can(regex("\\.ya?ml$", var.config_file))
    error_message = "config_file must point at a .yml or .yaml file."
  }
}

variable "tags" {
  description = "Extra tags merged over the ones derived from global.tags in the config. Use it for values CI knows and the config does not — the commit SHA, the pipeline ID."
  type        = map(string)
  default     = {}
}
