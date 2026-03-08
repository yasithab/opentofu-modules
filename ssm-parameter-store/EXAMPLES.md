# SSM Parameter Store Module - Examples

## Basic String Parameter

Store a plain configuration value as a `String` type SSM parameter.

```hcl
module "ssm_param_region" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ssm-parameter-store?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//ssm-parameter-store?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//ssm-parameter-store?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//ssm-parameter-store?depth=1&ref=v2.0.0"

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
