<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.34 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.34 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chatbot_role_name"></a> [chatbot\_role\_name](#input\_chatbot\_role\_name) | Override for the Chatbot IAM role name. Defaults to <name>-chatbot or chatbot-role. | `string` | `null` | no |
| <a name="input_create_teams_configuration"></a> [create\_teams\_configuration](#input\_create\_teams\_configuration) | Whether to create a Microsoft Teams channel configuration alongside the Slack configuration | `bool` | `false` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_guardrail_policies"></a> [guardrail\_policies](#input\_guardrail\_policies) | The list of IAM policy ARNs that are applied as channel guardrails. The AWS managed 'AdministratorAccess' policy is applied as a default if this is not set | `list(string)` | `null` | no |
| <a name="input_logging_level"></a> [logging\_level](#input\_logging\_level) | Specifies the logging level for this configuration: ERROR, INFO or NONE. This property affects the log entries pushed to Amazon CloudWatch logs | `string` | `"NONE"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to use for resource naming and tagging. | `string` | `null` | no |
| <a name="input_slack_channel_configuration_name"></a> [slack\_channel\_configuration\_name](#input\_slack\_channel\_configuration\_name) | The name of the Slack channel configuration. Required when enabled = true. | `string` | `null` | no |
| <a name="input_slack_channel_id"></a> [slack\_channel\_id](#input\_slack\_channel\_id) | The ID of the Slack channel. Required when enabled = true. | `string` | `null` | no |
| <a name="input_slack_workspace_id"></a> [slack\_workspace\_id](#input\_slack\_workspace\_id) | The ID of the Slack workspace (team) authorized with AWS Chatbot. Maps to the slack\_team\_id argument in the AWS provider (e.g., T07EA123LEP). Required when enabled = true. | `string` | `null` | no |
| <a name="input_sns_topic_arns"></a> [sns\_topic\_arns](#input\_sns\_topic\_arns) | ARNs of SNS topics which deliver notifications to AWS Chatbot, for example CloudWatch alarm notifications | `list(string)` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_teams_channel_id"></a> [teams\_channel\_id](#input\_teams\_channel\_id) | The ID of the Microsoft Teams channel | `string` | `null` | no |
| <a name="input_teams_channel_name"></a> [teams\_channel\_name](#input\_teams\_channel\_name) | The name of the Microsoft Teams channel | `string` | `null` | no |
| <a name="input_teams_configuration_name"></a> [teams\_configuration\_name](#input\_teams\_configuration\_name) | The name of the Microsoft Teams channel configuration | `string` | `null` | no |
| <a name="input_teams_guardrail_policies"></a> [teams\_guardrail\_policies](#input\_teams\_guardrail\_policies) | List of IAM policy ARNs applied as guardrails for the Teams channel | `list(string)` | `null` | no |
| <a name="input_teams_logging_level"></a> [teams\_logging\_level](#input\_teams\_logging\_level) | Logging level for the Teams channel configuration: ERROR, INFO or NONE | `string` | `"NONE"` | no |
| <a name="input_teams_sns_topic_arns"></a> [teams\_sns\_topic\_arns](#input\_teams\_sns\_topic\_arns) | ARNs of SNS topics for the Teams channel configuration | `list(string)` | `null` | no |
| <a name="input_teams_team_id"></a> [teams\_team\_id](#input\_teams\_team\_id) | The ID of the Microsoft Teams team | `string` | `null` | no |
| <a name="input_teams_team_name"></a> [teams\_team\_name](#input\_teams\_team\_name) | The name of the Microsoft Teams team | `string` | `null` | no |
| <a name="input_teams_tenant_id"></a> [teams\_tenant\_id](#input\_teams\_tenant\_id) | The ID of the Microsoft Teams tenant | `string` | `null` | no |
| <a name="input_teams_user_role_required"></a> [teams\_user\_role\_required](#input\_teams\_user\_role\_required) | Enables use of a user role requirement in your Teams chat configuration | `bool` | `false` | no |
| <a name="input_user_role_required"></a> [user\_role\_required](#input\_user\_role\_required) | Enables use of a user role requirement in your chat configuration | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_chatbot_role_arn"></a> [chatbot\_role\_arn](#output\_chatbot\_role\_arn) | ARN of the IAM role used by AWS Chatbot |
| <a name="output_chatbot_role_name"></a> [chatbot\_role\_name](#output\_chatbot\_role\_name) | Name of the IAM role used by AWS Chatbot |
| <a name="output_slack_configuration_arn"></a> [slack\_configuration\_arn](#output\_slack\_configuration\_arn) | Amazon Resource Name (ARN) of the Slack channel configuration |
| <a name="output_slack_configuration_id"></a> [slack\_configuration\_id](#output\_slack\_configuration\_id) | ID of the Slack channel configuration (ARN) |
| <a name="output_teams_configuration_arn"></a> [teams\_configuration\_arn](#output\_teams\_configuration\_arn) | Amazon Resource Name (ARN) of the Teams channel configuration |
| <a name="output_teams_configuration_id"></a> [teams\_configuration\_id](#output\_teams\_configuration\_id) | ID of the Teams channel configuration (ARN) |
<!-- END_TF_DOCS -->