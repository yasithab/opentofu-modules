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

  role_name        = "my-service-role"
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

  role_name        = "my-lambda-execution-role"
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

  role_name        = "my-ecs-task-role"
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

  role_name                = "my-ec2-app-role"
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

  role_name             = "cross-account-readonly"
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
