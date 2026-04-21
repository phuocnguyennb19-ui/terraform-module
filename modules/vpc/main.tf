module "vpc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=v5.8.1"

  name = local.vpc_config.name
  cidr = local.vpc_config.cidr

  azs             = local.vpc_config.azs
  private_subnets = local.vpc_config.private_subnets
  public_subnets  = local.vpc_config.public_subnets

  enable_nat_gateway = try(local.vpc_config.enable_nat_gateway, true)
  single_nat_gateway = try(local.vpc_config.single_nat_gateway, false)

  # Production Best Practices (DNS)
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Subnet Tags (Best Practice for ELB discovery)
  public_subnet_tags  = merge({ "kubernetes.io/role/elb" = "1" }, try(local.vpc_config.public_subnet_tags, {}))
  private_subnet_tags = merge({ "kubernetes.io/role/internal-elb" = "1" }, try(local.vpc_config.private_subnet_tags, {}))

  # Security: Flow Logs
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60
  flow_log_traffic_type                = "ALL"

  tags = local.tags
}

