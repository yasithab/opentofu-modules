# SSM Parameter Store

OpenTofu module to create a single AWS SSM Parameter Store parameter with automatic type detection, write-only secret support, and lifecycle management.

## Features

- **Single Parameter Management** - Creates one SSM parameter with support for String, StringList, and SecureString types
- **Automatic Type Detection** - Infers the parameter type from the input: uses SecureString when `secure_type` is true, StringList when `parameter_values` is provided, and String otherwise
- **Write-Only Values** - Supports `value_wo` and `value_wo_version` to store secrets that are never persisted to state, keeping sensitive data out of OpenTofu state files
- **StringList Support** - Accepts a list of string values via `parameter_values`, which are automatically JSON-encoded for native SSM StringList storage
- **KMS Encryption** - Optional KMS key for encrypting SecureString parameters
- **Ignore Value Changes** - Optionally ignore future external changes to parameter values after initial creation, useful for secrets rotated outside of OpenTofu
- **Validation** - Supports allowed pattern regex validation and data type constraints (text, aws:ssm:integration, aws:ec2:image)
- **Lifecycle Management** - Toggle resource creation on or off with the `enabled` variable

## Usage

```hcl
module "ssm_parameter" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ssm-parameter-store?depth=1&ref=master"

  parameter_name        = "/app/config/api-key"
  parameter_value       = "my-secret-key"
  parameter_description = "API key for external service"
  secure_type           = true
  key_id                = "arn:aws:kms:us-east-1:123456789012:key/abcd-1234"

  tags = {
    Environment = "production"
  }
}
```


## Examples

## Basic String Parameter

Store a plain configuration value as a `String` type SSM parameter.

```hcl
module "ssm_param_region" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ssm-parameter-store?depth=1&ref=master"

  enabled = true

  parameter_name        = "/production/myapp/aws_region"
  parameter_value       = "eu-west-1"
  parameter_description = "AWS region for MyApp"
  type                  = "String"

  tags = {
    Environment = "production"
    Application = "myapp"
    Team        = "platform"
  }
}
```

## Secure String Parameter with KMS

Store a sensitive value encrypted with a customer-managed KMS key, keeping the value out of Terraform state using `value_wo`.

```hcl
module "ssm_param_db_password" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ssm-parameter-store?depth=1&ref=master"

  enabled = true

  parameter_name        = "/production/myapp/db_password"
  parameter_description = "Database master password for MyApp"
  type                  = "SecureString"
  secure_type           = true

  value_wo         = var.db_master_password
  value_wo_version = 1

  key_id = "arn:aws:kms:eu-west-1:123456789012:key/mrk-00000000000000000000000000000000"

  tags = {
    Environment = "production"
    DataClass   = "confidential"
    Team        = "platform"
  }
}
```

## String List Parameter

Store a comma-separated list of subnet IDs as a `StringList` parameter for consumption by EC2 Auto Scaling groups.

```hcl
module "ssm_param_subnets" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ssm-parameter-store?depth=1&ref=master"

  enabled = true

  parameter_name        = "/production/infra/private_subnet_ids"
  parameter_description = "Private subnet IDs for production VPC"
  type                  = "StringList"

  parameter_values = [
    "subnet-0aaaa111111111111",
    "subnet-0bbbb222222222222",
    "subnet-0cccc333333333333",
  ]

  tags = {
    Environment = "production"
    Team        = "networking"
  }
}
```

## Advanced Tier Parameter with Ignore Value Changes

Create an Advanced tier parameter for values larger than 4KB, and ignore future external changes so the application can update the value without Terraform reverting it.

```hcl
module "ssm_param_config_blob" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ssm-parameter-store?depth=1&ref=master"

  enabled = true

  parameter_name        = "/production/myapp/service_config"
  parameter_description = "Full service configuration blob managed by the application"
  type                  = "String"
  tier                  = "Advanced"

  parameter_value      = jsonencode({ version = "1.0", features = {} })
  ignore_value_changes = true

  allowed_pattern = ".*"

  tags = {
    Environment = "production"
    ManagedBy   = "application"
    Team        = "platform"
  }
}
```
