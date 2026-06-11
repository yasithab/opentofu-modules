# IAM Role

General-purpose IAM role module that creates a role with a flexible trust policy, optional inline and managed policies, and an optional EC2 instance profile. Supports multiple principal types and assume-role conditions.

## Features

- **Flexible Trust Policy** - Define principals by type (Service, AWS, Federated) with optional conditions for fine-grained access control
- **Inline Policy** - Merge multiple JSON policy documents into a single inline policy attached to the role
- **Managed Policy Attachments** - Attach any number of AWS or customer managed policy ARNs
- **EC2 Instance Profile** - Optionally create an instance profile bound to the role for EC2 workloads
- **Name or Name Prefix** - Use either a fixed name or an auto-generated name with a prefix for uniqueness
- **Permissions Boundary** - Optional permissions boundary for organizational guardrails
- **Session Duration** - Configurable maximum session duration from 1 to 12 hours

## Usage

```hcl
module "role" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam/role?depth=1&ref=master"

  name             = "my-service-role"
  role_description = "Role for the backend service"

  principals = {
    Service = ["ecs-tasks.amazonaws.com"]
  }

  policy_documents = [data.aws_iam_policy_document.backend.json]

  tags = {
    Environment = "production"
  }
}
```

## Examples

## Basic Usage

Create a role assumable by a Lambda service principal with a single inline policy.

```hcl
module "lambda_role" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam/role?depth=1&ref=master"

  enabled = true

  name             = "my-lambda-execution-role"
  role_description = "Execution role for my Lambda function"

  principals = {
    Service = ["lambda.amazonaws.com"]
  }

  policy_documents = [
    data.aws_iam_policy_document.lambda_policy.json
  ]

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## With Managed Policies Attached

Attach AWS-managed policies to an ECS task role.

```hcl
module "ecs_task_role" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam/role?depth=1&ref=master"

  enabled = true

  name             = "my-ecs-task-role"
  role_description = "ECS task execution role"

  principals = {
    Service = ["ecs-tasks.amazonaws.com"]
  }

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  ]

  tags = {
    Environment = "production"
    Team        = "backend"
  }
}
```

## With Assume Role Conditions and Instance Profile

Create a role for EC2 instances with an IMDS condition and an attached instance profile.

```hcl
module "ec2_instance_role" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam/role?depth=1&ref=master"

  enabled = true

  name                     = "my-ec2-app-role"
  role_description         = "Role for application EC2 instances"
  instance_profile_enabled = true
  instance_profile_name    = "my-ec2-app-profile"

  principals = {
    Service = ["ec2.amazonaws.com"]
  }

  assume_role_conditions = [
    {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["us-east-1"]
    }
  ]

  policy_documents = [
    data.aws_iam_policy_document.app_policy.json
  ]

  tags = {
    Environment = "production"
  }
}
```

## Cross-Account Assume Role

Allow an IAM role in another account to assume this role with a permissions boundary.

```hcl
module "cross_account_role" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam/role?depth=1&ref=master"

  enabled = true

  name                  = "cross-account-readonly"
  role_description      = "Cross-account read-only role for auditing"
  max_session_duration  = 7200
  permissions_boundary  = "arn:aws:iam::123456789012:policy/ReadOnlyBoundary"

  principals = {
    AWS = ["arn:aws:iam::987654321098:role/AuditRole"]
  }

  assume_role_actions = ["sts:AssumeRole"]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess"
  ]

  tags = {
    Environment = "production"
    Purpose     = "cross-account-audit"
  }
}
```

## Per-Principal Assume-Role Conditions

Each `principals` entry can optionally carry its own conditions, applied only to that
principal's statement. Global `assume_role_conditions` continue to apply to all statements.
The legacy shape (`map of type => list of identifiers`) remains fully supported.

```hcl
module "role" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam/role?depth=1&ref=master"

  name             = "cross-account-deployer"
  role_description = "Role assumable by CI with an external ID"

  principals = {
    # legacy shape - no per-principal conditions
    Service = ["ec2.amazonaws.com"]

    # object shape - conditions apply only to the AWS principal statement
    AWS = {
      identifiers = ["arn:aws:iam::123456789012:role/ci"]
      conditions = [
        {
          test     = "StringEquals"
          variable = "sts:ExternalId"
          values   = ["my-external-id"]
        }
      ]
    }
  }
}
```

## Notes

The inline policy and its attachment are only created when `policy_documents` is non-empty.

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
| assume\_role\_actions | The IAM action to be granted by the AssumeRole policy | `list(string)` | <pre>[<br/>  "sts:AssumeRole",<br/>  "sts:TagSession"<br/>]</pre> | no |
| assume\_role\_conditions | List of conditions for the assume role policy | <pre>list(object({<br/>    test     = string<br/>    variable = string<br/>    values   = list(string)<br/>  }))</pre> | `[]` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| force\_detach\_policies | Whether to force detaching any policies the role has before destroying it | `bool` | `false` | no |
| instance\_profile\_enabled | Create EC2 Instance Profile for the role | `bool` | `false` | no |
| instance\_profile\_name | EC2 Instance Profile name | `string` | `null` | no |
| instance\_profile\_name\_prefix | EC2 Instance Profile name prefix | `string` | `null` | no |
| managed\_policy\_arns | List of managed policies to attach to created role | `set(string)` | `[]` | no |
| max\_session\_duration | The maximum session duration (in seconds) for the role. Can have a value from 1 hour to 12 hours | `number` | `3600` | no |
| name | IAM role name | `string` | `null` | no |
| name\_prefix | IAM role name prefix | `string` | `null` | no |
| path | Path to the role and policy. See [IAM Identifiers](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html) for more information. | `string` | `"/"` | no |
| permissions\_boundary | ARN of the policy that is used to set the permissions boundary for the role | `string` | `null` | no |
| policy\_delay\_after\_creation\_in\_ms | Number of milliseconds to wait between creating the policy and setting its version as default. Only applies when policy\_documents is non-empty. | `number` | `null` | no |
| policy\_description | The description of the IAM policy that is visible in the IAM policy manager | `string` | `null` | no |
| policy\_documents | List of JSON IAM policy documents. When non-empty, an IAM policy is created from the merged documents and attached to the role | `list(string)` | `[]` | no |
| policy\_name | The name of the IAM policy that is visible in the IAM policy manager | `string` | `null` | no |
| policy\_name\_prefix | The name prefix of the IAM policy that is visible in the IAM policy manager | `string` | `null` | no |
| principals | Map of principal type (e.g. `AWS`, `Service`, `Federated`) to either:<br/>  - a list of identifiers (legacy shape), e.g. `{ Service = ["ec2.amazonaws.com"] }`, or<br/>  - an object `{ identifiers = list(string), conditions = optional(list(object({ test, variable, values }))) }`<br/>    where `conditions` apply only to that principal's assume-role statement.<br/>Global `assume_role_conditions` apply to all principal statements. | `any` | `{}` | no |
| role\_description | The description of the IAM role that is visible in the IAM role manager | `string` | n/a | yes |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| tags\_enabled | Enable/disable tags on IAM roles and policies | `bool` | `true` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| arn | The Amazon Resource Name (ARN) specifying the role |
| create\_date | The creation date of the IAM role |
| id | The stable and unique string identifying the role |
| instance\_profile | Name of the ec2 profile (if enabled) |
| instance\_profile\_arn | ARN of the EC2 instance profile (if enabled) |
| instance\_profile\_unique\_id | Unique ID of the EC2 instance profile (if enabled) |
| name | The name of the IAM role created |
| policy | Role policy document in json format. Outputs always, independent of `enabled` variable |
<!-- END_TF_DOCS -->

</details>
