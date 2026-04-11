# IAM

Parent module containing submodules for managing AWS Identity and Access Management resources. Provides reusable building blocks for creating IAM roles, policies, and instance profiles.

## Submodules

| Submodule | Description |
|-----------|-------------|
| [role](./role/) | Creates an IAM role with a configurable trust policy, inline/managed policies, and an optional EC2 instance profile |

## Usage

```hcl
module "lambda_role" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam/role?depth=1&ref=master"

  role_name        = "my-lambda-execution-role"
  role_description = "Execution role for the data processing Lambda"

  principals = {
    Service = ["lambda.amazonaws.com"]
  }

  policy_documents = [data.aws_iam_policy_document.lambda.json]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  tags = {
    Environment = "production"
  }
}
```
