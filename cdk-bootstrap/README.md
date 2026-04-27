# CDK Bootstrap

Provisions the AWS CDK bootstrap resources natively in OpenTofu — S3 staging bucket, ECR repository, IAM roles, KMS key, and SSM version parameter — replacing the `cdk bootstrap` CLI command.

## Features

- **Native Resources** — All bootstrap infrastructure managed as first-class OpenTofu resources with full drift detection, plan visibility, and destroy support
- **S3 Staging Bucket** — Versioned, encrypted, SSL-only, with public access blocked and lifecycle rules for old versions
- **ECR Repository** — Immutable tags, scan-on-push, lifecycle policy for untagged images
- **5 IAM Roles** — CloudFormation execution, deployment, file publishing, image publishing, and lookup roles matching CDK bootstrap v32
- **KMS Key** (optional) — Dedicated encryption key for S3 and ECR, with key rotation enabled
- **Cross-Account Trust** — Configure trusted accounts for deployment and lookup roles
- **Custom Execution Policies** — Override the default AdministratorAccess CloudFormation execution policy

## Usage

```hcl
module "cdk_bootstrap" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cdk-bootstrap?depth=1&ref=master"

  cloudformation_execution_policy_arns = [
    "arn:aws:iam::aws:policy/PowerUserAccess"
  ]

  trust_account_ids = ["123456789012"]
}
```

## Examples

### Basic Usage

Bootstrap CDK in the current region using defaults.

```hcl
module "cdk_bootstrap" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cdk-bootstrap?depth=1&ref=master"
}
```

### With KMS Encryption

Use a dedicated KMS key for S3 and ECR encryption instead of default AES256.

```hcl
module "cdk_bootstrap" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cdk-bootstrap?depth=1&ref=master"

  create_kms_key = true

  tags = {
    Environment = "production"
  }
}
```

### With Custom CloudFormation Execution Policy

Restrict the CloudFormation execution role to a scoped-down policy.

```hcl
module "cdk_bootstrap" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cdk-bootstrap?depth=1&ref=master"

  cloudformation_execution_policy_arns = [
    "arn:aws:iam::123456789012:policy/CDKDeploymentPolicy",
  ]
}
```

### Cross-Account Deployment with Lookup Trust

Trust a CI/CD account for deployment and a shared-services account for lookups.

```hcl
module "cdk_bootstrap" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cdk-bootstrap?depth=1&ref=master"

  trust_account_ids            = ["987654321098"]
  trust_account_ids_for_lookup = ["111222333444"]

  cloudformation_execution_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess",
  ]
}
```

### Multi-Region Bootstrap

Bootstrap CDK in multiple regions by calling the module once per region with aliased providers.

```hcl
provider "aws" {
  alias  = "ap_southeast_1"
  region = "ap-southeast-1"
}

provider "aws" {
  alias  = "eu_west_1"
  region = "eu-west-1"
}

module "cdk_bootstrap_ap" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cdk-bootstrap?depth=1&ref=master"

  providers = { aws = aws.ap_southeast_1 }

  trust_account_ids = ["987654321098"]
}

module "cdk_bootstrap_eu" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cdk-bootstrap?depth=1&ref=master"

  providers = { aws = aws.eu_west_1 }

  trust_account_ids = ["987654321098"]
}
```
