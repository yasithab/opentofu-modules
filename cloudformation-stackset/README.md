# AWS CloudFormation StackSet

Manages AWS CloudFormation StackSets and their stack instances, supporting both service-managed (AWS Organizations) and self-managed permission models for multi-account, multi-region deployments.

## Features

- **Service-Managed Deployments** - Deploys stacks across AWS Organizations OUs with automatic deployment to new accounts, using Organizations-managed permissions
- **Self-Managed Deployments** - Supports explicit administration and execution IAM roles for deploying to specific accounts outside of AWS Organizations
- **Multi-Region Stack Instances** - Creates stack instances across multiple regions and accounts/OUs from a single StackSet definition with per-instance parameter overrides
- **Delegated Administrator** - Operates from a delegated administrator account instead of the management account via the `call_as` parameter
- **Managed Execution** - Enables conflict prevention to ensure only one StackSet operation runs at a time, avoiding concurrent modification errors
- **Operation Preferences** - Configurable failure tolerance, concurrency limits, and region ordering at both the StackSet and per-instance level
- **Flexible Template Sources** - Accepts CloudFormation templates inline via `template_body` or from S3 via `template_url`

## Usage

```hcl
module "cloudformation_stackset" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudformation-stackset?depth=1&ref=master"

  name             = "org-baseline-config"
  description      = "Baseline AWS Config rules deployed to all member accounts"
  permission_model = "SERVICE_MANAGED"

  template_url = "https://s3.us-east-1.amazonaws.com/my-cfn-templates/baseline-config.yaml"

  deployments = [
    {
      region                  = "us-east-1"
      organizational_unit_ids = ["ou-root-abc12345"]
    },
  ]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```


## Examples

## Basic Usage - Service-Managed (AWS Organizations)

Deploys a CloudFormation template to all accounts in a set of Organizational Units using AWS Organizations-managed permissions. Auto-deployment ensures new accounts in those OUs receive the stack automatically.

```hcl
module "cloudformation_stackset" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudformation-stackset?depth=1&ref=master"

  enabled = true
  name    = "org-baseline-config"

  description      = "Baseline AWS Config rules deployed to all member accounts"
  permission_model = "SERVICE_MANAGED"

  template_url = "https://s3.us-east-1.amazonaws.com/my-cfn-templates/baseline-config.yaml"

  capabilities = ["CAPABILITY_NAMED_IAM"]

  auto_deployment_enabled           = true
  retain_stacks_on_account_removal  = false

  deployments = [
    {
      region                  = "us-east-1"
      organizational_unit_ids = ["ou-root-abc12345", "ou-root-def67890"]
    },
    {
      region                  = "eu-west-1"
      organizational_unit_ids = ["ou-root-abc12345", "ou-root-def67890"]
    },
  ]

  tags = {
    Environment = "all"
    Team        = "platform"
  }
}
```

## Self-Managed with Custom Operation Preferences

Deploys using explicit administration and execution roles, targeting specific accounts. Parallel region deployment with a 10% failure tolerance gives you control over rollout behaviour.

```hcl
module "cloudformation_stackset_self_managed" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudformation-stackset?depth=1&ref=master"

  enabled = true
  name    = "security-baseline"

  description      = "Security baseline stack deployed to selected accounts"
  permission_model = "SELF_MANAGED"

  template_url = "https://s3.us-east-1.amazonaws.com/my-cfn-templates/security-baseline.yaml"

  capabilities = ["CAPABILITY_NAMED_IAM", "CAPABILITY_AUTO_EXPAND"]

  parameters = {
    LogRetentionDays = "90"
    EnableGuardDuty  = "true"
  }

  administration_role_arn = "arn:aws:iam::123456789012:role/AWSCloudFormationStackSetAdministrationRole"
  execution_role_name     = "AWSCloudFormationStackSetExecutionRole"

  deployments = [
    {
      region     = "us-east-1"
      account_id = "111122223333"
    },
    {
      region     = "us-east-1"
      account_id = "444455556666"
      parameter_overrides = {
        LogRetentionDays = "365"
      }
    },
  ]

  operation_preferences = {
    failure_tolerance_percentage = 10
    max_concurrent_percentage    = 50
    region_concurrency_type      = "PARALLEL"
  }

  tags = {
    Environment = "production"
    Team        = "security"
  }
}
```

## Delegated Admin with Managed Execution

A delegated administrator account (not the management account) deploys to a subset of OUs. Managed execution prevents conflicting StackSet operations from running simultaneously.

```hcl
module "cloudformation_stackset_delegated" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudformation-stackset?depth=1&ref=master"

  enabled = true
  name    = "tagging-policy"

  description      = "Enforce mandatory resource tagging policy across the organization"
  permission_model = "SERVICE_MANAGED"
  call_as          = "DELEGATED_ADMIN"

  template_body = <<-EOT
    AWSTemplateFormatVersion: "2010-09-09"
    Description: Tag enforcement policy
    Resources:
      TagPolicy:
        Type: AWS::Organizations::Policy
        Properties:
          Name: mandatory-tags
          Type: TAG_POLICY
          Content: '{"tags":{"Environment":{"tag_value":{"@@assign":["production","staging","development"]}}}}'
  EOT

  capabilities              = ["CAPABILITY_IAM"]
  managed_execution_enabled = true

  auto_deployment_enabled          = true
  retain_stacks_on_account_removal = true

  deployments = [
    {
      region                  = "us-east-1"
      organizational_unit_ids = ["ou-root-abc12345"]
      account_filter_type     = "INTERSECTION"
      accounts                = ["111122223333", "444455556666"]
    },
  ]

  instance_timeouts = {
    create = "45m"
    update = "45m"
    delete = "30m"
  }

  tags = {
    Environment = "all"
    Team        = "governance"
  }
}
```
