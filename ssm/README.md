# SSM

OpenTofu module to read and write AWS SSM Parameter Store parameters in bulk, with support for SecureString encryption and lifecycle management.

## Features

- **Bulk Parameter Write** - Create or update multiple SSM parameters at once from a list of parameter definitions with configurable defaults
- **Bulk Parameter Read** - Read existing SSM parameters by name and expose their values as outputs
- **SecureString Support** - Automatically encrypts SecureString parameters with an optional custom KMS key
- **Write-Only Values** - Per-entry `value_wo`/`value_wo_version` keep parameter values out of OpenTofu state entirely (preferred for secrets)
- **Configurable Defaults** - Set default type, tier, allowed pattern, and data type for all written parameters
- **Ignore Value Changes** - Optionally ignore future external changes to parameter values after initial creation, useful for secrets managed outside of OpenTofu
- **Combined Outputs** - Provides consolidated name lists, value lists, name-to-value maps, and name-to-ARN maps across all read and written parameters
- **Lifecycle Management** - Toggle resource creation on or off with the `enabled` variable

## Usage

```hcl
module "ssm" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ssm?depth=1&ref=master"

  parameter_write = [
    {
      name        = "/app/database/host"
      value       = "db.example.com"
      type        = "String"
      description = "Database hostname"
    },
    {
      name        = "/app/database/password"
      value       = "supersecret"
      type        = "SecureString"
      description = "Database password"
    }
  ]

  parameter_read = [
    "/shared/config/region"
  ]

  kms_arn = "arn:aws:kms:us-east-1:123456789012:key/abcd-1234"

  tags = {
    Environment = "production"
  }
}
```


> [!NOTE]
> - `parameter_write` is marked `sensitive`, so entry values never appear in plan output. Prefer `value_wo` + `value_wo_version` over `value` for secrets — write-only values are never stored in state. Bump `value_wo_version` to push a new value.
> - The deprecated `overwrite` argument has been removed; drop it from your entries and from any custom `parameter_write_defaults`.
> - `parameter_read` data sources are now addressed by parameter name instead of list index (`data.aws_ssm_parameter.read["/name"]`). This is a state address change for data sources only — they are simply re-read on the next plan; no managed resources are affected.
> - The `names`/`values`/`map`/`arn_map` outputs are built from a single name-keyed map, so they always stay aligned.

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
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| ignore\_value\_changes | Whether to ignore future external changes in paramater values | `bool` | `false` | no |
| kms\_arn | The ARN of a KMS key used to encrypt and decrypt SecretString values | `string` | `null` | no |
| parameter\_read | List of parameters to read from SSM. These must already exist otherwise an error is returned. Can be used with `parameter_write` as long as the parameters are different. | `list(string)` | `[]` | no |
| parameter\_write | List of maps with the parameter values to write to SSM Parameter Store. Each map supports `name` (required), `value`, `type`, `description`, `tier`, `allowed_pattern`, `data_type`, and write-only `value_wo`/`value_wo_version` (preferred over `value` to keep values out of state) | `list(map(string))` | `[]` | no |
| parameter\_write\_defaults | Parameter write default settings | `map(any)` | <pre>{<br/>  "allowed_pattern": null,<br/>  "data_type": "text",<br/>  "description": null,<br/>  "tier": "Standard",<br/>  "type": "SecureString",<br/>  "value": null,<br/>  "value_wo": null,<br/>  "value_wo_version": null<br/>}</pre> | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| arn\_map | A map of the names and ARNs created |
| map | A map of the names and values created |
| names | A list of all of the parameter names |
| values | A list of all of the parameter values, aligned with the `names` output |
<!-- END_TF_DOCS -->

## Examples

## Write Secrets with Write-Only Values (recommended)

Write-only values are sent to AWS but never persisted in OpenTofu state. Increment `value_wo_version` whenever the value changes.

```hcl
module "ssm_secrets_wo" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ssm?depth=1&ref=master"

  kms_arn = "arn:aws:kms:eu-west-1:123456789012:key/mrk-00000000000000000000000000000000"

  parameter_write = [
    {
      name             = "/production/myapp/db_password"
      type             = "SecureString"
      value_wo         = var.db_password
      value_wo_version = "1" # bump to rotate
      description      = "Database password for MyApp"
    },
  ]
}
```

## Write Plain String Parameters

Write application configuration values as plain `String` type parameters.

```hcl
module "ssm_config" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ssm?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//ssm?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//ssm?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//ssm?depth=1&ref=master"

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
