# terraform-module

A library of reusable AWS Terraform modules. Nothing here deploys anything on its
own: there is no root composition, no environment directory and no state backend.
Each module takes typed Terraform inputs, returns outputs, and is consumed by a
configuration that lives somewhere else.

The consumer in this workspace is
[`terraform-aws-platform`](../terraform-aws-platform), which holds the values,
the environments and the state.

```
terraform-module          this repo — modules, typed inputs, no state
        ▲
        │  source = "git::…//modules/<name>?ref=v1.0.0"
        │
terraform-aws-platform    values, environments, backends, apply
```

## Usage

```hcl
module "vpc" {
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-module.git//modules/vpc?ref=v1.0.0"

  name       = "platform-dev"
  cidr_block = "10.0.0.0/16"

  tags = { Environment = "dev" }
}
```

Always pin a tag. A `ref` pointing at a branch means an upstream commit can change
a plan you did not ask for.

Start from [`examples/`](examples/): [`examples/README.md`](examples/README.md)
has a call snippet for every module, and
[`examples/complete/`](examples/complete/) is a runnable environment showing how
they wire together.

## Modules

Sixteen modules take typed inputs. Six are older and still read a YAML file
through `global_config`; they are marked below and are not the pattern to copy.

| Module | Inputs | Required | Upstream |
|---|---|---|---|
| `acm` | 8 | 2 | `terraform-aws-modules/acm/aws` 5.2.0 |
| `alb` | 26 | 4 | `terraform-aws-modules/alb/aws` 9.17.0 |
| `cloudwatch` | 10 | 1 | `hashicorp/aws` resources |
| `ec2` | 7 | 2 | `terraform-aws-modules/ec2-instance/aws` 5.8.0 |
| `ecr` | 5 | 1 | `hashicorp/aws` resources |
| `ecs-cluster` | 14 | 1 | `terraform-aws-modules/ecs/aws//modules/cluster` 5.11.4 |
| `ecs-service` | 41 | 5 | `terraform-aws-modules/ecs/aws//modules/service` 5.11.4 |
| `eks` | 23 | 4 | `terraform-aws-modules/eks/aws` 20.37.2 |
| `elasticache` | 27 | 3 | `hashicorp/aws` resources |
| `iam` | 12 | 1 | `hashicorp/aws` resources |
| `kms` | 3 | 1 | `hashicorp/aws` resources |
| `lambda` | 6 | 1 | `terraform-aws-modules/lambda/aws` 7.21.1 |
| `rds` | 36 | 6 | `terraform-aws-modules/rds/aws` 6.13.1 |
| `route53` | 7 | 1 | `hashicorp/aws` resources |
| `security-groups` | 20 | 3 | `hashicorp/aws` resources |
| `vpc` | 25 | 2 | `terraform-aws-modules/vpc/aws` 5.21.0 |
| `dynamodb` | 4 | 1 | legacy YAML interface |
| `s3` | 4 | 1 | legacy YAML interface |
| `secrets_manager` | 4 | 1 | legacy YAML interface |
| `sns` | 4 | 1 | legacy YAML interface |
| `sqs` | 4 | 1 | legacy YAML interface |
| `waf` | 4 | 1 | legacy YAML interface |

Every module has its own `README.md` with the full input and output tables.

## Requirements

| | |
|---|---|
| Terraform | `>= 1.5.7, < 2.0.0` |
| AWS provider | `>= 5.80.0, < 6.0.0` |

The provider is capped below 6.0 because the upstream module set pinned above is
the newest line that supports the 5.x provider. Moving to 6.x requires the next
major of every one of those modules — a coordinated upgrade, not a version bump.

## Conventions

- **Module directories are kebab-case** (`ecs-cluster`), module block labels are
  snake_case (`module "ecs_cluster"`).
- **Typed inputs, not config files.** A module never reads a file from disk and
  never calls `yamldecode`. Whoever calls it decides where values come from.
- **No `depends_on` between modules.** Ordering is expressed by one module's
  output feeding another's input, so Terraform derives the graph itself.
- **No provider blocks in modules.** The consumer configures the provider; a
  module that declares one cannot be used twice in the same configuration.
- **Optional inputs carry defaults.** If a module can pick a safe value, it does,
  so a caller writes only what is genuinely a decision.

## Validating a change

`examples/complete` compiles every typed module against the working tree. It
needs no AWS credentials and no state bucket:

```bash
cd examples/complete
terraform init -backend=false
terraform validate

cd ../..
terraform fmt -check -recursive
```

## Releasing

Consumers pin a tag, so a change is not visible to them until one is cut:

```bash
git tag v1.1.0 && git push origin v1.1.0
```

Bump the minor for a new module or a new optional input; bump the major for a
renamed or removed input, a renamed module directory, or a changed output — each
of those breaks a caller's plan.

## Known gaps

- **Six modules still use the legacy YAML interface** — `s3`, `sqs`, `sns`,
  `dynamodb`, `secrets_manager`, `waf`. They take `global_config` and read a
  config file rather than typed inputs, so they cannot be called the way the
  snippets above show, and `examples/complete` does not exercise them. Porting
  them is outstanding work.
- `examples/complete` does not cover `ecs-cluster` or `ecs-service`; those are
  exercised by the consuming platform repository's own root.
