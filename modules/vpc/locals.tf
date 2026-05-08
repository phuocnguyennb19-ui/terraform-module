locals {
  config_local = merge(
    try(yamldecode(file("${path.cwd}/${var.config_file}")), {}),
    var.manual_config
  )

  env          = lookup(var.global_config, "environment", "dev")
  region       = lookup(var.global_config, "region", "ap-southeast-1")
  project      = lookup(var.global_config, "project", "core")
  app_name     = lookup(local.config_local, "app_name", null)
  service_type = lookup(local.config_local, "service_type", "infra")

  name_prefix = join("-", compact([local.env, local.app_name == "base" ? null : local.app_name, local.service_type]))

  raw_vpc_cfg = try(local.config_local.vpc, {})

  vpc_config = {
    name                 = "${local.name_prefix}-vpc"
    cidr                 = try(local.raw_vpc_cfg.cidr, "10.0.0.0/16")
    azs                  = try(local.raw_vpc_cfg.azs, [for s in ["a", "b", "c"] : "${local.region}${s}"])
    public_subnets       = try(local.raw_vpc_cfg.public_subnets, [])
    private_subnets      = try(local.raw_vpc_cfg.private_subnets, [])
    database_subnets     = try(local.raw_vpc_cfg.database_subnets, [])
    intra_subnets        = try(local.raw_vpc_cfg.intra_subnets, [])
    enable_nat_gateway   = try(local.raw_vpc_cfg.enable_nat_gateway, true)
    single_nat_gateway   = try(local.raw_vpc_cfg.single_nat_gateway, local.env != "prod")
    one_nat_gateway_per_az = try(local.raw_vpc_cfg.one_nat_gateway_per_az, local.env == "prod")
    enable_dns_hostnames = try(local.raw_vpc_cfg.enable_dns_hostnames, true)
    enable_dns_support   = try(local.raw_vpc_cfg.enable_dns_support, true)
    enable_vpn_gateway   = try(local.raw_vpc_cfg.enable_vpn_gateway, false)
    public_subnet_tags   = try(local.raw_vpc_cfg.public_subnet_tags, {})
    private_subnet_tags  = try(local.raw_vpc_cfg.private_subnet_tags, {})
    database_subnet_tags = try(local.raw_vpc_cfg.database_subnet_tags, {})
    intra_subnet_tags    = try(local.raw_vpc_cfg.intra_subnet_tags, {})
    create_database_subnet_group         = try(local.raw_vpc_cfg.create_database_subnet_group, length(try(local.raw_vpc_cfg.database_subnets, [])) > 0)
    create_database_subnet_route_table   = try(local.raw_vpc_cfg.create_database_subnet_route_table, false)
    enable_flow_log                      = try(local.raw_vpc_cfg.enable_flow_log, true)
    flow_log_traffic_type                = try(local.raw_vpc_cfg.flow_log_traffic_type, "REJECT")
    flow_log_max_aggregation_interval    = try(local.raw_vpc_cfg.flow_log_max_aggregation_interval, 60)
  }

  tags = merge(
    {
      Environment = local.env,
      Project     = local.project,
      ManagedBy   = lookup(var.global_config, "managed_by", "DylanDevOps"),
      CostCenter  = lookup(var.global_config, "cost_center", "shared-services"),
      Terraform   = "true"
    },
    var.tags,
    try(var.global_config.tags, {})
  )
}