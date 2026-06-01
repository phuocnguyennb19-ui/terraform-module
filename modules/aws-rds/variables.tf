# ── Required ──────────────────────────────────────────────────────────────────
variable "name"                  { type = string }
variable "environment"           { type = string }
variable "vpc_id"                { type = string }
variable "db_subnet_group_name"  { type = string }
variable "ecs_security_group_id" { type = string }
variable "db_name"               { type = string }
variable "username"              { type = string }

# ── Engine — hỗ trợ postgres | mysql | aurora-postgresql | aurora-mysql ────────
variable "engine" {
  type    = string
  default = "postgres"
  validation {
    condition     = contains(["postgres", "mysql", "aurora-postgresql", "aurora-mysql", "mariadb"], var.engine)
    error_message = "engine phải là postgres, mysql, aurora-postgresql, aurora-mysql, hoặc mariadb."
  }
}

variable "engine_version" { type = string; default = null }  # null = latest

variable "family" {
  description = "Parameter group family. null = auto-derive từ engine"
  type        = string
  default     = null
}

variable "major_engine_version" {
  description = "Option group major version. null = auto-derive"
  type        = string
  default     = null
}

# ── Instance ──────────────────────────────────────────────────────────────────
variable "instance_class"        { type = string; default = "db.t4g.medium" }
variable "allocated_storage"     { type = number; default = 20 }
variable "max_allocated_storage" { type = number; default = 100 }

# ── HA ────────────────────────────────────────────────────────────────────────
variable "multi_az" { type = bool; default = true }

# ── Encryption ────────────────────────────────────────────────────────────────
variable "storage_encrypted" { type = bool;   default = true }
variable "kms_key_id"        { type = string; default = null }

# ── Backup & Maintenance ──────────────────────────────────────────────────────
variable "backup_retention_period"    { type = number; default = 7 }
variable "backup_window"              { type = string; default = "03:00-04:00" }
variable "maintenance_window"         { type = string; default = "Mon:04:00-Mon:05:00" }
variable "deletion_protection"        { type = bool;   default = true }
variable "skip_final_snapshot"        { type = bool;   default = false }
variable "auto_minor_version_upgrade" { type = bool;   default = true }

# ── Observability ─────────────────────────────────────────────────────────────
variable "performance_insights" {
  type = object({
    enabled          = optional(bool, true)
    retention_period = optional(number, 7)
  })
  default = {}
}

variable "monitoring" {
  type = object({
    interval    = optional(number, 60)
    role_name   = optional(string, null)
    create_role = optional(bool, true)
  })
  default = {}
}

variable "tags" { type = map(string); default = {} }
