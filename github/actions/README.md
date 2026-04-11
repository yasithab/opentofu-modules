# GitHub Actions

Creates IAM roles and policies that GitHub Actions workflows can assume via OIDC federation. Scopes trust to specific repositories within a GitHub organization for secure, keyless CI/CD deployments.

## Features

- **OIDC-Based Trust** - IAM role trust policy scoped to the GitHub Actions OIDC provider with repository-level conditions
- **Multi-Repository Support** - Grant access to one or more repositories within the same GitHub organization
- **Custom Policy Attachment** - Attach any IAM policy document to the role for fine-grained permissions
- **Configurable Session Duration** - Set maximum session duration from 1 to 12 hours
- **Permissions Boundary** - Optional permissions boundary ARN for guardrail enforcement

## Usage

```hcl
module "github_actions" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//github/actions?depth=1&ref=master"

  github_oidc_arn          = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
  github_organization_name = "my-org"
  repo_names               = ["infra-repo"]
  iam_role_name            = "github-actions-deploy"
  iam_policy_document      = data.aws_iam_policy_document.deploy.json
}
```


## Examples

## Basic Usage

Create an IAM role and policy allowing a single GitHub repository to assume it via OIDC.

```hcl
module "github_actions" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//github/actions?depth=1&ref=master"

  enabled = true

  github_oidc_arn          = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
  github_organization_name = "my-org"
  iam_role_name            = "github-actions-deploy"
  repo_names               = ["my-service"]
  iam_policy_document      = data.aws_iam_policy_document.deploy.json

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Multiple Repositories

Allow multiple repositories in the organisation to assume the same role.

```hcl
module "github_actions_multi_repo" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//github/actions?depth=1&ref=master"

  enabled = true

  github_oidc_arn           = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
  github_organization_name  = "Example"
  iam_role_name             = "github-actions-infra"
  iam_policy_name           = "github-actions-infra-policy"
  iam_policy_description    = "Policy for GitHub Actions infra deployments"
  repo_names                = ["terraform-modules", "infrastructure", "platform-tools"]
  iam_policy_document       = data.aws_iam_policy_document.infra.json

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## With Custom Session Duration and Permissions Boundary

Set a longer session duration and enforce a permissions boundary on the role.

```hcl
module "github_actions_bounded" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//github/actions?depth=1&ref=master"

  enabled = true

  github_oidc_arn               = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
  github_organization_name      = "Example"
  iam_role_name                 = "github-actions-ecr-push"
  iam_role_description          = "Role for GitHub Actions ECR image publishing"
  iam_policy_name               = "github-actions-ecr-push-policy"
  iam_role_max_session_duration = 7200
  iam_role_permissions_boundary = "arn:aws:iam::123456789012:policy/DeveloperBoundary"
  iam_role_path                 = "/github-actions/"
  iam_policy_path               = "/github-actions/"
  repo_names                    = ["my-service"]
  iam_policy_document           = data.aws_iam_policy_document.ecr_push.json

  tags = {
    Environment = "production"
    Purpose     = "ci-cd"
  }
}
```
