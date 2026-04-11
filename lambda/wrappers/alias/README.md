# Lambda Alias Wrapper

Wrapper module that allows creating multiple Lambda aliases using a single module block with a `for_each`-driven interface. Each item in the `items` map creates a separate alias instance via the `lambda/modules/alias` submodule, while shared settings can be defined once in `defaults`.

## Features

- **Bulk alias creation** - Create multiple Lambda aliases from a single module block using a map of items
- **Shared defaults** - Define common configuration once in the `defaults` variable, with per-item overrides
- **Full feature parity** - Passes through all parameters supported by the alias submodule, including async event config, allowed triggers, event source mappings, and routing weights

## Usage

```hcl
module "lambda_alias" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/wrappers/alias?depth=1&ref=master"

  defaults = {
    refresh_alias = true
  }

  items = {
    production = {
      name             = "production"
      function_name    = "my-function"
      function_version = "5"
    }
    staging = {
      name             = "staging"
      function_name    = "my-function"
      function_version = "4"
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| defaults | Map of default values which will be used for each item | `any` | `{}` | no |
| items | Maps of items to create a wrapper from. Values are passed through to the module | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| wrapper | Map of outputs of the wrapper, keyed by each item's key |


## Examples

The `lambda/wrappers/alias` module creates multiple Lambda aliases in a single call
using `items` (per-alias configuration) and `defaults` (shared baseline settings).

## Basic Usage

Create `live` aliases for two Lambda functions pointing to their latest published versions.

```hcl
module "lambda_aliases" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/wrappers/alias?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/wrappers/alias?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/wrappers/alias?depth=1&ref=master"

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
