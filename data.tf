# Only what is actually referenced: every data source costs an API call on every
# plan and an IAM permission to allow it.

data "aws_caller_identity" "current" {}

# PRE-EXISTING INFRASTRUCTURE
# `enabled: false` plus an `existing:` block means "look it up" rather than "it
# does not exist". Each lookup is gated on the config naming it, so an
# environment that builds everything makes no extra API call.
#
#   existing:
#     vpc:
#       id: "vpc-0123456789abcdef0"        # or name_tag: "prod-vpc"
#     private_subnets:
#       tag: { key: "Tier", value: "Private" }
#     alb:
#       name: "prod-shared-alb"
#       listener_port: 443
#     ecs_cluster:
#       name: "prod-cluster"
#
# A count of 0 does not stop Terraform validating a data source's arguments
# against the provider schema, so every filter value falls back to a harmless
# placeholder rather than null or "".

data "aws_vpc" "existing" {
  count = local.lookup.vpc ? 1 : 0

  id = local.ex.vpc_id

  dynamic "filter" {
    for_each = local.ex.vpc_id == null ? [1] : []
    content {
      name   = "tag:Name"
      values = [local.ex.vpc_name_tag]
    }
  }
}

data "aws_subnets" "existing_private" {
  count = local.lookup.private_subnets ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }

  filter {
    name   = "tag:${local.ex.private_subnet_tag_key}"
    values = [local.ex.private_subnet_tag_value]
  }
}

data "aws_subnets" "existing_public" {
  count = local.lookup.public_subnets ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }

  filter {
    name   = "tag:${local.ex.public_subnet_tag_key}"
    values = [local.ex.public_subnet_tag_value]
  }
}

data "aws_lb" "existing" {
  count = local.lookup.alb ? 1 : 0
  name  = local.ex.alb_name
}

data "aws_lb_listener" "existing" {
  count             = local.lookup.alb ? 1 : 0
  load_balancer_arn = data.aws_lb.existing[0].arn
  port              = local.ex.alb_listener_port
}

data "aws_ecs_cluster" "existing" {
  count        = local.lookup.ecs_cluster ? 1 : 0
  cluster_name = local.ex.ecs_cluster_name
}
