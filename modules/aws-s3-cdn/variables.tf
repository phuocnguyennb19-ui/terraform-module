# ── Required ──────────────────────────────────────────────────────────────────
variable "name"        { type = string }
variable "environment" { type = string }

# ── S3 Bucket ─────────────────────────────────────────────────────────────────
variable "bucket_name" {
  description = "null = auto-generate: {name}-{environment}-static"
  type        = string
  default     = null
}

variable "versioning_enabled"  { type = bool; default = false }
variable "force_destroy"       { type = bool; default = false }

# ── CloudFront ────────────────────────────────────────────────────────────────
variable "create_cloudfront"   { type = bool;   default = true }
variable "price_class"         { type = string; default = "PriceClass_100" }  # 100=US+EU, 200=+Asia, All=global
variable "default_root_object" { type = string; default = "index.html" }
variable "aliases"             { type = list(string); default = [] }

variable "acm_certificate_arn" {
  description = "ACM cert ARN (us-east-1) cho custom domain. null = dùng CloudFront cert"
  type        = string
  default     = null
}

variable "custom_error_responses" {
  description = "SPA routing: redirect 403/404 về index.html"
  type = list(object({
    error_code            = number
    response_code         = optional(number, 200)
    response_page_path    = optional(string, "/index.html")
    error_caching_min_ttl = optional(number, 10)
  }))
  default = [
    { error_code = 403 },
    { error_code = 404 }
  ]
}

variable "cache_ttl" {
  type = object({
    default = optional(number, 86400)    # 1 day
    min     = optional(number, 0)
    max     = optional(number, 31536000) # 1 year
  })
  default = {}
}

variable "tags" { type = map(string); default = {} }
