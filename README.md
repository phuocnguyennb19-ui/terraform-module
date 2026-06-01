# aws-app-stack

> Production-grade AWS infrastructure — **10 opinionated Terraform modules** orchestrated by **Terragrunt**.  
> One file to configure, one command to deploy.

---

## Overview

This repository provides a complete, reusable AWS infrastructure stack built on top of [terraform-aws-modules](https://github.com/terraform-aws-modules). It is designed around a single principle: **all configuration lives in `values.base.yml`** — no Terraform files need to be edited between environments.

**Key characteristics:**
- Every module wraps an upstream HashiCorp community module with opinionated defaults
- Terragrunt orchestrates deployment order via `dependency {}` blocks — no manual sequencing
- Config is separated from logic: `*.tf` files never change, only YAML files do
- Supports multi-environment, multi-region, and multi-account deployments out of the box

---

## Quick Start

```bash
# Clone and configure
git clone <repo-url>
cd aws-app-stack

# Edit the single config file for your environment
vim live/prod/values.base.yml

# Plan and apply — Terragrunt resolves dependency order automatically
cd live/prod/
terragrunt run-all plan
terragrunt run-all apply
```

**How it works under the hood:**
1. Root `terragrunt.hcl` reads `values.base.yml` → generates `backend.tf` and `provider.tf` for every stack
2. Each stack reads its own section: `yamldecode(file("../values.base.yml"))["vpc"]`
3. Cross-stack outputs (e.g. `vpc_id`, `alb_arn`) are resolved automatically via `dependency {}` blocks
4. No resource IDs are hardcoded anywhere

---

## Architecture

```
                  ┌──────────────────────────────────────────────────────┐
                  │                    Route53 Hosted Zone                │
                  │                  devops.example.com                   │
                  └────────────┬─────────────────────┬────────────────────┘
                               │ A alias              │ CNAME
              ┌────────────────▼────────────┐  ┌──────▼──────────────────────┐
              │        ACM Certificate       │  │    CloudFront Distribution  │
              │    api.devops.example.com    │  │    Static assets / SPA      │
              └────────────┬────────────────┘  └──────┬──────────────────────┘
                           │ HTTPS :443                │ Origin Access Control
              ┌────────────▼────────────┐      ┌──────▼──────────────────────┐
Internet ────►│  Application Load Balancer│      │    S3 Bucket (private)      │
              │  internet-facing │ internal│      │    Server-side encrypted    │
              └────────────┬────────────┘      └─────────────────────────────┘
                           │ Path-based routing
         ┌─────────────────┼──────────────────────┐
         │ /api/*          │ /admin/*              │ default
┌────────▼──────┐  ┌───────▼────────┐   ┌─────────▼──────────────┐
│  ECS Service  │  │  ECS Service   │   │    Lambda Function      │
│  api-service  │  │  admin-service │   │    Serverless workload  │
│  Fargate MIXED│  │  Fargate SPOT  │   │    VPC-attached / URL   │
└────────┬──────┘  └───────┬────────┘   └────────────────────────┘
         └────────┬─────────┘
                  │ Ingress via Security Group rules only
      ┌───────────┴────────────────────────────────┐
      │                                            │
┌─────▼──────────────────┐         ┌──────────────▼─────────────┐
│  RDS (Multi-AZ)         │         │  ElastiCache               │
│  PostgreSQL/MySQL/Aurora│         │  Redis / Memcached         │
│  Encrypted + Secrets Mgr│         │  Cluster mode, TLS         │
└────────────────────────┘         └────────────────────────────┘

Shared infrastructure:
  VPC  — 3-tier subnets (public / private / database), one NAT GW per AZ, VPC Flow Logs
  ECR  — KMS-encrypted repository, immutable tags, automated lifecycle policy
```

---

## Modules

| Module | Upstream Source | Provisions |
|--------|-----------------|------------|
| [aws-vpc](modules/aws-vpc/README.md) | `terraform-aws-modules/vpc/aws ~> 5.0` | VPC, 3-tier subnets, multi-AZ NAT Gateways, VPC Flow Logs |
| [aws-ecr](modules/aws-ecr/README.md) | `terraform-aws-modules/ecr/aws ~> 2.0` | Private ECR repository, KMS encryption, lifecycle policies |
| [aws-route53](modules/aws-route53/README.md) | `terraform-aws-modules/route53/aws ~> 3.0` | Hosted zone (separate stack from DNS records to avoid circular deps) |
| [aws-acm](modules/aws-acm/README.md) | `terraform-aws-modules/acm/aws ~> 4.0` | ACM certificate with automatic Route53 DNS validation |
| [aws-alb](modules/aws-alb/README.md) | `terraform-aws-modules/alb/aws ~> 9.0` | ALB — internet-facing or internal, multiple target groups, path-based routing |
| [aws-ecs](modules/aws-ecs/README.md) | `terraform-aws-modules/ecs/aws ~> 5.0` | ECS Fargate cluster — FARGATE / SPOT / MIXED / EC2, autoscaling, deployment circuit breaker |
| [aws-rds](modules/aws-rds/README.md) | `terraform-aws-modules/rds/aws ~> 6.0` | RDS instance — PostgreSQL, MySQL, MariaDB, Aurora (engine auto-configured) |
| [aws-elasticache](modules/aws-elasticache/) | `terraform-aws-modules/elasticache/aws ~> 1.0` | ElastiCache cluster — Redis or Memcached, cluster mode, encryption at rest and in transit |
| [aws-s3-cdn](modules/aws-s3-cdn/) | `terraform-aws-modules/s3-bucket + cloudfront ~> 3.0` | Private S3 bucket + CloudFront with OAC, SPA error routing |
| [aws-lambda](modules/aws-lambda/) | `terraform-aws-modules/lambda/aws ~> 7.0` | Lambda function — local or S3 package, optional VPC attachment, Function URL |

---

## Dependency Graph

Terragrunt resolves this order automatically. No manual sequencing required.

```
ecr              (independent)
vpc              (independent)
route53          (independent — zone only)
  └── acm             needs: route53.zone_id
        └── alb        needs: vpc.vpc_id, vpc.public_subnets, acm.certificate_arn
              ├── route53-records  needs: alb.dns_name, route53.zone_id
              ├── ecs              needs: vpc.private_subnets, alb.target_group_arn, alb.security_group_id
              │     ├── rds         needs: vpc.database_subnet_group, ecs.security_group_id
              │     └── elasticache needs: vpc.private_subnets, ecs.security_group_id
              └── (internal-alb)   needs: vpc.private_subnets (no ACM required)

s3-cdn   (independent — add ACM dependency only for custom domain, cert must be in us-east-1)
lambda   (independent — add vpc dependency only if VPC access is needed)
```

> **Why Route53 is split into two stacks:**  
> A single Route53 stack would create a circular dependency: `route53 → alb → acm → route53`.  
> Splitting into `route53` (zone creation) and `route53-records` (A alias to ALB) breaks the cycle.

---

## Repository Structure

```
aws-app-stack/
├── terragrunt.hcl                  # Root: S3 remote state, provider, region, assume_role
│
├── modules/                        # 10 reusable wrapper modules
│   ├── aws-vpc/
│   ├── aws-ecr/
│   ├── aws-route53/
│   ├── aws-acm/
│   ├── aws-alb/
│   ├── aws-ecs/
│   ├── aws-rds/
│   ├── aws-elasticache/
│   ├── aws-s3-cdn/
│   └── aws-lambda/
│
└── live/
    └── prod/
        ├── values.base.yml         # Single source of truth for the entire environment
        ├── vpc/
        │   ├── terragrunt.hcl      # Reads values.base.yml["vpc"]
        │   ├── values.yaml         # Optional: per-stack overrides (backward compat)
        │   └── values.override.yml # Optional: temporary patch (hotfix, debug)
        ├── ecr/
        ├── route53/
        ├── acm/
        ├── alb/
        ├── ecs/
        ├── rds/
        ├── elasticache/
        ├── s3-cdn/
        ├── lambda/
        └── route53-records/
```

---

## Configuration

### Three-layer config merge

```
values.base.yml        # Layer 1 — environment baseline, all stacks
  + values.yaml        # Layer 2 — per-stack config (read by default)
    + values.override.yml  # Layer 3 — temporary patch, applied if file exists
```

Merge is performed in each `terragrunt.hcl`:

```hcl
locals {
  base     = yamldecode(file("../values.base.yml"))[basename(get_terragrunt_dir())]
  override = fileexists("values.override.yml") ? yamldecode(file("values.override.yml")) : {}
  cfg      = merge(local.base, local.override, {
    # Tags are deep-merged so neither base nor override tags are lost
    tags = merge(try(local.base.tags, {}), try(local.override.tags, {}))
  })
}
```

### `values.base.yml` structure

```yaml
global:
  region:     "ap-southeast-1"
  account_id: "123456789012"
  # deploy_role_arn: "arn:aws:iam::123456789012:role/TerraformDeployRole"  # multi-account

vpc:
  name:        "myapp"
  environment: "prod"
  vpc_cidr:    "10.0.0.0/16"
  ...

ecs:
  app_name:        "api-service"
  container_image: "123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/api-service:v1.0"
  capacity_type:   "MIXED"   # FARGATE | FARGATE_SPOT | MIXED | EC2
  ...

rds:
  engine:   "postgres"   # postgres | mysql | aurora-postgresql | aurora-mysql | mariadb
  multi_az: true
  ...
```

### Hotfix / temporary override

Create `values.override.yml` in the target stack folder — no base config changes needed:

```yaml
# live/prod/ecs/values.override.yml
container_image: "123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/api-service:v1.1-hotfix"
desired_count:   5
tags:
  Hotfix: "INC-2024-001"   # merged on top of base tags
```

---

## Use Cases

| Scenario | Stacks to enable |
|----------|-----------------|
| REST API / backend service | `vpc` → `ecr` → `route53` → `acm` → `alb` → `ecs` → `rds` |
| Microservices with path routing | `alb` (configure `target_groups` with `path_patterns`) + multiple `ecs` stacks |
| Internal service (no public exposure) | `alb` (`internal: true`, no ACM needed) → `ecs` |
| Static site / SPA | `s3-cdn` + `route53-records` pointing to CloudFront |
| Serverless workload | `lambda` (+ `route53` for custom domain) |
| Caching layer | `elasticache` alongside `ecs` |
| MySQL or Aurora | `rds` with `engine: mysql` or `engine: aurora-postgresql` |
| New environment | `cp -r live/prod live/staging` + edit `values.base.yml` |
| Multi-region | Set `global.region` per environment |
| Multi-account | Set `global.deploy_role_arn` — provider auto assumes the role |

---

## CI/CD Pipeline

```yaml
# .github/workflows/deploy.yml
name: Deploy Infrastructure

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.9.0"

      - name: Setup Terragrunt
        run: |
          curl -sL https://github.com/gruntwork-io/terragrunt/releases/download/v0.67.0/terragrunt_linux_amd64 \
            -o /usr/local/bin/terragrunt && chmod +x /usr/local/bin/terragrunt

      - name: Terragrunt Plan
        run: terragrunt run-all plan --terragrunt-working-dir live/prod
        env:
          AWS_ACCESS_KEY_ID:     ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

      - name: Terragrunt Apply
        run: terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir live/prod
        env:
          AWS_ACCESS_KEY_ID:     ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

**Multi-account deploy** — add to `values.base.yml`:

```yaml
global:
  region:          "ap-southeast-1"
  account_id:      "123456789012"
  deploy_role_arn: "arn:aws:iam::123456789012:role/TerraformDeployRole"
```

The root `terragrunt.hcl` automatically injects `assume_role` into the provider when `deploy_role_arn` is set.

---

## Spinning Up a New Environment

```bash
cp -r live/prod live/staging
```

Minimal changes to `live/staging/values.base.yml`:

```yaml
global:
  account_id: "111111111111"   # staging AWS account

vpc:
  vpc_cidr:           "10.1.0.0/16"
  single_nat_gateway: true     # single NAT GW to reduce cost

ecs:
  capacity_type: "FARGATE_SPOT"   # 100% Spot — acceptable for non-prod
  desired_count: 1
  cpu:           256
  memory:        512

rds:
  instance_class:      "db.t4g.micro"
  multi_az:            false
  skip_final_snapshot: true

elasticache:
  node_type:                  "cache.t4g.micro"
  automatic_failover_enabled: false
  multi_az_enabled:           false
```

```bash
cd live/staging
terragrunt run-all plan
terragrunt run-all apply
```

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| `IMMUTABLE` ECR image tags | Prevents silent overwrites of production images |
| `manage_master_user_password = true` on RDS | Password is auto-rotated in Secrets Manager — never stored in Terraform state |
| `launch_type = null` with `cluster_capacity_providers` | Setting `launch_type` conflicts with capacity provider strategy; `null` lets the cluster default take effect |
| `create_task_exec_iam_role` at service level, not cluster | Each service gets its own least-privilege execution role |
| `deployment_circuit_breaker { rollback = true }` | Automatically rolls back to the last stable task definition on deploy failure |
| `drop_invalid_header_fields = true` on ALB | Mitigates HTTP request smuggling attacks |
| `skip_final_snapshot = false` on RDS | Ensures a final snapshot is taken before any production database is deleted |
| Route53 split into `route53` + `route53-records` | Eliminates circular dependency: `route53 → alb → acm → route53` |
| S3 bucket private + CloudFront OAC | S3 is never publicly accessible; CloudFront is the sole entry point |
| `values.override.yml` as optional layer | Enables hotfixes and debug changes without modifying the environment baseline |
| `optional()` on all nested object variables | Callers only specify what differs from defaults — reduces required config to the minimum |

---

## Changelog

### v2.0

| Change | Detail |
|--------|--------|
| Dynamic region + account | Read from `values.base.yml.global` — no hardcoded values in HCL |
| Multi-account support | Provider auto-assumes role when `deploy_role_arn` is set |
| `aws-alb` | Added `internal` toggle; multiple target groups; path-based listener rules |
| `aws-rds` | Multi-engine support — PostgreSQL, MySQL, MariaDB, Aurora; `family` auto-derived |
| `aws-elasticache` | New module — Redis / Memcached, cluster mode, at-rest and in-transit encryption |
| `aws-s3-cdn` | New module — private S3 + CloudFront OAC + SPA 4xx error handling |
| `aws-lambda` | New module — Lambda with local/S3 source, optional VPC, Function URL |
| `values.base.yml` | Introduced as single-file config source; supports 3-layer merge pattern |
| Route53 decoupled | Split into zone stack and records stack to eliminate circular dependency |
| ECS `cluster_setting` fix | Corrected from `map(string)` to `list(object)` per upstream module API |
| `optional()` variables | All nested config objects use `optional()` — only override what you need |

### v1.0

- 7 modules: vpc, ecr, route53, acm, alb, ecs, rds
- Terragrunt + `yamldecode(values.yaml)` pattern
- Per-stack `values.yaml` files
