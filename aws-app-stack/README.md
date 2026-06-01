# aws-app-stack

Production-grade AWS Infrastructure as Code — **10 Terraform modules** orchestrated by **Terragrunt**.  
Thiết kế theo nguyên tắc: **chỉ cần `values.base.yml`** là đủ để deploy toàn bộ stack.

---

## Quick Start

```bash
# 1. Clone
git clone <repo-url> && cd aws-app-stack

# 2. Sửa duy nhất 1 file
vim live/prod/values.base.yml

# 3. Deploy — Terragrunt tự giải quyết thứ tự dependency
cd live/prod/
terragrunt run-all plan
terragrunt run-all apply
```

> **Cách hoạt động:**  
> Root `terragrunt.hcl` đọc `values.base.yml` → tự generate `backend.tf` + `provider.tf` cho toàn bộ stack.  
> Mỗi stack đọc section riêng của mình. Dependency outputs (vpc_id, alb_arn…) được wire tự động qua `dependency {}`.  
> Không hardcode bất kỳ resource ID nào.

---

## Architecture

```
                  ┌──────────────────────────────────────────────────────┐
                  │                     Route53 Zone                      │
                  │               devops.example.com                      │
                  └────────────┬─────────────────────┬────────────────────┘
                               │ A alias              │ CNAME (CloudFront)
              ┌────────────────▼──────────┐   ┌──────▼──────────────────────┐
              │      ACM Certificate       │   │   CloudFront Distribution   │
              │  api.devops.example.com    │   │   Static site / SPA / CDN   │
              └────────────┬──────────────┘   └──────┬──────────────────────┘
                           │ HTTPS 443                │ Origin (OAC)
              ┌────────────▼──────────────┐   ┌──────▼──────────────────────┐
Internet ────►│  Application Load Balancer │   │   S3 Bucket (private)       │
              │  internet-facing / internal│   │   Encrypted, versioned      │
              └────────────┬──────────────┘   └─────────────────────────────┘
                           │ path routing → multiple services
         ┌─────────────────┼─────────────────────┐
         │ /api/*          │ /admin/*             │ default
┌────────▼──────┐  ┌───────▼───────┐   ┌─────────▼─────────────────┐
│  ECS Service  │  │  ECS Service  │   │       Lambda Function       │
│  api-service  │  │  admin-service│   │   Serverless workload       │
│  MIXED: 30%   │  │  FARGATE_SPOT │   │   VPC / Function URL        │
│  Fargate+Spot │  └───────┬───────┘   └─────────────────────────────┘
└────────┬──────┘          │
         └────────┬─────────┘
                  │ postgresql-tcp / redis-tcp (SG rules only)
         ┌────────┴──────────────────────────────────────────┐
         │                                                    │
┌────────▼──────────────┐              ┌──────────────────────▼──────┐
│  RDS Multi-AZ          │              │  ElastiCache Redis/Memcached │
│  Postgres/MySQL/Aurora │              │  Cluster mode, encrypted     │
│  Encrypted + SecretsMgr│              └─────────────────────────────┘
└───────────────────────┘

Infrastructure:
  VPC ──► 3-tier subnets (public/private/database) + NAT GW per AZ + Flow Logs
  ECR ──► KMS encrypted, IMMUTABLE tags, lifecycle policy
```

---

## Modules (10)

| Module | Upstream | Chức năng |
|--------|----------|-----------|
| [aws-vpc](modules/aws-vpc/README.md) | `terraform-aws-modules/vpc/aws ~> 5.0` | VPC 3-tier, Multi-AZ NAT, VPC Flow Logs |
| [aws-ecr](modules/aws-ecr/README.md) | `terraform-aws-modules/ecr/aws ~> 2.0` | Container registry, KMS, lifecycle |
| [aws-route53](modules/aws-route53/README.md) | `terraform-aws-modules/route53/aws ~> 3.0` | DNS zone + records (zone/records tách riêng stack) |
| [aws-acm](modules/aws-acm/README.md) | `terraform-aws-modules/acm/aws ~> 4.0` | SSL/TLS cert với DNS auto-validation |
| [aws-alb](modules/aws-alb/README.md) | `terraform-aws-modules/alb/aws ~> 9.0` | ALB internet-facing **hoặc** internal, multi target group, path routing |
| [aws-ecs](modules/aws-ecs/README.md) | `terraform-aws-modules/ecs/aws ~> 5.0` | ECS FARGATE/SPOT/MIXED/EC2, autoscaling, circuit breaker |
| [aws-rds](modules/aws-rds/README.md) | `terraform-aws-modules/rds/aws ~> 6.0` | RDS PostgreSQL / MySQL / MariaDB / Aurora |
| [aws-elasticache](modules/aws-elasticache/) | `terraform-aws-modules/elasticache/aws ~> 1.0` | Redis / Memcached, cluster mode, encryption |
| [aws-s3-cdn](modules/aws-s3-cdn/) | `terraform-aws-modules/s3-bucket + cloudfront ~> 3.0` | S3 private + CloudFront OAC, SPA routing |
| [aws-lambda](modules/aws-lambda/) | `terraform-aws-modules/lambda/aws ~> 7.0` | Lambda, VPC optional, Function URL |

---

## Dependency graph

```
ecr              ← no deps
vpc              ← no deps
route53          ← no deps (zone only)
  └── acm        ← route53.zone_id
        └── alb  ← vpc + acm
              ├── route53-records  ← alb.dns_name + route53.zone_id
              ├── ecs              ← vpc.private_subnets + alb.target_group_arn
              │     ├── rds        ← vpc.db_subnet_group + ecs.security_group_id
              │     └── elasticache← vpc.private_subnets + ecs.security_group_id
              └── (internal-alb)   ← vpc.private_subnets (không cần acm)

s3-cdn   ← no deps (+ acm nếu custom domain, acm phải ở us-east-1)
lambda   ← no deps (optional: vpc.private_subnets nếu cần VPC access)
```

---

## Use case coverage

| Use case | Stacks cần bật |
|----------|---------------|
| **REST API / Backend service** | vpc, ecr, route53, acm, alb, ecs, rds |
| **Microservices + path routing** | alb (multi `target_groups` + `path_patterns`) + nhiều ecs |
| **Internal service** (không public) | alb (`internal: true`, không cần acm) + ecs |
| **Static site / SPA** | s3-cdn + route53-records (trỏ CloudFront) |
| **Serverless** | lambda + route53 (optional) |
| **Caching** | elasticache (Redis/Memcached) |
| **MySQL / Aurora** | rds với `engine: mysql / aurora-postgresql` |
| **Multi-environment** | copy `live/prod/` → `live/staging/`, đổi `values.base.yml` |
| **Multi-region** | `global.region` trong `values.base.yml` mỗi env |
| **Multi-account** | `global.deploy_role_arn` trong `values.base.yml` |

---

## Cấu trúc thư mục

```
aws-app-stack/
├── terragrunt.hcl                  ← root: remote_state, provider, region, assume_role
│
├── modules/                        ← 10 reusable modules
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
        ├── values.base.yml         ← SINGLE SOURCE OF TRUTH cho toàn env
        ├── vpc/                    ├── terragrunt.hcl  (đọc values.base.yml)
        ├── ecr/                    ├── values.yaml     (optional override)
        ├── route53/                └── values.override.yml (optional patch)
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

## Config pattern — 3 lớp

```
values.base.yml          ← base toàn env (mọi module)
  + values.yaml          ← config riêng từng stack (backward compat)
    + values.override.yml ← patch tạm thời (hotfix, debug)
```

**Merge logic trong `terragrunt.hcl`:**
```hcl
locals {
  base     = yamldecode(file("../values.base.yml"))[basename(get_terragrunt_dir())]
  override = fileexists("values.override.yml") ? yamldecode(file("values.override.yml")) : {}
  cfg      = merge(local.base, local.override, {
    tags = merge(try(local.base.tags, {}), try(local.override.tags, {}))
  })
}
```

Ví dụ `values.override.yml` khi hotfix:
```yaml
container_image: "123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/api:v1.1-hotfix"
desired_count:   5
tags:
  Hotfix: "INC-2024-001"   # deep-merged với tags base — không mất tag cũ
```

---

## Pipeline (GitHub Actions)

```yaml
deploy:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with: { terraform_version: "1.9.0" }

    - name: Setup Terragrunt
      run: |
        curl -sL https://github.com/gruntwork-io/terragrunt/releases/download/v0.67.0/terragrunt_linux_amd64 \
          -o /usr/local/bin/terragrunt && chmod +x /usr/local/bin/terragrunt

    - name: Plan
      run: terragrunt run-all plan --terragrunt-working-dir live/prod
      env:
        AWS_ACCESS_KEY_ID:     ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

    - name: Apply
      run: terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir live/prod
      env:
        AWS_ACCESS_KEY_ID:     ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

**Multi-account:** thêm `deploy_role_arn` vào `values.base.yml`:
```yaml
global:
  region:          "ap-southeast-1"
  account_id:      "123456789012"
  deploy_role_arn: "arn:aws:iam::123456789012:role/TerraformDeployRole"
```

---

## New environment trong 5 phút

```bash
cp -r live/prod live/staging
```

Chỉnh `live/staging/values.base.yml` — các key thường đổi:

```yaml
global:
  region:     "ap-southeast-1"
  account_id: "111111111111"   # staging account

vpc:
  vpc_cidr:           "10.1.0.0/16"
  single_nat_gateway: true      # staging: tiết kiệm — 1 NAT GW

ecs:
  container_image: "...api-service:latest"
  capacity_type:   "FARGATE_SPOT"   # staging: 100% Spot
  desired_count:   1
  cpu:             256
  memory:          512

rds:
  instance_class:     "db.t4g.micro"
  multi_az:           false
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

## Changelog

### v2.0 — Full use case coverage

| Thay đổi | Chi tiết |
|----------|----------|
| **Root terragrunt** | Region + account_id đọc từ `values.base.yml.global` — không hardcode |
| **Multi-account** | `deploy_role_arn` → provider tự `assume_role` |
| **aws-alb** | `internal: true/false` toggle; multi `target_groups`; path-based routing |
| **aws-rds** | Multi-engine: PostgreSQL / MySQL / MariaDB / Aurora; auto-derive `family` |
| **aws-elasticache** | Module mới — Redis / Memcached, cluster mode, encryption |
| **aws-s3-cdn** | Module mới — S3 private + CloudFront OAC + SPA error handling |
| **aws-lambda** | Module mới — Lambda, VPC optional, Function URL, IAM policies |
| **values.base.yml** | Single source of truth + `global:` section; hỗ trợ 3-layer merge |
| **Route53 split** | Tách thành `route53` (zone) + `route53-records` (A alias) — phá circular dependency |
| **ECS** | Fix `cluster_setting` (list, không phải map); `launch_type = null` khi dùng capacity providers |
| **ALB outputs** | `target_group_arns` map + backward-compat `target_group_arn` |
| **optional() pattern** | Tất cả nested objects dùng `optional()` — values.yaml chỉ cần override những gì khác default |

### v1.0 — Initial

- 7 modules: vpc, ecr, route53, acm, alb, ecs, rds
- Terragrunt + yamldecode pattern
- Per-stack `values.yaml`

---

## Key design decisions

| Decision | Lý do |
|----------|-------|
| `IMMUTABLE` image tags | Ngăn silent overwrite trên prod |
| `manage_master_user_password = true` | Password tự rotate trong Secrets Manager, không lưu state |
| `launch_type = null` + `cluster_capacity_providers` | Tránh conflict — capacity provider strategy tự schedule |
| `create_task_exec_iam_role` ở service level | Least-privilege: mỗi service role riêng |
| `deployment_circuit_breaker { rollback = true }` | Auto-rollback khi deploy lỗi |
| `drop_invalid_header_fields = true` | Ngăn HTTP request smuggling |
| `skip_final_snapshot = false` | Luôn giữ snapshot cuối khi xoá prod DB |
| Route53 zone/records tách stack | Phá circular dep: route53 → alb → acm → route53 |
| S3 + CloudFront OAC | Bucket không public, CloudFront là điểm duy nhất truy cập |
| `values.override.yml` optional | Hotfix/debug không cần sửa base config |
