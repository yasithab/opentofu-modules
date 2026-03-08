# Lambda Deploy Module - Examples

## Basic Usage

Create a CodeDeploy application and deployment group for a Lambda function with a linear deployment strategy.

```hcl
module "lambda_deploy" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/deploy?depth=1&ref=v2.0.0"

  enabled = true

  function_name    = "my-api-handler"
  alias_name       = "live"
  current_version  = module.lambda.lambda_function_version
  target_version   = module.lambda_alias.lambda_alias_function_version

  create_app              = true
  app_name                = "my-api-handler"
  create_deployment_group = true
  deployment_group_name   = "my-api-handler-live"
  deployment_config_name  = "CodeDeployDefault.LambdaLinear10PercentEvery1Minute"

  auto_rollback_enabled = true
  auto_rollback_events  = ["DEPLOYMENT_FAILURE"]
}
```

## With CloudWatch Alarm Rollback

Automatically roll back if a CloudWatch error alarm fires during deployment.

```hcl
module "lambda_deploy_with_alarms" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/deploy?depth=1&ref=v2.0.0"

  enabled = true

  function_name    = "order-processor"
  alias_name       = "live"
  current_version  = "5"
  target_version   = "6"

  create_app              = true
  app_name                = "order-processor"
  create_deployment_group = true
  deployment_group_name   = "order-processor-live"
  deployment_config_name  = "CodeDeployDefault.LambdaCanary10Percent5Minutes"

  alarm_enabled                = true
  alarms                       = ["order-processor-error-rate"]
  alarm_ignore_poll_alarm_failure = false

  auto_rollback_enabled = true
  auto_rollback_events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
}
```

## With Pre/Post Traffic Hooks

Run validation Lambda functions before and after traffic is shifted to the new version.

```hcl
module "lambda_deploy_with_hooks" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/deploy?depth=1&ref=v2.0.0"

  enabled = true

  function_name    = "payment-service"
  alias_name       = "live"
  current_version  = "10"
  target_version   = "11"

  create_app              = true
  app_name                = "payment-service"
  create_deployment_group = true
  deployment_group_name   = "payment-service-live"
  deployment_config_name  = "CodeDeployDefault.LambdaCanary10Percent10Minutes"

  before_allow_traffic_hook_arn = "arn:aws:lambda:us-east-1:123456789012:function:CodeDeployHook_payment_pre_traffic"
  after_allow_traffic_hook_arn  = "arn:aws:lambda:us-east-1:123456789012:function:CodeDeployHook_payment_post_traffic"

  auto_rollback_enabled = true
  auto_rollback_events  = ["DEPLOYMENT_FAILURE"]
}
```

## Run Deployment Immediately

Create all CodeDeploy resources and trigger the deployment in the same apply.

```hcl
module "lambda_deploy_and_run" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/deploy?depth=1&ref=v2.0.0"

  enabled = true

  function_name    = "data-pipeline"
  alias_name       = "live"
  current_version  = "3"
  target_version   = "4"

  use_existing_app              = true
  app_name                      = "data-pipeline"
  use_existing_deployment_group = true
  deployment_group_name         = "data-pipeline-live"

  create_deployment          = true
  run_deployment             = true
  wait_deployment_completion = true

  description = "Deploy v4 of data pipeline"
}
```
