# KMS Wrappers Module - Examples

The `kms/wrappers` module lets you create multiple KMS keys in a single call using
`items` (per-key configuration) and `defaults` (shared baseline settings).

## Basic Usage

Create two application CMKs with shared rotation settings.

```hcl
module "kms_keys" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kms/wrappers?depth=1&ref=v2.0.0"

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
      aliases     = ["alias/app-secrets"]
      key_users   = ["arn:aws:iam::123456789012:role/AppRole"]
    }
    rds_storage = {
      description = "CMK for RDS storage encryption"
      aliases     = ["alias/rds-storage"]
      key_users   = ["arn:aws:iam::123456789012:role/RDSRole"]
    }
  }
}
```

## Multi-Region Keys With Custom Rotation Periods

Create a multi-region CMK alongside a standard regional key.

```hcl
module "kms_keys_mixed" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kms/wrappers?depth=1&ref=v2.0.0"

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
      aliases                 = ["alias/global-app-key"]
      key_users               = ["arn:aws:iam::123456789012:role/GlobalAppRole"]
    }
    regional_key = {
      description             = "Regional key for us-east-1 only"
      rotation_period_in_days = 90
      aliases                 = ["alias/regional-key"]
      key_users               = ["arn:aws:iam::123456789012:role/RegionalRole"]
    }
  }
}
```

## Disabled Key (Feature Flag)

Provision a key in a disabled state for a feature not yet active in this environment.

```hcl
module "kms_keys_conditional" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kms/wrappers?depth=1&ref=v2.0.0"

  defaults = {
    enable_key_rotation = true
    deletion_window_in_days = 30
    tags = { Environment = "staging" }
  }

  items = {
    active_key = {
      enabled     = true
      description = "Active encryption key"
      aliases     = ["alias/staging-active"]
    }
    inactive_key = {
      enabled     = false
      description = "Pre-provisioned key for future feature"
      aliases     = ["alias/staging-future"]
    }
  }
}
```
