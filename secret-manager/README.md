# Secret Manager

OpenTofu module for managing AWS Secrets Manager secrets with support for versioning, rotation, replication, and resource policies.

## Features

- **Secret Management** - Create and manage secrets with configurable recovery windows and KMS encryption
- **Secret Versioning** - Manage secret versions with support for string, binary, and write-only values
- **Write-Only Secrets** - Store secrets using OpenTofu write-only attributes to keep values out of state (requires OpenTofu >= 1.11.0)
- **Random Password Generation** - Optionally generate random passwords with configurable length and special characters
- **Automatic Rotation** - Configure Lambda-based secret rotation with customizable schedules and immediate rotation support
- **Cross-Region Replication** - Replicate secrets to other AWS regions with per-region KMS key configuration
- **Resource Policies** - Attach IAM resource policies using inline statements, pre-built JSON documents, or merged policy documents with public policy blocking
- **Ignore External Changes** - Optionally ignore external modifications to secret values for rotation or application-managed secrets

## Usage

```hcl
module "secret" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//secret-manager?depth=1&ref=master"

  name          = "/production/myapp/api-key"
  description   = "API key for MyApp"
  secret_string = jsonencode({ api_key = "value" })

  tags = {
    Environment = "production"
  }
}
```


## Examples

## Basic Secret with Static Value

Store a static secret string in AWS Secrets Manager with the default 30-day recovery window.

```hcl
module "secret_api_key" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//secret-manager?depth=1&ref=master"

  enabled = true
  name    = "/production/myapp/api-key"

  description   = "Third-party API key for MyApp"
  secret_string = jsonencode({
    api_key    = "supersecretvalue"
    api_secret = "anothersecretvalue"
  })

  tags = {
    Environment = "production"
    Application = "myapp"
    Team        = "platform"
  }
}
```

## Write-Only Secret (State-Safe)

Use `secret_string_wo` to store a secret without ever writing its value to Terraform state. Increment `secret_string_wo_version` to trigger rotation.

```hcl
module "secret_db_password" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//secret-manager?depth=1&ref=master"

  enabled = true
  name    = "/production/myapp/db-password"

  description              = "Database master password for MyApp RDS instance"
  secret_string_wo         = var.db_master_password
  secret_string_wo_version = 1

  kms_key_id              = "arn:aws:kms:eu-west-1:123456789012:key/mrk-00000000000000000000000000000000"
  recovery_window_in_days = 7

  tags = {
    Environment = "production"
    Application = "myapp"
    DataClass   = "confidential"
  }
}
```

## Secret with Cross-Region Replication

Replicate a secret to a disaster-recovery region to ensure availability during a regional outage.

```hcl
module "secret_replicated" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//secret-manager?depth=1&ref=master"

  enabled = true
  name    = "/production/shared/service-token"

  description   = "Service-to-service authentication token"
  secret_string = var.service_token

  replica = {
    eu-central-1 = {
      kms_key_id = "arn:aws:kms:eu-central-1:123456789012:key/mrk-11111111111111111111111111111111"
    }
  }

  recovery_window_in_days = 30

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Secret with Automatic Rotation

Enable automatic rotation via a Lambda function for a database credential, rotating every 30 days.

```hcl
module "secret_with_rotation" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//secret-manager?depth=1&ref=master"

  enabled = true
  name    = "/production/myapp/rds-credentials"

  description   = "RDS credentials with automatic rotation"
  secret_string = jsonencode({
    username = "myapp_user"
    password = var.initial_db_password
    host     = "myapp.cluster-abcdefgh.eu-west-1.rds.amazonaws.com"
    port     = 5432
    dbname   = "myapp"
  })

  kms_key_id = "arn:aws:kms:eu-west-1:123456789012:key/mrk-00000000000000000000000000000000"

  enable_rotation    = true
  rotation_lambda_arn = "arn:aws:lambda:eu-west-1:123456789012:function:SecretsManagerRDSRotation"
  rotate_immediately = false

  rotation_rules = {
    automatically_after_days = 30
  }

  recovery_window_in_days = 7

  tags = {
    Environment = "production"
    Application = "myapp"
    Team        = "platform"
  }
}
```
