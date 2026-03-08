# CDK Bootstrap Module - Examples

## Basic Usage

Bootstrap CDK in a single region using the current AWS account.

```hcl
module "cdk_bootstrap" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cdk-bootstrap?depth=1&ref=v2.0.0"

  enabled = true
  region  = "ap-southeast-1"
}
```

## With Custom CloudFormation Execution Policy

Bootstrap CDK with a restricted CloudFormation execution policy instead of the default `AdministratorAccess`.

```hcl
module "cdk_bootstrap" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cdk-bootstrap?depth=1&ref=v2.0.0"

  enabled = true
  region  = "ap-southeast-1"

  cloudformation_execution_policy_arns = [
    "arn:aws:iam::123456789012:policy/CDKDeploymentPolicy",
  ]
}
```

## With Trusted Account for Cross-Account Deployment

Allow a CI/CD account (e.g., a tools account) to deploy into this account by trusting its account ID.

```hcl
module "cdk_bootstrap" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cdk-bootstrap?depth=1&ref=v2.0.0"

  enabled = true
  region  = "ap-southeast-1"

  trust_account_ids = ["987654321098"]

  cloudformation_execution_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess",
  ]
}
```

## Multi-Region Bootstrap with Trusted CI Account and Restricted Policy

Bootstrap CDK in multiple regions using separate module calls, each trusting the central CI/CD account with a scoped policy.

```hcl
module "cdk_bootstrap_ap_southeast_1" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cdk-bootstrap?depth=1&ref=v2.0.0"

  enabled = true
  region  = "ap-southeast-1"

  trust_account_ids = ["987654321098"]

  cloudformation_execution_policy_arns = [
    "arn:aws:iam::123456789012:policy/CDKDeploymentPolicy",
  ]
}

module "cdk_bootstrap_eu_west_1" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cdk-bootstrap?depth=1&ref=v2.0.0"

  enabled = true
  region  = "eu-west-1"

  trust_account_ids = ["987654321098"]

  cloudformation_execution_policy_arns = [
    "arn:aws:iam::123456789012:policy/CDKDeploymentPolicy",
  ]
}
```
