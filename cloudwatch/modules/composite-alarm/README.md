<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.11.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.39.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.39.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarm_name"></a> [alarm\_name](#input\_alarm\_name) | The name for the composite alarm. Must be unique within the region. | `string` | n/a | yes |
| <a name="input_alarm_rule"></a> [alarm\_rule](#input\_alarm\_rule) | An expression that specifies which other alarms are to be evaluated to determine this composite alarm's state (e.g. ALARM(my-alarm-1) OR ALARM(my-alarm-2)). | `string` | n/a | yes |
| <a name="input_actions_enabled"></a> [actions\_enabled](#input\_actions\_enabled) | Indicates whether actions should be executed during any changes to the alarm's state. | `bool` | `true` | no |
| <a name="input_actions_suppressor"></a> [actions\_suppressor](#input\_actions\_suppressor) | Configuration for actions suppression. | <pre>object({<br/>    alarm            = string<br/>    extension_period = number<br/>    wait_period      = number<br/>  })</pre> | `null` | no |
| <a name="input_alarm_actions"></a> [alarm\_actions](#input\_alarm\_actions) | The set of actions to execute when this alarm transitions into an ALARM state from any other state. Maximum 5 ARNs. | `list(string)` | `null` | no |
| <a name="input_alarm_description"></a> [alarm\_description](#input\_alarm\_description) | The description for the composite alarm. | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_insufficient_data_actions"></a> [insufficient\_data\_actions](#input\_insufficient\_data\_actions) | The set of actions to execute when this alarm transitions into an INSUFFICIENT\_DATA state from any other state. Maximum 5 ARNs. | `list(string)` | `null` | no |
| <a name="input_ok_actions"></a> [ok\_actions](#input\_ok\_actions) | The set of actions to execute when this alarm transitions into an OK state from any other state. Maximum 5 ARNs. | `list(string)` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alarm_arn"></a> [alarm\_arn](#output\_alarm\_arn) | The ARN of the composite alarm. |
| <a name="output_alarm_id"></a> [alarm\_id](#output\_alarm\_id) | The ID of the composite alarm. |
| <a name="output_alarm_name"></a> [alarm\_name](#output\_alarm\_name) | The name of the composite alarm. |
<!-- END_TF_DOCS -->
