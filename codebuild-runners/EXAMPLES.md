# CodeBuild Runners Module - Examples

## Basic Usage - GitHub Actions Self-Hosted Runners

Provisions CodeBuild projects for build and deployment GitHub Actions runners linked to a single repository, using an existing IAM role and security group.

```hcl
module "codebuild_runners" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//codebuild-runners?depth=1&ref=v2.0.0"

  repository_name  = "my-service"
  env_name         = "production"
  vpc_id           = "vpc-0abc1234def567890"
  codebuild_subnets = [
    "subnet-0aaa111122223333",
    "subnet-0bbb444455556666",
  ]

  codebuild_runner_repository_name = "codebuild-runner"
  codebuild_runner_image_tag       = "3.0.0"

  create_iam_role      = false
  iam_role_name        = "codebuild-my-service"
  create_security_group = false

  concurrent_build_limit      = 10
  concurrent_deployment_limit = 2

  build_runner_compute_type      = "BUILD_GENERAL1_MEDIUM"
  deployment_runner_compute_type = "BUILD_GENERAL1_SMALL"

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## With New IAM Role and Security Group

Creates dedicated IAM role, security group, and CloudWatch log group for full isolation per repository.

```hcl
module "codebuild_runners_full" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//codebuild-runners?depth=1&ref=v2.0.0"

  repository_name  = "checkout-service"
  env_name         = "staging"
  vpc_id           = "vpc-0abc1234def567890"
  codebuild_subnets = [
    "subnet-0aaa111122223333",
    "subnet-0bbb444455556666",
  ]

  codebuild_runner_repository_name = "codebuild-runner"
  codebuild_runner_image_tag       = "3.0.0"

  create_iam_role      = true
  iam_role_name        = "codebuild-checkout-service-staging"
  codebuild_iam_policy = data.aws_iam_policy_document.codebuild_policy.json

  create_security_group = true

  create_cloudwatch_log_group             = true
  cloudwatch_log_group_retention_in_days  = 30
  cloudwatch_log_group_kms_key_id         = "arn:aws:kms:us-east-1:123456789012:key/mrk-1234abcd5678efgh"

  concurrent_build_limit      = 5
  concurrent_deployment_limit = 2

  build_runner_build_timeout      = 60
  deployment_runner_build_timeout = 120

  environment_variables = [
    {
      name  = "AWS_REGION"
      value = "us-east-1"
      type  = "PLAINTEXT"
    },
    {
      name  = "DEPLOY_BUCKET"
      value = "/codebuild/checkout-service/deploy-bucket"
      type  = "PARAMETER_STORE"
    },
  ]

  tags = {
    Environment = "staging"
    Team        = "checkout"
  }
}
```

## With Encryption and S3 Logging

Encrypts CodeBuild artifacts with a customer-managed KMS key and sends build logs to S3 for long-term retention.

```hcl
module "codebuild_runners_encrypted" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//codebuild-runners?depth=1&ref=v2.0.0"

  repository_name  = "payments-service"
  env_name         = "production"
  vpc_id           = "vpc-0abc1234def567890"
  codebuild_subnets = [
    "subnet-0aaa111122223333",
    "subnet-0bbb444455556666",
  ]

  codebuild_runner_repository_name = "codebuild-runner"
  codebuild_runner_image_tag       = "3.0.0"

  create_iam_role      = false
  iam_role_name        = "codebuild-payments-service"
  create_security_group = false

  encryption_key = "arn:aws:kms:us-east-1:123456789012:key/mrk-1234abcd5678efgh"

  create_cloudwatch_log_group            = true
  cloudwatch_log_group_retention_in_days = 90
  cloudwatch_log_group_kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/mrk-1234abcd5678efgh"

  s3_logs_status              = "ENABLED"
  s3_logs_location            = "my-codebuild-logs-bucket/payments-service"
  s3_logs_encryption_disabled = false

  concurrent_build_limit      = 10
  concurrent_deployment_limit = 2

  build_runner_compute_type      = "BUILD_GENERAL1_LARGE"
  deployment_runner_compute_type = "BUILD_GENERAL1_MEDIUM"

  auto_retry_limit = 1

  tags = {
    Environment = "production"
    Team        = "payments"
  }
}
```

## Organization-Scoped Webhook

Configures a GitHub organization-level webhook so all repositories in the organization trigger the runners automatically, with a pull request approval policy.

```hcl
module "codebuild_runners_org_webhook" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//codebuild-runners?depth=1&ref=v2.0.0"

  repository_name          = "org-runners"
  github_organization_name = "MyOrganization"
  env_name                 = "production"
  vpc_id                   = "vpc-0abc1234def567890"
  codebuild_subnets = [
    "subnet-0aaa111122223333",
    "subnet-0bbb444455556666",
  ]

  codebuild_runner_repository_name = "codebuild-runner"
  codebuild_runner_image_tag       = "3.0.0"

  create_iam_role       = false
  iam_role_name         = "codebuild-org-runners"
  create_security_group = false

  webhook_scope_configuration = {
    name  = "MyOrganization"
    scope = "GITHUB_ORGANIZATION"
  }

  webhook_pull_request_build_policy = {
    requires_comment_approval = "COLLABORATORS_ONLY"
    approver_roles            = ["WRITER", "ADMIN"]
  }

  concurrent_build_limit      = 30
  concurrent_deployment_limit = 5

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```
