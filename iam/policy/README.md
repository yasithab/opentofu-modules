# IAM Policy

Manages an IAM policy resource with support for inline JSON documents and merged policy document references.

## Features

- **Standalone IAM Policy** - Create a managed IAM policy with a JSON policy document
- **Policy Document Merging** - Merge multiple `aws_iam_policy_document` data sources into a single policy
- **Path Configuration** - Organize policies under custom IAM paths
- **Tagging** - Consistent tag management with automatic `ManagedBy` tag
- **Conditional Creation** - Toggle the entire module on or off with the `enabled` variable

## Usage

```hcl
module "policy" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam/policy?depth=1&ref=master"

  name        = "my-app-policy"
  description = "Policy for my application"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = ["arn:aws:s3:::my-bucket/*"]
      }
    ]
  })

  tags = {
    Environment = "production"
  }
}
```

## Examples

### Basic Policy from JSON

Create a simple policy from an inline JSON document.

```hcl
module "basic_policy" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam/policy?depth=1&ref=master"

  name        = "basic-s3-read"
  description = "Allow reading objects from a specific S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowS3Read"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::my-bucket",
          "arn:aws:s3:::my-bucket/*"
        ]
      }
    ]
  })

  tags = {
    Environment = "production"
  }
}
```

### Policy with Multiple Statements

Define a policy with multiple permission statements covering different AWS services.

```hcl
module "multi_statement_policy" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam/policy?depth=1&ref=master"

  name        = "app-service-policy"
  description = "Application service permissions for S3, DynamoDB, and SQS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "S3Access"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = ["arn:aws:s3:::app-data-bucket/*"]
      },
      {
        Sid      = "DynamoDBAccess"
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Query"]
        Resource = ["arn:aws:dynamodb:us-east-1:123456789012:table/app-table"]
      },
      {
        Sid      = "SQSAccess"
        Effect   = "Allow"
        Action   = ["sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage"]
        Resource = ["arn:aws:sqs:us-east-1:123456789012:app-queue"]
      }
    ]
  })

  tags = {
    Application = "my-app"
  }
}
```

### Read-Only S3 Policy

Create a read-only policy scoped to specific S3 buckets using a policy document data source.

```hcl
data "aws_iam_policy_document" "s3_readonly" {
  statement {
    sid    = "ListBuckets"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = [
      "arn:aws:s3:::logs-bucket",
      "arn:aws:s3:::reports-bucket",
    ]
  }

  statement {
    sid    = "ReadObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]
    resources = [
      "arn:aws:s3:::logs-bucket/*",
      "arn:aws:s3:::reports-bucket/*",
    ]
  }
}

module "s3_readonly_policy" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam/policy?depth=1&ref=master"

  name        = "s3-readonly"
  description = "Read-only access to logs and reports S3 buckets"
  path        = "/application/"

  policy_documents = [data.aws_iam_policy_document.s3_readonly.json]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

### Cross-Account Assume Role Policy

Create a policy that allows assuming a role in another AWS account.

```hcl
module "cross_account_policy" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam/policy?depth=1&ref=master"

  name        = "cross-account-assume-role"
  description = "Allow assuming roles in the production account"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAssumeRole"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = [
          "arn:aws:iam::987654321098:role/deployment-role",
          "arn:aws:iam::987654321098:role/readonly-role"
        ]
      }
    ]
  })

  tags = {
    Purpose = "cross-account-access"
  }
}
```

### Policy with Conditions

Create a policy with IAM conditions for fine-grained access control.

```hcl
module "conditional_policy" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam/policy?depth=1&ref=master"

  name        = "s3-region-restricted"
  description = "S3 access restricted by region, MFA, and source IP"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3InRegion"
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = [
          "arn:aws:s3:::secure-bucket",
          "arn:aws:s3:::secure-bucket/*"
        ]
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "us-east-1"
          }
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
          IpAddress = {
            "aws:SourceIp" = "203.0.113.0/24"
          }
        }
      }
    ]
  })

  tags = {
    Security = "high"
  }
}
```
