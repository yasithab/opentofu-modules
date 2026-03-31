<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.11.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.38.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | ~> 0.12 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.38.0 |
| <a name="provider_time"></a> [time](#provider\_time) | ~> 0.12 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_iam_role_description"></a> [access\_iam\_role\_description](#input\_access\_iam\_role\_description) | Description of the role | `string` | `null` | no |
| <a name="input_access_iam_role_name"></a> [access\_iam\_role\_name](#input\_access\_iam\_role\_name) | Name to use on IAM role created | `string` | `null` | no |
| <a name="input_access_iam_role_path"></a> [access\_iam\_role\_path](#input\_access\_iam\_role\_path) | IAM role path | `string` | `null` | no |
| <a name="input_access_iam_role_permissions_boundary"></a> [access\_iam\_role\_permissions\_boundary](#input\_access\_iam\_role\_permissions\_boundary) | ARN of the policy that is used to set the permissions boundary for the IAM role | `string` | `null` | no |
| <a name="input_access_iam_role_policies"></a> [access\_iam\_role\_policies](#input\_access\_iam\_role\_policies) | Map of IAM role policy ARNs to attach to the IAM role | `map(string)` | `{}` | no |
| <a name="input_access_iam_role_tags"></a> [access\_iam\_role\_tags](#input\_access\_iam\_role\_tags) | A map of additional tags to add to the IAM role created | `map(string)` | `{}` | no |
| <a name="input_access_iam_role_use_name_prefix"></a> [access\_iam\_role\_use\_name\_prefix](#input\_access\_iam\_role\_use\_name\_prefix) | Determines whether the IAM role name (`access_iam_role_name`) is used as a prefix | `bool` | `true` | no |
| <a name="input_access_iam_statements"></a> [access\_iam\_statements](#input\_access\_iam\_statements) | A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage | `any` | `{}` | no |
| <a name="input_access_kms_key_arns"></a> [access\_kms\_key\_arns](#input\_access\_kms\_key\_arns) | A list of KMS key ARNs the access IAM role is permitted to decrypt | `list(string)` | `[]` | no |
| <a name="input_access_secret_arns"></a> [access\_secret\_arns](#input\_access\_secret\_arns) | A list of SecretManager secret ARNs the access IAM role is permitted to access | `list(string)` | `[]` | no |
| <a name="input_access_source_s3_bucket_arns"></a> [access\_source\_s3\_bucket\_arns](#input\_access\_source\_s3\_bucket\_arns) | A list of S3 bucket ARNs the access IAM role is permitted to access | `list(string)` | `[]` | no |
| <a name="input_access_target_dynamodb_table_arns"></a> [access\_target\_dynamodb\_table\_arns](#input\_access\_target\_dynamodb\_table\_arns) | A list of DynamoDB table ARNs the access IAM role is permitted to access | `list(string)` | `[]` | no |
| <a name="input_access_target_elasticsearch_arns"></a> [access\_target\_elasticsearch\_arns](#input\_access\_target\_elasticsearch\_arns) | A list of Elasticsearch ARNs the access IAM role is permitted to access | `list(string)` | `[]` | no |
| <a name="input_access_target_kinesis_arns"></a> [access\_target\_kinesis\_arns](#input\_access\_target\_kinesis\_arns) | A list of Kinesis ARNs the access IAM role is permitted to access | `list(string)` | `[]` | no |
| <a name="input_access_target_s3_bucket_arns"></a> [access\_target\_s3\_bucket\_arns](#input\_access\_target\_s3\_bucket\_arns) | A list of S3 bucket ARNs the access IAM role is permitted to access | `list(string)` | `[]` | no |
| <a name="input_certificates"></a> [certificates](#input\_certificates) | Map of objects that define the certificates to be created | `map(any)` | `{}` | no |
| <a name="input_create_access_iam_role"></a> [create\_access\_iam\_role](#input\_create\_access\_iam\_role) | Determines whether the ECS task definition IAM role should be created | `bool` | `true` | no |
| <a name="input_create_access_policy"></a> [create\_access\_policy](#input\_create\_access\_policy) | Determines whether the IAM policy should be created | `bool` | `true` | no |
| <a name="input_create_iam_roles"></a> [create\_iam\_roles](#input\_create\_iam\_roles) | Determines whether the required [DMS IAM resources](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.html#CHAP_Security.APIRole) will be created | `bool` | `true` | no |
| <a name="input_create_repl_instance"></a> [create\_repl\_instance](#input\_create\_repl\_instance) | Indicates whether a replication instace should be created | `bool` | `true` | no |
| <a name="input_create_repl_subnet_group"></a> [create\_repl\_subnet\_group](#input\_create\_repl\_subnet\_group) | Determines whether the replication subnet group will be created | `bool` | `true` | no |
| <a name="input_enable_redshift_target_permissions"></a> [enable\_redshift\_target\_permissions](#input\_enable\_redshift\_target\_permissions) | Determines whether `redshift.amazonaws.com` is permitted access to assume the `dms-access-for-endpoint` role | `bool` | `false` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Determines whether resources will be created | `bool` | `true` | no |
| <a name="input_endpoint_timeouts"></a> [endpoint\_timeouts](#input\_endpoint\_timeouts) | A map of timeouts for endpoint create/delete operations | `map(string)` | `{}` | no |
| <a name="input_endpoints"></a> [endpoints](#input\_endpoints) | Map of objects that define the endpoints to be created | `any` | `{}` | no |
| <a name="input_event_subscription_timeouts"></a> [event\_subscription\_timeouts](#input\_event\_subscription\_timeouts) | A map of timeouts for event subscription create/update/delete operations | `map(string)` | `{}` | no |
| <a name="input_event_subscriptions"></a> [event\_subscriptions](#input\_event\_subscriptions) | Map of objects that define the event subscriptions to be created | `any` | `{}` | no |
| <a name="input_iam_role_permissions_boundary"></a> [iam\_role\_permissions\_boundary](#input\_iam\_role\_permissions\_boundary) | ARN of the policy that is used to set the permissions boundary for the role | `string` | `null` | no |
| <a name="input_iam_role_tags"></a> [iam\_role\_tags](#input\_iam\_role\_tags) | A map of additional tags to apply to the DMS IAM roles | `map(string)` | `{}` | no |
| <a name="input_repl_config_timeouts"></a> [repl\_config\_timeouts](#input\_repl\_config\_timeouts) | A map of timeouts for serverless replication config create/update/delete operations | `map(string)` | `{}` | no |
| <a name="input_repl_instance_allocated_storage"></a> [repl\_instance\_allocated\_storage](#input\_repl\_instance\_allocated\_storage) | The amount of storage (in gigabytes) to be initially allocated for the replication instance. Min: 5, Max: 6144, Default: 50 | `number` | `null` | no |
| <a name="input_repl_instance_allow_major_version_upgrade"></a> [repl\_instance\_allow\_major\_version\_upgrade](#input\_repl\_instance\_allow\_major\_version\_upgrade) | Indicates that major version upgrades are allowed | `bool` | `true` | no |
| <a name="input_repl_instance_apply_immediately"></a> [repl\_instance\_apply\_immediately](#input\_repl\_instance\_apply\_immediately) | Indicates whether the changes should be applied immediately or during the next maintenance window | `bool` | `null` | no |
| <a name="input_repl_instance_auto_minor_version_upgrade"></a> [repl\_instance\_auto\_minor\_version\_upgrade](#input\_repl\_instance\_auto\_minor\_version\_upgrade) | Indicates that minor engine upgrades will be applied automatically to the replication instance during the maintenance window | `bool` | `true` | no |
| <a name="input_repl_instance_availability_zone"></a> [repl\_instance\_availability\_zone](#input\_repl\_instance\_availability\_zone) | The EC2 Availability Zone that the replication instance will be created in | `string` | `null` | no |
| <a name="input_repl_instance_class"></a> [repl\_instance\_class](#input\_repl\_instance\_class) | The compute and memory capacity of the replication instance as specified by the replication instance class | `string` | `null` | no |
| <a name="input_repl_instance_dns_name_servers"></a> [repl\_instance\_dns\_name\_servers](#input\_repl\_instance\_dns\_name\_servers) | Custom DNS name servers separated by a space for the replication instance | `string` | `null` | no |
| <a name="input_repl_instance_engine_version"></a> [repl\_instance\_engine\_version](#input\_repl\_instance\_engine\_version) | The [engine version](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_ReleaseNotes.html) number of the replication instance | `string` | `null` | no |
| <a name="input_repl_instance_id"></a> [repl\_instance\_id](#input\_repl\_instance\_id) | The replication instance identifier. This parameter is stored as a lowercase string | `string` | `null` | no |
| <a name="input_repl_instance_kerberos_authentication_settings"></a> [repl\_instance\_kerberos\_authentication\_settings](#input\_repl\_instance\_kerberos\_authentication\_settings) | Kerberos authentication settings for the replication instance. Includes key\_cache\_secret\_iam\_arn, key\_cache\_secret\_id, and krb5\_file\_contents | `any` | `null` | no |
| <a name="input_repl_instance_kms_key_arn"></a> [repl\_instance\_kms\_key\_arn](#input\_repl\_instance\_kms\_key\_arn) | The Amazon Resource Name (ARN) for the KMS key that will be used to encrypt the connection parameters | `string` | `null` | no |
| <a name="input_repl_instance_multi_az"></a> [repl\_instance\_multi\_az](#input\_repl\_instance\_multi\_az) | Specifies if the replication instance is a multi-az deployment. You cannot set the `availability_zone` parameter if the `multi_az` parameter is set to `true` | `bool` | `null` | no |
| <a name="input_repl_instance_network_type"></a> [repl\_instance\_network\_type](#input\_repl\_instance\_network\_type) | The type of IP address protocol used by a replication instance. Valid values: IPV4, DUAL | `string` | `null` | no |
| <a name="input_repl_instance_preferred_maintenance_window"></a> [repl\_instance\_preferred\_maintenance\_window](#input\_repl\_instance\_preferred\_maintenance\_window) | The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC) | `string` | `null` | no |
| <a name="input_repl_instance_publicly_accessible"></a> [repl\_instance\_publicly\_accessible](#input\_repl\_instance\_publicly\_accessible) | Specifies the accessibility options for the replication instance | `bool` | `false` | no |
| <a name="input_repl_instance_subnet_group_id"></a> [repl\_instance\_subnet\_group\_id](#input\_repl\_instance\_subnet\_group\_id) | An existing subnet group to associate with the replication instance | `string` | `null` | no |
| <a name="input_repl_instance_tags"></a> [repl\_instance\_tags](#input\_repl\_instance\_tags) | A map of additional tags to apply to the replication instance | `map(string)` | `{}` | no |
| <a name="input_repl_instance_timeouts"></a> [repl\_instance\_timeouts](#input\_repl\_instance\_timeouts) | A map of timeouts for replication instance create/update/delete operations | `map(string)` | `{}` | no |
| <a name="input_repl_instance_vpc_security_group_ids"></a> [repl\_instance\_vpc\_security\_group\_ids](#input\_repl\_instance\_vpc\_security\_group\_ids) | A list of VPC security group IDs to be used with the replication instance | `list(string)` | `null` | no |
| <a name="input_repl_subnet_group_description"></a> [repl\_subnet\_group\_description](#input\_repl\_subnet\_group\_description) | The description for the subnet group | `string` | `null` | no |
| <a name="input_repl_subnet_group_name"></a> [repl\_subnet\_group\_name](#input\_repl\_subnet\_group\_name) | The name for the replication subnet group. Stored as a lowercase string, must contain no more than 255 alphanumeric characters, periods, spaces, underscores, or hyphens | `string` | `null` | no |
| <a name="input_repl_subnet_group_subnet_ids"></a> [repl\_subnet\_group\_subnet\_ids](#input\_repl\_subnet\_group\_subnet\_ids) | A list of the EC2 subnet IDs for the subnet group | `list(string)` | `[]` | no |
| <a name="input_repl_subnet_group_tags"></a> [repl\_subnet\_group\_tags](#input\_repl\_subnet\_group\_tags) | A map of additional tags to apply to the replication subnet group | `map(string)` | `{}` | no |
| <a name="input_replication_tasks"></a> [replication\_tasks](#input\_replication\_tasks) | Map of objects that define the replication tasks to be created | `any` | `{}` | no |
| <a name="input_s3_endpoints"></a> [s3\_endpoints](#input\_s3\_endpoints) | Map of objects that define the S3 endpoints to be created | `any` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_access_iam_role_arn"></a> [access\_iam\_role\_arn](#output\_access\_iam\_role\_arn) | Access IAM role ARN |
| <a name="output_access_iam_role_name"></a> [access\_iam\_role\_name](#output\_access\_iam\_role\_name) | Access IAM role name |
| <a name="output_access_iam_role_unique_id"></a> [access\_iam\_role\_unique\_id](#output\_access\_iam\_role\_unique\_id) | Stable and unique string identifying the access IAM role |
| <a name="output_certificates"></a> [certificates](#output\_certificates) | A map of maps containing the certificates created and their full output of attributes and values |
| <a name="output_dms_access_for_endpoint_iam_role_arn"></a> [dms\_access\_for\_endpoint\_iam\_role\_arn](#output\_dms\_access\_for\_endpoint\_iam\_role\_arn) | Amazon Resource Name (ARN) specifying the role |
| <a name="output_dms_access_for_endpoint_iam_role_id"></a> [dms\_access\_for\_endpoint\_iam\_role\_id](#output\_dms\_access\_for\_endpoint\_iam\_role\_id) | Name of the IAM role |
| <a name="output_dms_access_for_endpoint_iam_role_unique_id"></a> [dms\_access\_for\_endpoint\_iam\_role\_unique\_id](#output\_dms\_access\_for\_endpoint\_iam\_role\_unique\_id) | Stable and unique string identifying the role |
| <a name="output_dms_cloudwatch_logs_iam_role_arn"></a> [dms\_cloudwatch\_logs\_iam\_role\_arn](#output\_dms\_cloudwatch\_logs\_iam\_role\_arn) | Amazon Resource Name (ARN) specifying the role |
| <a name="output_dms_cloudwatch_logs_iam_role_id"></a> [dms\_cloudwatch\_logs\_iam\_role\_id](#output\_dms\_cloudwatch\_logs\_iam\_role\_id) | Name of the IAM role |
| <a name="output_dms_cloudwatch_logs_iam_role_unique_id"></a> [dms\_cloudwatch\_logs\_iam\_role\_unique\_id](#output\_dms\_cloudwatch\_logs\_iam\_role\_unique\_id) | Stable and unique string identifying the role |
| <a name="output_dms_vpc_iam_role_arn"></a> [dms\_vpc\_iam\_role\_arn](#output\_dms\_vpc\_iam\_role\_arn) | Amazon Resource Name (ARN) specifying the role |
| <a name="output_dms_vpc_iam_role_id"></a> [dms\_vpc\_iam\_role\_id](#output\_dms\_vpc\_iam\_role\_id) | Name of the IAM role |
| <a name="output_dms_vpc_iam_role_unique_id"></a> [dms\_vpc\_iam\_role\_unique\_id](#output\_dms\_vpc\_iam\_role\_unique\_id) | Stable and unique string identifying the role |
| <a name="output_endpoints"></a> [endpoints](#output\_endpoints) | A map of maps containing the endpoints created and their full output of attributes and values |
| <a name="output_event_subscriptions"></a> [event\_subscriptions](#output\_event\_subscriptions) | A map of maps containing the event subscriptions created and their full output of attributes and values |
| <a name="output_replication_instance_arn"></a> [replication\_instance\_arn](#output\_replication\_instance\_arn) | The Amazon Resource Name (ARN) of the replication instance |
| <a name="output_replication_instance_private_ips"></a> [replication\_instance\_private\_ips](#output\_replication\_instance\_private\_ips) | A list of the private IP addresses of the replication instance |
| <a name="output_replication_instance_public_ips"></a> [replication\_instance\_public\_ips](#output\_replication\_instance\_public\_ips) | A list of the public IP addresses of the replication instance |
| <a name="output_replication_instance_tags_all"></a> [replication\_instance\_tags\_all](#output\_replication\_instance\_tags\_all) | A map of tags assigned to the resource, including those inherited from the provider `default_tags` configuration block |
| <a name="output_replication_subnet_group_id"></a> [replication\_subnet\_group\_id](#output\_replication\_subnet\_group\_id) | The ID of the subnet group |
| <a name="output_replication_tasks"></a> [replication\_tasks](#output\_replication\_tasks) | A map of maps containing the replication tasks created and their full output of attributes and values |
| <a name="output_s3_endpoints"></a> [s3\_endpoints](#output\_s3\_endpoints) | A map of maps containing the S3 endpoints created and their full output of attributes and values |
| <a name="output_serverless_replication_tasks"></a> [serverless\_replication\_tasks](#output\_serverless\_replication\_tasks) | A map of maps containing the serverless replication tasks (replication\_config) created and their full output of attributes and values |
<!-- END_TF_DOCS -->