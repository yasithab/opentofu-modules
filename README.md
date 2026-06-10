# OpenTofu Modules

A collection of 128+ reusable [OpenTofu](https://opentofu.org/) modules for AWS infrastructure, targeting AWS provider >= 6.49, < 7.0.

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
| [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest) | >= 6.49, < 7.0 |
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
| `acm` | ACM certificate with DNS/email validation (`certificate-manager` submodule) |
| `amp` | Amazon Managed Prometheus workspace, alert manager, and rule groups |
| `api-gateway` | API Gateway REST API with CloudWatch logging and Private Link |
| `app-runner` | App Runner service with IAM roles, VPC networking, and custom domains |
| `appconfig` | AppConfig applications, environments, and configuration profiles |
| `appsync` | AppSync GraphQL API with data sources and resolvers |
| `athena` | Athena workgroups, named queries, data catalogs, and databases |
| `autoscaling` | Auto Scaling Group with launch templates and scaling policies |
| `aws-config` | AWS Config recorder, rules, and delivery channel (+ `conformance-pack` submodule) |
| `aws-flow-logs` | Flow logs for VPC/subnet/ENI/TGW/NAT to CloudWatch, S3, or Firehose |
| `backup` | AWS Backup plan, vault, and IAM role |
| `bastion` | Bastion host (SSM and public SSH modes) |
| `batch` | AWS Batch compute environments, job queues, and job definitions |
| `cdk-bootstrap` | CDK bootstrap resources provisioned natively in OpenTofu |
| `chatbot-slack` | AWS Chatbot Slack and Teams channel configurations |
| `cloudformation-stackset` | CloudFormation StackSets and stack instances |
| `cloudfront` | CloudFront distributions, policies, functions, and signing keys |
| `cloudmap` | Cloud Map namespaces and service discovery services |
| `cloudwatch` | CloudWatch log groups (+ alarm, dashboard, metric, synthetics submodules) |
| `codebuild-runners` | CodeBuild projects as GitHub Actions self-hosted runners |
| `codeconnections` | CodeConnections + host |
| `cognito` | Cognito user pool for OIDC/OAuth2 authentication |
| `cost-usage-report` | Cost and Usage Report definitions with S3 delivery |
| `dms` | DMS replication instances, endpoints, and tasks |
| `documentdb` | DocumentDB cluster with encryption and log exports |
| `dynamodb` | DynamoDB table with autoscaling, global tables, and PITR |
| `ec2` | EC2 instance with spot, IAM instance profile, and EIP support |
| `ecr` | ECR repository (private and public) |
| `ecs` | ECS (`cluster`, `service`, `container-definition` submodules) |
| `efs` | EFS file system with mount targets and access points |
| `eks` | EKS cluster (+ `karpenter`, node-group, fargate-profile submodules) |
| `eks-pod-identity` | EKS Pod Identity associations with dedicated IAM roles |
| `elasticache` | ElastiCache replication group (+ `serverless-cache`, `user-group` submodules) |
| `emr-serverless` | EMR Serverless applications for Spark and Hive |
| `eventbridge` | EventBridge buses, rules, targets, schedules, and pipes |
| `fck-nat` | Cost-effective NAT instance using the fck-nat AMI |
| `firewall-manager` | Firewall Manager WAFv2 policies across an Organization |
| `fsx` | FSx file systems (Lustre, ONTAP, OpenZFS, Windows) |
| `github` | GitHub integration (`oidc` provider, `actions` IAM roles submodules) |
| `global-accelerator` | Global Accelerator with listeners and endpoint groups |
| `guardduty` | GuardDuty threat detection and finding exports |
| `headscale` | Self-hosted Headscale server on EC2 (+ `subnet-router` submodule) |
| `iam` | IAM building blocks (`group`, `policy`, `role`, `user` submodules) |
| `iam-identity-center` | IAM Identity Center users, groups, permission sets, and assignments |
| `inspector` | Amazon Inspector vulnerability scanning |
| `key-pair` | EC2 key pair with optional TLS private key generation |
| `kinesis-firehose` | Kinesis Firehose delivery stream (incl. Iceberg destination) |
| `kinesis-stream` | Kinesis data stream with consumers and KMS encryption |
| `kms` | KMS key (standard, external, replica, multi-region) (+ `wrappers`) |
| `lake-formation` | Lake Formation settings, registration, and permissions |
| `lambda` | Lambda function and layers (+ alias, deploy, docker-build submodules and `wrappers`) |
| `loadbalancer` | ALB / NLB / GWLB with listeners and target groups |
| `macie` | Macie sensitive data discovery and classification jobs |
| `managed-grafana` | Amazon Managed Grafana workspace |
| `managed-prefix-list` | EC2 managed prefix list with optional RAM sharing |
| `memorydb` | MemoryDB cluster with ACLs and snapshots |
| `mq` | Amazon MQ broker (RabbitMQ and ActiveMQ) |
| `msk` | MSK provisioned and serverless clusters |
| `neptune` | Neptune graph database cluster |
| `opensearch` | OpenSearch domain with VPC and fine-grained access control |
| `organizations` | AWS Organizations, OUs, accounts, and delegated admins |
| `ram` | RAM resource shares |
| `rds` | RDS instance with replicas, parameter and option groups |
| `rds-aurora` | Aurora cluster with write-only password |
| `rds-proxy` | RDS Proxy connection pooling |
| `redshift` | Redshift cluster |
| `redshift-serverless` | Redshift Serverless namespace + workgroup |
| `route53` | Route 53 (`zone`, `records`, `delegation-sets`, `resolver-endpoints`, `resolver-rule-associations` submodules) |
| `s3` | S3 bucket with notifications, object lock, and lifecycle |
| `s3-object` | S3 object upload/copy with encryption and object lock |
| `secret-manager` | Secrets Manager secret with rotation and replication (+ `wrappers`) |
| `security-group` | Security group using ingress/egress rule resources |
| `security-hub` | Security Hub standards and multi-region aggregation |
| `service-control-policy` | Organizations SCPs with pre-built guardrails |
| `sns` | SNS topic |
| `sqs` | SQS queue with redrive allow policy |
| `ssm` | Bulk SSM Parameter Store read/write |
| `ssm-parameter-store` | Single SSM parameter with write-only secret support |
| `step-functions` | Step Functions state machine |
| `tag-policy` | Organizations tag policies |
| `timestream` | Timestream databases and tables |
| `transfer-family` | Transfer Family servers (SFTP, FTPS, FTP, AS2) |
| `transit-gateway` | Transit Gateway (+ `route-table`, `vpc-attachments` submodules) |
| `vpc` | VPC with subnets, NAT gateway, and flow logs (+ `vpc-endpoints`, `vpc-peering` submodules) |
| `vpn-site-to-site` | Site-to-site VPN with Secrets Manager preshared keys |
| `waf` | WAFv2 web ACL (regional and CloudFront) |
| `xray` | X-Ray sampling rules, trace groups, and encryption |

## How to Use

Reference a module by selecting a specific tag with a shallow clone - **never point at a branch**:

```hcl
# select a specific tag and do shallow clone
module "vpc" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//vpc?depth=1&ref=v2.0.0"

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
| `task lockfiles` | (Re)generate `.terraform.lock.hcl` in every module |
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

1. Format check (`tofu fmt -check -recursive`) - fails on formatting drift (run `task format` locally to fix)
2. Validate all modules (`task validate`)
3. Lint with tflint (`task lint`)
4. Terratest validate - Go-based syntax/type validation
5. Terratest plan - validates changed modules against real AWS APIs via OIDC (read-only, no resources created)
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
