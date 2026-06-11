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

## Notes

- When `force_deploy = true`, the `null_resource.deploy` trigger uses `uuid()`, which produces a **perpetual diff**: every plan/apply will show the resource as changed and re-run the deployment. This is intentional - disable `force_deploy` to deploy only when the appspec changes.
- User-provided values (versions, names, description, appspec revision) are passed to the deployment script through environment variables rather than shell interpolation, so they cannot inject shell commands. `aws_cli_command` is still interpolated as the command itself by design.

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

## Reference

<details>
<summary>Requirements, providers, inputs and outputs (generated by terraform-docs)</summary>

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11.0 |
| aws | >= 6.49, < 7.0 |
| local | ~> 2.0 |
| null | ~> 3.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.49, < 7.0 |
| local | ~> 2.0 |
| null | ~> 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| after\_allow\_traffic\_hook\_arn | ARN of Lambda function to execute after allow traffic during deployment. This function should be named CodeDeployHook\_, to match the managed AWSCodeDeployForLambda policy, unless you're using a custom role | `string` | `null` | no |
| alarm\_enabled | Indicates whether the alarm configuration is enabled. This option is useful when you want to temporarily deactivate alarm monitoring for a deployment group without having to add the same alarms again later. | `bool` | `false` | no |
| alarm\_ignore\_poll\_alarm\_failure | Indicates whether a deployment should continue if information about the current state of alarms cannot be retrieved from CloudWatch. | `bool` | `false` | no |
| alarms | A list of alarms configured for the deployment group. A maximum of 10 alarms can be added to a deployment group. | `list(string)` | `[]` | no |
| alias\_name | Name for the alias | `string` | `null` | no |
| app\_name | Name of AWS CodeDeploy application | `string` | `null` | no |
| attach\_hooks\_policy | Whether to attach Invoke policy to CodeDeploy role when before allow traffic or after allow traffic hooks are defined. | `bool` | `true` | no |
| attach\_triggers\_policy | Whether to attach SNS policy to CodeDeploy role when triggers are defined | `bool` | `false` | no |
| auto\_rollback\_enabled | Indicates whether a defined automatic rollback configuration is currently enabled for this Deployment Group. | `bool` | `true` | no |
| auto\_rollback\_events | List of event types that trigger a rollback. Supported types are DEPLOYMENT\_FAILURE and DEPLOYMENT\_STOP\_ON\_ALARM. | `list(string)` | <pre>[<br/>  "DEPLOYMENT_STOP_ON_ALARM"<br/>]</pre> | no |
| aws\_cli\_command | Command to run as AWS CLI. May include extra arguments like region and profile. | `string` | `"aws"` | no |
| before\_allow\_traffic\_hook\_arn | ARN of Lambda function to execute before allow traffic during deployment. This function should be named CodeDeployHook\_, to match the managed AWSCodeDeployForLambda policy, unless you're using a custom role | `string` | `null` | no |
| codedeploy\_principals | List of CodeDeploy service principals to allow. The list can include global or regional endpoints. | `list(string)` | <pre>[<br/>  "codedeploy.amazonaws.com"<br/>]</pre> | no |
| codedeploy\_role\_name | IAM role name to create or use by CodeDeploy | `string` | `null` | no |
| create\_app | Whether to create new AWS CodeDeploy app | `bool` | `false` | no |
| create\_codedeploy\_role | Whether to create new AWS CodeDeploy IAM role | `bool` | `true` | no |
| create\_deployment | Create the AWS resources and script for CodeDeploy | `bool` | `false` | no |
| create\_deployment\_group | Whether to create new AWS CodeDeploy Deployment Group | `bool` | `false` | no |
| current\_version | Current version of Lambda function version to deploy (can't be $LATEST) | `string` | `null` | no |
| deployment\_config\_name | Name of deployment config to use | `string` | `"CodeDeployDefault.LambdaAllAtOnce"` | no |
| deployment\_group\_name | Name of deployment group to use | `string` | `null` | no |
| description | Description to use for the deployment | `string` | `""` | no |
| ec2\_tag\_filter | List of EC2 tag filters for the deployment group. Each filter has key, type (KEY\_ONLY, VALUE\_ONLY, KEY\_AND\_VALUE), and value. | `list(any)` | `[]` | no |
| ec2\_tag\_set | List of EC2 tag set filter groups. Each group contains a list of ec2\_tag\_filter objects. | `list(any)` | `[]` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| force\_deploy | Force deployment every time (even when nothing changes) | `bool` | `false` | no |
| function\_name | The name of the Lambda function to deploy | `string` | `null` | no |
| get\_deployment\_sleep\_timer | Adds additional sleep time to get-deployment command to avoid the service throttling | `number` | `5` | no |
| interpreter | List of interpreter arguments used to execute deploy script, first arg is path | `list(string)` | <pre>[<br/>  "/bin/bash",<br/>  "-c"<br/>]</pre> | no |
| outdated\_instances\_strategy | Indicates what happens when new Amazon EC2 instances are launched mid-deployment and do not receive the deployed application revision. Valid values are UPDATE and IGNORE. | `string` | `null` | no |
| run\_deployment | Run AWS CLI command to start the deployment | `bool` | `false` | no |
| save\_deploy\_script | Save deploy script locally | `bool` | `false` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| target\_version | Target version of Lambda function version to deploy | `string` | `null` | no |
| termination\_hook\_enabled | Indicates whether the deployment group was configured to have CodeDeploy install a termination hook into an Auto Scaling group. | `bool` | `null` | no |
| triggers | Map of triggers which will be notified when event happens. Valid options for event types are DeploymentStart, DeploymentSuccess, DeploymentFailure, DeploymentStop, DeploymentRollback, DeploymentReady (Applies only to replacement instances in a blue/green deployment), InstanceStart, InstanceSuccess, InstanceFailure, InstanceReady. Note that not all are applicable for Lambda deployments. | `map(any)` | `{}` | no |
| use\_existing\_app | Whether to use existing AWS CodeDeploy app | `bool` | `false` | no |
| use\_existing\_deployment\_group | Whether to use existing AWS CodeDeploy Deployment Group | `bool` | `false` | no |
| wait\_deployment\_completion | Wait until deployment completes. It can take a lot of time and your terraform process may lock execution for long time. | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| appspec | Appspec data as HCL |
| appspec\_content | Appspec data as valid JSON |
| appspec\_sha256 | SHA256 of Appspec JSON |
| codedeploy\_app\_name | Name of CodeDeploy application |
| codedeploy\_deployment\_group\_id | CodeDeploy deployment group id |
| codedeploy\_deployment\_group\_name | CodeDeploy deployment group name |
| codedeploy\_iam\_role\_name | Name of IAM role used by CodeDeploy |
| deploy\_script | Path to a deployment script |
| script | Deployment script |
<!-- END_TF_DOCS -->

</details>
