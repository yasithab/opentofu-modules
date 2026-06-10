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
| github\_environment | Optional GitHub Actions environment name to constrain the OIDC subject claim to (e.g. 'production'). When set, only workflows targeting this environment can assume the role. Strongly recommended for roles with write access. | `string` | `null` | no |
| github\_oidc\_arn | The GitHub openid connect provider arn | `string` | n/a | yes |
| github\_organization\_name | The GitHub organization name | `string` | n/a | yes |
| github\_ref | Optional git ref to constrain the OIDC subject claim to (e.g. 'refs/heads/main' or 'refs/tags/v*'). When set, only workflows running on this ref can assume the role. Strongly recommended for roles with write access. | `string` | `null` | no |
| iam\_policy\_delay\_after\_creation\_in\_ms | Number of milliseconds to wait between creating the policy and setting its version as default | `number` | `null` | no |
| iam\_policy\_description | The description of the GitHub actions IAM policy | `string` | `"GitHub Actions Policy"` | no |
| iam\_policy\_document | The JSON formatted policy document | `string` | `null` | no |
| iam\_policy\_name | The name of the GitHub actions IAM policy | `string` | `null` | no |
| iam\_policy\_path | Path for the IAM policy | `string` | `"/"` | no |
| iam\_role\_description | The description of the GitHub actions IAM role | `string` | `"GitHub Actions Role"` | no |
| iam\_role\_force\_detach\_policies | Whether to force-detach any policies the role has before destroying it | `bool` | `false` | no |
| iam\_role\_max\_session\_duration | Maximum session duration (in seconds) for the IAM role. Value between 3600 and 43200. | `number` | `3600` | no |
| iam\_role\_name | The name of the GitHub actions IAM role | `string` | n/a | yes |
| iam\_role\_path | Path for the IAM role | `string` | `"/"` | no |
| iam\_role\_permissions\_boundary | ARN of the policy used as permissions boundary for the IAM role | `string` | `null` | no |
| repo\_names | List of GitHub repository names allowed to assume the role | `list(string)` | n/a | yes |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| policy\_arn | ARN of the GitHub Actions IAM policy |
| policy\_name | Name of the GitHub Actions IAM policy |
| role\_arn | ARN of the GitHub Actions IAM role |
| role\_name | Name of the GitHub Actions IAM role |
<!-- END_TF_DOCS -->

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

## Security Notes

### Audience condition (SECURITY)

The role trust policy requires `token.actions.githubusercontent.com:aud = "sts.amazonaws.com"`
(`StringEquals`). Without this condition, a GitHub OIDC token minted for any audience by a
matching repository could be exchanged for role credentials. Workflows using
`aws-actions/configure-aws-credentials` request the `sts.amazonaws.com` audience by default.

### Constrain the subject claim (recommended)

By default any branch, tag, PR or environment of the listed repositories can assume the role
(`repo:<org>/<repo>:*`). Tighten this with the optional variables:

```hcl
# Only the main branch
github_ref = "refs/heads/main"

# And/or only a specific GitHub Actions environment
github_environment = "production"
```

When both are set, both subjects are allowed (ref-based OR environment-based). For roles with
write access to infrastructure, constraining the subject is strongly recommended.
