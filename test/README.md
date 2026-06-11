# Terratest harness

Go-based test suite that validates and plans every OpenTofu module in this
repository. Run from this directory with `go test`, or via `task test` /
`task test-plan` from the repo root.

## Test suites

| Test | Needs AWS creds | What it proves |
|------|-----------------|----------------|
| `TestValidateAllModules` | No | Every module passes `tofu validate` |
| `TestPlanAllModules` | Yes | Every module with `test/test.tfvars` plans successfully **and plans at least one resource** |
| `TestPlanFixtures` | Yes | Each optional `test/fixtures/plan-*.tfvars` plans successfully |
| `TestDisabledAllModules` | Yes | Every module with `variable "enabled"` plans cleanly with `enabled = false` and plans **zero** create/update/delete actions |
| `TestInvalidFixtures` | No | Every `test/fixtures/invalid-*.tfvars` fails plan with a variable validation error |

Common behavior:

- Module discovery walks the repo for `main.tf`, excluding `wrappers/`,
  `examples/`, `test/` and dot-directories.
- `TEST_MODULES=<mod1>,<mod2>` (comma-separated, paths relative to repo root)
  restricts any suite to specific modules.
- Plan-based suites skip locally when neither `AWS_DEFAULT_REGION` nor
  `AWS_REGION` is set, but **fail hard when `CI=true`** - in CI a missing AWS
  configuration means the OIDC credential step silently failed.

## Fixture conventions

All fixtures live inside the module directory, never in this `test/` harness
directory.

### 1. `test/test.tfvars` - default plan fixture

Realistic, complete variable values for the module's primary use case.
`TestPlanAllModules` plans every module that has one and asserts the plan
contains at least one resource change. An empty plan almost always means the
fixture left the module toggled off and is silently testing nothing.

Opt-out: if a module genuinely plans zero resources with its default fixture,
add an empty marker file `test/allow-empty-plan` next to `test.tfvars`.
(No module currently needs this.)

### 2. `test/fixtures/plan-<case>.tfvars` - additional plan paths

Optional. One file per extra plan path you want exercised (alternate feature
toggles, secondary resource shapes, ...). Each file must be a **complete,
standalone** variable set - it is passed to `tofu plan` as the only var file.
Subtests are named `<module>/plan-<case>`.

### 3. `test/fixtures/invalid-<case>.tfvars` - negative tests

A fixture that MUST fail plan because exactly one variable validation rejects
it. `TestInvalidFixtures` runs `tofu plan -var-file=<fixture>` and asserts:

1. the plan fails, and
2. the output contains `Invalid value for variable` (so a plan that fails for
   an unrelated reason - missing credentials, type error - does not pass
   vacuously).

Rules for writing one:

- Include the module's normally-required happy-path variables so that **only**
  the targeted validation fails. Add a leading comment naming the validation
  being targeted.
- Verify locally that exactly one validation fires:
  `cd <module> && tofu plan -var-file=test/fixtures/invalid-<case>.tfvars`

No AWS credentials are needed: variable validations are evaluated during plan
expression evaluation, before provider authentication. Verified empirically -
without credentials a valid fixture fails with credential errors only, while
an invalid fixture additionally reports `Invalid value for variable`, which is
why the suite asserts on that string instead of the exit code.

### Disabled-path testing (no fixture needed)

`TestDisabledAllModules` automatically covers every module that has both
`test/test.tfvars` and `variable "enabled"` in `variables.tf`: it plans with
the default fixture plus a final `enabled = false` var-file override (last
var file wins, so an `enabled = true` inside `test.tfvars` is still
overridden) and asserts the plan succeeds with zero create/update/delete
actions. This catches the historical bug class where `enabled = false` breaks
the plan or still creates resources.

## Running locally

```bash
cd test

# No AWS credentials needed
go test -run 'TestValidateAllModules|TestInvalidFixtures' -count=1 -timeout 40m

# With AWS credentials (read-only; plan never creates resources)
go test -run 'TestPlanAllModules|TestPlanFixtures|TestDisabledAllModules' -count=1 -timeout 60m

# Single module
TEST_MODULES=sns go test -run TestInvalidFixtures -count=1 -v
```
