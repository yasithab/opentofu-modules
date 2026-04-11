# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Collection of 73+ reusable OpenTofu modules for AWS infrastructure. All modules target OpenTofu >= 1.11.0 and AWS provider >= 6.34.

## Commands

| Command | Purpose |
|---------|---------|
| `task format` | Format all OpenTofu code (`tofu fmt -recursive`) |
| `task validate` | Run `tofu validate` in every module (backend-less init) |
| `task lint` | Run tflint across all modules |
| `task lint-init` | Install tflint plugins (run once before first lint) |
| `task security` | Trivy CRITICAL/HIGH misconfiguration scan |
| `task ci` | Run all of the above in parallel |
| `pre-commit run --all-files` | Run all pre-commit hooks manually |

To lint or validate a single module:
```bash
cd <module-dir> && tofu init -backend=false && tofu validate
tflint --chdir <module-dir>
```

## Module Conventions

Every module follows this structure:
- `main.tf` — resources and locals
- `variables.tf` — inputs
- `outputs.tf` — outputs
- `providers.tf` — version constraints (OpenTofu + AWS provider)
- `README.md` — module documentation
- `EXAMPLES.md` — usage examples

### Required patterns in every module

**Locals block** at top of `main.tf`:
```hcl
locals {
  enabled = var.enabled
  name    = var.name
  tags    = merge(var.tags, { ManagedBy = "opentofu" })
}
```

**Standard variables** every module must have:
- `enabled` (bool, default `true`) — controls resource creation via `lifecycle { enabled = local.create }`
- `tags` (map(string), default `{}`) — merged with `{ ManagedBy = "opentofu" }` in locals

**Resource lifecycle** — all resources use `lifecycle { enabled = local.create }` (or equivalent local like `local.enabled`) instead of `count`/`for_each` for toggling.

**Outputs** use `try()` for safe extraction with empty string defaults.

### Complex modules

Some modules have submodules under `modules/` (e.g., `eks/modules/`, `cloudwatch/modules/`). Some have `wrappers/` directories for multi-instance patterns using `for_each` with defaults merging via `try()`.

## Versioning

Commit message prefix determines version bump on merge to `master`:
- `[MAJOR]` — breaking change (v1.0.0 -> v2.0.0)
- `[MINOR]` — new feature (v1.0.0 -> v1.1.0)
- No prefix — patch (v1.0.0 -> v1.0.1)

Versions in `providers.tf` are auto-updated weekly by the `weekly-update.yml` workflow using `tfupdate`.

## Security Defaults

Modules ship with secure defaults. Key ones to preserve when editing:
- Encryption at rest enabled by default (RDS Aurora, ElastiCache, OpenSearch)
- `deletion_protection` / `prevent_destroy` on stateful resources
- RDS Aurora uses write-only `master_password_wo` (never stored in state)
- EKS public access CIDRs default to `[]`
- DynamoDB point-in-time recovery enabled
- CloudWatch log retention enforced

## Key Rules

- Modules must be generic — no environment-specific values
- Never hard-code secrets; use variables or secrets management
- Reference modules via git tags, never branches
- Run `task ci` before pushing
