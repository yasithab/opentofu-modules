

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.34 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | ~> 0.12 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.34 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.0 |
| <a name="provider_time"></a> [time](#provider\_time) | ~> 0.12 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | The password of the administrator for the first database created in the namespace | `string` | `null` | no |
| <a name="input_admin_password_secret_kms_key_id"></a> [admin\_password\_secret\_kms\_key\_id](#input\_admin\_password\_secret\_kms\_key\_id) | ID of the KMS key used to encrypt the namespace admin credentials secret when `manage_admin_password` is true | `string` | `null` | no |
| <a name="input_admin_user_password_wo_version"></a> [admin\_user\_password\_wo\_version](#input\_admin\_user\_password\_wo\_version) | Version counter for admin\_user\_password\_wo. Increment to trigger a password rotation when use\_admin\_password\_wo is true | `number` | `1` | no |
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | The username of the administrator for the first database created in the namespace | `string` | `null` | no |
| <a name="input_assume_role_policy"></a> [assume\_role\_policy](#input\_assume\_role\_policy) | Policy that grants an entity permission to assume the role | `any` | `null` | no |
| <a name="input_create_random_password"></a> [create\_random\_password](#input\_create\_random\_password) | Determines whether to create random password for cluster `master_password` | `bool` | `true` | no |
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | Determines if a security group is created | `bool` | `true` | no |
| <a name="input_custom_domain_certificate_arn"></a> [custom\_domain\_certificate\_arn](#input\_custom\_domain\_certificate\_arn) | ARN of the certificate for the custom domain association | `string` | `null` | no |
| <a name="input_custom_domain_enabled"></a> [custom\_domain\_enabled](#input\_custom\_domain\_enabled) | If `true`, custom domain is enabled | `bool` | `false` | no |
| <a name="input_custom_domain_name"></a> [custom\_domain\_name](#input\_custom\_domain\_name) | Custom domain to associate with the workgroup | `string` | `null` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | The name of the first database created in the namespace | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_endpoint_enabled"></a> [endpoint\_enabled](#input\_endpoint\_enabled) | If `true`, VPC endpoint is enabled | `bool` | `true` | no |
| <a name="input_endpoint_name"></a> [endpoint\_name](#input\_endpoint\_name) | The Redshift-managed VPC endpoint name | `string` | `null` | no |
| <a name="input_endpoint_owner_account"></a> [endpoint\_owner\_account](#input\_endpoint\_owner\_account) | The AWS account ID of the owner of the workgroup. This is only required if the workgroup is in another AWS account | `string` | `null` | no |
| <a name="input_endpoint_security_group_ids"></a> [endpoint\_security\_group\_ids](#input\_endpoint\_security\_group\_ids) | The security group IDs to use for the endpoint access (managed VPC endpoint) | `list(string)` | `[]` | no |
| <a name="input_engine_mode"></a> [engine\_mode](#input\_engine\_mode) | The RedShift cluster engine mode. Valid values: `serverless` | `string` | `"serverless"` | no |
| <a name="input_iam_role_enabled"></a> [iam\_role\_enabled](#input\_iam\_role\_enabled) | If `true`, iam role resource is enabled | `bool` | `true` | no |
| <a name="input_iam_role_name"></a> [iam\_role\_name](#input\_iam\_role\_name) | The name of the iam role | `string` | `null` | no |
| <a name="input_kms_alias"></a> [kms\_alias](#input\_kms\_alias) | The display name of the alias. The name must start with the word 'alias' followed by a forward slash (alias/) | `string` | `"alias/redshift-serverless"` | no |
| <a name="input_kms_enabled"></a> [kms\_enabled](#input\_kms\_enabled) | If `true`, kms key is enabled | `bool` | `false` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | The ARN for the KMS encryption key. When specifying `kms_key_arn`, `encrypted` needs to be set to `true` | `string` | `null` | no |
| <a name="input_log_exports"></a> [log\_exports](#input\_log\_exports) | The types of logs the namespace can export. Available export types are userlog, connectionlog, and useractivitylog. | `list(string)` | `[]` | no |
| <a name="input_manage_admin_password"></a> [manage\_admin\_password](#input\_manage\_admin\_password) | Whether to use AWS SecretsManager to manage the cluster admin credentials. Conflicts with `admin_password`. One of `admin_password` or `manage_admin_password` is required unless `snapshot_identifier` is provided | `bool` | `true` | no |
| <a name="input_managed_policy_arns"></a> [managed\_policy\_arns](#input\_managed\_policy\_arns) | n/a | `set(string)` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to use for resource naming and tagging. | `string` | `null` | no |
| <a name="input_namespace_name"></a> [namespace\_name](#input\_namespace\_name) | The name of the namespace | `string` | `null` | no |
| <a name="input_policy"></a> [policy](#input\_policy) | If `true`, iam policy is enabled | `any` | `null` | no |
| <a name="input_policy_arn"></a> [policy\_arn](#input\_policy\_arn) | The ARN of the policy you want to apply | `string` | `null` | no |
| <a name="input_policy_enabled"></a> [policy\_enabled](#input\_policy\_enabled) | Whether to Attach Iam policy with role | `bool` | `true` | no |
| <a name="input_policy_name"></a> [policy\_name](#input\_policy\_name) | The name of the iam policy name | `string` | `null` | no |
| <a name="input_port"></a> [port](#input\_port) | RedShift cluster port, default is `5439` | `number` | `5439` | no |
| <a name="input_publicly_accessible"></a> [publicly\_accessible](#input\_publicly\_accessible) | If true, the cluster can be accessed from a public network | `bool` | `false` | no |
| <a name="input_random_password_length"></a> [random\_password\_length](#input\_random\_password\_length) | Length of random password to create. Defaults to `16` | `number` | `16` | no |
| <a name="input_security_group_description"></a> [security\_group\_description](#input\_security\_group\_description) | Description of the security group created | `string` | `null` | no |
| <a name="input_security_group_name"></a> [security\_group\_name](#input\_security\_group\_name) | Name to use on security group created | `string` | `null` | no |
| <a name="input_security_group_rules"></a> [security\_group\_rules](#input\_security\_group\_rules) | Security group ingress and egress rules to add to the security group created | `any` | `{}` | no |
| <a name="input_security_group_tags"></a> [security\_group\_tags](#input\_security\_group\_tags) | A map of additional tags to add to the security group created | `map(string)` | `{}` | no |
| <a name="input_security_group_use_name_prefix"></a> [security\_group\_use\_name\_prefix](#input\_security\_group\_use\_name\_prefix) | Determines whether the security group name (`security_group_name`) is used as a prefix | `bool` | `true` | no |
| <a name="input_snapshot_enabled"></a> [snapshot\_enabled](#input\_snapshot\_enabled) | If `true`, snapshot is enabled | `bool` | `false` | no |
| <a name="input_snapshot_name"></a> [snapshot\_name](#input\_snapshot\_name) | The name of the snapshot. | `string` | `null` | no |
| <a name="input_snapshot_policy"></a> [snapshot\_policy](#input\_snapshot\_policy) | If `true`, serverless snapshot policy is enabled | `any` | `null` | no |
| <a name="input_snapshot_policy_enabled"></a> [snapshot\_policy\_enabled](#input\_snapshot\_policy\_enabled) | If `true`, snapshot policy is enabled | `bool` | `false` | no |
| <a name="input_snapshot_retention_period"></a> [snapshot\_retention\_period](#input\_snapshot\_retention\_period) | How long to retain the created snapshot. Default value is -1. | `string` | `"-1"` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | An array of VPC subnet IDs to use in the subnet group | `list(string)` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_usage_amount"></a> [usage\_amount](#input\_usage\_amount) | The limit amount. If time-based, this amount is in Redshift Processing Units (RPU) consumed per hour. If data-based, this amount is in terabytes (TB) of data transferred between Regions in cross-account sharing. The value must be a positive number. | `number` | `60` | no |
| <a name="input_usage_breach_action"></a> [usage\_breach\_action](#input\_usage\_breach\_action) | The action that Amazon Redshift Serverless takes when the limit is reached. Valid values are log, emit-metric, and deactivate. The default is log. | `string` | `"log"` | no |
| <a name="input_usage_limit_enabled"></a> [usage\_limit\_enabled](#input\_usage\_limit\_enabled) | If `true`, it creates a new amazon redshift serverless usage limit. | `bool` | `false` | no |
| <a name="input_usage_period"></a> [usage\_period](#input\_usage\_period) | The time period that the amount applies to. A weekly period begins on Sunday. Valid values are daily, weekly, and monthly. The default is monthly. | `string` | `"monthly"` | no |
| <a name="input_usage_type"></a> [usage\_type](#input\_usage\_type) | The type of Amazon Redshift Serverless usage to create a usage limit for. Valid values are serverless-compute or cross-region-datasharing. | `string` | `"serverless-compute"` | no |
| <a name="input_use_admin_password_wo"></a> [use\_admin\_password\_wo](#input\_use\_admin\_password\_wo) | Whether to use the write-only admin\_user\_password\_wo attribute instead of admin\_user\_password. When true, the password is never stored in state | `bool` | `false` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | Identifier of the VPC where the security group will be created | `string` | `null` | no |
| <a name="input_workgroup_base_capacity"></a> [workgroup\_base\_capacity](#input\_workgroup\_base\_capacity) | The base data warehouse capacity of the workgroup in Redshift Processing Units (RPUs). | `number` | `16` | no |
| <a name="input_workgroup_config_parameter"></a> [workgroup\_config\_parameter](#input\_workgroup\_config\_parameter) | An array of parameters to set for more control over a serverless database. | `list(any)` | `[]` | no |
| <a name="input_workgroup_enhanced_vpc_routing"></a> [workgroup\_enhanced\_vpc\_routing](#input\_workgroup\_enhanced\_vpc\_routing) | If `true`, enhanced VPC routing is enabled | `bool` | `null` | no |
| <a name="input_workgroup_max_capacity"></a> [workgroup\_max\_capacity](#input\_workgroup\_max\_capacity) | The maximum data-warehouse capacity Amazon Redshift Serverless uses to serve queries, specified in Redshift Processing Units (RPUs) | `number` | `64` | no |
| <a name="input_workgroup_name"></a> [workgroup\_name](#input\_workgroup\_name) | The name of the workgroup | `string` | `null` | no |
| <a name="input_workgroup_port"></a> [workgroup\_port](#input\_workgroup\_port) | The custom port to use when connecting to a workgroup. Valid port ranges are 5431-5455 and 8191-8215. The default is 5439 | `number` | `null` | no |
| <a name="input_workgroup_price_performance_target"></a> [workgroup\_price\_performance\_target](#input\_workgroup\_price\_performance\_target) | The price performance target configuration for the workgroup. Set `enabled = true` and provide a `level` (1-100) to enable price performance targeting | <pre>object({<br/>    enabled = optional(bool, false)<br/>    level   = optional(number, null)<br/>  })</pre> | `null` | no |
| <a name="input_workgroup_track_name"></a> [workgroup\_track\_name](#input\_workgroup\_track\_name) | The release track for the workgroup. Valid values are `current` or `trailing` | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_endpoint_access_arn"></a> [endpoint\_access\_arn](#output\_endpoint\_access\_arn) | Amazon Resource Name (ARN) of the Redshift Serverless Endpoint Access. |
| <a name="output_endpoint_access_name"></a> [endpoint\_access\_name](#output\_endpoint\_access\_name) | Amazon Resource Name (ARN) of the Redshift Serverless Endpoint Access. |
| <a name="output_endpoint_address"></a> [endpoint\_address](#output\_endpoint\_address) | The DNS address of the workgroup endpoint |
| <a name="output_limit_arn"></a> [limit\_arn](#output\_limit\_arn) | Amazon Resource Name (ARN) of the Redshift Serverless Usage Limit. |
| <a name="output_limit_id"></a> [limit\_id](#output\_limit\_id) | The Redshift Usage Limit id. |
| <a name="output_namespace_arn"></a> [namespace\_arn](#output\_namespace\_arn) | The Redshift Namespace ID. |
| <a name="output_namespace_id"></a> [namespace\_id](#output\_namespace\_id) | The Redshift Namespace ID. |
| <a name="output_namespace_name"></a> [namespace\_name](#output\_namespace\_name) | The Redshift Namespace Name. |
| <a name="output_snapshot_accounts_with_restore_access"></a> [snapshot\_accounts\_with\_restore\_access](#output\_snapshot\_accounts\_with\_restore\_access) | All of the Amazon Web Services accounts that have access to restore a snapshot to a namespace. |
| <a name="output_snapshot_admin_username"></a> [snapshot\_admin\_username](#output\_snapshot\_admin\_username) | The username of the database within a snapshot. |
| <a name="output_snapshot_arn"></a> [snapshot\_arn](#output\_snapshot\_arn) | The Amazon Resource Name (ARN) of the namespace the snapshot was created from. |
| <a name="output_snapshot_name"></a> [snapshot\_name](#output\_snapshot\_name) | The name of the snapshot. |
| <a name="output_snapshot_namespace_arn"></a> [snapshot\_namespace\_arn](#output\_snapshot\_namespace\_arn) | The Amazon Resource Name (ARN) of the namespace the snapshot was created from. |
| <a name="output_snapshot_owner_account"></a> [snapshot\_owner\_account](#output\_snapshot\_owner\_account) | The owner Amazon Web Services; account of the snapshot. |
| <a name="output_vpc_endpoint"></a> [vpc\_endpoint](#output\_vpc\_endpoint) | The VPC endpoint or the Redshift Serverless workgroup |
| <a name="output_vpc_endpoint_address"></a> [vpc\_endpoint\_address](#output\_vpc\_endpoint\_address) | The DNS address of the VPC endpoint |
| <a name="output_workgroup_arn"></a> [workgroup\_arn](#output\_workgroup\_arn) | Amazon Resource Name (ARN) of the Redshift Serverless Workgroup. |
| <a name="output_workgroup_id"></a> [workgroup\_id](#output\_workgroup\_id) | The Redshift Workgroup ID. |
| <a name="output_workgroup_name"></a> [workgroup\_name](#output\_workgroup\_name) | The Redshift Workgroup Name. |
<!-- END_TF_DOCS -->