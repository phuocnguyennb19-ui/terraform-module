module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name = local.vpc_config.name
  cidr = local.vpc_config.cidr
  azs  = local.vpc_config.azs

  private_subnets   = local.vpc_config.private_subnets
  public_subnets    = local.vpc_config.public_subnets
  database_subnets  = local.vpc_config.database_subnets
  intra_subnets     = local.vpc_config.intra_subnets

  enable_nat_gateway     = local.vpc_config.enable_nat_gateway
  single_nat_gateway     = local.vpc_config.single_nat_gateway
  one_nat_gateway_per_az = local.vpc_config.one_nat_gateway_per_az

  enable_dns_hostnames = local.vpc_config.enable_dns_hostnames
  enable_dns_support   = local.vpc_config.enable_dns_support
  enable_vpn_gateway   = local.vpc_config.enable_vpn_gateway

  create_database_subnet_group       = local.vpc_config.create_database_subnet_group
  create_database_subnet_route_table = local.vpc_config.create_database_subnet_route_table

  public_subnet_tags   = local.vpc_config.public_subnet_tags
  private_subnet_tags  = local.vpc_config.private_subnet_tags
  database_subnet_tags = local.vpc_config.database_subnet_tags
  intra_subnet_tags    = local.vpc_config.intra_subnet_tags

  enable_flow_log                      = local.vpc_config.enable_flow_log
  create_flow_log_cloudwatch_log_group = local.vpc_config.enable_flow_log
  create_flow_log_cloudwatch_iam_role  = local.vpc_config.enable_flow_log
  flow_log_traffic_type                = local.vpc_config.flow_log_traffic_type
  flow_log_max_aggregation_interval    = local.vpc_config.flow_log_max_aggregation_interval

  tags = local.tags
}