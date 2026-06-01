# ── Required ──────────────────────────────────────────────────────────────────
variable "name"        { type = string }
variable "environment" { type = string }

# ── Create toggles ────────────────────────────────────────────────────────────
variable "create"                 { type = bool;   default = true }
variable "create_lifecycle_policy"{ type = bool;   default = true }

# ── Repository settings ───────────────────────────────────────────────────────
variable "repository_type"            { type = string; default = "private" }
variable "image_tag_mutability"       { type = string; default = "IMMUTABLE" }
variable "scan_on_push"               { type = bool;   default = true }
variable "encryption_type"            { type = string; default = "KMS" }   # KMS | AES256
variable "kms_key"                    { type = string; default = null }
variable "force_delete"               { type = bool;   default = false }
variable "read_write_access_arns"     { type = list(string); default = [] }

# ── Lifecycle ─────────────────────────────────────────────────────────────────
variable "lifecycle" {
  type = object({
    untagged_expire_days    = optional(number, 1)
    tagged_keep_count       = optional(number, 30)
    tagged_prefix_list      = optional(list(string), ["v", "release", "prod"])
  })
  default = {}
}

variable "tags" { type = map(string); default = {} }
