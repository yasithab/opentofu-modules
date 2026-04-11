# Lambda Deploy

Submodule for deploying AWS Lambda functions using AWS CodeDeploy with blue/green deployment strategy. Manages CodeDeploy applications, deployment groups, IAM roles, and triggers deployments via the AWS CLI.

## Features

- **Blue/green deployments** - Performs blue/green Lambda deployments with traffic shifting through AWS CodeDeploy
- **CodeDeploy application management** - Creates or references an existing CodeDeploy application
- **Deployment group configuration** - Creates deployment groups with configurable deployment strategies (e.g., AllAtOnce, Linear, Canary)
- **Auto rollback** - Supports automatic rollback on deployment failure or CloudWatch alarm triggers
- **Lifecycle hooks** - Configures BeforeAllowTraffic and AfterAllowTraffic Lambda hooks for validation
- **IAM role management** - Creates or references an existing CodeDeploy IAM role with appropriate policies
- **Deployment triggers** - Sends SNS notifications on deployment lifecycle events
- **Wait for completion** - Optionally waits for the deployment to complete before returning

## Usage

```hcl
module "deploy" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/deploy?depth=1&ref=master"

  function_name  = "my-lambda-function"
  alias_name     = "production"
  target_version = "5"

  create_app              = true
  app_name                = "my-lambda-app"
  create_deployment_group = true
  deployment_group_name   = "my-deployment-group"
  create_deployment       = true
  run_deployment          = true

  deployment_config_name = "CodeDeployDefault.LambdaAllAtOnce"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enabled | Controls whether resources should be created | `bool` | `true` | no |
| function_name | The name of the Lambda function to deploy | `string` | `null` | no |
| alias_name | Name for the alias | `string` | `null` | no |
| current_version | Current version of the Lambda function (cannot be $LATEST) | `string` | `null` | no |
| target_version | Target version of the Lambda function to deploy | `string` | `null` | no |
| description | Description for the deployment | `string` | `null` | no |
| create_app | Whether to create a new CodeDeploy application | `bool` | `false` | no |
| app_name | Name of the CodeDeploy application | `string` | `null` | no |
| create_deployment_group | Whether to create a new CodeDeploy deployment group | `bool` | `false` | no |
| deployment_group_name | Name of the deployment group | `string` | `null` | no |
| deployment_config_name | Name of the deployment config to use | `string` | `"CodeDeployDefault.LambdaAllAtOnce"` | no |
| create_deployment | Create the AWS resources and script for CodeDeploy | `bool` | `false` | no |
| run_deployment | Run the AWS CLI command to start the deployment | `bool` | `false` | no |
| force_deploy | Force deployment every time, even when nothing changes | `bool` | `false` | no |
| wait_deployment_completion | Wait until deployment completes | `bool` | `false` | no |
| auto_rollback_enabled | Whether automatic rollback is enabled | `bool` | `true` | no |
| auto_rollback_events | List of event types that trigger a rollback | `list(string)` | `["DEPLOYMENT_STOP_ON_ALARM"]` | no |
| before_allow_traffic_hook_arn | ARN of Lambda function to execute before allowing traffic | `string` | `null` | no |
| after_allow_traffic_hook_arn | ARN of Lambda function to execute after allowing traffic | `string` | `null` | no |
| alarm_enabled | Whether the alarm configuration is enabled for the deployment group | `bool` | `false` | no |
| alarms | A list of CloudWatch alarm names configured for the deployment group (max 10) | `list(string)` | `[]` | no |
| alarm_ignore_poll_alarm_failure | Whether a deployment should continue if alarm state cannot be retrieved from CloudWatch | `bool` | `false` | no |
| create_codedeploy_role | Whether to create a new CodeDeploy IAM role | `bool` | `true` | no |
| tags | A map of tags to assign to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| codedeploy_app_name | Name of the CodeDeploy application |
| codedeploy_deployment_group_name | CodeDeploy deployment group name |
| codedeploy_deployment_group_id | CodeDeploy deployment group ID |
| codedeploy_iam_role_name | Name of the IAM role used by CodeDeploy |
| appspec | Appspec data as HCL |
| appspec_content | Appspec data as valid JSON |
| appspec_sha256 | SHA256 of Appspec JSON |
| script | Deployment script |
| deploy_script | Path to the deployment script |


## Examples

## Basic Usage

Create a CodeDeploy application and deployment group for a Lambda function with a linear deployment strategy.

```hcl
module "lambda_deploy" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/deploy?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/deploy?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/deploy?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//lambda/modules/deploy?depth=1&ref=master"

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
