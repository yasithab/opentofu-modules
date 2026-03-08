# Lambda Alias Module - Examples

## Basic Usage

Create a `live` alias pinned to the latest published version of a Lambda function.

```hcl
module "lambda_alias_live" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/alias?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/alias?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/alias?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/alias?depth=1&ref=v2.0.0"

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
