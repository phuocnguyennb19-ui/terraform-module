locals {
  # Whether each group exists. Booleans only — for_each keys must be known at
  # plan time, and security group IDs are not.
  exists = {
    alb         = var.create_alb_sg
    eks_cluster = var.create_eks_sg
    eks_node    = var.create_eks_sg
    ec2         = var.create_ec2_sg
    ecs         = var.create_ecs_sg
    rds         = var.create_rds_sg
    elasticache = var.create_elasticache_sg
    lambda      = var.create_lambda_sg
    bastion     = var.create_bastion_sg
  }

  ids = {
    alb         = one(aws_security_group.alb[*].id)
    eks_cluster = one(aws_security_group.eks_cluster[*].id)
    eks_node    = one(aws_security_group.eks_node[*].id)
    ec2         = one(aws_security_group.ec2[*].id)
    ecs         = one(aws_security_group.ecs[*].id)
    rds         = one(aws_security_group.rds[*].id)
    elasticache = one(aws_security_group.elasticache[*].id)
    lambda      = one(aws_security_group.lambda[*].id)
    bastion     = one(aws_security_group.bastion[*].id)
  }

  # Every group-to-group ingress rule in the platform, declared once. A rule is
  # created only when both endpoints exist, so disabling a tier removes the
  # rules that pointed at it instead of leaving a dangling reference.
  group_ingress = {
    # --- edge to compute -------------------------------------------------
    "ec2-from-alb" = {
      target = "ec2", source = "alb"
      from   = var.application_port, to = var.application_port
      desc   = "Application traffic from the ALB"
    }
    # Fargate awsvpc networking gives every task its own ENI in the private
    # subnets, so the ALB reaches the container port directly. There is no
    # NodePort equivalent and no host to hop through.
    "ecs-from-alb" = {
      target = "ecs", source = "alb"
      from   = var.application_port, to = var.application_port
      desc   = "Application traffic from the ALB to Fargate task ENIs"
    }
    "eks-node-from-alb-app" = {
      target = "eks_node", source = "alb"
      from   = var.application_port, to = var.application_port
      desc   = "Application traffic from the ALB to pods (IP target mode)"
    }
    "eks-node-from-alb-nodeport" = {
      target = "eks_node", source = "alb"
      from   = 30000, to = 32767
      desc   = "NodePort range from the ALB (instance target mode)"
    }

    # --- EKS control plane <-> nodes -------------------------------------
    # These are the minimum set the kubelet and the API server need. The EKS
    # module adds its own managed rules on top when it creates its own groups;
    # these exist so the platform's groups work standalone.
    "eks-cluster-from-node" = {
      target = "eks_cluster", source = "eks_node"
      from   = 443, to = 443
      desc   = "Kubelet and pods to the API server"
    }
    "eks-node-from-cluster-kubelet" = {
      target = "eks_node", source = "eks_cluster"
      from   = 10250, to = 10250
      desc   = "API server to kubelet (logs, exec, port-forward)"
    }
    "eks-node-from-cluster-webhook" = {
      target = "eks_node", source = "eks_cluster"
      from   = 443, to = 443
      desc   = "API server to admission and extension webhooks"
    }
    "eks-node-from-node" = {
      target = "eks_node", source = "eks_node"
      from   = 0, to = 0, protocol = "-1"
      desc   = "Node to node — required by the VPC CNI and CoreDNS"
    }

    # --- compute to data --------------------------------------------------
    "rds-from-ec2" = {
      target = "rds", source = "ec2"
      from   = var.database_port, to = var.database_port
      desc   = "Database access from EC2 application instances"
    }
    "rds-from-eks-node" = {
      target = "rds", source = "eks_node"
      from   = var.database_port, to = var.database_port
      desc   = "Database access from EKS workloads"
    }
    "rds-from-ecs" = {
      target = "rds", source = "ecs"
      from   = var.database_port, to = var.database_port
      desc   = "Database access from ECS tasks"
    }
    "rds-from-lambda" = {
      target = "rds", source = "lambda"
      from   = var.database_port, to = var.database_port
      desc   = "Database access from VPC-attached Lambda functions"
    }
    "rds-from-bastion" = {
      target = "rds", source = "bastion"
      from   = var.database_port, to = var.database_port
      desc   = "Database access from the bastion for operational tasks"
    }
    "cache-from-ec2" = {
      target = "elasticache", source = "ec2"
      from   = var.cache_port, to = var.cache_port
      desc   = "Cache access from EC2 application instances"
    }
    "cache-from-eks-node" = {
      target = "elasticache", source = "eks_node"
      from   = var.cache_port, to = var.cache_port
      desc   = "Cache access from EKS workloads"
    }
    "cache-from-ecs" = {
      target = "elasticache", source = "ecs"
      from   = var.cache_port, to = var.cache_port
      desc   = "Cache access from ECS tasks"
    }
    "cache-from-lambda" = {
      target = "elasticache", source = "lambda"
      from   = var.cache_port, to = var.cache_port
      desc   = "Cache access from VPC-attached Lambda functions"
    }

    # --- bastion to compute ----------------------------------------------
    "ec2-from-bastion-ssh" = {
      target = "ec2", source = "bastion"
      from   = 22, to = 22
      desc   = "SSH from the bastion"
    }
    "eks-node-from-bastion-ssh" = {
      target = "eks_node", source = "bastion"
      from   = 22, to = 22
      desc   = "SSH from the bastion"
    }
    "eks-cluster-from-bastion" = {
      target = "eks_cluster", source = "bastion"
      from   = 443, to = 443
      desc   = "kubectl from the bastion to a private API endpoint"
    }
  }

  # Filtered to the rules whose two endpoints both exist in this environment.
  active_group_ingress = {
    for k, r in local.group_ingress : k => r
    if local.exists[r.target] && local.exists[r.source]
  }

  # Perimeter ingress: the only rules that name a CIDR instead of a group.
  cidr_ingress = merge(
    var.create_alb_sg ? {
      for c in var.alb_ingress_cidrs : "alb-https-${c}" => {
        target = "alb", cidr = c, from = 443, to = 443
        desc   = "HTTPS from ${c}"
      }
    } : {},
    var.create_alb_sg && var.alb_allow_http ? {
      for c in var.alb_ingress_cidrs : "alb-http-${c}" => {
        target = "alb", cidr = c, from = 80, to = 80
        desc   = "HTTP from ${c} — redirected to HTTPS by the listener"
      }
    } : {},
    var.create_bastion_sg ? {
      for c in var.bastion_allowed_cidrs : "bastion-ssh-${c}" => {
        target = "bastion", cidr = c, from = 22, to = 22
        desc   = "SSH from administrative range ${c}"
      }
    } : {},
    var.create_eks_sg ? {
      for c in var.eks_public_api_allowed_cidrs : "eks-api-${c}" => {
        target = "eks_cluster", cidr = c, from = 443, to = 443
        desc   = "EKS API from administrative range ${c}"
      }
    } : {},
  )
}

# ---------------------------------------------------------------------------
# Ingress
# ---------------------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "group" {
  for_each = local.active_group_ingress

  security_group_id            = local.ids[each.value.target]
  referenced_security_group_id = local.ids[each.value.source]

  ip_protocol = try(each.value.protocol, "tcp")
  from_port   = try(each.value.protocol, "tcp") == "-1" ? null : each.value.from
  to_port     = try(each.value.protocol, "tcp") == "-1" ? null : each.value.to
  description = each.value.desc

  tags = merge(var.tags, { Name = "${var.name}-${each.key}" })
}

resource "aws_vpc_security_group_ingress_rule" "cidr" {
  for_each = local.cidr_ingress

  security_group_id = local.ids[each.value.target]
  cidr_ipv4         = each.value.cidr

  ip_protocol = "tcp"
  from_port   = each.value.from
  to_port     = each.value.to
  description = each.value.desc

  tags = merge(var.tags, { Name = "${var.name}-${each.key}" })
}

resource "aws_vpc_security_group_ingress_rule" "additional" {
  for_each = var.additional_ingress_rules

  security_group_id = local.ids[each.value.security_group]

  referenced_security_group_id = each.value.source_security_group != null ? local.ids[each.value.source_security_group] : null
  cidr_ipv4                    = each.value.cidr_ipv4

  ip_protocol = each.value.ip_protocol
  from_port   = each.value.ip_protocol == "-1" ? null : each.value.from_port
  to_port     = each.value.ip_protocol == "-1" ? null : each.value.to_port
  description = each.value.description

  tags = merge(var.tags, { Name = "${var.name}-${each.key}" })
}

# ---------------------------------------------------------------------------
# Egress
#
# The compute tiers get unrestricted egress: they pull container images, OS
# packages and third-party APIs, and pinning that to a CIDR list breaks the
# first time a registry changes address. Tightening it is a real hardening step,
# but it needs an egress proxy or VPC endpoints to replace what it removes —
# not a narrower CIDR list.
#
# The ALB gets egress to the VPC only, because it never has a reason to talk to
# the internet. The data tiers get NO egress rule at all: RDS and ElastiCache
# are pure destinations, and an AWS security group with zero egress rules
# denies all outbound traffic.
# ---------------------------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "alb_to_vpc" {
  count = var.create_alb_sg ? 1 : 0

  security_group_id = local.ids.alb
  cidr_ipv4         = var.vpc_cidr_block
  ip_protocol       = "-1"
  description       = "To targets inside the VPC only — the ALB has no reason to reach the internet"

  tags = merge(var.tags, { Name = "${var.name}-alb-egress-vpc" })
}

resource "aws_vpc_security_group_egress_rule" "compute_all" {
  for_each = toset([
    for k in ["eks_cluster", "eks_node", "ec2", "ecs", "lambda", "bastion"] : k
    if local.exists[k]
  ])

  security_group_id = local.ids[each.key]
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Outbound to the internet via NAT — container images, OS packages, AWS APIs"

  tags = merge(var.tags, { Name = "${var.name}-${replace(each.key, "_", "-")}-egress" })
}
