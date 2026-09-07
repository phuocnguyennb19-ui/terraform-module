# terraform-module

Reusable AWS Terraform modules and a root composition that deploys them one environment at a
time. Every module is a thin wrapper over a pinned `terraform-aws-modules` release; the module's
job is to map YAML onto upstream arguments.

Configuration is YAML, not tfvars — `.gitignore` excludes `*.tfvars`.

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"

  config_file = "environments/dev/config.yml"

  global_config = {
    environment = "dev"
    region      = "ap-southeast-1"
    project     = "SM-Platform"
  }

  tags = {
    Owner = "platform-team"
  }
}
```

The root wires all 20 modules together and gates each one on `<block>.enabled` in the YAML:

```bash
terraform init -reconfigure -backend-config=environments/dev/backend.hcl

terraform plan  -input=false -var="config_file=environments/dev/config.yml" -out=tfplan-dev
terraform apply -input=false tfplan-dev
```

Run from the repository root. Modules resolve their YAML as
`file("${path.cwd}/${var.config_file}")`, so from another directory the path is wrong, `try`
swallows the error, and Terraform builds from defaults without failing.

Against a local emulator instead of AWS:

```bash
terraform plan -var="config_file=environments/dev/config.yml" \
               -var="localstack_endpoint=http://localhost:4566"
```

## Examples

- [`examples/core-service`](examples/core-service) — runnable. One HTTPS API end to end:
  Route53 → ALB → ECS Service → RDS, with ECR, KMS, IAM, WAF, CloudWatch, SNS and EKS.
  `terraform init && terraform plan` from that directory.
- [`examples/module-config`](examples/module-config) — one config file per module plus `common.yml`;
  usable directly as a `config_dir`.

Each module also has its own README with Requirements, Providers, Modules, Resources, Inputs
and Outputs — see [`modules/vpc`](modules/vpc) for the shape.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3 |
| aws | >= 5.0, < 6.0 |

Pinned to `1.5.7` in `.terraform-version`. `.terraform.lock.hcl` is committed.

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0, < 6.0 |

Declared once in `providers.tf`. No module declares a provider or a backend.

## Modules

Each links to its own README.

| Name | Source | Version |
|------|--------|---------|
| `acm` | `terraform-aws-acm` | `v4.3.2` |
| `alb` | `terraform-aws-security-group` | `v5.1.0` |
| | `terraform-aws-alb` | `v9.11.0` |
| `cloudwatch` | `terraform-aws-cloudwatch//modules/log-group` | `v5.7.0` |
| | `terraform-aws-cloudwatch//modules/metric-alarm` | `v5.7.0` |
| `dns` | `terraform-aws-route53//modules/zones` | `v4.1.0` |
| | `terraform-aws-route53//modules/records` | `v4.1.0` |
| `dynamodb` | `terraform-aws-dynamodb-table` | `v4.1.0` |
| `ecr` | `terraform-aws-ecr` | `v2.2.1` |
| `ecs_cluster` | `terraform-aws-ecs` | `v5.11.4` |
| `ecs_service` | `terraform-aws-ecs//modules/service` | `v5.11.4` |
| `eks` | `terraform-aws-eks` | `v20.31.6` |
| `elasticache` | `terraform-aws-elasticache` | `v1.1.0` |
| `iam` | `terraform-aws-iam//modules/iam-assumable-role` | `v5.44.0` |
| | `terraform-aws-iam//modules/iam-assumable-role` | `v5.44.0` |
| `kms` | `terraform-aws-kms` | `v2.2.1` |
| `rds` | `terraform-aws-security-group` | `v5.1.0` |
| | `terraform-aws-rds` | `v6.10.0` |
| `s3` | `terraform-aws-s3-bucket` | `v4.2.1` |
| `secrets_manager` | `terraform-aws-secrets-manager` | `v1.1.0` |
| `security_group` | `terraform-aws-modules/security-group/aws` | `~> 5.0` |
| `sns` | `terraform-aws-sns` | `v6.1.1` |
| `sqs` | `terraform-aws-sqs` | `v4.2.1` |
| `vpc` | `terraform-aws-modules/vpc/aws` | `5.13.0` |
| `waf` | `terraform-aws-wafv2` | `v1.1.0` |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `config_file` | Path to the environment config, relative to the directory Terraform is run from. | `string` | `"environments/dev/config.yml"` | no |
| `tags` | Extra tags merged over the ones derived from config.yml global.tags. | `map(string)` | `{}` | no |
| `config_dir` | Optional. Path to a directory of per-module config, relative to the run directory. | `string` | `null` | no |
| `localstack_endpoint` | Redirect every AWS API this repository uses to a local emulator, e.g. | `string` | `null` | no |

Exactly one of `config_file` or `config_dir` is used; `config_dir` wins when set.

## Outputs

| Name | Description |
|------|-------------|
| `environment` | Environment this state manages. |
| `region` | AWS region. |
| `account_id` | AWS account this ran against. |
| `enabled_modules` | Which modules this environment's config.yml switched on. |
| `vpc_id` | VPC ID. |
| `vpc_cidr_block` | VPC CIDR block. |
| `public_subnets` | Public subnet IDs. |
| `private_subnets` | Private subnet IDs. |
| `database_subnets` | Database subnet IDs. |
| `nat_public_ips` | NAT gateway public IPs — the addresses to whitelist downstream. |
| `kms_key_arn` | KMS key ARN for encryption at rest. |
| `security_group_id` | Shared application security group ID. |
| `acm_certificate_arn` | ACM certificate ARN. |
| `web_acl_arn` | WAF web ACL ARN. |
| `iam_role_arns` | All IAM role ARNs created by the iam module. |
| `secret_arns` | Secrets Manager secret ARNs. |
| `alb_dns_name` | ALB DNS name. |
| `alb_zone_id` | ALB hosted zone ID — for a Route53 alias record. |
| `alb_listener_arns` | ALB listener ARNs. |
| `route53_zone_ids` | Route53 hosted zone IDs. |
| `rds_endpoint` | RDS instance endpoint. |
| `rds_master_user_secret_arn` | ARN of the AWS-managed master user secret. |
| `elasticache_primary_endpoint` | ElastiCache primary endpoint. |
| `s3_bucket_arn` | S3 bucket ARN. |
| `dynamodb_table_arns` | DynamoDB table ARNs. |
| `ecr_repository_urls` | ECR repository URLs. |
| `ecs_cluster_arn` | ECS cluster ARN. |
| `ecs_service_name` | ECS service name. |
| `ecs_task_definition_arn` | ECS task definition ARN. |
| `eks_cluster_name` | EKS cluster name. |
| `eks_cluster_endpoint` | EKS Kubernetes API endpoint. |
| `eks_oidc_provider_arn` | OIDC provider ARN — the trust anchor for IRSA roles. |
| `eks_node_security_group_id` | Security group shared by the EKS managed node groups. |
| `eks_kubeconfig_command` | Command that writes a kubeconfig entry for the cluster. |
| `sqs_queue_urls` | SQS queue URLs. |
| `sns_topic_arns` | SNS topic ARNs — paste into cloudwatch alarm_actions in config.yml. |
| `log_group_names` | CloudWatch log group names. |

## Configuration

### Module interface

Every module declares the same four variables:

| Variable | Purpose |
|---|---|
| `global_config` | `environment`, `region`, `project`, `managed_by`, `cost_center`, `tags` |
| `config_file` | path to the YAML, resolved against `path.cwd` |
| `manual_config` | merged over the YAML at the top level |
| `tags` | extra tags |

`global_config.environment` is validated against `dev`, `test`, `staging`, `preprod`, `prod`.

Modules that consume another module's output take wiring inputs, never more config:

| Module | Wiring inputs |
|---|---|
| `alb` | `vpc_id`, `vpc_cidr_block`, `public_subnets`, `private_subnets` |
| `ecs_service` | `cluster_arn`, `listener_arn`, `vpc_id`, `vpc_cidr_block`, `private_subnets` |
| `eks` | `vpc_id`, `private_subnets`, `public_subnets` |
| `rds` | `vpc_id`, `vpc_cidr_block`, `private_subnets` |
| `elasticache` | `vpc_id`, `private_subnets` |
| `dns` | `alb_dns_name`, `alb_zone_id`, `cloudfront_domain_name` |
| `ecs_cluster`, `security_group` | `vpc_id` |

### Naming and tags

```hcl
name_prefix = join("-", compact([env, app_name == "base" ? null : app_name, service_type]))
```

`app_name` and `service_type` are at the YAML root. `app_name: "base"` is dropped, so
`dev` + `infra` gives `dev-infra`.

### `enabled`

No module has an internal `enabled` flag. The root reads `<block>.enabled` and turns it into
`count`. `terraform output enabled_modules` lists what an environment switched on.

### Config modes

| Mode | Flag | Shape |
|---|---|---|
| Single file | `-var="config_file=environments/dev/config.yml"` | every block in one file |
| Per module | `-var="config_dir=examples/module-config"` | `common.yml` + optional `<module>.yml` |

Precedence, lowest to highest:

```
module defaults (locals.tf)  ->  common.yml  ->  <module>.yml
```

`common.yml` is required in directory mode and read with a bare `file()`, so a missing one is a
hard error.

The merge is two levels deep. Terraform's `merge()` is shallow and would drop the rest of a
block:

```yaml
# common.yml              # vpc.yml               # shallow merge loses this
vpc:                      vpc:                    vpc:
  cidr: "10.0.0.0/16"       cidr: "10.9.0.0/16"     cidr: "10.9.0.0/16"
  single_nat_gateway: true
```

Lists are replaced wholesale, not concatenated.

### YAML block per module

| Module | Block | Legacy key |
|---|---|---|
| `vpc` | `vpc` | |
| `kms` | `kms` | |
| `iam` | `iam` | |
| `security_group` | `security_group` | |
| `acm` | `acm` | |
| `dns` | `dns` | `route53` |
| `waf` | `waf` | |
| `alb` | `alb` | |
| `ecr` | `ecr` | |
| `s3` | `s3` | |
| `secrets_manager` | `secrets_manager` | |
| `dynamodb` | `dynamodb` | |
| `sqs` | `sqs` | |
| `sns` | `sns` | |
| `cloudwatch` | `cloudwatch` | |
| `rds` | `rds` | |
| `elasticache` | `elasticache` | |
| `ecs_cluster` | `ecs` | `ecs_cluster` |
| `ecs_service` | `service` + `autoscaling` | `ecs_service` |
| `eks` | `eks` | |

Keys per block are in `examples/module-config/<module>.yml`; every one of them appears in that
module's `locals.tf`. Omitted keys fall back to the module default.

### Adding a key

```yaml
vpc:
  enable_ipv6: true
```

```hcl
# modules/vpc/locals.tf — always with a default
vpc_config = {
  enable_ipv6 = try(local.raw_vpc_cfg.enable_ipv6, false)
}

# modules/vpc/main.tf — reads only from the built object
enable_ipv6 = local.vpc_config.enable_ipv6
```

Adding a key with a `try()` default is backward compatible; renaming or removing one is not.

## Environments

```
environments/dev|staging|prod/
  config.yml
  backend.hcl
```

| | dev | staging | prod |
|---|---|---|---|
| CIDR | `10.10.0.0/16` | `10.20.0.0/16` | `10.30.0.0/16` |
| NAT gateway | shared | shared | one per AZ |
| Flow logs | off | `REJECT` | `ALL` |
| KMS deletion window | 7d | 30d | 30d |
| S3 `force_destroy` | true | false | false |
| Log retention | 7d | 30d | 90d |
| Egress SG | `all-all` | `all-all` | `https-443-tcp` |
| ECR | on | off | off |
| Fargate Spot | 100% | 50% | 0% |

`staging` and `prod` must stay structurally identical; only values differ.

### State

`backend.tf` is empty by design; bucket and key come from `-backend-config` at init.

`environments/localstack/backend.hcl` points the backend at the emulator. It has no
`config.yml` — pair it with any environment's config, or a `config_dir`. Its `endpoint` and
`force_path_style` are the pre-1.6 spellings, correct for the pinned 1.5.7; on 1.6+ they become
`endpoints = { s3 = ... }` and `use_path_style`, and left unchanged there the backend's STS call
goes to real AWS.

State locking is off. Terraform 1.5.7 predates S3-native locking, so each `backend.hcl` carries
two commented lines — enable one:

- `dynamodb_table` — works on 1.5.7, needs a table with a `LockID` string hash key
- `use_lockfile = true` — preferred, requires CLI >= 1.10

## Known issues

1. `required_version = ">= 1.0"` is wrong in 19 of 20 modules. All 20 use
   `optional(<type>, <default>)`, a Terraform 1.3 feature. Only `eks` and the root declare
   `>= 1.3`.

2. `ecs_service` hardcodes its log group as `/ecs/${name_prefix}` instead of taking it as an
   input, so a differently-named `cloudwatch` group leaves a second one auto-created.

3. Four module-to-module edges do not exist; the values must be literals, which forces a
   two-pass apply:

   | Value | From | Consumed by |
   |---|---|---|
   | `certificate_arn` | `acm` | `alb.listeners.<k>` |
   | `execution_role_arn`, `task_role_arn` | `iam` | `service.task_definition` |
   | ALB ARN | `alb` | `waf.associate_alb_arns` |
   | SNS topic ARN | `sns` | `cloudwatch.metric_alarms.*.alarm_actions` |

   `cloudwatch` does pass `alarm_actions` per alarm — only the wiring is missing. It is `[]` in
   all three environments, so those alarms notify nobody. `dns` was fixed for this and resolves
   `alias.target: "alb"` from the ALB outputs.

4. `ecs_service` resolves its nested blocks inconsistently. `task_definition` uses
   `merge(nested, root)` so a **root-level** `task_definition:` overrides the one under
   `service:`, while `container_definitions` and `volumes` prefer the **nested** copy. The code
   comment claimed the opposite and has been corrected; the behaviour was left alone because
   changing it would silently relocate config. See `modules/ecs_service/README.md`.

5. `security_group` floats on `~> 5.0`, the only upstream not pinned exactly.

6. No production invariant is enforced. `vpc.one_nat_gateway_per_az` and `s3.force_destroy` in
   prod live only in `config.yml`. `terraform test` is unusable on 1.5.7; `check` blocks run and
   would assert them on every plan.

7. `kms.rotation_period_in_days`, `waf.logging_configuration` and `s3.notification_configurations`
   remain as locals but were removed from `main.tf` — the pinned upstream rejects them. Setting
   them in YAML has no effect.

8. LocalStack Community answers 501 for `ecr`, `ecs`, `elbv2`, `eks` and `rds`, so a config
   enabling those cannot be applied against it. A service missing from the `endpoints` block in
   `providers.tf` silently goes to real AWS — add new services there in the same change.

## Conventions

- Upstream pinned by git tag, except `vpc` (registry, exact `5.13.0`) and `security_group`.
  Outputs are pass-throughs, so a renamed upstream output breaks every stack above.
- Directories are `snake_case`; YAML keys match.
- `locals.tf` builds one `local.<service>_config` object with defaults via
  `try(raw_cfg.<key>, <default>)`; `main.tf` reads only from it.
- Environment-conditional defaults go in the local,
  e.g. `single_nat_gateway = try(..., local.env != "prod")`.
- Outputs wrapped in `try(..., null)` where the upstream output is conditional.
- No secret values in this tree. RDS uses the AWS-managed master user secret; everything else is
  referenced by ARN. Terraform state stores those values in plaintext.

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Chosen to match every pinned `terraform-aws-modules`
release this repository wraps, so there is no compatibility question with the upstream code.

## Blast radius

Renaming an output or changing a variable type breaks `aws-base-infras` and
`aws-application-infras`. Grep both before changing either.

Restructuring `modules/` into domain directories would break 25 `source` paths — 10 in
`aws-base-infras`, 15 in `aws-application-infras`. Not decided.

`~/Dylan/Claude/terraform-module` is the same repo at the same commit and is the checkout the
consumer repos resolve against; changes here do not reach them until pushed and pulled there.
