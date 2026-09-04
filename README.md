# terraform-module

Reusable AWS Terraform modules, plus a root composition that deploys them one environment
at a time.

This file is the only documentation in the repository.

---

## 1. What this repository is

The **source layer** of a three-layer chain:

```
terraform-module  →  aws-base-infras  →  aws-application-infras
   (modules)          (infrastructure)      (application)
```

20 modules under `modules/`, each a thin wrapper around a pinned `terraform-aws-modules`
release. **Modules do not author resources** — their job is to map YAML onto the upstream
module's arguments. Only four declare a resource of their own: `iam` (`aws_iam_policy`,
`aws_iam_instance_profile`), `waf` (`aws_wafv2_web_acl_association`), `ecs_service`
(`aws_lb_target_group`, `aws_lb_listener_rule`) and `cloudwatch` (`aws_cloudwatch_dashboard`).

### Two compute planes

`ecs_cluster` / `ecs_service` (Fargate) and `eks` both exist. **`eks` was added deliberately, not
as a migration step** — running both means two control planes, two networking models and two sets
of IAM to reason about. They share only the VPC and its private subnets. If EKS is meant to
replace ECS, that is a separate decision with its own migration path; nothing here assumes it.

### The root composition, and what it costs

`main.tf` at the repository root calls all 19 modules as one stack per environment. That makes
the library runnable on its own, but it also creates a **third** place these modules can be
deployed from — the two consumer repositories already have their own roots.

The rule that keeps them from fighting:

> The roots here own the state key `<env>/platform/terraform.tfstate`
> (see `environments/*/backend.hcl`). The consumer repos own their own keys.
> **Never point a root here at a state key a consumer owns.**
> If a resource is managed by `aws-base-infras`, it is not managed here.

### There are two checkouts of this repository on this machine

`~/Dylan/Claude/terraform-module` is the **same repo at the same commit**. The consumer repos
resolve `source = "../../terraform-module/modules/<name>"` from `~/Dylan/Claude/aws-*/engine/*/`,
so **the checkout wired to the consumers is the one under `Claude/`**, not this one. A change
made here does not reach `aws-base-infras` until it is pushed and pulled into that copy. Always
say which checkout you edited.

---

## 2. Commands

> **Every command runs from the repository root**, and **every command names its environment.**
> Neither is a style preference — see §2.1 and §4.2.

```bash
# ---- checks: no credentials, no state ----
terraform fmt -check -recursive -diff
terraform init -backend=false -input=false
terraform validate

# ---- per environment: swap dev for staging | prod ----
terraform init -reconfigure -input=false \
  -backend-config=environments/dev/backend.hcl

# one monolithic file...
terraform plan -input=false \
  -var="config_file=environments/dev/config.yml" \
  -out=tfplan-dev

# ...or a directory of per-module files, layered over a common base (§4.5)
terraform plan -input=false \
  -var="config_dir=examples/split-config" \
  -out=tfplan-dev

terraform show -json tfplan-dev          # inspect before applying
terraform apply -input=false tfplan-dev  # apply the plan that was reviewed

# ---- drift detection: exit code 2 means drift ----
terraform plan -input=false -detailed-exitcode \
  -var="config_file=environments/prod/config.yml"
```

### 2.1 Four rules, and why each exists

**1. Run from the repository root.** Modules read their YAML with
`try(yamldecode(file("${path.cwd}/${var.config_file}")), {})`. From the wrong directory the path
is wrong, `try` swallows the error, the config resolves to empty — and Terraform **builds
infrastructure entirely from defaults without printing a single error**. This is the most
dangerous failure mode in this repository.

**2. Always pass `-var="config_file=..."`.** The variable defaults to
`environments/dev/config.yml`. Forgetting the flag while intending to touch prod means you just
planned **dev**.

**3. `apply` must be given a saved plan file.** `terraform apply` with no file **recomputes a
fresh plan** at apply time, so the change that was approved and the change that executes become
two different computations.

**4. Read the plan before applying to prod.** Nothing in this repository enforces that for you.
Check the first lines of the output: `environment` must be right, and there must be no
unexpected `destroy`.

To validate every module in isolation:

```bash
for d in modules/*/; do
  ( cd "$d" && terraform init -backend=false -input=false >/dev/null 2>&1 \
    && terraform validate >/dev/null 2>&1 \
    && echo "PASS $d" || echo "FAIL $d" )
  rm -rf "$d/.terraform" "$d/.terraform.lock.hcl"
done
```

---

## 3. Layout

```
terraform-module/
├── main.tf              calls all 19 modules, each behind a count gate
├── locals.tf            decodes the YAML once; builds global_config, gates and wiring
├── variables.tf         config_file and tags, nothing else
├── outputs.tf           30 outputs, all try()-wrapped
├── providers.tf         the ONLY place a provider is configured
├── versions.tf          terraform >= 1.3, aws >= 5.0 < 6.0
├── data.tf              caller identity, region, availability zones
├── backend.tf           deliberately empty backend "s3" {} — configured at init time
│
├── modules/             19 reusable modules
├── environments/        REAL environments — these get applied
│   ├── dev/                 config.yml + backend.hcl
│   ├── staging/             config.yml + backend.hcl
│   └── prod/                config.yml + backend.hcl
│
├── examples/            TEMPLATES — nothing here is applied by CI
│   ├── core-service/        worked example: one service, end to end
│   │   └── config.yml
│   ├── all-keys/            every module, every key, all disabled
│   │   └── config.yml
│   └── split-config/        per-module layering (§4.5)
│       ├── common.yml  vpc.yml  kms.yml  s3.yml
│
├── .terraform-version   1.5.7
├── .terraform.lock.hcl  COMMITTED — pins provider versions and checksums
├── .gitignore           keeps state, plans and .terraform/ out of Git
└── README.md            this file
```

---

## 4. The configuration contract

### 4.1 Four standard variables

Every module declares exactly these four, and no more:

```hcl
variable "global_config" {}   # object: environment, region, project,
                              #         managed_by, cost_center, tags
                              # environment is validated: dev|test|staging|preprod|prod
variable "config_file"  {}    # string, default "config.yml"
variable "manual_config" {}   # any, default {} — merged over the YAML at the top level
variable "tags"          {}   # map(string), default {}
```

Modules that need data from another module take **wiring inputs only**, never more config:

| Module | Additional wiring inputs |
|---|---|
| `alb` | `vpc_id`, `vpc_cidr_block`, `public_subnets`, `private_subnets` |
| `ecs_service` | `cluster_arn`, `listener_arn`, `vpc_id`, `vpc_cidr_block`, `private_subnets` |
| `rds` | `vpc_id`, `vpc_cidr_block`, `private_subnets` |
| `elasticache` | `vpc_id`, `private_subnets` |
| `eks` | `vpc_id`, `private_subnets`, `public_subnets` |
| `dns` | `alb_dns_name`, `alb_zone_id`, `cloudfront_domain_name` |
| `ecs_cluster`, `security_group` | `vpc_id` |

A new option belongs in the YAML and in `locals.tf` — **not** in a new variable.

### 4.2 Modules read their own YAML, and they read it from `path.cwd`

```hcl
config_local = merge(
  try(yamldecode(file("${path.cwd}/${var.config_file}")), {}),
  var.manual_config
)
```

Three consequences worth knowing before debugging a missing key:

1. **`path.cwd`, not `path.module`.** The YAML is resolved against the *caller's* working
   directory. The root passes `config_file = "environments/dev/config.yml"`, so Terraform must
   run from the repository root. Anywhere else and the path is wrong.
2. **`try(..., {})` swallows a missing or unparseable file** — a wrong path yields an empty
   config and silently-defaulted infrastructure, **with no error**. Verify the decode before
   blaming the mapping.
3. **`manual_config` merges at the top level**, so overriding one key means passing the whole
   `{ vpc = { ... } }` sub-map, not just the leaf.

### 4.3 Naming and tags — identical in every module

```hcl
name_prefix = join("-", compact([env, app_name == "base" ? null : app_name, service_type]))

tags = merge(
  { Environment, Project, ManagedBy, CostCenter, Terraform = "true" },
  var.tags,
  global_config.tags,     # last wins
)
```

`app_name` and `service_type` sit at the **root** of the YAML, not inside a service block.
`app_name: "base"` is dropped from the name, so `dev` + `infra` produces the prefix `dev-infra`.

### 4.4 `enabled` is the caller's gate, not the module's

**No module has an internal `enabled` flag.** The root reads `<block>.enabled` from the YAML and
turns it into a `count`:

```hcl
module "vpc" {
  count  = local.enabled.vpc ? 1 : 0
  source = "./modules/vpc"
  ...
}
```

Adding a second gate inside the module would double-gate it.
`terraform output enabled_modules` is the source of truth for what an environment switched on.

### 4.5 Two config modes: one file, or per-module files

Each module has its **own defaults** in `locals.tf`. On top of those you can layer config in
either of two shapes.

**Monolithic** — `-var="config_file=environments/dev/config.yml"`. One file, every block in it.
Fine for a small environment; it grows awkward once several people edit different services.

**Per-module** — `-var="config_dir=examples/split-config"`. The root reads:

```
examples/split-config/
├── common.yml      REQUIRED — globals plus shared defaults for any block
├── vpc.yml         optional — overrides only what it names
├── kms.yml         optional
└── s3.yml          optional
```

The file is named after the **module directory** (`ecs_cluster.yml`, `ecs_service.yml`,
`security_group.yml`), and contains whichever block that module reads. A module with no file
simply gets `common.yml`.

Precedence, lowest to highest:

```
module defaults (locals.tf)  ->  common.yml  ->  <module>.yml
```

`common.yml` is **required** in this mode — the root reads it with a bare `file()`, so a missing
one is a loud error rather than an environment silently built from defaults.

#### The merge is two levels deep, and that matters

`merge()` in Terraform is **shallow**. A naive `merge(common, overlay)` replaces a whole block
and silently discards everything else common.yml put inside it:

```yaml
# common.yml            # vpc.yml              # shallow merge gives you
vpc:                    vpc:                   vpc:
  cidr: "10.0.0.0/16"     cidr: "10.9.0.0/16"    cidr: "10.9.0.0/16"
  single_nat_gateway: true                       #  <- single_nat_gateway is GONE
```

The root merges one level further, so an overlay overrides individual keys and leaves the rest
of the block intact. Verified against `examples/split-config`: `vpc.yml` sets `cidr` and the
subnets, while `azs`, `enable_nat_gateway`, `enable_dns_hostnames`, `enable_dns_support`,
`enable_flow_log` and `single_nat_gateway` all survive from `common.yml`.

**Lists are replaced wholesale, not concatenated.** An overlay's `azs` or `public_subnets`
replaces common's entirely — which is what you want for a list, but worth knowing.

#### How it reaches the module

The root does not translate config. It merges the layers and hands the result to the module as
`manual_config`, which the module merges over its own file read:

```hcl
# in every module
config_local = merge(
  try(yamldecode(file("${path.cwd}/${var.config_file}")), {}),
  var.manual_config,          # <- the root's merged result wins
)
```

In monolithic mode `manual_config` is `{}` and the module reads the single file itself. Both
modes end at the same place, so no module knows or cares which one you used.

---

## 5. YAML → module mapping

Each module reads **exactly one block** of `config.yml`. The "legacy key" column is the older
name still merged for backward compatibility.

| Module | YAML block | Legacy key | Local it builds |
|---|---|---|---|
| `vpc` | `vpc` | — | `local.vpc_config` |
| `kms` | `kms` | — | `local.kms_config` |
| `iam` | `iam` | — | `local.policies`, `roles`, `groups`, `users` |
| `security_group` | `security_group` | — | `local.sg_config` |
| `acm` | `acm` | — | `local.acm_config` |
| `dns` | `dns` | `route53` | `local.raw_dns_cfg` |
| `waf` | `waf` | — | `local.waf_config` |
| `ecr` | `ecr` | — | `local.ecr_config` |
| `s3` | `s3` | — | `local.s3_config` |
| `secrets_manager` | `secrets_manager` | — | `local.sm_config` |
| `dynamodb` | `dynamodb` | — | `local.tables` |
| `sqs` | `sqs` | — | `local.queues` |
| `sns` | `sns` | — | `local.topics` |
| `cloudwatch` | `cloudwatch` | — | `local.log_groups`, `metric_alarms`, `dashboards` |
| `alb` | `alb` | — | `local.alb_config` |
| `rds` | `rds` | — | `local.rds_config` |
| `elasticache` | `elasticache` | — | `local.elasticache_config` |
| `ecs_cluster` | `ecs` | `ecs_cluster` | `local.ecs_config` |
| `ecs_service` | `service` | `ecs_service` | `local.service_cfg`, `task_cfg`, `containers` |
| `eks` | `eks` | — | `local.eks_config` |

`ecs_service` also reads three blocks at the YAML root — `autoscaling`, `task_definition` and
`volumes` — preferring the copies nested under `service.` and falling back to the root.

### Adding a new variable — three steps

```yaml
# 1. add it to environments/<env>/config.yml
vpc:
  enable_ipv6: true
```

```hcl
# 2. expose it in modules/vpc/locals.tf, always with a default
vpc_config = {
  # ...
  enable_ipv6 = try(local.raw_vpc_cfg.enable_ipv6, false)
}
```

```hcl
# 3. use it in modules/vpc/main.tf — main.tf reads ONLY from the built object
module "vpc" {
  enable_ipv6 = local.vpc_config.enable_ipv6
}
```

Never read `local.config_local` directly inside a resource. Adding a key with a `try(...)`
default is backward compatible; renaming or removing one is not.

---

## 6. YAML reference, by module

Every key below is read by the module's `locals.tf`; the examples are valid input for the
current pinned upstream versions. Keys you omit fall back to the module's own defaults — open
`modules/<name>/locals.tf` to see them.

Each module reads **its own block only**, out of the same `config.yml`.

> **Start here instead:** for a stack that actually hangs together —
> Route53 → ALB → ECS → RDS, with EKS alongside — read
> **`examples/core-service/config.yml`**. It shows the flow and the wiring.
> The blocks below are the exhaustive per-key reference.
>
> **Copy-pasteable version:** every example below also lives in
> **`examples/all-keys/config.yml`** as one complete file, with all 20 modules set to
> `enabled: false`. That file is a template — nothing reads it, and it is not an environment.
> To start a new environment, copy it rather than retyping from here.

### 6.1 Foundation

#### `vpc`

```yaml
vpc:
  enabled: true                       # read by the ROOT, not the module (§4.4)
  cidr: "10.10.0.0/16"
  azs: ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  public_subnets:   ["10.10.0.0/20",  "10.10.16.0/20",  "10.10.32.0/20"]
  private_subnets:  ["10.10.64.0/19", "10.10.96.0/19",  "10.10.128.0/19"]
  database_subnets: ["10.10.160.0/24","10.10.161.0/24", "10.10.162.0/24"]
  intra_subnets: []                   # no route to the internet at all
  enable_nat_gateway: true
  single_nat_gateway: true            # false + one_nat_gateway_per_az: true for prod
  one_nat_gateway_per_az: false
  enable_dns_hostnames: true
  enable_dns_support: true
  enable_vpn_gateway: false
  create_database_subnet_group: true
  create_database_subnet_route_table: false
  enable_flow_log: true
  flow_log_traffic_type: "REJECT"     # ALL | ACCEPT | REJECT
  flow_log_max_aggregation_interval: 60
  public_subnet_tags:   { Tier: "Public" }
  private_subnet_tags:  { Tier: "Private" }
  database_subnet_tags: { Tier: "Data" }
  intra_subnet_tags:    {}
```

#### `kms`

```yaml
kms:
  enabled: true
  description: "Master key for dev-infra"
  aliases: ["alias/dev-infra-key"]
  deletion_window_in_days: 30         # 7 is the minimum AWS allows
  key_usage: "ENCRYPT_DECRYPT"
  customer_master_key_spec: "SYMMETRIC_DEFAULT"
  multi_region: false
  key_administrators: ["arn:aws:iam::111122223333:role/platform-admin"]
  key_users:          ["arn:aws:iam::111122223333:role/dev-infra-ecs-task"]
  policy: null                        # raw JSON overrides everything above
  # rotation_period_in_days: 365      # NO EFFECT — upstream v2.2.1 rejects it (§8.6)
```

#### `iam` — factory

The map key becomes the resource name. `custom_policy_names` refers to entries in `policies`;
the module resolves them to ARNs for you.

```yaml
iam:
  enabled: true

  policies:
    dev-infra-s3-read:
      path: "/"
      description: "Read-only access to the artifacts bucket"
      policy: |
        {
          "Version": "2012-10-17",
          "Statement": [{
            "Effect": "Allow",
            "Action": ["s3:GetObject", "s3:ListBucket"],
            "Resource": ["arn:aws:s3:::sm-platform-dev-artifacts",
                         "arn:aws:s3:::sm-platform-dev-artifacts/*"]
          }]
        }

  roles:
    dev-infra-ecs-task:
      trusted_role_services: ["ecs-tasks.amazonaws.com"]
      custom_role_policy_arns:
        - "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
      custom_policy_names: ["dev-infra-s3-read"]
      role_requires_mfa: false
      create_instance_profile: false  # true only for EC2 roles
      # assume_role_policy: |         # raw JSON replaces the trust policy entirely
```

When `roles` is empty the module falls back to a single role built from
`role_name` · `trusted_role_services` · `role_requires_mfa` · `custom_role_policy_arns` ·
`assume_role_policy`.

#### `security_group`

```yaml
security_group:
  enabled: true
  description: "Shared application security group"
  ingress_rules: ["https-443-tcp"]           # named rules from the upstream module
  ingress_cidr_blocks: ["10.10.0.0/16"]
  ingress_with_cidr_blocks:                  # or spell them out
    - from_port: 8080
      to_port: 8080
      protocol: "tcp"
      description: "App port from inside the VPC"
      cidr_blocks: "10.10.0.0/16"
  ingress_with_source_security_group_id:
    - from_port: 5432
      to_port: 5432
      protocol: "tcp"
      description: "Postgres from the app SG"
      source_security_group_id: "sg-0123456789abcdef0"
  egress_rules: ["all-all"]                  # ["https-443-tcp"] in prod
  egress_cidr_blocks: ["0.0.0.0/0"]
  egress_with_source_security_group_id: []
  revoke_rules_on_delete: false
```

### 6.2 Edge and certificates

#### `acm`

```yaml
acm:
  enabled: true
  domain_name: "dev.platform.example.com"
  subject_alternative_names: ["*.dev.platform.example.com"]
  validation_method: "DNS"                   # DNS | EMAIL
  wait_for_validation: true                  # false in CI so apply does not block
  key_algorithm: "RSA_2048"
  certificate_transparency_logging_preference: "ENABLED"
```

#### `dns` — factory *(legacy key: `route53`)*

`records` is keyed by **zone name**, and each entry is a list of records.

```yaml
dns:
  enabled: true
  zones:
    "dev.platform.example.com":
      comment: "Dev platform zone"
  records:
    "dev.platform.example.com":
      - name: "api"
        type: "A"
        alias:
          name:    "dualstack.dev-alb-123456.ap-southeast-1.elb.amazonaws.com"
          zone_id: "Z1LMS91P8CMLE5"
      - name: ""
        type: "TXT"
        ttl: 300
        records: ["v=spf1 -all"]
```

#### `waf`

```yaml
waf:
  enabled: true
  scope: "REGIONAL"                          # REGIONAL for ALB, CLOUDFRONT for CDN
  description: "Edge protection for dev-infra"
  default_action: "allow"                    # allow | block
  token_domains: ["dev.platform.example.com"]
  associate_alb_arns:                        # creates the WebACL association
    - "arn:aws:elasticloadbalancing:ap-southeast-1:111122223333:loadbalancer/app/dev-alb/abc"
  rules:
    - name: "AWSManagedRulesCommonRuleSet"
      priority: 1
      override_action: "none"
      statement:
        managed_rule_group_statement:
          name:        "AWSManagedRulesCommonRuleSet"
          vendor_name: "AWS"
      visibility_config:
        cloudwatch_metrics_enabled: true
        metric_name: "common-rule-set"
        sampled_requests_enabled: true
  # logging_configuration: {}                # NO EFFECT — upstream v1.1.0 rejects it (§8.6)
```

#### `alb`

`listeners` and `target_groups` are **maps** (upstream v9). Omit them and the module builds a
default port-80 listener plus one target group.

```yaml
alb:
  enabled: true
  internal: false                            # true puts it on the private subnets
  idle_timeout: 60
  enable_deletion_protection: true           # prod
  enable_waf_fail_open: false
  drop_invalid_header_fields: true
  preserve_host_header: false
  desync_mitigation_mode: "defensive"
  xff_header_processing_mode: "append"

  security_group_ingress_rules:              # the module creates the ALB's own SG
    https:
      from_port:   443
      to_port:     443
      ip_protocol: "tcp"
      description: "HTTPS from the internet"
      cidr_ipv4:   "0.0.0.0/0"

  listeners:
    https:
      port:            443
      protocol:        "HTTPS"
      certificate_arn: "arn:aws:acm:ap-southeast-1:111122223333:certificate/abc-123"
      forward:
        target_group_key: "app"

  target_groups:
    app:
      protocol:    "HTTP"
      port:        8080
      target_type: "ip"                      # ip is required for Fargate
      health_check:
        enabled: true
        path:    "/healthz"
        matcher: "200"

  access_logs:
    bucket:  "sm-platform-dev-logs"
    prefix:  "alb"
    enabled: true
  connection_logs: {}
```

### 6.3 Storage and data

#### `s3`

```yaml
s3:
  enabled: true
  bucket: "sm-platform-dev-artifacts"
  versioning_enabled: true
  kms_key_id: null                           # null = SSE-S3; set an ARN for SSE-KMS
  block_public_acls: true
  block_public_policy: true
  force_destroy: false                       # true ONLY in dev
  object_lock_enabled: false
  object_lock_configuration: {}
  acceleration_status: null
  lifecycle_rule:
    - id: "expire-old-artifacts"
      enabled: true
      expiration: { days: 90 }
      noncurrent_version_expiration: { days: 30 }
  cors_rule: []
  logging:
    target_bucket: "sm-platform-dev-logs"
    target_prefix: "s3/"
  website: {}
  intelligent_tiering: {}
  metric_configuration: []
  replication_configuration: {}
  # notification_configurations: {}          # NO EFFECT — upstream v4.2.1 rejects it (§8.6)
```

#### `ecr`

```yaml
ecr:
  enabled: true
  repository_names: ["core-backend-api", "core-frontend-web"]
  image_tag_mutability: "IMMUTABLE"          # MUTABLE in dev
  scan_on_push: true
  encryption_type: "AES256"                  # or KMS, with kms_key set
  kms_key: null
  repository_force_delete: false
  read_access_arns:       ["arn:aws:iam::111122223333:role/dev-infra-ecs-task"]
  read_write_access_arns: ["arn:aws:iam::111122223333:role/ci-deployer"]
  lifecycle_policy: |
    {
      "rules": [{
        "rulePriority": 1,
        "description": "Keep the last 30 images",
        "selection": { "tagStatus": "any", "countType": "imageCountMoreThan", "countNumber": 30 },
        "action": { "type": "expire" }
      }]
    }
```

#### `rds`

```yaml
rds:
  enabled: true
  engine: "postgres"
  engine_version: "16.3"
  major_engine_version: "16"
  family: "postgres16"
  instance_class: "db.t4g.micro"             # db.m6g.large in prod
  allocated_storage: 20
  max_allocated_storage: 100                 # 0 disables storage autoscaling
  storage_type: "gp3"
  storage_throughput: null
  iops: null
  multi_az: false                            # true in prod
  port: 5432
  username: "appuser"                        # the password is an AWS-managed secret
  backup_retention_period: 7                 # 0 disables backups — never in prod
  backup_window: "17:00-18:00"               # UTC
  maintenance_window: "Sun:18:00-Sun:19:00"
  deletion_protection: true
  skip_final_snapshot: false
  final_snapshot_identifier_prefix: "final"
  copy_tags_to_snapshot: true
  apply_immediately: false                   # true forces a restart outside the window
  auto_minor_version_upgrade: true
  performance_insights_enabled: true
  monitoring_interval: 60                    # 0 disables enhanced monitoring
  enabled_cloudwatch_logs_exports: ["postgresql", "upgrade"]
  iam_database_authentication_enabled: true
  kms_key_id: null
  ca_cert_identifier: "rds-ca-rsa2048-g1"
```

#### `elasticache`

```yaml
elasticache:
  enabled: true
  engine: "redis"
  engine_version: "7.1"
  node_type: "cache.t4g.micro"
  num_cache_nodes: 1
  num_node_groups: 1                         # shards, for cluster mode
  replicas_per_node_group: 2                 # prod
  port: 6379
  parameter_group_name: "default.redis7"
  automatic_failover_enabled: true           # requires at least one replica
  multi_az_enabled: true
  snapshot_retention_limit: 7                # 0 disables snapshots
  snapshot_window: "03:00-05:00"
  maintenance_window: "sun:05:00-sun:07:00"
  apply_immediately: false
  auto_minor_version_upgrade: true
  kms_key_arn: null
  security_group_ids: []                     # empty = the module creates one
```

#### `dynamodb` — factory

```yaml
dynamodb:
  enabled: true
  tables:
    sessions:
      name: "dev-infra-sessions"
      billing_mode: "PAY_PER_REQUEST"        # or PROVISIONED + read/write_capacity
      hash_key:  "pk"
      range_key: "sk"
      attributes:
        - { name: "pk", type: "S" }
        - { name: "sk", type: "S" }
      ttl_attribute_name: "expires_at"
      point_in_time_recovery_enabled: true
      deletion_protection_enabled: true
      server_side_encryption_enabled: true
      kms_key_arn: null
      stream_enabled: true
      stream_view_type: "NEW_AND_OLD_IMAGES"
      global_secondary_indexes: []
      local_secondary_indexes: []
```

#### `secrets_manager` — factory

```yaml
secrets_manager:
  enabled: true
  secrets:
    db_password:
      description: "Application database password"
      kms_key_id: null
      recovery_window_in_days: 30            # 0 deletes immediately — dev only
      ignore_secret_changes: true            # rotation happens outside Terraform
      rotation_lambda_arn: null
      rotation_rules: {}
```

Never put the secret's **value** in this file. Create the secret here, set the value out of
band, and reference it by ARN (see §9).

### 6.4 Compute

#### `ecs_cluster` *(block is `ecs`, legacy `ecs_cluster`)*

```yaml
ecs:
  enabled: true
  container_insights: true
  kms_key_id: null                           # encrypts ECS Exec sessions
  fargate_weight: 100                        # prod: all on-demand
  fargate_base: 0
  fargate_spot_weight: 0                     # dev: 0 / 100 to run entirely on spot
  create_task_exec_iam_role: true
  create_task_exec_policy: true
  task_exec_secret_arns:    ["arn:aws:secretsmanager:ap-southeast-1:111122223333:secret:*"]
  task_exec_ssm_param_arns: []
```

#### `ecs_service` *(block is `service`, legacy `ecs_service`)*

```yaml
service:
  enabled: true
  desired_count: 3
  health_check_path: "/healthz"
  health_check_matcher: "200"
  health_check_grace_period: 30
  priority: 100                              # ALB listener rule priority
  host_header: "api.dev.platform.example.com"
  deployment_maximum_percent: 200
  deployment_minimum_healthy_percent: 100
  deployment_controller_type: "ECS"
  enable_execute_command: false              # true in dev for debugging
  force_new_deployment: false
  propagate_tags: "SERVICE"
  platform_version: "LATEST"
  scheduling_strategy: "REPLICA"
  wait_for_steady_state: true                # prod: apply blocks until healthy
  assign_public_ip: false
  capacity_provider_strategy: []

  load_balancer:
    container_name: "app"
    container_port: 8080

  task_definition:
    family: "dev-infra-task"
    network_mode: "awsvpc"
    requires_compatibilities: ["FARGATE"]
    cpu: 512
    memory: 1024
    execution_role_arn: null                 # null = the cluster's role
    task_role_arn: null

  container_definitions:
    - name: "app"
      image: "111122223333.dkr.ecr.ap-southeast-1.amazonaws.com/core-backend-api:1.4.2"
      essential: true
      cpu: 512
      memory: 1024
      command: []
      port_mappings:
        - { container_port: 8080, protocol: "tcp" }
      environment:                           # a map, converted to name/value pairs
        LOG_LEVEL: "info"
        APP_ENV: "dev"
      secrets:                               # a map of NAME -> ARN, never a value
        DB_PASSWORD: "arn:aws:secretsmanager:ap-southeast-1:111122223333:secret:db-abc"
      mount_points: []
      depends_on: []

  volumes: []

autoscaling:                                 # its own block at the YAML root
  enabled: true
  min_capacity: 3
  max_capacity: 12
  target_cpu_utilization: 60                 # 0 disables the CPU policy
  target_memory_utilization: 70              # 0 disables the memory policy
```

#### `eks`

Independent of the ECS blocks above. Shares the VPC and private subnets, nothing else.

```yaml
eks:
  enabled: false
  cluster_name: "dev-payments-eks"
  cluster_version: "1.31"
  endpoint_private_access: true
  endpoint_public_access: false                # a public API server is the #1 EKS mistake
  public_access_cidrs: []                      # required if public access is on
  enabled_log_types: ["api", "audit"]          # prod: all five
  authentication_mode: "API"                   # access entries, not the aws-auth ConfigMap
  enable_cluster_creator_admin_permissions: true
  enable_irsa: true                            # OIDC provider, for pod-level IAM roles
  create_kms_key: true                         # envelope-encrypts Kubernetes secrets
  kms_key_arn: null                            # set this to reuse an existing key
  cluster_encryption_config: { resources: ["secrets"] }
  create_cloudwatch_log_group: true
  cloudwatch_log_group_retention_in_days: 30
  subnet_ids: []                               # empty = the private_subnets wired in
  access_entries:
    platform_admins:
      principal_arn: "arn:aws:iam::111122223333:role/platform-admin"
      policy_associations:
        admin:
          policy_arn: "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope: { type: "cluster" }
  addons:
    coredns: {}
    kube-proxy: {}
    vpc-cni: { before_compute: true }          # must exist before nodes join
    eks-pod-identity-agent: {}
  node_group_defaults:
    ami_type: "AL2023_x86_64_STANDARD"
    disk_size: 50
  node_groups:
    default:
      min_size: 2
      max_size: 6
      desired_size: 2
      instance_types: ["t3.large"]
      capacity_type: "SPOT"                    # ON_DEMAND in prod
      labels: { workload: "general" }
  fargate_profiles: {}
  security_group_additional_rules: {}
  node_security_group_additional_rules: {}
```

For EKS to place load balancers correctly, the VPC subnets need the standard tags —
`kubernetes.io/role/elb: "1"` on public subnets and `kubernetes.io/role/internal-elb: "1"` on
private ones. The core-service example sets both.

---

### 6.5 Observability and messaging

#### `cloudwatch` — factory

```yaml
cloudwatch:
  enabled: true
  log_groups:
    app:
      name: "/ecs/dev-infra"
      retention_in_days: 30
      kms_key_id: null
  metric_alarms:
    ecs_cpu_high:
      alarm_name: "dev-infra-ecs-cpu-high"
      alarm_description: "ECS service CPU above 80% for 5 minutes"
      namespace: "AWS/ECS"
      metric_name: "CPUUtilization"
      statistic: "Average"
      comparison_operator: "GreaterThanOrEqualToThreshold"
      threshold: 80
      period: 60
      evaluation_periods: 5
      treat_missing_data: "notBreaching"
      dimensions:
        ClusterName: "dev-infra-cluster"
        ServiceName: "dev-infra"
      # No module-to-module wiring exists (§8.3): paste the ARN from
      # `terraform output sns_topic_arns`. Leaving this empty means the alarm notifies nobody.
      alarm_actions: ["arn:aws:sns:ap-southeast-1:111122223333:dev-infra-alerts"]
      ok_actions: []
      insufficient_data_actions: []
  dashboards:
    overview:
      name: "dev-infra-overview"
      body: |
        { "widgets": [] }
```

#### `sns` — factory

```yaml
sns:
  enabled: true
  topics:
    alerts:
      name: "dev-infra-alerts"
      display_name: "Dev infra alerts"
      fifo_topic: false
      content_based_deduplication: false
      kms_master_key_id: null
      delivery_policy: null
      subscriptions:
        oncall_email:
          protocol: "email"
          endpoint: "oncall@example.com"
      lambda_feedback: {}                    # v6.1.1 shape (§8.6)
      sqs_feedback: {}
```

#### `sqs` — factory

```yaml
sqs:
  enabled: true
  queues:
    jobs:
      name: "dev-infra-jobs"
      fifo_queue: false
      content_based_deduplication: false
      visibility_timeout_seconds: 30
      message_retention_seconds: 345600      # 4 days
      max_message_size: 262144
      delay_seconds: 0
      receive_wait_time_seconds: 20          # long polling
      kms_master_key_id: null
      kms_data_key_reuse_period_seconds: 300
      redrive_policy: |
        { "deadLetterTargetArn": "arn:aws:sqs:ap-southeast-1:111122223333:dev-infra-jobs-dlq",
          "maxReceiveCount": 5 }
      redrive_allow_policy: null
      queue_policy_statements: {}
      policy: null
```

---

## 7. Environments

Each environment is a directory of **values, with no HCL**:

```
environments/          only real environments live here
├── dev/      config.yml  backend.hcl
├── staging/  config.yml  backend.hcl
└── prod/     config.yml  backend.hcl
```

Templates live in `examples/` and are never applied — see §3.

### Worked example

**`examples/core-service/config.yml`** is a complete stack for one HTTPS API —
Route53 → ALB → ECS Service → RDS, with ECR, KMS, IAM, WAF, CloudWatch and SNS around it, plus
an EKS cluster in the same VPC. Every block is enabled and the values line up. Read that file
before writing a new environment; it documents which values the root wires automatically and
which ones you still have to paste in (§8.3).

### Adding an environment

```bash
mkdir -p environments/uat
cp examples/all-keys/config.yml environments/uat/config.yml
cp environments/dev/backend.hcl    environments/uat/backend.hcl
```

Then edit `global.environment` (it is validated against `dev|test|staging|preprod|prod`, so
`uat` would be rejected — extend the validation in all 19 modules first, or reuse an accepted
name), the CIDRs, the bucket and key in `backend.hcl`, and switch `enabled` to `true` on only
what that environment needs.

`staging/config.yml` and `prod/config.yml` must stay **structurally identical** — only the values
differ. The moment prod has a key staging does not, staging has stopped rehearsing production.

Current differences:

| | dev | staging | prod |
|---|---|---|---|
| CIDR | `10.10.0.0/16` | `10.20.0.0/16` | `10.30.0.0/16` |
| NAT gateway | one, shared | one, shared | **one per AZ** |
| Flow logs | off | `REJECT` | `ALL` |
| KMS deletion window | 7 days | 30 days | 30 days |
| S3 `force_destroy` | `true` | `false` | `false` |
| Log retention | 7 days | 30 days | 90 days |
| Egress SG | `all-all` | `all-all` | `https-443-tcp` |
| ECR | on | off (images promoted from dev) | off |
| Fargate Spot | 100% | 50% | **0%** |

### State

`backend.tf` is deliberately empty. The bucket and key are supplied at init time:

```bash
terraform init -reconfigure -backend-config=environments/prod/backend.hcl
```

Never hardcode an environment into `backend.tf` — a committed bucket/key pair is exactly how a
dev apply ends up writing prod state.

**State locking is not switched on.** Terraform here is 1.5.7, which predates S3-native locking.
Each `backend.hcl` carries two commented lines — pick one:

- `dynamodb_table` — works on 1.5.7; needs a DynamoDB table with a `LockID` string hash key
- `use_lockfile = true` — the better option, but requires CLI >= 1.10

Running with neither means two concurrent applies can corrupt the state.

---

## 8. Known defects

All verified by running, not inferred.

1. **`required_version = ">= 1.0"` is wrong in all 19 modules.** Every `variables.tf` uses
   `optional(<type>, <default>)` inside an object type — a **Terraform 1.3** feature. The declared
   floor is three minor versions too low. The machine here runs 1.5.7, so this is latent rather
   than breaking. The root already declares `>= 1.3` correctly. Fix: one line per module.

2. **`ecs_service` hardcodes its log group.** `modules/ecs_service/locals.tf` composes
   `awslogs-group = "/ecs/${local.name_prefix}"` instead of taking a log group name as an input.
   If `cloudwatch` creates the group under a different name, the task writes to a second,
   auto-created group while the configured one stays empty.

3. **Several module-to-module edges do not exist — the values have to be pasted in as
   literals.** Building the worked example surfaced these. Each one is an ARN or an ID that is
   an *output* of one module and an *input* to another, with no wiring between them:

   | Needs | From | Consumed by | Today |
   |---|---|---|---|
   | `certificate_arn` | `acm` | `alb.listeners.<k>` | literal in YAML |
   | `execution_role_arn`, `task_role_arn` | `iam` | `service.task_definition` | literal in YAML |
   | ALB ARN | `alb` | `waf.associate_alb_arns` | literal in YAML |
   | SNS topic ARN | `sns` | `cloudwatch.metric_alarms.*.alarm_actions` | literal in YAML |

   The practical consequence is a **two-pass apply**: apply once, read the ARNs out of
   `terraform output`, paste them into `config.yml`, apply again. `dns` was fixed for this — it
   now takes `alb_dns_name` / `alb_zone_id` and resolves `alias.target: "alb"` — and the same
   pattern would close the four rows above.

   For the SNS row specifically: `modules/cloudwatch/main.tf` **does** pass `alarm_actions`,
   `ok_actions` and `insufficient_data_actions` through per alarm — the mechanism exists, only
   the wiring does not. In all three environment files `alarm_actions` is currently `[]`, which
   means those alarms notify nobody. **Prod must have it filled in.**

4. **`security_group` floats on `~> 5.0`** — the only upstream not pinned to an exact version in
   this repository. A new minor release can change a plan with no commit here. Suspect it first
   when a diff appears from nowhere.

5. **No production invariant is enforced automatically.** Two conditions matter —
   `vpc.one_nat_gateway_per_az` must be `true` and `s3.force_destroy` must be `false` in prod —
   and they live only in `environments/prod/config.yml` with nothing stopping an edit.
   `terraform test` is unusable here (1.5.7 only ships the old experimental command, whose format
   differs from `.tftest.hcl`), but **`check` blocks do run on 1.5.7** and would assert this on
   every `plan`. That is the right place to guard it.

6. **Three modules still keep locals for arguments their upstream rejects** —
   `kms.rotation_period_in_days`, `waf.logging_configuration`, `s3.notification_configurations`.
   These used to be passed straight through and made the whole module **fail `terraform
   validate`**; they have been removed from `main.tf`, with the local kept alongside a comment
   naming the correct upstream argument. Declaring these keys in YAML has **no effect** until the
   upstream version is raised and they are re-wired.

---

## 9. Conventions

- **Pin upstream by git tag.** Every module uses
  `git::https://github.com/terraform-aws-modules/terraform-aws-<x>.git?ref=v<n>`, except `vpc`
  (registry, pinned exactly to `5.13.0`) and `security_group` (`~> 5.0`, see §8.4). When raising a
  version, check `outputs.tf` still resolves — outputs here are pass-throughs, and a renamed
  upstream output is a breaking change for every stack above.
- **Directories use `snake_case`** (`ecs_service`, `secrets_manager`); YAML keys match.
- **`locals.tf` builds exactly one `local.<service>_config` object**, with every default resolved
  through `try(raw_cfg.<key>, <default>)`. `main.tf` reads only from that object.
- **Environment-conditional defaults live in the local**, in the existing style — for example
  `single_nat_gateway = try(..., local.env != "prod")`.
- **Outputs are wrapped in `try(..., null)`** where the upstream output is conditional.
- **No module declares a `provider` or a `backend`.** Providers live in the root's `providers.tf`;
  state belongs to the root.
- **No secrets anywhere in this tree.** RDS uses the AWS-managed master user secret; everything
  else is referenced by ARN. Note that Terraform state stores those values in **plaintext** —
  state read access is secret read access.

---

## 10. Blast radius

Changing an output name or a variable's type here breaks `aws-base-infras` and
`aws-application-infras` above it. Before renaming anything in an `outputs.tf` or changing a
variable's type, grep both consumer repositories for the symbol.

**Restructuring `modules/` into domain directories** (`modules/networking/vpc/`, …) has been
proposed but **not decided**: it would break **25 `source` paths** — 10 in `aws-base-infras`,
15 in `aws-application-infras`. Do not start it without an explicit instruction that also says
how the consumers will be handled.

**One dangling pointer sits outside this repository:**
`Claude/aws-application-infras/deployments/dev/services/apps.yml` has a comment referring to
`terraform-module/config_variables_mapping.md`, a file that was folded into this README and
deleted. That repo has uncommitted changes and was left untouched — repoint the comment at §5
when convenient.
