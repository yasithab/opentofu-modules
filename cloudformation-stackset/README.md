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

## Notes

- `deployments` is a `map(object)` keyed by a user-chosen identifier. Map keys become the
  stack instance resource keys, so inserting/removing entries never reshuffles other instances.
- Exactly one of `template_body` or `template_url` must be provided (validated at plan time).

## Usage

```hcl
module "cloudformation_stackset" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudformation-stackset?depth=1&ref=master"

  name             = "org-baseline-config"
  description      = "Baseline AWS Config rules deployed to all member accounts"
  permission_model = "SERVICE_MANAGED"

  template_url = "https://s3.us-east-1.amazonaws.com/my-cfn-templates/baseline-config.yaml"

  deployments = {
    workloads-us-east-1 = {
      region                  = "us-east-1"
      organizational_unit_ids = ["ou-root-abc12345"]
    }
  }

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

  deployments = {
    baseline-us-east-1 = {
      region                  = "us-east-1"
      organizational_unit_ids = ["ou-root-abc12345", "ou-root-def67890"]
    }
    baseline-eu-west-1 = {
      region                  = "eu-west-1"
      organizational_unit_ids = ["ou-root-abc12345", "ou-root-def67890"]
    }
  }

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

  deployments = {
    security-account-a = {
      region     = "us-east-1"
      account_id = "111122223333"
    }
    security-account-b = {
      region     = "us-east-1"
      account_id = "444455556666"
      parameter_overrides = {
        LogRetentionDays = "365"
      }
    }
  }

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

  deployments = {
    tagging-us-east-1 = {
      region                  = "us-east-1"
      organizational_unit_ids = ["ou-root-abc12345"]
      account_filter_type     = "INTERSECTION"
      accounts                = ["111122223333", "444455556666"]
    }
  }

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

## Reference

<details>
<summary>Requirements, providers, inputs and outputs (generated by terraform-docs)</summary>

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11.0 |
| aws | >= 6.49, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.49, < 7.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| administration\_role\_arn | ARN of the IAM role in the administrator account (SELF\_MANAGED only) | `string` | `null` | no |
| auto\_deployment\_enabled | Enable automatic deployment to new accounts in target OUs | `bool` | `true` | no |
| call\_as | Whether acting as account admin or delegated admin | `string` | `"SELF"` | no |
| capabilities | List of capabilities required by the template | `list(string)` | <pre>[<br/>  "CAPABILITY_NAMED_IAM"<br/>]</pre> | no |
| deployments | Map of deployment configurations keyed by a stable, user-chosen identifier<br/>(e.g. "prod-us-east-1"). The key is used as the stack instance resource key,<br/>so renaming a key replaces that instance. For SERVICE\_MANAGED:<br/>- organizational\_unit\_ids: List of OU IDs to deploy to<br/>- account\_filter\_type: DIFFERENCE, INTERSECTION, UNION, or NONE<br/>- accounts: Account IDs for filtering<br/>- accounts\_url: S3 URL of the file containing the list of accounts<br/>- region: AWS region for deployment<br/><br/>For SELF\_MANAGED:<br/>- account\_id: Target account ID<br/>- region: AWS region for deployment<br/><br/>Optional:<br/>- parameter\_overrides: Map of parameter key-value pairs to override StackSet-level parameters for this instance<br/>- retain\_stack: If true, retains the stack when the instance is removed (default false) | <pre>map(object({<br/>    region                  = string<br/>    organizational_unit_ids = optional(list(string), [])<br/>    account_filter_type     = optional(string, "NONE")<br/>    accounts                = optional(list(string), [])<br/>    accounts_url            = optional(string)<br/>    account_id              = optional(string)<br/>    parameter_overrides     = optional(map(string))<br/>    retain_stack            = optional(bool, false)<br/>  }))</pre> | `{}` | no |
| description | Description of the StackSet | `string` | `null` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| execution\_role\_name | Name of the IAM role in target accounts (SELF\_MANAGED only) | `string` | `"AWSCloudFormationStackSetExecutionRole"` | no |
| instance\_timeouts | Timeout configuration for stack instances | <pre>object({<br/>    create = optional(string, "30m")<br/>    update = optional(string, "30m")<br/>    delete = optional(string, "30m")<br/>  })</pre> | `{}` | no |
| managed\_execution\_enabled | Enable managed execution for conflict prevention | `bool` | `false` | no |
| name | Name of the StackSet | `string` | n/a | yes |
| operation\_preferences | Preferences for how AWS CloudFormation performs stack operations | <pre>object({<br/>    failure_tolerance_count      = optional(number)<br/>    failure_tolerance_percentage = optional(number)<br/>    max_concurrent_count         = optional(number)<br/>    max_concurrent_percentage    = optional(number)<br/>    concurrency_mode             = optional(string)<br/>    region_concurrency_type      = optional(string, "PARALLEL")<br/>    region_order                 = optional(list(string), [])<br/>  })</pre> | <pre>{<br/>  "failure_tolerance_percentage": 10,<br/>  "max_concurrent_percentage": 25,<br/>  "region_concurrency_type": "PARALLEL",<br/>  "region_order": []<br/>}</pre> | no |
| parameters | Map of parameters to pass to the CloudFormation template | `map(string)` | `{}` | no |
| permission\_model | Permission model: SERVICE\_MANAGED (uses AWS Organizations) or SELF\_MANAGED | `string` | `"SERVICE_MANAGED"` | no |
| retain\_stacks\_on\_account\_removal | Retain stacks when an account is removed from the organization | `bool` | `false` | no |
| stackset\_operation\_preferences | Operation preferences to apply to the StackSet itself (not per-instance). Used for managed StackSet operations. | <pre>object({<br/>    failure_tolerance_count      = optional(number)<br/>    failure_tolerance_percentage = optional(number)<br/>    max_concurrent_count         = optional(number)<br/>    max_concurrent_percentage    = optional(number)<br/>    region_concurrency_type      = optional(string)<br/>    region_order                 = optional(list(string), [])<br/>  })</pre> | `null` | no |
| stackset\_update\_timeout | Timeout for StackSet update operations (e.g., '30m', '1h') | `string` | `"30m"` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| template\_body | CloudFormation template body (mutually exclusive with template\_url) | `string` | `null` | no |
| template\_url | S3 URL for CloudFormation template (mutually exclusive with template\_body) | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| instance\_ids | Map of deployment key to stack instance IDs |
| instance\_stack\_ids | Map of deployment key to CloudFormation stack IDs in target accounts |
| stack\_set\_id | Unique identifier of the StackSet |
| stackset\_arn | ARN of the StackSet |
| stackset\_id | ID of the StackSet |
| stackset\_name | Name of the StackSet |
<!-- END_TF_DOCS -->

</details>
