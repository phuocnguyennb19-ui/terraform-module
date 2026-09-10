# Examples

How to call every module in this library. Each snippet lists **only the required
inputs** — everything else has a default in the module's `variables.tf`, so start
here and add options as you need them.

A runnable, wired-together stack lives in [`complete/`](complete/) — read that one
to see how the modules feed each other. The snippets below are per-module reference.

Generated from `modules/*/variables.tf`. If a snippet disagrees with the module,
the module wins.

Always pin a tag, never a branch: `?ref=v1.0.0`.

| Module | Inputs | Required | |
|---|---|---|---|
| [`acm`](#acm) | 8 | 2 |  |
| [`alb`](#alb) | 26 | 4 |  |
| [`cloudwatch`](#cloudwatch) | 10 | 1 |  |
| [`dynamodb`](#dynamodb) | 4 | 1 | legacy YAML interface |
| [`ec2`](#ec2) | 7 | 2 |  |
| [`ecr`](#ecr) | 5 | 1 |  |
| [`ecs-cluster`](#ecs-cluster) | 14 | 1 |  |
| [`ecs-service`](#ecs-service) | 41 | 5 |  |
| [`eks`](#eks) | 23 | 4 |  |
| [`elasticache`](#elasticache) | 27 | 3 |  |
| [`iam`](#iam) | 12 | 1 |  |
| [`kms`](#kms) | 3 | 1 |  |
| [`lambda`](#lambda) | 6 | 1 |  |
| [`rds`](#rds) | 36 | 6 |  |
| [`route53`](#route53) | 7 | 1 |  |
| [`s3`](#s3) | 4 | 1 | legacy YAML interface |
| [`secrets_manager`](#secrets_manager) | 4 | 1 | legacy YAML interface |
| [`security-groups`](#security-groups) | 20 | 3 |  |
| [`sns`](#sns) | 4 | 1 | legacy YAML interface |
| [`sqs`](#sqs) | 4 | 1 | legacy YAML interface |
| [`vpc`](#vpc) | 25 | 2 |  |
| [`waf`](#waf) | 4 | 1 | legacy YAML interface |

---

## acm

```hcl
module "acm" {
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-module.git//modules/acm?ref=v1.0.0"

  domain_name = "api.example.com"
  zone_id     = module.route53.zone_id

  tags        = local.tags
}
```

| Required input | Type | Purpose |
|---|---|---|
| `domain_name` | `string` | Primary domain for the certificate, e.g. "app.example.com" or "*.example.com". |
| `zone_id` | `string` | Route53 hosted zone ID where the DNS validation records are written. Comes from the route53 mod… |

## alb

```hcl
module "alb" {
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-module.git//modules/alb?ref=v1.0.0"

  name               = "${local.name_prefix}-alb"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.security_groups.ecs_sg_id]

  tags               = local.tags
}
```

| Required input | Type | Purpose |
|---|---|---|
| `name` | `string` | Load balancer name. Must be 32 characters or fewer — AWS rejects longer names, and the error ar… |
| `vpc_id` | `string` | VPC the load balancer and its target groups live in. From the foundation: module.vpc.vpc_id. |
| `subnet_ids` | `list(string)` | Subnets to place the load balancer in — at least two, in different AZs. Public subnets for an i… |
| `security_group_ids` | `list(string)` | Security groups for the load balancer. From module.security_groups.alb_sg_id. |

## cloudwatch

```hcl
module "cloudwatch" {
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-module.git//modules/cloudwatch?ref=v1.0.0"

  name = "${local.name_prefix}-cloudwatch"

  tags = local.tags
}
```

| Required input | Type | Purpose |
|---|---|---|
| `name` | `string` | Name prefix, conventionally "<project>-<environment>". |

## dynamodb

> **Legacy interface.** Still reads a YAML file through `global_config` instead
> of typed inputs; not yet ported to the contract the other modules use. Do not
> copy its shape when writing a new module.

```hcl
module "dynamodb" {
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-module.git//modules/dynamodb?ref=v1.0.0"

  global_config = {}

  tags          = local.tags
}
```

| Required input | Type | Purpose |
|---|---|---|
| `global_config` | `object` | Environment context shared by every module: environment, region and project, plus optional mana… |

## ec2

```hcl
module "ec2" {
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-module.git//modules/ec2?ref=v1.0.0"

  name               = "${local.name_prefix}-ec2"
  security_group_ids = [module.security_groups.ecs_sg_id]

  tags               = local.tags
}
```

| Required input | Type | Purpose |
|---|---|---|
| `name` | `string` | Name prefix. Each instance is named "<name>-<key>". |
| `security_group_ids` | `list(string)` | Security groups applied to every instance. From module.security_groups.ec2_sg_id. |

## ecr

```hcl
module "ecr" {
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-module.git//modules/ecr?ref=v1.0.0"

  name = "${local.name_prefix}-ecr"

  tags = local.tags
}
```

| Required input | Type | Purpose |
|---|---|---|
| `name` | `string` | Name prefix. Repository names become "<name>/<key>" unless use_name_prefix is false. |

## ecs-cluster

```hcl
module "ecs_cluster" {
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-module.git//modules/ecs-cluster?ref=v1.0.0"

  cluster_name = "${local.name_prefix}-ecscluster"

  tags         = local.tags
}
```

| Required input | Type | Purpose |
|---|---|---|
| `cluster_name` | `string` | ECS cluster name, conventionally "<project>-<environment>-ecs". |

## ecs-service

```hcl
module "ecs_service" {
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-module.git//modules/ecs-service?ref=v1.0.0"

  name               = "${local.name_prefix}-ecsservice"
  cluster_arn        = module.ecs_cluster.arn
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.security_groups.ecs_sg_id]
  containers         = {
    api = {
      image     = "111122223333.dkr.ecr.ap-southeast-1.amazonaws.com/api:v1.4.2"
      essential = true
      port_mappings = [{ containerPort = 8080, protocol = "tcp" }]
    }
  }

  tags               = local.tags
}
```

| Required input | Type | Purpose |
|---|---|---|
| `name` | `string` | Service name, conventionally "<project>-<environment>-<app>". Also the task definition family. |
| `cluster_arn` | `string` | ECS cluster the service runs in. From the foundation: module.ecs_cluster.arn. |
| `subnet_ids` | `list(string)` | Subnets the task ENIs are created in. Private subnets only — see assign_public_ip in main.tf fo… |
| `security_group_ids` | `list(string)` | Security groups attached to the task ENIs. From module.security_groups.ecs_sg_id. This module n… |
| `containers` | `map(object` |  |

## eks

```hcl
module "eks" {
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-module.git//modules/eks?ref=v1.0.0"

  cluster_name       = "${local.name_prefix}-eks"
  kubernetes_version = "1.31"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids

  tags               = local.tags
}
```

| Required input | Type | Purpose |
|---|---|---|
| `cluster_name` | `string` | EKS cluster name. |
| `kubernetes_version` | `string` | Kubernetes minor version, e.g. "1.31". EKS supports a narrow window of versions; a cluster left… |
| `vpc_id` | `string` | VPC the cluster runs in. From the foundation: module.vpc.vpc_id. This module never creates a VP… |
| `subnet_ids` | `list(string)` | Subnets for the node groups and the cluster ENIs. Private subnets: module.vpc.private_subnet_id… |

## elasticache

```hcl
module "elasticache" {
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-module.git//modules/elasticache?ref=v1.0.0"

  name               = "${local.name_prefix}-elasticache"
  subnet_group_name  = module.vpc.elasticache_subnet_group_name
  security_group_ids = [module.security_groups.ecs_sg_id]

  tags               = local.tags
}
```

| Required input | Type | Purpose |
|---|---|---|
| `name` | `string` | Replication group identifier, e.g. "dev-redis". |
| `subnet_group_name` | `string` | ElastiCache subnet group. From module.vpc.elasticache_subnet_group_name, which spans the databa… |
| `security_group_ids` | `list(string)` | Security groups for the cache nodes. From module.security_groups.elasticache_sg_id. |

## iam

```hcl
module "iam" {
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-module.git//modules/iam?ref=v1.0.0"

  name = "${local.name_prefix}-iam"

  tags = local.tags
}
```

| Required input | Type | Purpose |
|---|---|---|
| `name` | `string` | Name prefix for every role and policy, conventionally "<project>-<environment>". |

## kms

```hcl
module "kms" {
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-module.git//modules/kms?ref=v1.0.0"

  name = "${local.name_prefix}-kms"

  tags = local.tags
}
```

| Required input | Type | Purpose |
|---|---|---|
| `name` | `string` | Name prefix, conventionally "<project>-<environment>". Aliases become alias/<name>-<key>. |

## lambda

```hcl
module "lambda" {
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-module.git//modules/lambda?ref=v1.0.0"

  name = "${local.name_prefix}-lambda"

  tags = local.tags
}
```

| Required input | Type | Purpose |
|---|---|---|
| `name` | `string` | Name prefix. Each function is named "<name>-<key>". |

## rds

```hcl
module "rds" {
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-module.git//modules/rds?ref=v1.0.0"

  identifier           = "${local.name_prefix}-rds"
  engine_version       = "16.4"
  family               = "postgres16"
  major_engine_version = "16"
  db_subnet_group_name = module.vpc.database_subnet_group_name
  security_group_ids   = [module.security_groups.ecs_sg_id]

  tags                 = local.tags
}
```

| Required input | Type | Purpose |
|---|---|---|
| `identifier` | `string` | DB instance identifier, e.g. "dev-postgres". |
| `engine_version` | `string` | Engine version, e.g. "16.4" for PostgreSQL or "8.0.39" for MySQL. |
| `family` | `string` | Parameter group family, e.g. "postgres16" or "mysql8.0". Must match engine_version's major — a … |
| `major_engine_version` | `string` | Major engine version for the option group, e.g. "16" or "8.0". |
| `db_subnet_group_name` | `string` | DB subnet group. From module.vpc.database_subnet_group_name. Those subnets have no internet gat… |
| `security_group_ids` | `list(string)` | Security groups for the instance. From module.security_groups.rds_sg_id, which allows the datab… |

## route53

```hcl
module "route53" {
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-module.git//modules/route53?ref=v1.0.0"

  zone_name = "example.com"

  tags      = local.tags
}
```

| Required input | Type | Purpose |
|---|---|---|
| `zone_name` | `string` | Hosted zone name, e.g. "example.com". Used to create the zone when create_zone is true, and to … |

## s3

> **Legacy interface.** Still reads a YAML file through `global_config` instead
> of typed inputs; not yet ported to the contract the other modules use. Do not
> copy its shape when writing a new module.

```hcl
module "s3" {
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-module.git//modules/s3?ref=v1.0.0"

  global_config = {}

  tags          = local.tags
}
```

| Required input | Type | Purpose |
|---|---|---|
| `global_config` | `object` | Environment context shared by every module: environment, region and project, plus optional mana… |

## secrets_manager

> **Legacy interface.** Still reads a YAML file through `global_config` instead
> of typed inputs; not yet ported to the contract the other modules use. Do not
> copy its shape when writing a new module.

```hcl
module "secrets_manager" {
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-module.git//modules/secrets_manager?ref=v1.0.0"

  global_config = {}

  tags          = local.tags
}
```

| Required input | Type | Purpose |
|---|---|---|
| `global_config` | `object` | Environment context shared by every module: environment, region and project, plus optional mana… |

## security-groups

```hcl
module "security_groups" {
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-module.git//modules/security-groups?ref=v1.0.0"

  name           = "${local.name_prefix}-securitygroups"
  vpc_id         = module.vpc.vpc_id
  vpc_cidr_block = module.vpc.vpc_cidr_block

  tags           = local.tags
}
```

| Required input | Type | Purpose |
|---|---|---|
| `name` | `string` | Name prefix for every security group, conventionally "<project>-<environment>". |
| `vpc_id` | `string` | VPC the security groups belong to. Comes from the foundation: module.vpc.vpc_id. |
| `vpc_cidr_block` | `string` | VPC CIDR. Used only where a security group reference is impossible — ALB egress to targets, who… |

## sns

> **Legacy interface.** Still reads a YAML file through `global_config` instead
> of typed inputs; not yet ported to the contract the other modules use. Do not
> copy its shape when writing a new module.

```hcl
module "sns" {
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-module.git//modules/sns?ref=v1.0.0"

  global_config = {}

  tags          = local.tags
}
```

| Required input | Type | Purpose |
|---|---|---|
| `global_config` | `object` | Environment context shared by every module: environment, region and project, plus optional mana… |

## sqs

> **Legacy interface.** Still reads a YAML file through `global_config` instead
> of typed inputs; not yet ported to the contract the other modules use. Do not
> copy its shape when writing a new module.

```hcl
module "sqs" {
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-module.git//modules/sqs?ref=v1.0.0"

  global_config = {}

  tags          = local.tags
}
```

| Required input | Type | Purpose |
|---|---|---|
| `global_config` | `object` | Environment context shared by every module: environment, region and project, plus optional mana… |

## vpc

```hcl
module "vpc" {
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-module.git//modules/vpc?ref=v1.0.0"

  name       = local.name_prefix
  cidr_block = "10.0.0.0/16"

  tags       = local.tags
}
```

| Required input | Type | Purpose |
|---|---|---|
| `name` | `string` | Name prefix for the VPC and every subnet, route table and gateway inside it. Conventionally "<p… |
| `cidr_block` | `string` | IPv4 CIDR for the VPC. A /16 gives the default subnet layout room to grow; anything smaller tha… |

## waf

> **Legacy interface.** Still reads a YAML file through `global_config` instead
> of typed inputs; not yet ported to the contract the other modules use. Do not
> copy its shape when writing a new module.

```hcl
module "waf" {
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-module.git//modules/waf?ref=v1.0.0"

  global_config = {}

  tags          = local.tags
}
```

| Required input | Type | Purpose |
|---|---|---|
| `global_config` | `object` | Environment context shared by every module: environment, region and project, plus optional mana… |

