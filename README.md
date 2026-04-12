# OpenTofu Modules

A collection of 128+ reusable [OpenTofu](https://opentofu.org/) modules for AWS infrastructure, targeting AWS provider >= 6.34.

## Table of Contents

1. [Introduction](#introduction)
2. [Requirements](#requirements)
3. [Modules Structure](#modules-structure)
4. [Module List](#module-list)
5. [How to Use](#how-to-use)
6. [Development](#development)
7. [CI / CD](#ci--cd)
8. [Best Practices](#best-practices)
9. [What to Do](#what-to-do)
10. [What Not to Do](#what-not-to-do)
11. [Security Defaults](#security-defaults)
12. [Configuration Files](#configuration-files)
13. [Versioning](#versioning)
14. [Contributing](#contributing)

## Introduction

This repository provides reusable OpenTofu modules that follow industry best practices. Whether you're a beginner or an experienced developer, these modules are designed to simplify your OpenTofu workflow and ensure consistency across your infrastructure codebase.

## Requirements

| Tool | Minimum version |
|------|----------------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.11.0 |
| [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest) | >= 6.34 |
| [Task](https://taskfile.dev/installation/) | >= 3.0 |
| [tflint](https://github.com/terraform-linters/tflint#installation) | latest |
| [Go](https://go.dev/doc/install) | >= 1.22 |
| [Trivy](https://aquasecurity.github.io/trivy/latest/getting-started/installation/) | latest |
| [pre-commit](https://pre-commit.com/#install) | >= 3.0 |

## Modules Structure

Each module is located in its own directory under the root of the repository. For example:

- `vpc/`
- `s3/`
- `eks/`

Each module folder includes the following files:

- `main.tf` - Primary configuration file for the module.
- `variables.tf` - Defines input variables for the module.
- `outputs.tf` - Specifies the module's outputs.
- `providers.tf` - Specifies the required OpenTofu and provider version constraints.
- `README.md` - Documentation specific to the module.

Some modules contain additional files for organisational clarity (e.g. `iam.tf` for IAM-specific resources).

## Module List

| Module | Description |
|--------|-------------|
| `acm/certificate-manager` | ACM certificate with DNS validation |
| `amp` | Amazon Managed Prometheus workspace + scraper |
| `api-gateway` | API Gateway REST API with CloudWatch logging |
| `backup` | AWS Backup plan, vault, and IAM role |
| `chatbot-slack` | AWS Chatbot Slack and Teams channel configurations |
| `cloudfront` | CloudFront distribution |
| `codeconnections` | CodeConnections + host |
| `dynamodb` | DynamoDB table with resource policy |
| `ec2` | EC2 instance |
| `ecr` | ECR repository |
| `ecs/cluster` | ECS cluster |
| `ecs/service` | ECS service + task definition |
| `efs` | EFS file system |
| `eks` | EKS cluster |
| `elasticache` | ElastiCache replication group |
| `elb` | Application / Network load balancer |
| `eventbridge` | EventBridge rule and target |
| `github/oidc` | GitHub OIDC identity provider |
| `glue` | Glue job and crawler |
| `iam-identity-center` | IAM Identity Center permission sets + trusted token issuer |
| `kinesis-firehose` | Kinesis Firehose delivery stream (incl. Iceberg destination) |
| `kinesis-stream` | Kinesis data stream |
| `kms` | KMS key (+ external / replica variants) |
| `lambda` | Lambda function |
| `mq` | Amazon MQ broker |
| `opensearch` | OpenSearch domain |
| `rds-aurora` | Aurora cluster with write-only password |
| `rds-instance` | RDS instance |
| `redshift` | Redshift cluster |
| `redshift-serverless` | Redshift Serverless namespace + workgroup |
| `route53` | Route53 hosted zone and records |
| `resolver-endpoints` | Route53 Resolver inbound/outbound endpoints |
| `s3` | S3 bucket with notifications, object lock, and lifecycle |
| `security-group` | Security group using ingress/egress rule resources |
| `ses` | SES email identity and configuration set |
| `sns` | SNS topic |
| `sqs` | SQS queue with redrive allow policy |
| `ssm` | SSM Parameter Store parameter |
| `step-functions` | Step Functions state machine |
| `transit-gateway` | Transit Gateway and attachments |
| `transit-gateway/route-table` | Transit Gateway route table |
| `vpc` | VPC with subnets, NAT gateway, and flow logs |
| `vpc-endpoints` | VPC interface and gateway endpoints |
| `vpn-site-to-site` | Site-to-site VPN with Secrets Manager preshared keys |
| `waf` | WAFv2 web ACL |
| *(and more…)* | |

## How to Use

Reference a module by selecting a specific tag with a shallow clone - **never point at a branch**:

```hcl
# select a specific tag and do shallow clone
module "vpc" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//vpc?depth=1&ref=master"

  name    = "my-vpc"
  enabled = true
  tags    = { Environment = "production" }
}
```

Replace `vpc` with the name of the module directory and `v2.0.0` with the desired release tag. All modules follow [semantic versioning](#versioning).

All resources respect the `enabled` variable via OpenTofu's `lifecycle { enabled = ... }` meta-argument, so modules can be toggled without removing them from state.

## Development

### Available Tasks

```bash
task --list
```

| Task | Description |
|------|-------------|
| `task format` | Format all OpenTofu code recursively |
| `task validate` | Run `tofu validate` in every module (backend-less) |
| `task lint` | Run tflint across all modules |
| `task test` | Run Terratest validate on all modules (no AWS creds needed) |
| `task test-plan` | Run Terratest plan on all modules (requires AWS credentials) |
| `task security` | Run Trivy CRITICAL/HIGH misconfiguration scan |
| `task ci` | Run all of the above |

### Pre-commit Hooks

Install the hooks once after cloning:

```bash
pre-commit install
```

On every `git commit` the following run automatically:

- `terraform_fmt` - format check
- `terraform_validate` - per-module validation (no backend)
- `terraform_tflint` - lint using `.tflint.hcl`
- Standard file hygiene (trailing whitespace, end-of-file, YAML syntax, merge conflicts)

Run manually against all files:

```bash
pre-commit run --all-files
```

### Linting

tflint uses the AWS ruleset plugin (`tflint-ruleset-aws` v0.45.0) configured in `.tflint.hcl`.

```bash
tflint --init
tflint --chdir <module>/
```

### Security Scanning

Trivy scans all module configs for CRITICAL and HIGH misconfigurations:

```bash
task security
```

## CI / CD

### PR Workflow (`.github/workflows/pr.yml`)

Runs on every pull request:

1. Format (`task format`) — auto-commits any formatting changes
2. Validate all modules (`task validate`)
3. Lint with tflint (`task lint`)
4. Terratest validate — Go-based syntax/type validation
5. Terratest plan — validates all modules against real AWS APIs via OIDC (read-only, no resources created)
6. Trivy security scan (fails on CRITICAL/HIGH)

### Release Workflow (`.github/workflows/release.yml`)

Runs on every push to `master`:

1. Validate all modules (`task validate`)
2. Terratest validate + plan (all modules, via AWS OIDC)
3. Auto-create semantic version tag based on commit message prefix
4. Create GitHub release with auto-generated notes

### Module Health Check (`.github/workflows/module-health.yml`)

Runs monthly (1st of each month):

1. Validates all modules
2. Detects modules missing README
3. Creates a GitHub issue if problems are found

## Best Practices

- **Keep Modules Focused:** Each module should focus on a specific task or resource type.
- **Use Version Control:** Tag releases and document changes to provide a history of modifications.
- **Encapsulate Complexity:** Abstract complex logic within modules to present a simple interface.

## What to Do

- **Do** follow semantic versioning for module tags.
  - Merging a PR with a commit message that begins with `[MAJOR]` will automatically increment the major version of the tag.
  - Merging a PR with a commit message that starts with `[MINOR]` will automatically increment the minor version of the tag.
  - If neither `[MAJOR]` nor `[MINOR]` is specified at the beginning of the commit message, the patch version will be incremented by 1.
- **Do** document every module within its corresponding `README.md` file with usage examples covering all patterns.
- **Do** use descriptive variable names and output values.
- **Do** run `pre-commit install` after cloning so local checks run before every commit.
- **Do** run `task ci` locally before pushing to catch format, validation, lint, and security issues early.

## What Not to Do

- **Do not** hard-code sensitive information like passwords in the code. Use variables or secrets management.
- **Do not** create overly large modules that try to do too much.
- **Do not** put environment-specific information in modules; modules must be generic across all environments.
- **Do not** ignore warnings or errors reported by OpenTofu.

## Security Defaults

All modules ship with secure defaults:

- Encryption at rest enabled by default (RDS Aurora, ElastiCache, OpenSearch)
- `deletion_protection` enabled by default on stateful resources (RDS, S3, KMS, DynamoDB, EFS, ElastiCache, OpenSearch, Redshift)
- RDS Aurora uses write-only `master_password_wo` (never stored in state)
- EKS public access CIDRs default to `[]` (no public access)
- DynamoDB point-in-time recovery enabled by default
- CloudWatch log retention enforced on all log groups

## Configuration Files

| File | Purpose |
|------|---------|
| `.tflint.hcl` | tflint rules and AWS plugin configuration |
| `.pre-commit-config.yaml` | Pre-commit hook definitions |
| `Taskfile.yml` | Task runner definitions |

## Versioning

This repository follows [Semantic Versioning](https://semver.org/). Tags are created automatically when a PR is merged to `master`, based on the commit message prefix:

| Commit message prefix | Version bump | Example |
|-----------------------|-------------|---------|
| `[MAJOR]` | Major - breaking change | `v1.0.0` → `v2.0.0` |
| `[MINOR]` | Minor - backwards-compatible new feature | `v1.0.0` → `v1.1.0` |
| *(no prefix)* | Patch - bug fix / small improvement | `v1.0.0` → `v1.0.1` |

## Contributing

We welcome contributions to enhance these modules! Please fork the repository and submit a pull request with your changes. Make sure to follow the existing code style and include documentation updates.

## License

Internal use only.
