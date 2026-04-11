# Lambda Deploy Wrapper

Wrapper module that allows creating multiple Lambda CodeDeploy deployments using a single module block with a `for_each`-driven interface. Each item in the `items` map creates a separate deployment instance via the `lambda/modules/deploy` submodule, while shared settings can be defined once in `defaults`.

## Features

- **Bulk deployment management** - Manage multiple Lambda CodeDeploy deployments from a single module block using a map of items
- **Shared defaults** - Define common configuration once in the `defaults` variable, with per-item overrides
- **Full feature parity** - Passes through all parameters supported by the deploy submodule, including CodeDeploy app, deployment group, IAM role, rollback settings, and deployment triggers

## Usage

```hcl
module "lambda_deploy" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/wrappers/deploy?depth=1&ref=master"

  defaults = {
    create_app              = true
    create_deployment_group = true
    create_deployment       = true
    run_deployment          = true
    deployment_config_name  = "CodeDeployDefault.LambdaAllAtOnce"
  }

  items = {
    function_a = {
      app_name              = "function-a-deploy"
      deployment_group_name = "function-a-dg"
      function_name         = "function-a"
      alias_name            = "production"
      target_version        = "3"
    }
    function_b = {
      app_name              = "function-b-deploy"
      deployment_group_name = "function-b-dg"
      function_name         = "function-b"
      alias_name            = "production"
      target_version        = "7"
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

The `lambda/wrappers/deploy` module creates multiple Lambda CodeDeploy configurations
in a single call using `items` (per-deployment configuration) and `defaults` (shared baseline settings).

## Basic Usage

Set up CodeDeploy for two Lambda functions sharing the same all-at-once strategy.

```hcl
module "lambda_deployments" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/wrappers/deploy?depth=1&ref=master"

  defaults = {
    create_app              = true
    create_deployment_group = true
    deployment_config_name  = "CodeDeployDefault.LambdaAllAtOnce"
    auto_rollback_enabled   = true
    auto_rollback_events    = ["DEPLOYMENT_FAILURE"]
    alias_name              = "live"
  }

  items = {
    api_handler = {
      function_name         = "api-handler"
      app_name              = "api-handler"
      deployment_group_name = "api-handler-live"
      current_version       = "5"
      target_version        = "6"
    }
    event_processor = {
      function_name         = "event-processor"
      app_name              = "event-processor"
      deployment_group_name = "event-processor-live"
      current_version       = "3"
      target_version        = "4"
    }
  }
}
```

## With Canary Strategy and Alarm Rollback

Deploy both functions using a canary strategy with CloudWatch alarm-based auto-rollback.

```hcl
module "lambda_deployments_canary" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/wrappers/deploy?depth=1&ref=master"

  defaults = {
    create_app              = true
    create_deployment_group = true
    deployment_config_name  = "CodeDeployDefault.LambdaCanary10Percent5Minutes"
    auto_rollback_enabled   = true
    auto_rollback_events    = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
    alarm_enabled           = true
    alias_name              = "live"
  }

  items = {
    order_service = {
      function_name         = "order-service"
      app_name              = "order-service"
      deployment_group_name = "order-service-live"
      current_version       = "12"
      target_version        = "13"
      alarms                = ["order-service-5xx-alarm"]
    }
    payment_service = {
      function_name         = "payment-service"
      app_name              = "payment-service"
      deployment_group_name = "payment-service-live"
      current_version       = "8"
      target_version        = "9"
      alarms                = ["payment-service-error-alarm"]
    }
  }
}
```

## With Pre and Post Traffic Hook Functions

Use shared hook defaults with per-function hooks where needed.

```hcl
module "lambda_deployments_hooks" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/wrappers/deploy?depth=1&ref=master"

  defaults = {
    create_app              = true
    create_deployment_group = true
    deployment_config_name  = "CodeDeployDefault.LambdaLinear10PercentEvery1Minute"
    alias_name              = "live"
    auto_rollback_enabled   = true
    auto_rollback_events    = ["DEPLOYMENT_FAILURE"]
  }

  items = {
    checkout_service = {
      function_name                 = "checkout-service"
      app_name                      = "checkout-service"
      deployment_group_name         = "checkout-service-live"
      current_version               = "4"
      target_version                = "5"
      before_allow_traffic_hook_arn = "arn:aws:lambda:us-east-1:123456789012:function:CodeDeployHook_checkout_pre"
      after_allow_traffic_hook_arn  = "arn:aws:lambda:us-east-1:123456789012:function:CodeDeployHook_checkout_post"
    }
    notification_service = {
      function_name         = "notification-service"
      app_name              = "notification-service"
      deployment_group_name = "notification-service-live"
      current_version       = "2"
      target_version        = "3"
    }
  }
}
```
