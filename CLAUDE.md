# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Collection of 128+ reusable OpenTofu modules for AWS infrastructure. All modules target OpenTofu >= 1.11.0 and AWS provider >= 6.49, < 7.0.

## Commands

| Command | Purpose |
|---------|---------|
| `task format` | Format all OpenTofu code (`tofu fmt -recursive`) |
| `task validate` | Run `tofu validate` in every module (backend-less init) |
| `task lockfiles` | (Re)generate `.terraform.lock.hcl` in every module |
| `task lint` | Run tflint across all modules |
| `task lint-init` | Install tflint plugins (run once before first lint) |
| `task test-plan` | Run Terratest plan on all modules (requires AWS creds) |
| `task offline-test` | Run native `tofu test` (mocked providers, no AWS creds) in every module with `tests/*.tftest.hcl` |
| `task security` | Trivy CRITICAL/HIGH misconfiguration scan |
| `task docs` | Regenerate README Requirements/Providers/Inputs/Outputs tables via terraform-docs (`.terraform-docs.yml`) |
| `task new-module -- <name>` | Scaffold a new module skeleton (refuses if the directory exists) |
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

### Test fixture conventions (see test/README.md)

- `test/test.tfvars` - default plan fixture; the plan must contain at least one resource change (opt-out marker: `test/allow-empty-plan`)
- `test/fixtures/plan-<case>.tfvars` - optional extra plan paths; each is a complete standalone var set, planned on its own
- Negative tests are hand-written `run "invalid_<case>"` blocks in `tests/offline.tftest.hcl`: `command = plan` with the bad values inline and `expect_failures = [var.<name>]` targeting the variable whose validation must fire; include the happy-path required vars so only the targeted validation fails (no AWS creds needed)
- The disabled-path guarantee (module plans cleanly with `enabled = false`) is enforced by each module's `tests/offline.tftest.hcl` (`run "plan_disabled"`, mocked providers) - runs on every PR, no AWS creds needed
- When adding a variable validation, add a matching `run "invalid_*"` block to prove it fires - the generator preserves these on regeneration

### Offline tests (`tests/offline.tftest.hcl`)

Every module has a generated native `tofu test` file that plans the module
creds-free with all providers mocked (`mock_provider`): `run "plan_enabled"`
uses the `test/test.tfvars` values, `run "plan_disabled"` adds
`enabled = false` (wrappers only get a minimal enabled run). Do not edit the
generated runs by hand — regenerate with `python3
scripts/generate-offline-tests.py [module ...]` (add `--test --fix` to
auto-derive mock defaults from format-validation errors). Hand-written
`run "invalid_*"` negative tests in the same file are preserved verbatim on
regeneration. Per-module mock overrides live in `scripts/offline-test-mocks/`.
See test/README.md "Offline tests".

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

**`try()` semantics** - `try()` only falls back on *error*, not on `null` — use `coalesce()` or a ternary for null fallbacks on `optional()` attributes.


### Derived locals naming

Modules that conditionally create sub-resources use `local.create_<thing>` derived locals (e.g., `local.create_security_group = local.enabled && var.create_security_group`). The base toggle is always `local.enabled`; the `create_` prefix is reserved for sub-resource flags only.

### Known intentional patterns

- **DynamoDB 3-copy table**: `dynamodb/main.tf` has three `aws_dynamodb_table` resources (`this`, `autoscaled`, `autoscaled_gsi_ignore`) differentiated only by `lifecycle { ignore_changes }`. This is the correct workaround for OpenTofu's limitation that `ignore_changes` cannot be dynamic. Do not consolidate.

### Complex modules

Some modules have submodules under `modules/` (e.g., `eks/modules/`, `cloudwatch/modules/`, `iam/`). Some have `wrappers/` directories for multi-instance patterns using `for_each` with defaults merging via `try()`.

## CI/CD

### PR Workflow
1. Format check (`tofu fmt -check -recursive`) - fails on drift; run `task format` locally to fix
2. Validate all modules (`task validate`)
3. Lint with tflint (`task lint`)
4. Offline `tofu test` - native tests with mocked providers, all modules, enabled + disabled paths plus `expect_failures` negative-validation runs (no AWS creds)
5. Terratest plan - Go-based plan + fixture validation via AWS OIDC (read-only, no resources created)
6. Trivy security scan (fails on CRITICAL/HIGH)

### Master Merge
1. Validate all modules (`task validate`)
2. Offline `tofu test` (all modules, mocked providers) + Terratest plan suites (via AWS OIDC)
3. Auto-create semantic version tag and GitHub release

## Versioning

Commit message prefix determines version bump on merge to `master`:
- `[MAJOR]` - breaking change (v1.0.0 -> v2.0.0)
- `[MINOR]` - new feature (v1.0.0 -> v1.1.0)
- No prefix - patch (v1.0.0 -> v1.0.1)

Versions in `providers.tf` use bounded floor constraints (`>= 6.49, < 7.0`) for the AWS provider — never exact pins in reusable modules. Update manually when raising the minimum provider version. Non-AWS providers use bounded floors too (e.g. `>= 4.0, < 5.0`).

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
