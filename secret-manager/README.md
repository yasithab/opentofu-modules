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


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11.0 |
| aws | >= 6.49, < 7.0 |
| random | ~> 3.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.49, < 7.0 |
| random | ~> 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| block\_public\_policy | Makes an optional API call to Zelkova to validate the Resource Policy to prevent broad access to your secret | `bool` | `null` | no |
| create\_policy | Determines whether a policy will be created | `bool` | `false` | no |
| create\_random\_password | Determines whether a random password will be generated | `bool` | `false` | no |
| description | A description of the secret | `string` | `null` | no |
| enable\_rotation | Determines whether secret rotation is enabled | `bool` | `false` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| force\_overwrite\_replica\_secret | Accepts boolean value to specify whether to overwrite a secret with the same name in the destination Region | `bool` | `null` | no |
| ignore\_secret\_changes | Determines whether or not OpenTofu will ignore changes made externally to `secret_string` or `secret_binary`. Changing this value after creation is a destructive operation | `bool` | `false` | no |
| kms\_key\_id | ARN or Id of the AWS KMS key to be used to encrypt the secret values in the versions stored in this secret. If you need to reference a CMK in a different account, you can use only the key ARN. If you don't specify this value, then Secrets Manager defaults to using the AWS account's default KMS key (the one named `aws/secretsmanager` | `string` | `null` | no |
| name | Friendly name of the new secret. The secret name can consist of uppercase letters, lowercase letters, digits, and any of the following characters: `/_+=.@-` | `string` | `null` | no |
| name\_prefix | Creates a unique name beginning with the specified prefix | `string` | `null` | no |
| override\_policy\_documents | List of IAM policy documents that are merged together into the exported document. In merging, statements with non-blank `sid`s will override statements with the same `sid` | `list(string)` | `[]` | no |
| policy\_statements | A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage | `map(any)` | `{}` | no |
| random\_password\_length | The length of the generated random password | `number` | `32` | no |
| random\_password\_override\_special | Supply your own list of special characters to use for string generation. This overrides the default character list in the special argument | `string` | `"!@#$%&*()-_=+[]{}<>:?"` | no |
| recovery\_window\_in\_days | Number of days that AWS Secrets Manager waits before it can delete the secret. Must be 0 (force delete, no recovery) or 7-30. The default value is 30. | `number` | `30` | no |
| replica | Configuration block to support secret replication. The map key is used as the replica region when `region` is not set | <pre>map(object({<br/>    kms_key_id = optional(string)<br/>    region     = optional(string)<br/>  }))</pre> | `{}` | no |
| rotate\_immediately | Whether to rotate the secret immediately or wait until the next scheduled rotation window. Defaults to true. Only applies when enable\_rotation is true | `bool` | `null` | no |
| rotation\_lambda\_arn | Specifies the ARN of the Lambda function that can rotate the secret | `string` | `null` | no |
| rotation\_rules | A structure that defines the rotation configuration for this secret | <pre>object({<br/>    automatically_after_days = optional(number)<br/>    duration                 = optional(string)<br/>    schedule_expression      = optional(string)<br/>  })</pre> | `{}` | no |
| secret\_binary | Specifies binary data that you want to encrypt and store in this version of the secret. This is required if `secret_string` is not set. Needs to be encoded to base64 | `string` | `null` | no |
| secret\_resource\_policy | A valid JSON document representing a resource policy. When set, this is applied directly to the secret (alternative to create\_policy). Note: conflicts with create\_policy. | `string` | `null` | no |
| secret\_string | Specifies text data that you want to encrypt and store in this version of the secret. This is required if `secret_binary` or `secret_string_wo` is not set. Note: this value is stored in the OpenTofu state - prefer `secret_string_wo` where possible | `string` | `null` | no |
| secret\_string\_wo | Write-only text data to encrypt and store in this version of the secret. Requires OpenTofu >= 1.11.0. Mutually exclusive with secret\_string. | `string` | `null` | no |
| secret\_string\_wo\_version | Increment this value to trigger an update when secret\_string\_wo changes. | `number` | `null` | no |
| source\_policy\_documents | List of IAM policy documents that are merged together into the exported document. Statements must have unique `sid`s | `list(string)` | `[]` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| version\_stages | Specifies a list of staging labels that are attached to this version of the secret. A staging label must be unique to a single version of the secret | `list(string)` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| secret\_arn | The ARN of the secret |
| secret\_binary | The secret binary |
| secret\_id | The ID of the secret |
| secret\_name | The name of the secret |
| secret\_replica | Attributes of the replica created |
| secret\_string | The secret string |
| secret\_version\_id | The unique identifier of the version of the secret |
<!-- END_TF_DOCS -->

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

## Secret Value Precedence and State Safety

The initial secret value written by this module is resolved with the same precedence in both
secret version resources (`this` and `ignore_changes`):

1. `random_password` result — when `create_random_password = true` (wins over `secret_string`)
2. `secret_string`
3. `secret_binary` / `secret_string_wo` (provider-level attributes, mutually handled by the provider)

`secret_string` and `secret_string_wo` are mutually exclusive — validation fails if both are set.

State-safety notes:

- **Prefer `secret_string_wo`** (write-only, requires OpenTofu >= 1.11): the value is never
  persisted to state. Bump `secret_string_wo_version` to push a new value.
- `secret_string` and `secret_binary` are stored (encrypted at rest only if your state backend
  encrypts) in the OpenTofu state.
- `create_random_password` generates the value with the `random_password` resource, whose result
  **is stored in state**. Treat state access as secret access, or prefer `secret_string_wo` with
  an externally generated value.

## Rotation Requirements

When `enable_rotation = true`:

- `rotation_lambda_arn` is required (validation enforced).
- An initial secret value must be provided via `create_random_password`, `secret_string`,
  `secret_string_wo` or `secret_binary`. Earlier versions of this module silently wrote the
  placeholder string `"default"` as the live secret value when no source was given; this now
  fails validation instead.

The same initial-value requirement applies when `ignore_secret_changes = true`.
