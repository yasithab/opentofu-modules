# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Collection of 128+ reusable OpenTofu modules for AWS infrastructure. All modules target OpenTofu >= 1.11.0 and AWS provider >= 6.38, < 7.0.

## Commands

| Command | Purpose |
|---------|---------|
| `task format` | Format all OpenTofu code (`tofu fmt -recursive`) |
| `task validate` | Run `tofu validate` in every module (backend-less init) |
| `task lint` | Run tflint across all modules |
| `task lint-init` | Install tflint plugins (run once before first lint) |
| `task test` | Run Terratest validate on all modules (no AWS creds needed) |
| `task test-plan` | Run Terratest plan on all modules (requires AWS creds) |
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
- `main.tf` - resources and locals
- `variables.tf` - inputs
- `outputs.tf` - outputs (expose all useful resource attributes via `try()`)
- `providers.tf` - version constraints (OpenTofu + AWS provider)
- `README.md` - module documentation with usage examples covering all patterns
- `test/test.tfvars` - realistic variable values for Terratest `tofu plan` in CI

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
- `enabled` (bool, default `true`) - controls resource creation via `lifecycle { enabled = local.enabled }`
- `tags` (map(string), default `{}`) - merged with `{ ManagedBy = "opentofu" }` in locals

**Resource lifecycle** - resources use `lifecycle { enabled = local.enabled }` for toggling. **Important:** `lifecycle { enabled }` is mutually exclusive with `for_each`/`count`. Resources that use `for_each` must use the `if local.enabled` filter pattern instead (e.g., `for_each = { for k, v in var.items : k => v if local.enabled }`). Never use `lifecycle { enabled }` on `data` sources.

**Outputs** use `try()` for safe extraction with empty string defaults. Expose all useful resource attributes for composability.


### Derived locals naming

Modules that conditionally create sub-resources use `local.create_<thing>` derived locals (e.g., `local.create_security_group = local.enabled && var.create_security_group`). The base toggle is always `local.enabled`; the `create_` prefix is reserved for sub-resource flags only.

### Known intentional patterns

- **DynamoDB 3-copy table**: `dynamodb/main.tf` has three `aws_dynamodb_table` resources (`this`, `autoscaled`, `autoscaled_gsi_ignore`) differentiated only by `lifecycle { ignore_changes }`. This is the correct workaround for OpenTofu's limitation that `ignore_changes` cannot be dynamic. Do not consolidate.

### Complex modules

Some modules have submodules under `modules/` (e.g., `eks/modules/`, `cloudwatch/modules/`, `iam/`). Some have `wrappers/` directories for multi-instance patterns using `for_each` with defaults merging via `try()`.

## CI/CD

### PR Workflow
1. Format (`task format`) - auto-commits fixes
2. Validate all modules (`task validate`)
3. Lint with tflint (`task lint`)
4. Terratest validate - Go-based syntax/type validation (no AWS creds)
5. Terratest plan - Go-based plan validation via AWS OIDC (read-only, no resources created)
6. Trivy security scan (fails on CRITICAL/HIGH)

### Master Merge
1. Validate all modules (`task validate`)
2. Terratest validate + plan (all modules, via AWS OIDC)
3. Auto-create semantic version tag and GitHub release

## Versioning

Commit message prefix determines version bump on merge to `master`:
- `[MAJOR]` - breaking change (v1.0.0 -> v2.0.0)
- `[MINOR]` - new feature (v1.0.0 -> v1.1.0)
- No prefix - patch (v1.0.0 -> v1.0.1)

Versions in `providers.tf` use bounded floor constraints (`>= 6.38, < 7.0`) for the AWS provider — never exact pins in reusable modules. Update manually when raising the minimum provider version.

`.terraform.lock.hcl` files are committed to ensure reproducible builds. Regenerate with `tofu init -upgrade` when bumping provider constraints.

## Security Defaults

Modules ship with secure defaults. Key ones to preserve when editing:
- Encryption at rest enabled by default (RDS Aurora, ElastiCache, OpenSearch)
- `deletion_protection` enabled by default on stateful resources
- RDS Aurora uses write-only `master_password_wo` (never stored in state)
- EKS public access CIDRs default to `[]`
- DynamoDB point-in-time recovery enabled
- CloudWatch log retention enforced
- Password/secret variables marked `sensitive = true`
- Outputs exposing full resource objects (e.g., `cluster_instances`) marked `sensitive = true`

## Key Rules

- Modules must be generic - no environment-specific values
- Never hard-code secrets; use variables or secrets management
- Reference modules via git tags, never branches
- Run `task ci` before pushing
