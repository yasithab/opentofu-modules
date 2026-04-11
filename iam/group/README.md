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
