# ==============================================================================
# ROOT INPUT VARIABLES
# ==============================================================================
# The root takes a path, not a pile of settings. Everything else lives in the
# environment's config.yml, because that is the file the modules themselves read.
# ==============================================================================

variable "config_file" {
  description = <<-EOT
    Path to the environment config, relative to the directory Terraform is run from.

    This exact string is handed to every module, and each module resolves it as
    file("$${path.cwd}/$${var.config_file}"). Run Terraform from the repository root
    so that "environments/dev/config.yml" resolves for the root and the modules alike.
  EOT
  type        = string
  default     = "environments/dev/config.yml"

  validation {
    condition     = can(regex("\\.ya?ml$", var.config_file))
    error_message = "config_file must point at a .yml or .yaml file."
  }
}

variable "tags" {
  description = "Extra tags merged over the ones derived from config.yml global.tags."
  type        = map(string)
  default     = {}
}

variable "config_dir" {
  description = <<-EOT
    Optional. Path to a directory of per-module config, relative to the run directory.

    When set, the root reads `<config_dir>/common.yml` (required) plus an optional
    `<config_dir>/<module>.yml` for each module, and merges them two levels deep:
    the per-module file overrides individual keys inside a block without discarding
    the rest of that block from common.yml.

    When null (the default), `config_file` is used as a single monolithic config.

    Precedence, lowest to highest:
      module defaults in locals.tf  ->  common.yml  ->  <module>.yml
  EOT
  type        = string
  default     = null
}

variable "localstack_endpoint" {
  description = <<-EOT
    Redirect every AWS API this repository uses to a local emulator, e.g.
    "http://localhost:4566". Unset (the default) means real AWS through the
    normal credential chain.

    Only the services named in the endpoints block of providers.tf are
    redirected; anything else silently goes to the real account, so a new module
    must add its service there in the same change.

    LocalStack Community implements iam, secretsmanager, logs, cloudwatch, ec2,
    kms, s3, sns and sqs. It answers 501 for ecr, ecs, elbv2, eks and rds, so a
    config enabling those cannot be applied against it:

      curl -s http://localhost:4566/_localstack/health
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.localstack_endpoint == null || can(regex("^https?://", var.localstack_endpoint))
    error_message = "localstack_endpoint must be a URL, e.g. http://localhost:4566."
  }
}
