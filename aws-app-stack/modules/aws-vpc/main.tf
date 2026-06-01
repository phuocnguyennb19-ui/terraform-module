module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.name}-${var.environment}"
  cidr = var.vpc_cidr

  azs              = var.availability_zones
  private_subnets  = var.private_subnet_cidrs
  public_subnets   = var.public_subnet_cidrs
  database_subnets = var.database_subnet_cidrs

  # Database subnet group tự động tạo — dùng cho RDS
  create_database_subnet_group           = length(var.database_subnet_cidrs) > 0
  create_database_subnet_route_table     = length(var.database_subnet_cidrs) > 0
  create_database_internet_gateway_route = false  # DB không ra internet

  enable_nat_gateway      = true
  single_nat_gateway      = var.single_nat_gateway
  one_nat_gateway_per_az  = var.one_nat_gateway_per_az
  enable_vpn_gateway      = false
  enable_dns_hostnames    = var.enable_dns_hostnames
  enable_dns_support      = var.enable_dns_support

  # VPC Flow Logs — bắt buộc trên prod
  enable_flow_log                      = var.enable_flow_log
  create_flow_log_cloudwatch_log_group = var.enable_flow_log
  create_flow_log_cloudwatch_iam_role  = var.enable_flow_log
  flow_log_max_aggregation_interval    = 60

  public_subnet_tags   = var.public_subnet_tags
  private_subnet_tags  = var.private_subnet_tags
  database_subnet_tags = var.database_subnet_tags

  tags = var.tags
}
