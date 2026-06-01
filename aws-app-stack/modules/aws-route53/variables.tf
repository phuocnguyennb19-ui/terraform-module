variable "zone_name" { type = string }

# Khi create_zone = false: dùng zone_id có sẵn (stack route53-records)
# Khi create_zone = true:  tạo zone mới (stack route53)
variable "create_zone" { type = bool; default = true }
variable "zone_id"     { type = string; default = "" }  # dùng khi create_zone = false

variable "records" {
  description = "Map of DNS records to create"
  type = map(object({
    type    = string
    ttl     = optional(number, 300)
    alias   = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = bool
    }))
    records = optional(list(string))
  }))
  default = {}
}

variable "tags" { type = map(string); default = {} }
