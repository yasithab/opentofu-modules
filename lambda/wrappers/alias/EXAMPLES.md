# Lambda Wrappers Alias Module - Examples

The `lambda/wrappers/alias` module creates multiple Lambda aliases in a single call
using `items` (per-alias configuration) and `defaults` (shared baseline settings).

## Basic Usage

Create `live` aliases for two Lambda functions pointing to their latest published versions.

```hcl
module "lambda_aliases" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/wrappers/alias?depth=1&ref=v2.0.0"

  defaults = {
    name          = "live"
    description   = "Production traffic alias"
    refresh_alias = true
  }

  items = {
    api_handler = {
      function_name    = "api-handler"
      function_version = module.lambda_functions.lambda_function_version["api_handler"]
    }
    event_processor = {
      function_name    = "event-processor"
      function_version = module.lambda_functions.lambda_function_version["event_processor"]
    }
  }
}
```

## With Canary Traffic Shifting

Route 5 % of traffic to the new version for each function during a canary rollout.

```hcl
module "lambda_aliases_canary" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/wrappers/alias?depth=1&ref=v2.0.0"

  defaults = {
    name          = "live"
    refresh_alias = true
  }

  items = {
    api_handler = {
      function_name    = "api-handler"
      function_version = "10"
      routing_additional_version_weights = { "11" = 0.05 }
    }
    event_processor = {
      function_name    = "event-processor"
      function_version = "7"
      routing_additional_version_weights = { "8" = 0.05 }
    }
  }
}
```

## With Async Event Configuration

Configure async retry and dead letter destinations across multiple function aliases.

```hcl
module "lambda_aliases_async" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/wrappers/alias?depth=1&ref=v2.0.0"

  defaults = {
    name                        = "live"
    create_async_event_config   = true
    maximum_retry_attempts      = 1
    maximum_event_age_in_seconds = 3600
    destination_on_failure      = "arn:aws:sqs:us-east-1:123456789012:global-dlq"
  }

  items = {
    order_processor = {
      function_name    = "order-processor"
      function_version = module.lambda_functions.lambda_function_version["order_processor"]
    }
    payment_processor = {
      function_name    = "payment-processor"
      function_version = module.lambda_functions.lambda_function_version["payment_processor"]
      destination_on_failure = "arn:aws:sqs:us-east-1:123456789012:payment-dlq"
    }
  }
}
```
