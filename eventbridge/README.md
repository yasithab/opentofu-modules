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
| <a name="input_api_destinations"></a> [api\_destinations](#input\_api\_destinations) | A map of objects with EventBridge Destination definitions. | `map(any)` | `{}` | no |
| <a name="input_append_connection_postfix"></a> [append\_connection\_postfix](#input\_append\_connection\_postfix) | Controls whether to append '-connection' to the name of the connection | `bool` | `true` | no |
| <a name="input_append_destination_postfix"></a> [append\_destination\_postfix](#input\_append\_destination\_postfix) | Controls whether to append '-destination' to the name of the destination | `bool` | `true` | no |
| <a name="input_append_pipe_postfix"></a> [append\_pipe\_postfix](#input\_append\_pipe\_postfix) | Controls whether to append '-pipe' to the name of the pipe | `bool` | `true` | no |
| <a name="input_append_rule_postfix"></a> [append\_rule\_postfix](#input\_append\_rule\_postfix) | Controls whether to append '-rule' to the name of the rule | `bool` | `true` | no |
| <a name="input_append_schedule_group_postfix"></a> [append\_schedule\_group\_postfix](#input\_append\_schedule\_group\_postfix) | Controls whether to append '-group' to the name of the schedule group | `bool` | `true` | no |
| <a name="input_append_schedule_postfix"></a> [append\_schedule\_postfix](#input\_append\_schedule\_postfix) | Controls whether to append '-schedule' to the name of the schedule | `bool` | `true` | no |
| <a name="input_archives"></a> [archives](#input\_archives) | A map of objects with the EventBridge Archive definitions. | `map(any)` | `{}` | no |
| <a name="input_attach_api_destination_policy"></a> [attach\_api\_destination\_policy](#input\_attach\_api\_destination\_policy) | Controls whether the API Destination policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| <a name="input_attach_cloudwatch_policy"></a> [attach\_cloudwatch\_policy](#input\_attach\_cloudwatch\_policy) | Controls whether the Cloudwatch policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| <a name="input_attach_ecs_policy"></a> [attach\_ecs\_policy](#input\_attach\_ecs\_policy) | Controls whether the ECS policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| <a name="input_attach_kinesis_firehose_policy"></a> [attach\_kinesis\_firehose\_policy](#input\_attach\_kinesis\_firehose\_policy) | Controls whether the Kinesis Firehose policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| <a name="input_attach_kinesis_policy"></a> [attach\_kinesis\_policy](#input\_attach\_kinesis\_policy) | Controls whether the Kinesis policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| <a name="input_attach_lambda_policy"></a> [attach\_lambda\_policy](#input\_attach\_lambda\_policy) | Controls whether the Lambda Function policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| <a name="input_attach_policies"></a> [attach\_policies](#input\_attach\_policies) | Controls whether list of policies should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_policy"></a> [attach\_policy](#input\_attach\_policy) | Controls whether policy should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_policy_json"></a> [attach\_policy\_json](#input\_attach\_policy\_json) | Controls whether policy\_json should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_policy_jsons"></a> [attach\_policy\_jsons](#input\_attach\_policy\_jsons) | Controls whether policy\_jsons should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_policy_statements"></a> [attach\_policy\_statements](#input\_attach\_policy\_statements) | Controls whether policy\_statements should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_sfn_policy"></a> [attach\_sfn\_policy](#input\_attach\_sfn\_policy) | Controls whether the StepFunction policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| <a name="input_attach_sns_policy"></a> [attach\_sns\_policy](#input\_attach\_sns\_policy) | Controls whether the SNS policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| <a name="input_attach_sqs_policy"></a> [attach\_sqs\_policy](#input\_attach\_sqs\_policy) | Controls whether the SQS policy should be added to IAM role for EventBridge Target | `bool` | `false` | no |
| <a name="input_attach_tracing_policy"></a> [attach\_tracing\_policy](#input\_attach\_tracing\_policy) | Controls whether X-Ray tracing policy should be added to IAM role for EventBridge | `bool` | `false` | no |
| <a name="input_bus_description"></a> [bus\_description](#input\_bus\_description) | Event bus description | `string` | `null` | no |
| <a name="input_bus_name"></a> [bus\_name](#input\_bus\_name) | A unique name for your EventBridge Bus | `string` | `"default"` | no |
| <a name="input_cloudwatch_target_arns"></a> [cloudwatch\_target\_arns](#input\_cloudwatch\_target\_arns) | The Amazon Resource Name (ARN) of the Cloudwatch Log Streams you want to use as EventBridge targets | `list(string)` | `[]` | no |
| <a name="input_connections"></a> [connections](#input\_connections) | A map of objects with EventBridge Connection definitions. | `any` | `{}` | no |
| <a name="input_create_api_destinations"></a> [create\_api\_destinations](#input\_create\_api\_destinations) | Controls whether EventBridge Destination resources should be created | `bool` | `false` | no |
| <a name="input_create_archives"></a> [create\_archives](#input\_create\_archives) | Controls whether EventBridge Archive resources should be created | `bool` | `false` | no |
| <a name="input_create_bus"></a> [create\_bus](#input\_create\_bus) | Controls whether EventBridge Bus resource should be created | `bool` | `true` | no |
| <a name="input_create_connections"></a> [create\_connections](#input\_create\_connections) | Controls whether EventBridge Connection resources should be created | `bool` | `false` | no |
| <a name="input_create_log_delivery"></a> [create\_log\_delivery](#input\_create\_log\_delivery) | Controls whether EventBridge log delivery resources should be created | `bool` | `true` | no |
| <a name="input_create_log_delivery_source"></a> [create\_log\_delivery\_source](#input\_create\_log\_delivery\_source) | Controls whether EventBridge log delivery source resource should be created | `bool` | `true` | no |
| <a name="input_create_permissions"></a> [create\_permissions](#input\_create\_permissions) | Controls whether EventBridge Permission resources should be created | `bool` | `true` | no |
| <a name="input_create_pipe_role_only"></a> [create\_pipe\_role\_only](#input\_create\_pipe\_role\_only) | Controls whether an IAM role should be created for the pipes only | `bool` | `false` | no |
| <a name="input_create_pipes"></a> [create\_pipes](#input\_create\_pipes) | Controls whether EventBridge Pipes resources should be created | `bool` | `true` | no |
| <a name="input_create_role"></a> [create\_role](#input\_create\_role) | Controls whether IAM roles should be created | `bool` | `true` | no |
| <a name="input_create_rules"></a> [create\_rules](#input\_create\_rules) | Controls whether EventBridge Rule resources should be created | `bool` | `true` | no |
| <a name="input_create_schedule_groups"></a> [create\_schedule\_groups](#input\_create\_schedule\_groups) | Controls whether EventBridge Schedule Group resources should be created | `bool` | `true` | no |
| <a name="input_create_schedules"></a> [create\_schedules](#input\_create\_schedules) | Controls whether EventBridge Schedule resources should be created | `bool` | `true` | no |
| <a name="input_create_schemas_discoverer"></a> [create\_schemas\_discoverer](#input\_create\_schemas\_discoverer) | Controls whether default schemas discoverer should be created | `bool` | `false` | no |
| <a name="input_create_targets"></a> [create\_targets](#input\_create\_targets) | Controls whether EventBridge Target resources should be created | `bool` | `true` | no |
| <a name="input_dead_letter_config"></a> [dead\_letter\_config](#input\_dead\_letter\_config) | Configuration details of the Amazon SQS queue for EventBridge to use as a dead-letter queue (DLQ) | `any` | `{}` | no |
| <a name="input_ecs_pass_role_resources"></a> [ecs\_pass\_role\_resources](#input\_ecs\_pass\_role\_resources) | List of approved roles to be passed | `list(string)` | `[]` | no |
| <a name="input_ecs_target_arns"></a> [ecs\_target\_arns](#input\_ecs\_target\_arns) | The Amazon Resource Name (ARN) of the AWS ECS Tasks you want to use as EventBridge targets | `list(string)` | `[]` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Controls whether resources should be created | `bool` | `true` | no |
| <a name="input_event_source_name"></a> [event\_source\_name](#input\_event\_source\_name) | The partner event source that the new event bus will be matched with. Must match name. | `string` | `null` | no |
| <a name="input_kinesis_firehose_target_arns"></a> [kinesis\_firehose\_target\_arns](#input\_kinesis\_firehose\_target\_arns) | The Amazon Resource Name (ARN) of the Kinesis Firehose Delivery Streams you want to use as EventBridge targets | `list(string)` | `[]` | no |
| <a name="input_kinesis_target_arns"></a> [kinesis\_target\_arns](#input\_kinesis\_target\_arns) | The Amazon Resource Name (ARN) of the Kinesis Streams you want to use as EventBridge targets | `list(string)` | `[]` | no |
| <a name="input_kms_key_identifier"></a> [kms\_key\_identifier](#input\_kms\_key\_identifier) | The identifier of the AWS KMS customer managed key for EventBridge to use, if you choose to use a customer managed key to encrypt events on this event bus. The identifier can be the key Amazon Resource Name (ARN), KeyId, key alias, or key alias ARN. | `string` | `null` | no |
| <a name="input_lambda_target_arns"></a> [lambda\_target\_arns](#input\_lambda\_target\_arns) | The Amazon Resource Name (ARN) of the Lambda Functions you want to use as EventBridge targets | `list(string)` | `[]` | no |
| <a name="input_log_config"></a> [log\_config](#input\_log\_config) | The configuration block for the EventBridge bus log config settings | <pre>object({<br/>    include_detail = string<br/>    level          = string<br/>  })</pre> | `null` | no |
| <a name="input_log_delivery"></a> [log\_delivery](#input\_log\_delivery) | Map of the configuration block for the EventBridge bus log delivery settings (key is the type of log delivery: cloudwatch\_logs, s3, firehose) | <pre>map(object({<br/>    enabled                   = optional(bool, true)<br/>    destination_arn           = string<br/>    delivery_destination_type = optional(string)<br/>    source_name               = optional(string)<br/>    name                      = optional(string)<br/>    output_format             = optional(string)<br/>    field_delimiter           = optional(string)<br/>    record_fields             = optional(list(string))<br/>    s3_delivery_configuration = optional(object({<br/>      enable_hive_compatible_path = optional(bool)<br/>      suffix_path                 = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_log_delivery_source_name"></a> [log\_delivery\_source\_name](#input\_log\_delivery\_source\_name) | Name of log delivery source | `string` | `null` | no |
| <a name="input_number_of_policies"></a> [number\_of\_policies](#input\_number\_of\_policies) | Number of policies to attach to IAM role | `number` | `0` | no |
| <a name="input_number_of_policy_jsons"></a> [number\_of\_policy\_jsons](#input\_number\_of\_policy\_jsons) | Number of policies JSON to attach to IAM role | `number` | `0` | no |
| <a name="input_permissions"></a> [permissions](#input\_permissions) | A map of objects with EventBridge Permission definitions. | `map(any)` | `{}` | no |
| <a name="input_pipes"></a> [pipes](#input\_pipes) | A map of objects with EventBridge Pipe definitions. | `any` | `{}` | no |
| <a name="input_policies"></a> [policies](#input\_policies) | List of policy statements ARN to attach to IAM role | `list(string)` | `[]` | no |
| <a name="input_policy"></a> [policy](#input\_policy) | An additional policy document ARN to attach to IAM role | `string` | `null` | no |
| <a name="input_policy_json"></a> [policy\_json](#input\_policy\_json) | An additional policy document as JSON to attach to IAM role | `string` | `null` | no |
| <a name="input_policy_jsons"></a> [policy\_jsons](#input\_policy\_jsons) | List of additional policy documents as JSON to attach to IAM role | `list(string)` | `[]` | no |
| <a name="input_policy_path"></a> [policy\_path](#input\_policy\_path) | Path of IAM policy to use for EventBridge | `string` | `null` | no |
| <a name="input_policy_statements"></a> [policy\_statements](#input\_policy\_statements) | Map of dynamic policy statements to attach to IAM role | `any` | `{}` | no |
| <a name="input_region"></a> [region](#input\_region) | Region where the resource(s) will be managed. Defaults to the region set in the provider configuration | `string` | `null` | no |
| <a name="input_role_description"></a> [role\_description](#input\_role\_description) | Description of IAM role to use for EventBridge | `string` | `null` | no |
| <a name="input_role_force_detach_policies"></a> [role\_force\_detach\_policies](#input\_role\_force\_detach\_policies) | Specifies to force detaching any policies the IAM role has before destroying it. | `bool` | `true` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Name of IAM role to use for EventBridge | `string` | `null` | no |
| <a name="input_role_path"></a> [role\_path](#input\_role\_path) | Path of IAM role to use for EventBridge | `string` | `null` | no |
| <a name="input_role_permissions_boundary"></a> [role\_permissions\_boundary](#input\_role\_permissions\_boundary) | The ARN of the policy that is used to set the permissions boundary for the IAM role used by EventBridge | `string` | `null` | no |
| <a name="input_role_tags"></a> [role\_tags](#input\_role\_tags) | A map of tags to assign to IAM role | `map(string)` | `{}` | no |
| <a name="input_rules"></a> [rules](#input\_rules) | A map of objects with EventBridge Rule definitions. | `map(any)` | `{}` | no |
| <a name="input_schedule_group_timeouts"></a> [schedule\_group\_timeouts](#input\_schedule\_group\_timeouts) | A map of objects with EventBridge Schedule Group create and delete timeouts. | `map(string)` | `{}` | no |
| <a name="input_schedule_groups"></a> [schedule\_groups](#input\_schedule\_groups) | A map of objects with EventBridge Schedule Group definitions. | `any` | `{}` | no |
| <a name="input_schedules"></a> [schedules](#input\_schedules) | A map of objects with EventBridge Schedule definitions. | `map(any)` | `{}` | no |
| <a name="input_schemas_discoverer_description"></a> [schemas\_discoverer\_description](#input\_schemas\_discoverer\_description) | Default schemas discoverer description | `string` | `"Auto schemas discoverer event"` | no |
| <a name="input_sfn_target_arns"></a> [sfn\_target\_arns](#input\_sfn\_target\_arns) | The Amazon Resource Name (ARN) of the StepFunctions you want to use as EventBridge targets | `list(string)` | `[]` | no |
| <a name="input_sns_kms_arns"></a> [sns\_kms\_arns](#input\_sns\_kms\_arns) | The Amazon Resource Name (ARN) of the AWS KMS's configured for AWS SNS you want Decrypt/GenerateDataKey for | `list(string)` | <pre>[<br/>  "*"<br/>]</pre> | no |
| <a name="input_sns_target_arns"></a> [sns\_target\_arns](#input\_sns\_target\_arns) | The Amazon Resource Name (ARN) of the AWS SNS's you want to use as EventBridge targets | `list(string)` | `[]` | no |
| <a name="input_sqs_target_arns"></a> [sqs\_target\_arns](#input\_sqs\_target\_arns) | The Amazon Resource Name (ARN) of the AWS SQS Queues you want to use as EventBridge targets | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to resources. | `map(string)` | `{}` | no |
| <a name="input_targets"></a> [targets](#input\_targets) | A map of objects with EventBridge Target definitions. | `any` | `{}` | no |
| <a name="input_trusted_entities"></a> [trusted\_entities](#input\_trusted\_entities) | Additional trusted entities for assuming roles (trust relationship) | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eventbridge_api_destination_arns"></a> [eventbridge\_api\_destination\_arns](#output\_eventbridge\_api\_destination\_arns) | The EventBridge API Destination ARNs |
| <a name="output_eventbridge_api_destinations"></a> [eventbridge\_api\_destinations](#output\_eventbridge\_api\_destinations) | The EventBridge API Destinations created and their attributes |
| <a name="output_eventbridge_archive_arns"></a> [eventbridge\_archive\_arns](#output\_eventbridge\_archive\_arns) | The EventBridge Archive ARNs |
| <a name="output_eventbridge_archives"></a> [eventbridge\_archives](#output\_eventbridge\_archives) | The EventBridge Archives created and their attributes |
| <a name="output_eventbridge_bus"></a> [eventbridge\_bus](#output\_eventbridge\_bus) | The EventBridge Bus created and their attributes |
| <a name="output_eventbridge_bus_arn"></a> [eventbridge\_bus\_arn](#output\_eventbridge\_bus\_arn) | The EventBridge Bus ARN |
| <a name="output_eventbridge_bus_name"></a> [eventbridge\_bus\_name](#output\_eventbridge\_bus\_name) | The EventBridge Bus Name |
| <a name="output_eventbridge_connection_arns"></a> [eventbridge\_connection\_arns](#output\_eventbridge\_connection\_arns) | The EventBridge Connection Arns |
| <a name="output_eventbridge_connection_ids"></a> [eventbridge\_connection\_ids](#output\_eventbridge\_connection\_ids) | The EventBridge Connection IDs |
| <a name="output_eventbridge_connections"></a> [eventbridge\_connections](#output\_eventbridge\_connections) | The EventBridge Connections created and their attributes |
| <a name="output_eventbridge_iam_roles"></a> [eventbridge\_iam\_roles](#output\_eventbridge\_iam\_roles) | The EventBridge IAM roles created and their attributes |
| <a name="output_eventbridge_log_delivery_source_arn"></a> [eventbridge\_log\_delivery\_source\_arn](#output\_eventbridge\_log\_delivery\_source\_arn) | The EventBridge Bus CloudWatch Log Delivery Source ARN |
| <a name="output_eventbridge_log_delivery_source_name"></a> [eventbridge\_log\_delivery\_source\_name](#output\_eventbridge\_log\_delivery\_source\_name) | The EventBridge Bus CloudWatch Log Delivery Source Name |
| <a name="output_eventbridge_permission_ids"></a> [eventbridge\_permission\_ids](#output\_eventbridge\_permission\_ids) | The EventBridge Permission IDs |
| <a name="output_eventbridge_permissions"></a> [eventbridge\_permissions](#output\_eventbridge\_permissions) | The EventBridge Permissions created and their attributes |
| <a name="output_eventbridge_pipe_arns"></a> [eventbridge\_pipe\_arns](#output\_eventbridge\_pipe\_arns) | The EventBridge Pipes ARNs |
| <a name="output_eventbridge_pipe_ids"></a> [eventbridge\_pipe\_ids](#output\_eventbridge\_pipe\_ids) | The EventBridge Pipes IDs |
| <a name="output_eventbridge_pipe_role_arns"></a> [eventbridge\_pipe\_role\_arns](#output\_eventbridge\_pipe\_role\_arns) | The ARNs of the IAM role created for EventBridge Pipes |
| <a name="output_eventbridge_pipe_role_names"></a> [eventbridge\_pipe\_role\_names](#output\_eventbridge\_pipe\_role\_names) | The names of the IAM role created for EventBridge Pipes |
| <a name="output_eventbridge_pipes"></a> [eventbridge\_pipes](#output\_eventbridge\_pipes) | The EventBridge Pipes created and their attributes |
| <a name="output_eventbridge_pipes_iam_roles"></a> [eventbridge\_pipes\_iam\_roles](#output\_eventbridge\_pipes\_iam\_roles) | The EventBridge Pipes IAM roles created and their attributes |
| <a name="output_eventbridge_role_arn"></a> [eventbridge\_role\_arn](#output\_eventbridge\_role\_arn) | The ARN of the IAM role created for EventBridge |
| <a name="output_eventbridge_role_name"></a> [eventbridge\_role\_name](#output\_eventbridge\_role\_name) | The name of the IAM role created for EventBridge |
| <a name="output_eventbridge_rule_arns"></a> [eventbridge\_rule\_arns](#output\_eventbridge\_rule\_arns) | The EventBridge Rule ARNs |
| <a name="output_eventbridge_rule_ids"></a> [eventbridge\_rule\_ids](#output\_eventbridge\_rule\_ids) | The EventBridge Rule IDs |
| <a name="output_eventbridge_rules"></a> [eventbridge\_rules](#output\_eventbridge\_rules) | The EventBridge Rules created and their attributes |
| <a name="output_eventbridge_schedule_arns"></a> [eventbridge\_schedule\_arns](#output\_eventbridge\_schedule\_arns) | The EventBridge Schedule ARNs created |
| <a name="output_eventbridge_schedule_group_arns"></a> [eventbridge\_schedule\_group\_arns](#output\_eventbridge\_schedule\_group\_arns) | The EventBridge Schedule Group ARNs |
| <a name="output_eventbridge_schedule_group_ids"></a> [eventbridge\_schedule\_group\_ids](#output\_eventbridge\_schedule\_group\_ids) | The EventBridge Schedule Group IDs |
| <a name="output_eventbridge_schedule_group_states"></a> [eventbridge\_schedule\_group\_states](#output\_eventbridge\_schedule\_group\_states) | The EventBridge Schedule Group states |
| <a name="output_eventbridge_schedule_groups"></a> [eventbridge\_schedule\_groups](#output\_eventbridge\_schedule\_groups) | The EventBridge Schedule Groups created and their attributes |
| <a name="output_eventbridge_schedule_ids"></a> [eventbridge\_schedule\_ids](#output\_eventbridge\_schedule\_ids) | The EventBridge Schedule IDs created |
| <a name="output_eventbridge_schedules"></a> [eventbridge\_schedules](#output\_eventbridge\_schedules) | The EventBridge Schedules created and their attributes |
| <a name="output_eventbridge_targets"></a> [eventbridge\_targets](#output\_eventbridge\_targets) | The EventBridge Targets created and their attributes |
<!-- END_TF_DOCS -->