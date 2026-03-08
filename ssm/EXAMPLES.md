# SSM Module - Examples

## Write Plain String Parameters

Write application configuration values as plain `String` type parameters.

```hcl
module "ssm_config" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ssm?depth=1&ref=v2.0.0"

  enabled = true

  parameter_write = [
    {
      name        = "/production/myapp/database_host"
      value       = "myapp.cluster-abcdefgh.eu-west-1.rds.amazonaws.com"
      type        = "String"
      description = "RDS cluster endpoint for MyApp"
    },
    {
      name        = "/production/myapp/database_port"
      value       = "5432"
      type        = "String"
      description = "RDS port for MyApp"
    },
    {
      name        = "/production/myapp/region"
      value       = "eu-west-1"
      type        = "String"
      description = "AWS region for MyApp"
    },
  ]

  tags = {
    Environment = "production"
    Application = "myapp"
    Team        = "platform"
  }
}
```

## Write Secure String Parameters with KMS Encryption

Store sensitive credentials as `SecureString` parameters, encrypted with a customer-managed KMS key.

```hcl
module "ssm_secrets" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ssm?depth=1&ref=v2.0.0"

  enabled = true

  kms_arn = "arn:aws:kms:eu-west-1:123456789012:key/mrk-00000000000000000000000000000000"

  parameter_write = [
    {
      name        = "/production/myapp/db_password"
      value       = var.db_password
      type        = "SecureString"
      description = "Database password for MyApp"
    },
    {
      name        = "/production/myapp/jwt_secret"
      value       = var.jwt_secret
      type        = "SecureString"
      description = "JWT signing secret"
    },
  ]

  tags = {
    Environment = "production"
    DataClass   = "confidential"
    Team        = "platform"
  }
}
```

## Read Existing Parameters

Read parameters already stored in SSM (managed by another team or pipeline) for use as data sources.

```hcl
module "ssm_read" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ssm?depth=1&ref=v2.0.0"

  enabled = true

  parameter_read = [
    "/shared/infra/vpc_id",
    "/shared/infra/private_subnet_ids",
    "/shared/infra/kms_key_arn",
  ]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Write Parameters with Ignore Value Changes

Write initial parameter values and then ignore external changes, useful for parameters whose values are managed by an application or CI/CD pipeline after initial creation.

```hcl
module "ssm_managed_by_app" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ssm?depth=1&ref=v2.0.0"

  enabled              = true
  ignore_value_changes = true

  kms_arn = "arn:aws:kms:eu-west-1:123456789012:key/mrk-00000000000000000000000000000000"

  parameter_write = [
    {
      name        = "/production/myapp/oauth_client_secret"
      value       = "initial-placeholder"
      type        = "SecureString"
      description = "OAuth client secret - rotated by the application"
    },
    {
      name        = "/production/myapp/feature_flags"
      value       = "{}"
      type        = "String"
      description = "Feature flag JSON - updated by the feature flag service"
    },
  ]

  tags = {
    Environment = "production"
    ManagedBy   = "application"
    Team        = "platform"
  }
}
```
