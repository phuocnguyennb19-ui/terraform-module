variable "domain_name" { type = string }

variable "subject_alternative_names" {
  type    = list(string)
  default = []
}

variable "zone_id"             { type = string }
variable "wait_for_validation" { type = bool; default = true }

variable "tags" {
  type    = map(string)
  default = {}
}
