# KMS Wrapper

Wrapper module that allows creating multiple KMS keys using a single module block with a `for_each`-driven interface. Each item in the `items` map creates a separate KMS key instance via the root KMS module, while shared settings can be defined once in `defaults`.

## Features

- **Bulk key provisioning** - Create multiple KMS keys from a single module block using a map of items
- **Shared defaults** - Define common configuration once in the `defaults` variable, with per-item overrides
- **Full feature parity** - Passes through all parameters supported by the root KMS module, including key policies, aliases, grants, key rotation, multi-region support, Route53 DNSSEC, and external/replica key configurations

## Usage

```hcl
module "kms" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kms/wrappers?depth=1&ref=master"

  defaults = {
    enable_key_rotation     = true
    deletion_window_in_days = 14
  }

  items = {
    app_encryption = {
      description    = "KMS key for application data encryption"
      aliases        = ["app-encryption"]
      key_administrators = ["arn:aws:iam::123456789012:role/admin"]
      key_users          = ["arn:aws:iam::123456789012:role/app-role"]
    }
    database_encryption = {
      description = "KMS key for database encryption"
      aliases     = ["db-encryption"]
      key_users   = ["arn:aws:iam::123456789012:role/rds-role"]
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

The `kms/wrappers` module lets you create multiple KMS keys in a single call using
`items` (per-key configuration) and `defaults` (shared baseline settings).

## Basic Usage

Create two application CMKs with shared rotation settings.

```hcl
module "kms_keys" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kms/wrappers?depth=1&ref=master"

  defaults = {
    enable_key_rotation = true
    deletion_window_in_days = 14
    key_administrators  = ["arn:aws:iam::123456789012:role/KMSAdminRole"]
    tags = {
      Environment = "production"
      ManagedBy   = "terraform"
    }
  }

  items = {
    app_secrets = {
      description = "CMK for application secrets"
      aliases     = ["app-secrets"]
      key_users   = ["arn:aws:iam::123456789012:role/AppRole"]
    }
    rds_storage = {
      description = "CMK for RDS storage encryption"
      aliases     = ["rds-storage"]
      key_users   = ["arn:aws:iam::123456789012:role/RDSRole"]
    }
  }
}
```

## Multi-Region Keys With Custom Rotation Periods

Create a multi-region CMK alongside a standard regional key.

```hcl
module "kms_keys_mixed" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kms/wrappers?depth=1&ref=master"

  defaults = {
    enable_key_rotation = true
    key_administrators  = ["arn:aws:iam::123456789012:role/KMSAdminRole"]
    tags = {
      Environment = "production"
    }
  }

  items = {
    global_key = {
      description             = "Multi-region primary key"
      multi_region            = true
      rotation_period_in_days = 365
      aliases                 = ["global-app-key"]
      key_users               = ["arn:aws:iam::123456789012:role/GlobalAppRole"]
    }
    regional_key = {
      description             = "Regional key for us-east-1 only"
      rotation_period_in_days = 90
      aliases                 = ["regional-key"]
      key_users               = ["arn:aws:iam::123456789012:role/RegionalRole"]
    }
  }
}
```

## Disabled Key (Feature Flag)

Provision a key in a disabled state for a feature not yet active in this environment.

```hcl
module "kms_keys_conditional" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kms/wrappers?depth=1&ref=master"

  defaults = {
    enable_key_rotation = true
    deletion_window_in_days = 30
    tags = { Environment = "staging" }
  }

  items = {
    active_key = {
      enabled     = true
      description = "Active encryption key"
      aliases     = ["staging-active"]
    }
    inactive_key = {
      enabled     = false
      description = "Pre-provisioned key for future feature"
      aliases     = ["staging-future"]
    }
  }
}
```
