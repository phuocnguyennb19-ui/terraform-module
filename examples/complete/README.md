# complete

One environment built from this library end to end: KMS and IAM, a VPC, the
security groups every workload attaches to, then ALB, EKS, EC2, RDS,
ElastiCache and Lambda on top of them.

This is the example to read first. The per-module snippets in
[`../README.md`](../README.md) show one module in isolation; this shows how they
feed each other, which is where the real decisions are.

## Run it

```bash
terraform init -backend=false
terraform validate
```

That much needs no AWS credentials and no state bucket, and it is what CI runs.
To go further, supply your own values and a real backend:

```bash
cp terraform.tfvars.example terraform.tfvars   # then edit it
terraform init
terraform plan
```

`terraform.tfvars` is gitignored. `terraform.tfvars.example` is the template —
every value in it is a placeholder, not an account you can reach.

## How the modules wire together

Dependency order is expressed entirely through module outputs feeding module
inputs. There is not one `depends_on` in `main.tf`: Terraform derives the graph
from the references themselves, and an explicit `depends_on` would only
serialise work that could otherwise run in parallel.

```
  kms ──┐
        ├──▶ vpc ──┬──▶ security_groups ──┬──▶ alb ──▶ route53 (alias record)
  iam ──┘          │                      ├──▶ eks
                   │                      ├──▶ ec2
                   │                      ├──▶ rds
                   │                      ├──▶ elasticache
                   │                      └──▶ lambda
                   │
  route53 (zone) ──▶ acm ──▶ alb ──▶ aws_route53_record.app (alias)
```

The alias record is a bare `resource` rather than an input to the `route53`
module on purpose. Routing it through the module would make route53 depend on
alb, while alb already depends on acm which depends on route53's zone id — a
cycle Terraform rejects outright. Splitting "own the zone" from "write one
record into it" is what breaks it.

## `source` here vs. `source` in your code

This example uses a **relative path** so it validates against the modules in
this working tree — that is the point of an example living beside the library:

```hcl
source = "../../modules/vpc"
```

Your own code must pin a tag instead, so an upstream change cannot alter a plan
you did not ask for:

```hcl
source = "git::https://github.com/phuocnguyennb19-ui/terraform-module.git//modules/vpc?ref=v1.0.0"
```

Never point `ref` at a branch.

## What this example does not cover

- **Remote state.** No `backend.tf`; bucket, key and locking belong to the
  configuration that names the environment, not to a library example.
- **The six legacy modules** — `s3`, `sqs`, `sns`, `dynamodb`,
  `secrets_manager`, `waf`. They still read YAML through `global_config` rather
  than typed inputs and are not wired in here.
- **ECS.** `ecs-cluster` and `ecs-service` are exercised by the platform
  repository's own root, not by this example.
