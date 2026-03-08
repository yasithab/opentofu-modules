# Secret Manager Wrappers Module - Examples

## Create Multiple Secrets with Shared Defaults

Use the wrappers module to create several secrets in a single call, sharing common configuration such as KMS key and recovery window via `defaults`.

```hcl
module "secrets" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//secret-manager/wrappers?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//secret-manager/wrappers?depth=1&ref=v2.0.0"

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
