# SSM Parameter Store

OpenTofu module to create a single AWS SSM Parameter Store parameter with automatic type detection, write-only secret support, and lifecycle management.

## Features

- **Single Parameter Management** - Creates one SSM parameter with support for String, StringList, and SecureString types
- **Automatic Type Detection** - Infers the parameter type from the input: StringList when `parameter_values` is provided, otherwise SecureString by default (`secure_type = true`); set `secure_type = false` (or `type = "String"`) for plain values
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

  name                  = "/app/config/api-key"
  parameter_value       = "my-secret-key"
  parameter_description = "API key for external service"
  secure_type           = true
  key_id                = "arn:aws:kms:us-east-1:123456789012:key/abcd-1234"

  tags = {
    Environment = "production"
  }
}
```


> [!IMPORTANT]
> **BREAKING:** `secure_type` now defaults to `true`, so parameters created without an explicit `type` are stored as **SecureString** by default. Callers relying on the old inferred `String` type must set `type = "String"` (or `secure_type = false`) to keep the previous behaviour — otherwise the parameter will be updated to SecureString.
>
> Parameter value outputs are sensitive (`value`, `raw_value`, `secure_value`). Only the `insecure_value` output is non-sensitive, and it is populated exclusively for `String` type parameters (null for SecureString and StringList). One of `parameter_value`, `parameter_values`, or `value_wo` must be provided when the module is enabled.

## Examples

## Basic String Parameter

Store a plain configuration value as a `String` type SSM parameter.

```hcl
module "ssm_param_region" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ssm-parameter-store?depth=1&ref=master"

  enabled = true

  name                  = "/production/myapp/aws_region"
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

  name                  = "/production/myapp/db_password"
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

  name                  = "/production/infra/private_subnet_ids"
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

  name                  = "/production/myapp/service_config"
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

## Reference

<details>
<summary>Requirements, providers, inputs and outputs (generated by terraform-docs)</summary>

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11.0 |
| aws | >= 6.49, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.49, < 7.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| allowed\_pattern | Regular expression used to validate the parameter value. | `string` | `null` | no |
| data\_type | Data type of the parameter. Valid values: text, aws:ssm:integration and aws:ec2:image for AMI format. | `string` | `null` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| ignore\_value\_changes | Whether to create SSM Parameter and ignore changes in value | `bool` | `false` | no |
| key\_id | KMS key ID or ARN for encrypting a parameter (when type is SecureString) | `string` | `null` | no |
| name | Name of SSM parameter | `string` | `null` | no |
| parameter\_description | Description of the parameter | `string` | `null` | no |
| parameter\_value | Value of the parameter | `string` | `null` | no |
| parameter\_values | List of values of the parameter (will be jsonencoded to store as string natively in SSM) | `list(string)` | `[]` | no |
| secure\_type | Whether the inferred parameter type (when `type` is not set) should be SecureString. Defaults to true so single-value parameters are encrypted unless explicitly opted out | `bool` | `true` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| tier | Parameter tier to assign to the parameter. If not specified, will use the default parameter tier for the region. Valid tiers are Standard, Advanced, and Intelligent-Tiering. Downgrading an Advanced tier parameter to Standard will recreate the resource. | `string` | `null` | no |
| type | Type of the parameter. Valid types are String, StringList and SecureString. | `string` | `null` | no |
| value\_wo | Write-only value of the parameter. Never stored to state. Requires value\_wo\_version to trigger updates. Use instead of parameter\_value for SecureString parameters to keep values out of state. | `string` | `null` | no |
| value\_wo\_version | Increment this number to trigger an update when using value\_wo. Required when value\_wo is set. | `number` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| insecure\_value | Insecure value of the parameter. Only populated for String type parameters; null for StringList and SecureString |
| raw\_value | Raw value of the parameter (as it is stored in SSM). Use 'value' output to get jsondecode'd value |
| secure\_type | Whether SSM parameter is a SecureString or not? |
| secure\_value | Secure value of the parameter |
| ssm\_parameter\_arn | The ARN of the parameter |
| ssm\_parameter\_name | Name of the parameter |
| ssm\_parameter\_tags\_all | All tags used for the parameter |
| ssm\_parameter\_type | Type of the parameter |
| ssm\_parameter\_version | Version of the parameter |
| value | Parameter value after jsondecode(). Probably this is what you are looking for |
<!-- END_TF_DOCS -->

</details>
