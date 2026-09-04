# modules

One config file per module, plus `common.yml`. Two ways to use it.

## As a reference

`<module>.yml` lists every key that module's `locals.tf` reads. Omitted keys fall back to the
module's default. Filenames match the directory under `modules/`.

## As a config_dir

The directory is a valid layered config:

```bash
terraform plan -var="config_dir=examples/modules"
```

The root reads `common.yml` (required) plus an optional `<module>.yml` for each module.
Precedence, lowest to highest:

```
module defaults (locals.tf)  ->  common.yml  ->  <module>.yml
```

The merge is two levels deep, so a per-module file overrides individual keys inside a block
without discarding the rest of it. Lists are replaced wholesale.

`common.yml` deliberately sets defaults that two module files override, to show this working:

| Key | common.yml | override | result |
|---|---|---|---|
| `kms.deletion_window_in_days` | `30` | `kms.yml` → `7` | `7` |
| `s3.force_destroy` | `false` | `s3.yml` → `true` | `true` |
| `s3.versioning_enabled` | `true` | not overridden | `true` — survives |

Every module is `enabled: false` here. Nothing is built until you switch one on.
