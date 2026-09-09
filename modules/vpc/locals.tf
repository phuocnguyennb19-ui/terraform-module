data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  azs = var.azs != null ? var.azs : slice(data.aws_availability_zones.available.names, 0, var.az_count)

  az_count = length(local.azs)

  # Default subnet layout, derived from cidr_block so a caller only has to
  # supply one CIDR. For a /16 and three AZs this produces:
  #
  #   private (app)   10.x.0.0/20   10.x.16.0/20   10.x.32.0/20   <- large, pods and instances live here
  #   public          10.x.240.0/24 10.x.241.0/24  10.x.242.0/24  <- small, only load balancers and NAT
  #   database        10.x.250.0/24 10.x.251.0/24  10.x.252.0/24  <- small, no internet route at all
  #
  # The application tier gets the /20 blocks because it is the only tier whose
  # address consumption is unpredictable — an EKS node group with the VPC CNI
  # burns one VPC address per pod. Public and database subnets hold a countable
  # number of ENIs, so /24 is generous.
  #
  # The high indices keep the public and database ranges out of the way of the
  # application /20s, leaving 10.x.48.0 - 10.x.239.255 free for future tiers.
  derived_private_subnet_cidrs  = [for i in range(local.az_count) : cidrsubnet(var.cidr_block, 4, i)]
  derived_public_subnet_cidrs   = [for i in range(local.az_count) : cidrsubnet(var.cidr_block, 8, 240 + i)]
  derived_database_subnet_cidrs = [for i in range(local.az_count) : cidrsubnet(var.cidr_block, 8, 250 + i)]

  private_subnet_cidrs  = var.private_subnet_cidrs != null ? var.private_subnet_cidrs : local.derived_private_subnet_cidrs
  public_subnet_cidrs   = var.public_subnet_cidrs != null ? var.public_subnet_cidrs : local.derived_public_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs != null ? var.database_subnet_cidrs : local.derived_database_subnet_cidrs

  # Discovery tags. The AWS Load Balancer Controller looks for kubernetes.io/role/elb
  # on public subnets and kubernetes.io/role/internal-elb on private ones; both it
  # and the Cluster Autoscaler look for kubernetes.io/cluster/<name>.
  eks_shared_tags = { for c in var.eks_cluster_names : "kubernetes.io/cluster/${c}" => "shared" }

  public_tags = merge(
    { Tier = "public" },
    length(var.eks_cluster_names) > 0 ? merge(local.eks_shared_tags, { "kubernetes.io/role/elb" = "1" }) : {},
    var.public_subnet_tags,
  )

  private_tags = merge(
    { Tier = "private-app" },
    length(var.eks_cluster_names) > 0 ? merge(local.eks_shared_tags, { "kubernetes.io/role/internal-elb" = "1" }) : {},
    var.private_subnet_tags,
  )

  database_tags = merge(
    { Tier = "private-data" },
    var.database_subnet_tags,
  )
}
