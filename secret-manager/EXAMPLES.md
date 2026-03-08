# Secret Manager Module - Examples

## Basic Secret with Static Value

Store a static secret string in AWS Secrets Manager with the default 30-day recovery window.

```hcl
module "secret_api_key" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//secret-manager?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//secret-manager?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//secret-manager?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//secret-manager?depth=1&ref=v2.0.0"

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
