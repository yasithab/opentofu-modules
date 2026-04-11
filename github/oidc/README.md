# GitHub OIDC

Registers OpenID Connect (OIDC) identity providers in your AWS account, enabling federated authentication from external identity providers such as GitHub Actions without long-lived credentials.

## Features

- **Multiple Providers** - Register one or more OIDC providers in a single module call
- **Automatic Thumbprint Handling** - For GitHub Actions OIDC, AWS validates tokens via its trusted CA library, so thumbprints are handled automatically
- **Per-Provider Tags** - Apply custom tags to individual OIDC provider resources

## Usage

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


## Examples

## Basic Usage

Register the GitHub Actions OIDC provider so that GitHub Actions workflows can authenticate with AWS.

```hcl
module "github_oidc" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//github/oidc?depth=1&ref=master"

  enabled = true

  openid_providers = {
    github = {
      url            = "https://token.actions.githubusercontent.com"
      client_id_list = ["sts.amazonaws.com"]
    }
  }

  tags = {
    Environment = "global"
    ManagedBy   = "terraform"
  }
}
```

## With Explicit Thumbprint

Supply an explicit thumbprint list instead of relying on automatic CA detection.

```hcl
module "github_oidc_with_thumbprint" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//github/oidc?depth=1&ref=master"

  enabled = true

  openid_providers = {
    github = {
      url             = "https://token.actions.githubusercontent.com"
      client_id_list  = ["sts.amazonaws.com"]
      thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
    }
  }

  tags = {
    Environment = "global"
  }
}
```

## Multiple OIDC Providers

Register both GitHub and an internal provider in one module call.

```hcl
module "oidc_providers" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//github/oidc?depth=1&ref=master"

  enabled = true

  openid_providers = {
    github = {
      url            = "https://token.actions.githubusercontent.com"
      client_id_list = ["sts.amazonaws.com"]
      tags           = { Provider = "github" }
    }
    gitlab = {
      url            = "https://gitlab.example.com"
      client_id_list = ["sts.amazonaws.com"]
      thumbprint_list = ["a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2"]
      tags           = { Provider = "gitlab" }
    }
  }

  tags = {
    ManagedBy = "terraform"
  }
}
```
