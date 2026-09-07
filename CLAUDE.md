# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

20 reusable AWS Terraform modules under `modules/`, plus a root composition that wires all 20
into one stack for one environment. Every module is a thin wrapper over a pinned
`terraform-aws-modules` release; the module's only job is to map YAML onto upstream arguments.

Configuration is **YAML, not tfvars** — `.gitignore` excludes `*.tfvars`.

`README.md` is the reference: per-module upstream pins, every root output, every YAML block name,
the per-environment value table, and the numbered known-defects list. Read it before changing a
module; this file covers only what is not written down there.

## Commands

There is no Makefile, no CI, no `terraform test`, and no lint config. Some config comments still
say `make plan ENV=dev` — that Makefile does not exist. The real loop:

```bash
# Always from the repository root — see "path.cwd" below.
terraform init -reconfigure -backend-config=environments/dev/backend.hcl

terraform fmt -recursive
terraform validate

terraform plan  -input=false -var="config_file=environments/dev/config.yml" -out=tfplan-dev
terraform apply -input=false tfplan-dev
```

Per-module config directory instead of one file (`config_dir` wins when both are set):

```bash
terraform plan -var="config_dir=examples/module-config"
```

Closest thing to a single-unit test — plan one module in isolation:

```bash
cd examples/core-service && terraform init && terraform plan   # 5 modules, HTTPS API end to end
terraform plan -var="config_file=environments/dev/config.yml" -target=module.vpc   # from root
```

Against LocalStack rather than AWS:

```bash
terraform plan -var="config_file=environments/dev/config.yml" \
               -var="localstack_endpoint=http://localhost:4566"
```

LocalStack Community answers 501 for `ecr`, `ecs`, `elbv2`, `eks` and `rds`; a config enabling
those cannot be applied against it.

Terraform is pinned to `1.5.7` in `.terraform-version`; `.terraform.lock.hcl` is committed.

## Architecture

### Config is read twice, by two different readers

The root decodes the YAML in `locals.tf`, and **each module decodes the same file again** in its
own `locals.tf`. The root does not translate config — it passes the same `config_file` string
down and each module picks its own block out of it. The root only passes:

| Argument | Meaning |
|---|---|
| `config_file` | path, resolved by the module as `file("${path.cwd}/${var.config_file}")` |
| `manual_config` | the merged config for that module, merged over the module's own YAML read |
| `global_config` | `environment`, `region`, `project`, `managed_by`, `cost_center`, `tags` |
| `tags` | extra tags |

Plus wiring inputs (`vpc_id`, subnets, `cluster_arn`, `listener_arn`, ARNs) — the only values that
travel between modules. Everything else travels through the YAML.

**`path.cwd`, not `path.module`.** Run from the repository root or the module's read resolves to
the wrong path, `try(..., {})` swallows the error, and Terraform silently builds from defaults
without failing. This is the failure mode to suspect whenever a plan looks empty or generic.

### `enabled` is the caller's flag

No module has an internal `enabled` flag. `local.enabled` in the root reads `<block>.enabled` and
turns it into `count = ... ? 1 : 0`; default is **false**. Every root output is `try()`-wrapped
because a disabled module has no instance to index. `terraform output enabled_modules` reports
what an environment switched on. `dns`, `ecs_cluster` and `ecs_service` accept a legacy block name
too (`route53`, `ecs_cluster`, `ecs_service`) via `coalesce`.

### Two-level merge in directory mode

`merge()` is shallow and would drop the rest of a block, so `local.cfg` re-merges every map-valued
block one level down: `module defaults (locals.tf) → common.yml → <module>.yml`. Lists are
replaced wholesale. `common.yml` is read with a bare `file()` so a missing one is a hard error;
per-module overlays are read as a **string first, then decoded** — deliberately not
`try(yamldecode(...), {})`, so malformed YAML errors instead of masquerading as "no overlay".

### `existing:` — adopting infrastructure this stack does not own

`enabled: false` plus an `existing:` block means "look it up" rather than "it does not exist".
`local.lookup` gates each data source on the owning module being disabled *and* the config naming
it, so an environment that builds everything makes no extra API call. A `count = 0` data source is
still schema-checked, hence the `"unused"` placeholders in `local.ex`.

### Module authoring pattern

`locals.tf` builds exactly one `local.<service>_config` object where every key is
`try(raw_cfg.<key>, <default>)`; `main.tf` reads **only** from that object, never from the raw
YAML. Environment-conditional defaults live in the local
(`single_nat_gateway = try(..., local.env != "prod")`). Adding a key with a `try()` default is
backward compatible; renaming or removing one is not.

Naming: `name_prefix = join("-", compact([env, app_name == "base" ? null : app_name, service_type]))`
— `app_name` and `service_type` are at the YAML root, and `"base"` is dropped, so dev + infra gives
`dev-infra`.

## Traps

- **`providers.tf` `endpoints`** — a service missing from that block does not fail under
  `localstack_endpoint`; it silently goes to **real AWS**. Adding a module means adding its service
  there in the same change.
- **`backend.tf` is empty by design**; bucket and key come from `-backend-config` at init. There
  is deliberately no `backend.hcl` at the repo root — always name one under
  `environments/<env>/`.
- **State locking is off** in every environment. Each `backend.hcl` carries two commented lines
  (`dynamodb_table` for 1.5.7, `use_lockfile` for CLI ≥ 1.10); concurrent applies can corrupt state.
- **Four module-to-module edges do not exist** (ACM cert → ALB listener, IAM roles → task
  definition, ALB ARN → WAF, SNS topic → CloudWatch `alarm_actions`), so those values must be
  literals and a full stack needs a two-pass apply. `alarm_actions` is `[]` in all three
  environments, meaning those alarms notify nobody.
- **`required_version = ">= 1.0"` is wrong in 19 of 20 modules** — all 20 use `optional()`, a 1.3
  feature. Only `eks` and the root declare `>= 1.3`.
- **`ecs_service` resolves nested blocks inconsistently**: `task_definition` uses
  `merge(nested, root)` so a root-level `task_definition:` wins, while `container_definitions` and
  `volumes` prefer the nested copy. Left alone on purpose — changing it would silently relocate
  config. It also hardcodes its log group as `/ecs/${name_prefix}`.
- `kms.rotation_period_in_days`, `waf.logging_configuration` and `s3.notification_configurations`
  survive in `locals.tf` but are no longer passed in `main.tf`; setting them in YAML does nothing.
- No secret values belong in this tree. RDS uses the AWS-managed master user secret; everything
  else is referenced by ARN. State stores those values in plaintext.

## Blast radius

Outputs are pass-throughs of pinned upstream modules, so renaming an output or changing a variable
type breaks `aws-base-infras` and `aws-application-infras`, which read this repo's state and
`source` paths (10 and 15 references respectively). Grep both before changing either. Restructuring
`modules/` into domain directories would break all 25 `source` paths.

`~/Dylan/Claude/terraform-module` is the same repo at the same commit and is the checkout the
consumer repos resolve against; changes here do not reach them until pushed and pulled there.

`staging` and `prod` configs must stay structurally identical — only values differ.
