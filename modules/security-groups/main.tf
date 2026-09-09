# SECURITY GROUP ARCHITECTURE
#
#   Internet ──▶ alb :80/:443
#                  │
#                  ├──▶ ec2 :application_port
#                  ├──▶ ecs :application_port
#                  └──▶ eks_node :application_port, :30000-32767
#                              │
#                              ├──▶ rds :database_port
#                              └──▶ elasticache :cache_port
#
# Every rule between tiers references the *source security group*, not a CIDR.
# A CIDR rule keeps allowing traffic after the instance behind the address is
# replaced by something else; a group reference follows membership, so scaling a
# node group or replacing an instance never widens the boundary.
#
# Raw CIDRs are accepted in exactly three places, all of them at the perimeter
# where there is no group to reference: ALB ingress, bastion SSH ingress, and
# the EKS public API endpoint. The last two are validated against 0.0.0.0/0.
#
# Rules are separate aws_vpc_security_group_*_rule resources rather than inline
# blocks. Inline blocks are authoritative over the whole group, so two modules
# touching one group silently delete each other's rules; discrete rules also give
# each rule its own description, which is what makes an audit readable.

# ---------------------------------------------------------------------------
# The groups
# ---------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  count = var.create_alb_sg ? 1 : 0

  name        = "${var.name}-alb"
  description = "Application Load Balancer — the only tier reachable from outside the VPC"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-alb", Tier = "edge" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "eks_cluster" {
  count = var.create_eks_sg ? 1 : 0

  name        = "${var.name}-eks-cluster"
  description = "EKS control plane ENIs"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-eks-cluster", Tier = "control-plane" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "eks_node" {
  count = var.create_eks_sg ? 1 : 0

  name        = "${var.name}-eks-node"
  description = "EKS managed node group instances"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-eks-node", Tier = "compute" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ec2" {
  count = var.create_ec2_sg ? 1 : 0

  name        = "${var.name}-ec2"
  description = "EC2 application instances in the private tier"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-ec2", Tier = "compute" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ecs" {
  count = var.create_ecs_sg ? 1 : 0

  name        = "${var.name}-ecs"
  description = "ECS Fargate task ENIs in the private tier"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-ecs", Tier = "compute" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "rds" {
  count = var.create_rds_sg ? 1 : 0

  name        = "${var.name}-rds"
  description = "RDS instances — reachable only from the application tier"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-rds", Tier = "data" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "elasticache" {
  count = var.create_elasticache_sg ? 1 : 0

  name        = "${var.name}-elasticache"
  description = "ElastiCache nodes — reachable only from the application tier"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-elasticache", Tier = "data" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "lambda" {
  count = var.create_lambda_sg ? 1 : 0

  name        = "${var.name}-lambda"
  description = "VPC-attached Lambda function ENIs"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-lambda", Tier = "compute" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "bastion" {
  count = var.create_bastion_sg ? 1 : 0

  name        = "${var.name}-bastion"
  description = "Bastion host — SSH from named administrative ranges only"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-bastion", Tier = "edge" })

  lifecycle {
    create_before_destroy = true
  }
}
