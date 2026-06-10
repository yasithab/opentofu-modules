# IAM Group

Manages an IAM group with optional managed and inline policy attachments and user membership.

## Features

- **IAM Group** - Create a group with a configurable path
- **Managed Policy Attachments** - Attach any number of AWS or customer managed policy ARNs
- **Inline Policies** - Define group-level inline policies via a simple name-to-JSON map
- **Group Membership** - Add any number of existing IAM users to the group
- **Conditional Creation** - Toggle the entire module on or off with the `enabled` variable

## Usage

```hcl
module "group" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam/group?depth=1&ref=master"

  name = "developers"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
  ]

  users = ["alice", "bob"]

  tags = {
    Environment = "production"
  }
}
```

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
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| inline\_policies | Map of inline policy names to their JSON policy documents. | `map(string)` | `{}` | no |
| managed\_policy\_arns | Set of managed policy ARNs to attach to the group. | `set(string)` | `[]` | no |
| name | The name of the IAM group. | `string` | n/a | yes |
| path | Path in which to create the group. | `string` | `"/"` | no |
| users | Set of IAM user names to add as members of the group. | `set(string)` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| arn | The ARN assigned by AWS for this group. |
| attached\_policy\_arns | The set of managed policy ARNs attached to the group. |
| id | The group's ID. |
| inline\_policy\_names | The list of inline policy names attached to the group. |
| membership\_name | The name of the group membership resource. |
| membership\_users | The list of IAM user names in the group. |
| name | The name of the IAM group. |
| path | The path of the group in IAM. |
| unique\_id | The unique ID assigned by AWS. |
<!-- END_TF_DOCS -->

## Examples

### Basic Group

Create a minimal IAM group with no policies or members.

```hcl
module "basic_group" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam/group?depth=1&ref=master"

  name = "interns"
  path = "/teams/"

  tags = {
    Department = "engineering"
  }
}
```

### Group with Managed Policies

Create a group with multiple AWS managed policies attached.

```hcl
module "managed_policy_group" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam/group?depth=1&ref=master"

  name = "cloud-engineers"
  path = "/teams/"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonVPCFullAccess",
  ]

  tags = {
    Team = "infrastructure"
  }
}
```

### Group with Inline Policy

Create a group with a custom inline policy for fine-grained permissions.

```hcl
module "inline_policy_group" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam/group?depth=1&ref=master"

  name = "deployers"

  inline_policies = {
    deploy-permissions = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid      = "AllowECSDeploy"
          Effect   = "Allow"
          Action   = [
            "ecs:UpdateService",
            "ecs:DescribeServices",
            "ecs:DescribeTaskDefinition",
            "ecs:RegisterTaskDefinition",
          ]
          Resource = "*"
        },
        {
          Sid      = "AllowECRPush"
          Effect   = "Allow"
          Action   = [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:PutImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
          ]
          Resource = "*"
        }
      ]
    })
  }

  tags = {
    Purpose = "deployment"
  }
}
```

### Admin Group with Multiple Users

Create an administrators group with full access and multiple members.

```hcl
module "admin_group" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam/group?depth=1&ref=master"

  name = "administrators"
  path = "/admin/"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess",
  ]

  users = [
    "admin.alice",
    "admin.bob",
    "admin.charlie",
  ]

  inline_policies = {
    enforce-mfa = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "DenyAllExceptMFASetupUnlessMFA"
          Effect = "Deny"
          NotAction = [
            "iam:CreateVirtualMFADevice",
            "iam:EnableMFADevice",
            "iam:GetUser",
            "iam:ListMFADevices",
            "iam:ListVirtualMFADevices",
            "iam:ResyncMFADevice",
            "sts:GetSessionToken",
          ]
          Resource = "*"
          Condition = {
            BoolIfExists = {
              "aws:MultiFactorAuthPresent" = "false"
            }
          }
        }
      ]
    })
  }

  tags = {
    Security = "high"
  }
}
```

### Read-Only Group

Create a read-only group for auditors or observers with no write permissions.

```hcl
module "readonly_group" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam/group?depth=1&ref=master"

  name = "auditors"
  path = "/security/"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
    "arn:aws:iam::aws:policy/SecurityAudit",
  ]

  users = [
    "auditor.dana",
    "auditor.eve",
  ]

  tags = {
    Purpose    = "audit"
    Compliance = "soc2"
  }
}
```

## Notes

### No tags on IAM groups

`aws_iam_group` does not support tags (the IAM Groups API has no tagging operations), so this
module intentionally has no `tags` variable and is exempt from the repo-wide
`tags`/`ManagedBy` convention.
