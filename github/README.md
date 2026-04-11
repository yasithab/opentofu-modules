# GitHub

Parent module containing submodules for integrating GitHub with AWS via OIDC federation. Enables secure, keyless authentication from GitHub Actions workflows to AWS accounts.

## Submodules

| Submodule | Description |
|-----------|-------------|
| [oidc](./oidc/) | Registers OpenID Connect identity providers (e.g., GitHub Actions OIDC) in your AWS account |
| [actions](./actions/) | Creates IAM roles and policies assumable by GitHub Actions workflows via OIDC federation |

## Usage

First, register the GitHub OIDC provider once per AWS account using the `oidc` submodule:

```hcl
module "github_oidc" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//github/oidc?depth=1&ref=master"

  openid_providers = {
    github = {
      url            = "https://token.actions.githubusercontent.com"
      client_id_list = ["sts.amazonaws.com"]
    }
  }
}
```

Then, create a role for each repository or set of repositories using the `actions` submodule:

```hcl
module "github_actions" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//github/actions?depth=1&ref=master"

  github_oidc_arn          = module.github_oidc.openid_provider_arns["github"]
  github_organization_name = "my-org"
  repo_names               = ["my-repo"]
  iam_role_name            = "github-actions-my-repo"
  iam_policy_document      = data.aws_iam_policy_document.deploy.json
}
```
