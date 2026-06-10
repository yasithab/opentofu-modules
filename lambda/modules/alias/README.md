# Lambda Alias

Submodule for creating and managing AWS Lambda function aliases. Supports alias creation, async event configuration, invocation permissions, and event source mappings on the alias.

## Features

- **Alias management** - Creates a Lambda alias pointing to a specific function version, or references an existing alias
- **Version refresh control** - Optionally refreshes the function version associated with the alias on each apply
- **Weighted routing** - Supports traffic shifting between multiple function versions via routing configuration
- **Async event configuration** - Configures maximum event age, retry attempts, and success/failure destinations for async invocations
- **Invocation permissions** - Creates Lambda permissions for allowed triggers on both the version and the qualified alias
- **Event source mappings** - Attaches event sources (SQS, Kinesis, DynamoDB, Kafka, DocumentDB, etc.) to the alias

## Usage

```hcl
module "alias" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/alias?depth=1&ref=master"

  name             = "production"
  function_name    = "my-lambda-function"
  function_version = "5"
  refresh_alias    = true

  allowed_triggers = {
    api_gateway = {
      service    = "apigateway"
      source_arn = "arn:aws:execute-api:us-east-1:123456789012:abcdefg/*/*/*"
    }
  }
}
```

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
| allowed\_triggers | Map of allowed triggers to create Lambda permissions | `map(any)` | `{}` | no |
| create\_async\_event\_config | Controls whether async event configuration for Lambda Function/Alias should be created | `bool` | `false` | no |
| create\_qualified\_alias\_allowed\_triggers | Whether to allow triggers on qualified alias | `bool` | `true` | no |
| create\_qualified\_alias\_async\_event\_config | Whether to allow async event configuration on qualified alias | `bool` | `true` | no |
| create\_version\_allowed\_triggers | Whether to allow triggers on version of Lambda Function used by alias (this will revoke permissions from previous version because Terraform manages only current resources) | `bool` | `true` | no |
| create\_version\_async\_event\_config | Whether to allow async event configuration on version of Lambda Function used by alias (this will revoke permissions from previous version because Terraform manages only current resources) | `bool` | `true` | no |
| description | Description of the alias. | `string` | `null` | no |
| destination\_on\_failure | Amazon Resource Name (ARN) of the destination resource for failed asynchronous invocations | `string` | `null` | no |
| destination\_on\_success | Amazon Resource Name (ARN) of the destination resource for successful asynchronous invocations | `string` | `null` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| event\_source\_mapping | Map of event source mapping | `any` | `{}` | no |
| function\_name | The function ARN of the Lambda function for which you want to create an alias. | `string` | `null` | no |
| function\_version | Lambda function version for which you are creating the alias. Pattern: ($LATEST\|[0-9]+). | `string` | `null` | no |
| maximum\_event\_age\_in\_seconds | Maximum age of a request that Lambda sends to a function for processing in seconds. Valid values between 60 and 21600. | `number` | `null` | no |
| maximum\_retry\_attempts | Maximum number of times to retry when the function returns an error. Valid values between 0 and 2. Defaults to 2. | `number` | `null` | no |
| name | Name for the alias you are creating. | `string` | `null` | no |
| refresh\_alias | Whether to refresh function version used in the alias. Useful when using this module together with external tool do deployments (eg, AWS CodeDeploy). | `bool` | `true` | no |
| routing\_additional\_version\_weights | A map that defines the proportion of events that should be sent to different versions of a lambda function. | `map(number)` | `{}` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| use\_existing\_alias | Whether to manage existing alias instead of creating a new one. Useful when using this module together with external tool do deployments (eg, AWS CodeDeploy). | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| lambda\_alias\_arn | The ARN of the Lambda Function Alias |
| lambda\_alias\_description | Description of alias |
| lambda\_alias\_event\_source\_mapping\_function\_arn | The the ARN of the Lambda function the event source mapping is sending events to |
| lambda\_alias\_event\_source\_mapping\_state | The state of the event source mapping |
| lambda\_alias\_event\_source\_mapping\_state\_transition\_reason | The reason the event source mapping is in its current state |
| lambda\_alias\_event\_source\_mapping\_uuid | The UUID of the created event source mapping |
| lambda\_alias\_function\_version | Lambda function version which the alias uses |
| lambda\_alias\_invoke\_arn | The ARN to be used for invoking Lambda Function from API Gateway |
| lambda\_alias\_name | The name of the Lambda Function Alias |
<!-- END_TF_DOCS -->

## Examples

## Basic Usage

Create a `live` alias pinned to the latest published version of a Lambda function.

```hcl
module "lambda_alias_live" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/alias?depth=1&ref=master"

  enabled = true

  name             = "live"
  description      = "Production traffic alias"
  function_name    = "my-api-handler"
  function_version = module.lambda.lambda_function_version
}
```

## With Traffic Shifting (Canary)

Route 10 % of production traffic to a new version while the remaining 90 % goes to the stable version.

```hcl
module "lambda_alias_canary" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/alias?depth=1&ref=master"

  enabled = true

  name             = "live"
  description      = "Canary deployment - 10 % on v42"
  function_name    = "my-api-handler"
  function_version = "41"

  routing_additional_version_weights = {
    "42" = 0.1
  }
}
```

## With Async Event Configuration

Set retry limits and on-failure destination for asynchronous invocations through the alias.

```hcl
module "lambda_alias_async" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/alias?depth=1&ref=master"

  enabled = true

  name             = "async-processor"
  description      = "Alias for async processing with DLQ routing"
  function_name    = "order-processor"
  function_version = module.lambda.lambda_function_version

  create_async_event_config   = true
  maximum_retry_attempts      = 1
  maximum_event_age_in_seconds = 3600
  destination_on_failure       = "arn:aws:sqs:us-east-1:123456789012:order-processor-dlq"
  destination_on_success       = "arn:aws:sns:us-east-1:123456789012:order-success-topic"
}
```

## With Allowed Triggers

Allow an API Gateway to invoke the function via the alias.

```hcl
module "lambda_alias_with_trigger" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/alias?depth=1&ref=master"

  enabled = true

  name             = "live"
  description      = "Production alias with API Gateway trigger"
  function_name    = "my-api-handler"
  function_version = module.lambda.lambda_function_version

  allowed_triggers = {
    apigw = {
      service    = "apigateway"
      source_arn = "arn:aws:execute-api:us-east-1:123456789012:abc1def2gh/*/*/*"
    }
  }
}
```
