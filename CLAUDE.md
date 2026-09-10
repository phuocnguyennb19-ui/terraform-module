# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A **library** of 22 reusable AWS Terraform modules under `modules/`. Nothing here deploys
anything: there is no root composition, no environment directory, no state backend and no
provider block. Each module takes typed Terraform inputs and returns outputs.

The consumer is [`../terraform-aws-platform`](../terraform-aws-platform), which holds the
values, the environments and the state, and pulls modules by tag:

```hcl
source = "git::https://github.com/phuocnguyennb19-ui/terraform-module.git//modules/vpc?ref=v1.0.0"
```

Because the source is a `//modules/<name>` subdirectory, a consumer only ever receives that one
directory — never the repository root.

`README.md` is the reference: the module table with upstream pins, the version constraints and
the release rules. Each module has its own `README.md` with full input and output tables,
generated from `variables.tf` and `outputs.tf`.

## Two interfaces live here — do not mix them

**Typed (16 modules)** — `acm`, `alb`, `cloudwatch`, `ec2`, `ecr`, `ecs-cluster`,
`ecs-service`, `eks`, `elasticache`, `iam`, `kms`, `lambda`, `rds`, `route53`,
`security-groups`, `vpc`. Ordinary Terraform variables. This is the contract.

**Legacy YAML (6 modules)** — `s3`, `sqs`, `sns`, `dynamodb`, `secrets_manager`, `waf`. These
still take a `global_config` object and read a config file through `yamldecode`, a holdover from
when this repo carried its own root. They cannot be called the way the README snippets show,
`examples/complete` does not exercise them, and **they are not the pattern to copy**. Porting
them to typed inputs is outstanding work.

## Commands

No Makefile and no CI in this repo. `examples/complete` is what proves a change compiles — it
sources every typed module by relative path, so it validates against the working tree:

```bash
cd examples/complete
terraform init -backend=false      # no AWS credentials, no state bucket needed
terraform validate

cd ../..
terraform fmt -check -recursive
```

`terraform plan` in `examples/complete` needs real credentials and a `terraform.tfvars`; copy
`terraform.tfvars.example` first. `terraform.tfvars` is gitignored.

## Conventions

- Module directories are **kebab-case** (`ecs-cluster`); module block labels are snake_case
  (`module "ecs_cluster"`). The six legacy modules keep snake_case directory names.
- **A module never reads a file from disk** and never calls `yamldecode`. Whoever calls it
  decides where values come from. (The six legacy modules violate this; that is the bug, not
  the precedent.)
- **No provider blocks in modules.** A module that declares one cannot be used twice in the
  same configuration.
- **No `depends_on` between modules.** Ordering comes from one module's output feeding
  another's input, so Terraform derives the graph itself.
- Optional inputs carry defaults, so a caller writes only what is genuinely a decision.
- Terraform `>= 1.5.7`, AWS provider `>= 5.80.0, < 6.0.0`, declared per module in
  `modules/*/versions.tf`.

## Changing a module

1. Read the module's `README.md` and `variables.tf` first — an input may already exist.
2. Change `variables.tf`, `main.tf`, `outputs.tf`.
3. Regenerate that module's `README.md` and the snippet in `examples/README.md`; both are
   derived from `variables.tf` and go stale silently.
4. `terraform validate` in `examples/complete`, then `terraform fmt -check -recursive`.

## Releasing

Consumers pin a tag, so a change is invisible to them until one is cut:

```bash
git tag v1.1.0 && git push origin v1.1.0
```

Minor for a new module or a new optional input. **Major** for a renamed or removed input, a
renamed module directory, or a changed output — each of those breaks a caller's plan.

Never point a consumer's `ref` at a branch.

## Known gaps

- The six legacy modules above.
- `examples/complete` does not cover `ecs-cluster` or `ecs-service`; those are exercised by the
  platform repository's own root.
