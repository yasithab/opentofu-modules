# Secrets Manager Wrapper

Wrapper module that allows creating multiple AWS Secrets Manager secrets using a single module block with a `for_each`-driven interface. Each item in the `items` map creates a separate secret instance via the root Secrets Manager module, while shared settings can be defined once in `defaults`.

## Features

- **Bulk secret provisioning** - Create multiple Secrets Manager secrets from a single module block using a map of items
- **Shared defaults** - Define common configuration once in the `defaults` variable, with per-item overrides
- **Full feature parity** - Passes through all parameters supported by the root Secrets Manager module, including secret values, random password generation, rotation configuration, resource policies, replica regions, and KMS encryption

## Usage

```hcl
module "secrets" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//secret-manager/wrappers?depth=1&ref=master"

  defaults = {
    recovery_window_in_days = 7
  }

  items = {
    db_credentials = {
      name          = "prod/database/credentials"
      description   = "Database credentials for production"
      secret_string = jsonencode({ username = "admin", password = "changeme" })
      kms_key_id    = "arn:aws:kms:us-east-1:123456789012:key/abc-123"
    }
    api_key = {
      name                   = "prod/api/key"
      description            = "External API key"
      create_random_password = true
      random_password_length = 48
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| defaults | Map of default values which will be used for each item | `any` | `{}` | no |
| items | Maps of items to create a wrapper from. Values are passed through to the module | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| wrapper | Map of outputs of the wrapper, keyed by each item's key (sensitive) |


## Examples

## Create Multiple Secrets with Shared Defaults

Use the wrappers module to create several secrets in a single call, sharing common configuration such as KMS key and recovery window via `defaults`.

```hcl
module "secrets" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//secret-manager/wrappers?depth=1&ref=master"

  defaults = {
    enabled                 = true
    recovery_window_in_days = 7
    kms_key_id              = "arn:aws:kms:eu-west-1:123456789012:key/mrk-00000000000000000000000000000000"
    tags = {
      Environment = "production"
      Team        = "platform"
    }
  }

  items = {
    db_password = {
      name          = "/production/myapp/db-password"
      description   = "RDS master password"
      secret_string = jsonencode({ password = "changeme" })
    }
    api_key = {
      name          = "/production/myapp/api-key"
      description   = "External API key"
      secret_string = jsonencode({ key = "apikey123" })
    }
    service_token = {
      name          = "/production/myapp/service-token"
      description   = "Internal service-to-service token"
      secret_string = jsonencode({ token = "svc-token-xyz" })
    }
  }
}
```

## Write-Only Secrets Across Multiple Applications

Store credentials for multiple applications using write-only values to keep secrets out of Terraform state.

```hcl
module "app_secrets" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//secret-manager/wrappers?depth=1&ref=master"

  defaults = {
    enabled                 = true
    recovery_window_in_days = 7
    ignore_secret_changes   = true
    tags = {
      Environment = "production"
      ManagedBy   = "terraform"
    }
  }

  items = {
    search_api = {
      name                     = "/production/search-service/api-credentials"
      description              = "Search service external API credentials"
      secret_string_wo         = var.search_api_secret
      secret_string_wo_version = var.search_api_secret_version
    }
    payments_api = {
      name                     = "/production/payments-service/api-credentials"
      description              = "Payment gateway credentials"
      secret_string_wo         = var.payments_api_secret
      secret_string_wo_version = var.payments_api_secret_version
      kms_key_id               = "arn:aws:kms:eu-west-1:123456789012:key/mrk-11111111111111111111111111111111"
    }
  }
}
```
