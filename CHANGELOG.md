# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **OPA policy guardrails** - `policy/deny_public_s3.rego`, `policy/require_encryption.rego`, `policy/require_deletion_protection.rego` for plan-level enforcement via Conftest
- **OpenTofu check blocks** - runtime security assertions in `elasticache`, `dynamodb`, `s3`, `redshift`, `redshift-serverless`, `mq`, `msk`, `memorydb`, `eks`, `vpc`, `cdk-bootstrap`
- **CloudWatch log groups** for `neptune` and `documentdb` modules
- **Security group support** for `neptune` module (standalone rules)
- `task policy` command in Taskfile for OPA/Conftest policy checks

### Changed
- **cdk-bootstrap** - complete rewrite from `null_resource` + `local-exec` anti-pattern to native OpenTofu resources (S3, ECR, KMS, 5 IAM roles, SSM parameter)
- **Provider constraints** - standardized all modules to `>= 6.38, < 7.0` (was exact pin `6.38.0` in most modules)
- **Standalone security group rules** - migrated `headscale`, `headscale/subnet-router`, and `fsx` from deprecated inline rules / `aws_security_group_rule` to `aws_vpc_security_group_ingress_rule` / `aws_vpc_security_group_egress_rule`
- **Type-narrowed `security_group_rules`** - replaced `type = any` with typed `map(object({...}))` using `optional()` defaults across 14 modules: `documentdb`, `neptune`, `opensearch`, `mq`, `elasticache`, `rds`, `rds-aurora`, `redshift`, `redshift-serverless`, `efs`, `batch`, `ecs/service`, `ecs/cluster`, `vpc/vpc-endpoints`
- **Sensitive markers** - added `sensitive = true` to `secret-manager` secret values, `rds` and `rds-aurora` master user secrets, and `fsx` ONTAP SVM config
- **Deprecated attribute fix** - replaced `data.aws_region.*.name` with `data.aws_region.*.region` in `cdk-bootstrap` and `cloudwatch/modules/synthetics`
- **Description fix** - corrected `rds-aurora` `deletion_protection` default description from "false" to "true"
- Added missing `tls` provider constraint to `key-pair/providers.tf`

### Removed
- Removed unused `variable "region"` from 28 modules
- Removed unused data sources (`aws_region`, `aws_caller_identity`, `aws_partition`) from 7 modules
- Removed unused locals (`tags`, `name`, `account_id`, `has_domain`, `has_custom_domain`) from 8 modules
- Removed unused variables (`allow_lists`, `key_type`, `name_prefix`, `customer_algorithm`, `customer_key`, `requestor_vpc_tags`) from 5 modules
- Removed cascading unused `variable "tags"` from 5 modules and `variable "name"` from 4 modules where resources don't support them
- Removed `hashicorp/null` provider dependency from `cdk-bootstrap`

## [v1.0.14] - 2026-03-31

### Changes
- [module-refactor-nat] NAT module refactor (#18)

## [v1.0.13] - 2026-03-31

### Changes
- [module-refactor-nat] NAT module refactor (#17)

## [v1.0.12] - 2026-03-31

### Changes
- [master] NAT module refactor

## [v1.0.11] - 2026-03-31

### Changes
- chore: weekly version update - OpenTofu 1.11.5, AWS provider 6.38.0 (#16)

## [v1.0.10] - 2026-03-31

### Changes
- [master] NAT module refactor
- chore(deps): bump opentofu/setup-opentofu from 1 to 2 in the actions group (#14)

## [v1.0.9] - 2026-03-25

### Changes
- chore: weekly version update - OpenTofu 1.11.5, AWS provider 6.37.0 (#13)

## [v1.0.8] - 2026-03-25

### Changes
- [fck-nat] Adding fck-nat module (#15)

## [v1.0.7] - 2026-03-20

### Changes
- [master] Fix drift

## [v1.0.6] - 2026-03-13

### Changes
- [fix-modules] Fixing modules (#12)

## [v1.0.5] - 2026-03-12

### Changes
- [update-readme] Updating readme (#11)
- fix: use direct merge for Dependabot (no branch protection) (#10)
- ci: auto-merge Dependabot PRs after checks pass (#9)

## [v1.0.4] - 2026-03-12

### Changes
- fix: fallback to github.token when GH_TOKEN is unavailable (#8)
- chore(deps): bump the actions group with 2 updates (#7)
- ci: optimize workflows and add dependabot (#6)
- [pipeline] Fix release workflow and standardize GH_TOKEN (#5)

## [v1.0.3] - 2026-03-12

### Changes
- [fix-pipelines] Fix actions pipelines (#4)
- [rds] Adding rds module (#3)
- [patch-modules] Fixing security concerns (#2)

## [v1.0.2] - 2026-03-10

### Changes
- chore: apply tofu fmt and terraform-docs [skip ci]
- [module-refactor] Updating modules

## [v1.0.1] - 2026-03-08

### Changes
- [master] Initial
- [master] Initial
- [master] Initial

