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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enabled | Controls whether resources should be created | `bool` | `true` | no |
| name | Name for the alias | `string` | `null` | no |
| description | Description of the alias | `string` | `null` | no |
| function_name | The function ARN of the Lambda function | `string` | `null` | no |
| function_version | Lambda function version for the alias. Pattern: ($LATEST\|[0-9]+) | `string` | `null` | no |
| use_existing_alias | Whether to use an existing alias instead of creating a new one | `bool` | `false` | no |
| refresh_alias | Whether to refresh the function version used in the alias | `bool` | `true` | no |
| routing_additional_version_weights | Map defining the proportion of events sent to different function versions | `map(number)` | `{}` | no |
| create_async_event_config | Controls whether async event configuration should be created | `bool` | `false` | no |
| maximum_event_age_in_seconds | Maximum age of a request for processing in seconds (60-21600) | `number` | `null` | no |
| maximum_retry_attempts | Maximum number of retries when the function returns an error (0-2) | `number` | `null` | no |
| destination_on_failure | ARN of the destination for failed asynchronous invocations | `string` | `null` | no |
| destination_on_success | ARN of the destination for successful asynchronous invocations | `string` | `null` | no |
| allowed_triggers | Map of allowed triggers to create Lambda permissions | `map(any)` | `{}` | no |
| event_source_mapping | Map of event source mappings | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| lambda_alias_name | The name of the Lambda Function Alias |
| lambda_alias_arn | The ARN of the Lambda Function Alias |
| lambda_alias_invoke_arn | The ARN for invoking the Lambda Function from API Gateway |
| lambda_alias_description | Description of the alias |
| lambda_alias_function_version | Lambda function version which the alias uses |
| lambda_alias_event_source_mapping_function_arn | The ARN of the Lambda function the event source mapping sends events to |
| lambda_alias_event_source_mapping_state | The state of the event source mapping |
| lambda_alias_event_source_mapping_uuid | The UUID of the created event source mapping |


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
