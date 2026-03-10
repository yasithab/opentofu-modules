<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.34 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.34 |
| <a name="provider_local"></a> [local](#provider\_local) | ~> 2.0 |
| <a name="provider_null"></a> [null](#provider\_null) | ~> 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_after_allow_traffic_hook_arn"></a> [after\_allow\_traffic\_hook\_arn](#input\_after\_allow\_traffic\_hook\_arn) | ARN of Lambda function to execute after allow traffic during deployment. This function should be named CodeDeployHook\_, to match the managed AWSCodeDeployForLambda policy, unless you're using a custom role | `string` | `null` | no |
| <a name="input_alarm_enabled"></a> [alarm\_enabled](#input\_alarm\_enabled) | Indicates whether the alarm configuration is enabled. This option is useful when you want to temporarily deactivate alarm monitoring for a deployment group without having to add the same alarms again later. | `bool` | `false` | no |
| <a name="input_alarm_ignore_poll_alarm_failure"></a> [alarm\_ignore\_poll\_alarm\_failure](#input\_alarm\_ignore\_poll\_alarm\_failure) | Indicates whether a deployment should continue if information about the current state of alarms cannot be retrieved from CloudWatch. | `bool` | `false` | no |
| <a name="input_alarms"></a> [alarms](#input\_alarms) | A list of alarms configured for the deployment group. A maximum of 10 alarms can be added to a deployment group. | `list(string)` | `[]` | no |
| <a name="input_alias_name"></a> [alias\_name](#input\_alias\_name) | Name for the alias | `string` | `null` | no |
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | Name of AWS CodeDeploy application | `string` | `null` | no |
| <a name="input_attach_hooks_policy"></a> [attach\_hooks\_policy](#input\_attach\_hooks\_policy) | Whether to attach Invoke policy to CodeDeploy role when before allow traffic or after allow traffic hooks are defined. | `bool` | `true` | no |
| <a name="input_attach_triggers_policy"></a> [attach\_triggers\_policy](#input\_attach\_triggers\_policy) | Whether to attach SNS policy to CodeDeploy role when triggers are defined | `bool` | `false` | no |
| <a name="input_auto_rollback_enabled"></a> [auto\_rollback\_enabled](#input\_auto\_rollback\_enabled) | Indicates whether a defined automatic rollback configuration is currently enabled for this Deployment Group. | `bool` | `true` | no |
| <a name="input_auto_rollback_events"></a> [auto\_rollback\_events](#input\_auto\_rollback\_events) | List of event types that trigger a rollback. Supported types are DEPLOYMENT\_FAILURE and DEPLOYMENT\_STOP\_ON\_ALARM. | `list(string)` | <pre>[<br/>  "DEPLOYMENT_STOP_ON_ALARM"<br/>]</pre> | no |
| <a name="input_aws_cli_command"></a> [aws\_cli\_command](#input\_aws\_cli\_command) | Command to run as AWS CLI. May include extra arguments like region and profile. | `string` | `"aws"` | no |
| <a name="input_before_allow_traffic_hook_arn"></a> [before\_allow\_traffic\_hook\_arn](#input\_before\_allow\_traffic\_hook\_arn) | ARN of Lambda function to execute before allow traffic during deployment. This function should be named CodeDeployHook\_, to match the managed AWSCodeDeployForLambda policy, unless you're using a custom role | `string` | `null` | no |
| <a name="input_codedeploy_principals"></a> [codedeploy\_principals](#input\_codedeploy\_principals) | List of CodeDeploy service principals to allow. The list can include global or regional endpoints. | `list(string)` | <pre>[<br/>  "codedeploy.amazonaws.com"<br/>]</pre> | no |
| <a name="input_codedeploy_role_name"></a> [codedeploy\_role\_name](#input\_codedeploy\_role\_name) | IAM role name to create or use by CodeDeploy | `string` | `null` | no |
| <a name="input_create_app"></a> [create\_app](#input\_create\_app) | Whether to create new AWS CodeDeploy app | `bool` | `false` | no |
| <a name="input_create_codedeploy_role"></a> [create\_codedeploy\_role](#input\_create\_codedeploy\_role) | Whether to create new AWS CodeDeploy IAM role | `bool` | `true` | no |
| <a name="input_create_deployment"></a> [create\_deployment](#input\_create\_deployment) | Create the AWS resources and script for CodeDeploy | `bool` | `false` | no |
| <a name="input_create_deployment_group"></a> [create\_deployment\_group](#input\_create\_deployment\_group) | Whether to create new AWS CodeDeploy Deployment Group | `bool` | `false` | no |
| <a name="input_current_version"></a> [current\_version](#input\_current\_version) | Current version of Lambda function version to deploy (can't be $LATEST) | `string` | `null` | no |
| <a name="input_deployment_config_name"></a> [deployment\_config\_name](#input\_deployment\_config\_name) | Name of deployment config to use | `string` | `"CodeDeployDefault.LambdaAllAtOnce"` | no |
| <a name="input_deployment_group_name"></a> [deployment\_group\_name](#input\_deployment\_group\_name) | Name of deployment group to use | `string` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | Description to use for the deployment | `string` | `null` | no |
| <a name="input_ec2_tag_filter"></a> [ec2\_tag\_filter](#input\_ec2\_tag\_filter) | List of EC2 tag filters for the deployment group. Each filter has key, type (KEY\_ONLY, VALUE\_ONLY, KEY\_AND\_VALUE), and value. | `list(any)` | `[]` | no |
| <a name="input_ec2_tag_set"></a> [ec2\_tag\_set](#input\_ec2\_tag\_set) | List of EC2 tag set filter groups. Each group contains a list of ec2\_tag\_filter objects. | `list(any)` | `[]` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Controls whether resources should be created | `bool` | `true` | no |
| <a name="input_force_deploy"></a> [force\_deploy](#input\_force\_deploy) | Force deployment every time (even when nothing changes) | `bool` | `false` | no |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | The name of the Lambda function to deploy | `string` | `null` | no |
| <a name="input_get_deployment_sleep_timer"></a> [get\_deployment\_sleep\_timer](#input\_get\_deployment\_sleep\_timer) | Adds additional sleep time to get-deployment command to avoid the service throttling | `number` | `5` | no |
| <a name="input_interpreter"></a> [interpreter](#input\_interpreter) | List of interpreter arguments used to execute deploy script, first arg is path | `list(string)` | <pre>[<br/>  "/bin/bash",<br/>  "-c"<br/>]</pre> | no |
| <a name="input_outdated_instances_strategy"></a> [outdated\_instances\_strategy](#input\_outdated\_instances\_strategy) | Indicates what happens when new Amazon EC2 instances are launched mid-deployment and do not receive the deployed application revision. Valid values are UPDATE and IGNORE. | `string` | `null` | no |
| <a name="input_run_deployment"></a> [run\_deployment](#input\_run\_deployment) | Run AWS CLI command to start the deployment | `bool` | `false` | no |
| <a name="input_save_deploy_script"></a> [save\_deploy\_script](#input\_save\_deploy\_script) | Save deploy script locally | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to resources. | `map(string)` | `{}` | no |
| <a name="input_target_version"></a> [target\_version](#input\_target\_version) | Target version of Lambda function version to deploy | `string` | `null` | no |
| <a name="input_termination_hook_enabled"></a> [termination\_hook\_enabled](#input\_termination\_hook\_enabled) | Indicates whether the deployment group was configured to have CodeDeploy install a termination hook into an Auto Scaling group. | `bool` | `null` | no |
| <a name="input_triggers"></a> [triggers](#input\_triggers) | Map of triggers which will be notified when event happens. Valid options for event types are DeploymentStart, DeploymentSuccess, DeploymentFailure, DeploymentStop, DeploymentRollback, DeploymentReady (Applies only to replacement instances in a blue/green deployment), InstanceStart, InstanceSuccess, InstanceFailure, InstanceReady. Note that not all are applicable for Lambda deployments. | `map(any)` | `{}` | no |
| <a name="input_use_existing_app"></a> [use\_existing\_app](#input\_use\_existing\_app) | Whether to use existing AWS CodeDeploy app | `bool` | `false` | no |
| <a name="input_use_existing_deployment_group"></a> [use\_existing\_deployment\_group](#input\_use\_existing\_deployment\_group) | Whether to use existing AWS CodeDeploy Deployment Group | `bool` | `false` | no |
| <a name="input_wait_deployment_completion"></a> [wait\_deployment\_completion](#input\_wait\_deployment\_completion) | Wait until deployment completes. It can take a lot of time and your terraform process may lock execution for long time. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_appspec"></a> [appspec](#output\_appspec) | Appspec data as HCL |
| <a name="output_appspec_content"></a> [appspec\_content](#output\_appspec\_content) | Appspec data as valid JSON |
| <a name="output_appspec_sha256"></a> [appspec\_sha256](#output\_appspec\_sha256) | SHA256 of Appspec JSON |
| <a name="output_codedeploy_app_name"></a> [codedeploy\_app\_name](#output\_codedeploy\_app\_name) | Name of CodeDeploy application |
| <a name="output_codedeploy_deployment_group_id"></a> [codedeploy\_deployment\_group\_id](#output\_codedeploy\_deployment\_group\_id) | CodeDeploy deployment group id |
| <a name="output_codedeploy_deployment_group_name"></a> [codedeploy\_deployment\_group\_name](#output\_codedeploy\_deployment\_group\_name) | CodeDeploy deployment group name |
| <a name="output_codedeploy_iam_role_name"></a> [codedeploy\_iam\_role\_name](#output\_codedeploy\_iam\_role\_name) | Name of IAM role used by CodeDeploy |
| <a name="output_deploy_script"></a> [deploy\_script](#output\_deploy\_script) | Path to a deployment script |
| <a name="output_script"></a> [script](#output\_script) | Deployment script |
<!-- END_TF_DOCS -->