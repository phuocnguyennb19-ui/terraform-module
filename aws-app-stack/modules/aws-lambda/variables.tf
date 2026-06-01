# ── Required ──────────────────────────────────────────────────────────────────
variable "name"        { type = string }
variable "environment" { type = string }
variable "handler"     { type = string }
variable "runtime"     { type = string }

# ── Source ────────────────────────────────────────────────────────────────────
variable "source_path" {
  description = "Local path để package. null nếu dùng s3_existing_package"
  type        = string
  default     = null
}

variable "s3_existing_package" {
  description = "{ bucket, key, version_id } — dùng package đã upload sẵn trên S3"
  type        = map(string)
  default     = null
}

# ── Create toggles ────────────────────────────────────────────────────────────
variable "create"         { type = bool; default = true }
variable "create_package" { type = bool; default = true }  # false nếu dùng s3_existing_package
variable "create_role"    { type = bool; default = true }
variable "publish"        { type = bool; default = true }   # tạo version mới mỗi deploy

# ── Function config ───────────────────────────────────────────────────────────
variable "description"  { type = string; default = "" }
variable "memory_size"  { type = number; default = 256 }
variable "timeout"      { type = number; default = 30 }
variable "layers"       { type = list(string); default = [] }

variable "environment_variables" { type = map(string); default = {} }

# ── VPC (optional — bỏ trống nếu không cần VPC access) ───────────────────────
variable "vpc_subnet_ids"         { type = list(string); default = null }
variable "vpc_security_group_ids" { type = list(string); default = null }

# ── URL / API Gateway ─────────────────────────────────────────────────────────
variable "create_lambda_function_url" {
  description = "Tạo Lambda Function URL (không cần API Gateway)"
  type        = bool
  default     = false
}

variable "attach_policy_arns" {
  description = "Danh sách IAM policy ARN đính kèm vào Lambda role"
  type        = list(string)
  default     = []
}

# ── Reserved concurrency ──────────────────────────────────────────────────────
variable "reserved_concurrent_executions" {
  description = "-1 = unlimited | 0 = throttle all | N = limit"
  type        = number
  default     = -1
}

variable "tags" { type = map(string); default = {} }
