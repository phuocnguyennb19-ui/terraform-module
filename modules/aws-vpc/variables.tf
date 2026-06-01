# ── Required ──────────────────────────────────────────────────────────────────
variable "name"        { type = string }
variable "environment" { type = string }
variable "vpc_cidr"    { type = string }

variable "availability_zones"    { type = list(string) }
variable "private_subnet_cidrs"  { type = list(string) }
variable "public_subnet_cidrs"   { type = list(string) }

# ── Optional subnets ──────────────────────────────────────────────────────────
variable "database_subnet_cidrs" { type = list(string); default = [] }
variable "intra_subnet_cidrs"    { type = list(string); default = [] }

# ── NAT Gateway ───────────────────────────────────────────────────────────────
variable "single_nat_gateway"      { type = bool; default = false }
variable "one_nat_gateway_per_az"  { type = bool; default = false }

# ── DNS ───────────────────────────────────────────────────────────────────────
variable "enable_dns_hostnames" { type = bool; default = true }
variable "enable_dns_support"   { type = bool; default = true }

# ── Flow Logs ─────────────────────────────────────────────────────────────────
variable "enable_flow_log"                      { type = bool;   default = true }
variable "flow_log_max_aggregation_interval"    { type = number; default = 60 }

# ── Subnet Tags ───────────────────────────────────────────────────────────────
variable "public_subnet_tags"   { type = map(string); default = { "kubernetes.io/role/elb" = "1" } }
variable "private_subnet_tags"  { type = map(string); default = { "kubernetes.io/role/internal-elb" = "1" } }
variable "database_subnet_tags" { type = map(string); default = {} }

variable "tags" { type = map(string); default = {} }
