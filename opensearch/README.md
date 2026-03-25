<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.11.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.37.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.37.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_policies"></a> [access\_policies](#input\_access\_policies) | IAM policy document specifying the access policies for the domain. Required if `create_access_policy` is `false` | `string` | `null` | no |
| <a name="input_access_policy_override_policy_documents"></a> [access\_policy\_override\_policy\_documents](#input\_access\_policy\_override\_policy\_documents) | List of IAM policy documents that are merged together into the exported document. In merging, statements with non-blank `sid`s will override statements with the same `sid` | `list(string)` | `[]` | no |
| <a name="input_access_policy_source_policy_documents"></a> [access\_policy\_source\_policy\_documents](#input\_access\_policy\_source\_policy\_documents) | List of IAM policy documents that are merged together into the exported document. Statements must have unique `sid`s | `list(string)` | `[]` | no |
| <a name="input_access_policy_statements"></a> [access\_policy\_statements](#input\_access\_policy\_statements) | A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage | `any` | `{}` | no |
| <a name="input_advanced_options"></a> [advanced\_options](#input\_advanced\_options) | Key-value string pairs to specify advanced configuration options. Note that the values for these configuration options must be strings (wrapped in quotes) or they may be wrong and cause a perpetual diff, causing Terraform to want to recreate your Elasticsearch domain on every apply | `map(string)` | <pre>{<br/>  "indices.fielddata.cache.size": "40",<br/>  "indices.query.bool.max_clause_count": "1024",<br/>  "override_main_response_version": "false",<br/>  "rest.action.multi.allow_explicit_index": "true"<br/>}</pre> | no |
| <a name="input_advanced_security_options"></a> [advanced\_security\_options](#input\_advanced\_security\_options) | Configuration block for [fine-grained access control](https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/fgac.html) | `any` | <pre>{<br/>  "anonymous_auth_enabled": false,<br/>  "enabled": true<br/>}</pre> | no |
| <a name="input_aiml_options"></a> [aiml\_options](#input\_aiml\_options) | Configuration block for AI/ML options including natural language query generation, S3 vectors engine, and serverless vector acceleration | `any` | `{}` | no |
| <a name="input_auto_tune_options"></a> [auto\_tune\_options](#input\_auto\_tune\_options) | Configuration block for the Auto-Tune options of the domain | `any` | <pre>{<br/>  "desired_state": "ENABLED",<br/>  "rollback_on_disable": "NO_ROLLBACK"<br/>}</pre> | no |
| <a name="input_cloudwatch_log_group_class"></a> [cloudwatch\_log\_group\_class](#input\_cloudwatch\_log\_group\_class) | Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT\_ACCESS | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_kms_key_id"></a> [cloudwatch\_log\_group\_kms\_key\_id](#input\_cloudwatch\_log\_group\_kms\_key\_id) | If a KMS Key ARN is set, this key will be used to encrypt the corresponding log group. Please be sure that the KMS Key has an appropriate key policy (https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html) | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_retention_in_days"></a> [cloudwatch\_log\_group\_retention\_in\_days](#input\_cloudwatch\_log\_group\_retention\_in\_days) | Number of days to retain log events | `number` | `7` | no |
| <a name="input_cloudwatch_log_group_skip_destroy"></a> [cloudwatch\_log\_group\_skip\_destroy](#input\_cloudwatch\_log\_group\_skip\_destroy) | Set to true if you do not wish the log group (and any logs it may contain) to be deleted at destroy time, and instead just remove the log group from the Terraform state | `bool` | `null` | no |
| <a name="input_cloudwatch_log_resource_policy_name"></a> [cloudwatch\_log\_resource\_policy\_name](#input\_cloudwatch\_log\_resource\_policy\_name) | Name of the resource policy for OpenSearch to log to CloudWatch | `string` | `null` | no |
| <a name="input_cluster_config"></a> [cluster\_config](#input\_cluster\_config) | Configuration block for the cluster of the domain | `any` | <pre>{<br/>  "dedicated_master_enabled": false,<br/>  "zone_awareness_config": {<br/>    "availability_zone_count": 3<br/>  }<br/>}</pre> | no |
| <a name="input_cognito_options"></a> [cognito\_options](#input\_cognito\_options) | Configuration block for authenticating Kibana with Cognito | `any` | `{}` | no |
| <a name="input_create_access_policy"></a> [create\_access\_policy](#input\_create\_access\_policy) | Determines whether an access policy will be created | `bool` | `true` | no |
| <a name="input_create_cloudwatch_log_groups"></a> [create\_cloudwatch\_log\_groups](#input\_create\_cloudwatch\_log\_groups) | Determines whether log groups are created | `bool` | `true` | no |
| <a name="input_create_cloudwatch_log_resource_policy"></a> [create\_cloudwatch\_log\_resource\_policy](#input\_create\_cloudwatch\_log\_resource\_policy) | Determines whether a resource policy will be created for OpenSearch to log to CloudWatch | `bool` | `true` | no |
| <a name="input_create_saml_options"></a> [create\_saml\_options](#input\_create\_saml\_options) | Determines whether SAML options will be created | `bool` | `false` | no |
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | Determines if a security group is created | `bool` | `true` | no |
| <a name="input_domain_endpoint_options"></a> [domain\_endpoint\_options](#input\_domain\_endpoint\_options) | Configuration block for domain endpoint HTTP(S) related options | `any` | <pre>{<br/>  "enforce_https": true,<br/>  "tls_security_policy": "Policy-Min-TLS-1-2-2019-07"<br/>}</pre> | no |
| <a name="input_ebs_options"></a> [ebs\_options](#input\_ebs\_options) | Configuration block for EBS related options, may be required based on chosen [instance size](https://aws.amazon.com/elasticsearch-service/pricing/) | `any` | <pre>{<br/>  "ebs_enabled": true,<br/>  "volume_size": 30,<br/>  "volume_type": "gp3"<br/>}</pre> | no |
| <a name="input_enable_access_policy"></a> [enable\_access\_policy](#input\_enable\_access\_policy) | Determines whether an access policy will be applied to the domain | `bool` | `true` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_encrypt_at_rest"></a> [encrypt\_at\_rest](#input\_encrypt\_at\_rest) | Configuration block for encrypting at rest | `any` | <pre>{<br/>  "enabled": true<br/>}</pre> | no |
| <a name="input_identity_center_options"></a> [identity\_center\_options](#input\_identity\_center\_options) | Configuration block for AWS IAM Identity Center options | `any` | `{}` | no |
| <a name="input_ip_address_type"></a> [ip\_address\_type](#input\_ip\_address\_type) | The IP address type for the endpoint. Valid values are ipv4 and dualstack | `string` | `null` | no |
| <a name="input_log_publishing_options"></a> [log\_publishing\_options](#input\_log\_publishing\_options) | Configuration block for publishing slow and application logs to CloudWatch Logs. This block can be declared multiple times, for each log\_type, within the same resource | `any` | <pre>[<br/>  {<br/>    "log_type": "INDEX_SLOW_LOGS"<br/>  },<br/>  {<br/>    "log_type": "SEARCH_SLOW_LOGS"<br/>  },<br/>  {<br/>    "log_type": "ES_APPLICATION_LOGS"<br/>  }<br/>]</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | Name to use for resource naming and tagging. | `string` | `null` | no |
| <a name="input_node_to_node_encryption"></a> [node\_to\_node\_encryption](#input\_node\_to\_node\_encryption) | Configuration block for node-to-node encryption options | `any` | <pre>{<br/>  "enabled": true<br/>}</pre> | no |
| <a name="input_off_peak_window_options"></a> [off\_peak\_window\_options](#input\_off\_peak\_window\_options) | Configuration to add Off Peak update options | `any` | <pre>{<br/>  "enabled": true,<br/>  "off_peak_window": {<br/>    "hours": 7<br/>  }<br/>}</pre> | no |
| <a name="input_opensearch_domain_name"></a> [opensearch\_domain\_name](#input\_opensearch\_domain\_name) | Name of the opensearch domain | `string` | `null` | no |
| <a name="input_opensearch_version"></a> [opensearch\_version](#input\_opensearch\_version) | OpenSearch version | `string` | `"OpenSearch_2.13"` | no |
| <a name="input_outbound_connections"></a> [outbound\_connections](#input\_outbound\_connections) | Map of AWS OpenSearch outbound connections to create | `any` | `{}` | no |
| <a name="input_package_associations"></a> [package\_associations](#input\_package\_associations) | Map of package association IDs to associate with the domain | `map(string)` | `{}` | no |
| <a name="input_saml_options"></a> [saml\_options](#input\_saml\_options) | SAML authentication options for an AWS OpenSearch Domain | `any` | `{}` | no |
| <a name="input_security_group_description"></a> [security\_group\_description](#input\_security\_group\_description) | Description of the security group created | `string` | `null` | no |
| <a name="input_security_group_name"></a> [security\_group\_name](#input\_security\_group\_name) | Name to use on security group created | `string` | `null` | no |
| <a name="input_security_group_rules"></a> [security\_group\_rules](#input\_security\_group\_rules) | Security group ingress and egress rules to add to the security group created | `any` | `{}` | no |
| <a name="input_security_group_tags"></a> [security\_group\_tags](#input\_security\_group\_tags) | A map of additional tags to add to the security group created | `map(string)` | `{}` | no |
| <a name="input_security_group_use_name_prefix"></a> [security\_group\_use\_name\_prefix](#input\_security\_group\_use\_name\_prefix) | Determines whether the security group name (`security_group_name`) is used as a prefix | `bool` | `true` | no |
| <a name="input_snapshot_options"></a> [snapshot\_options](#input\_snapshot\_options) | Configuration block for automated daily snapshots. Note: deprecated for OpenSearch 5.3 and later which take hourly automated snapshots. Set `automated_snapshot_start_hour` (0-23) to configure | <pre>object({<br/>    automated_snapshot_start_hour = number<br/>  })</pre> | `null` | no |
| <a name="input_software_update_options"></a> [software\_update\_options](#input\_software\_update\_options) | Software update options for the domain | `any` | <pre>{<br/>  "auto_software_update_enabled": false<br/>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Create and delete timeout configurations for the domain | `map(string)` | `{}` | no |
| <a name="input_vpc_endpoints"></a> [vpc\_endpoints](#input\_vpc\_endpoints) | Map of VPC endpoints to create for the domain | `any` | `{}` | no |
| <a name="input_vpc_options"></a> [vpc\_options](#input\_vpc\_options) | Configuration block for VPC related options. Adding or removing this configuration forces a new resource ([documentation](https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html#es-vpc-limitations)) | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_logs"></a> [cloudwatch\_logs](#output\_cloudwatch\_logs) | Map of CloudWatch log groups created and their attributes |
| <a name="output_domain_arn"></a> [domain\_arn](#output\_domain\_arn) | The Amazon Resource Name (ARN) of the domain |
| <a name="output_domain_dashboard_endpoint"></a> [domain\_dashboard\_endpoint](#output\_domain\_dashboard\_endpoint) | Domain-specific endpoint for Dashboard without https scheme |
| <a name="output_domain_dashboard_endpoint_v2"></a> [domain\_dashboard\_endpoint\_v2](#output\_domain\_dashboard\_endpoint\_v2) | V2 domain endpoint for Dashboard that works with both IPv4 and IPv6 addresses, without https scheme |
| <a name="output_domain_endpoint"></a> [domain\_endpoint](#output\_domain\_endpoint) | Domain-specific endpoint used to submit index, search, and data upload requests |
| <a name="output_domain_endpoint_v2"></a> [domain\_endpoint\_v2](#output\_domain\_endpoint\_v2) | V2 domain endpoint that works with both IPv4 and IPv6 addresses, used to submit index, search, and data upload requests |
| <a name="output_domain_id"></a> [domain\_id](#output\_domain\_id) | The unique identifier for the domain |
| <a name="output_outbound_connections"></a> [outbound\_connections](#output\_outbound\_connections) | Map of outbound connections created and their attributes |
| <a name="output_package_associations"></a> [package\_associations](#output\_package\_associations) | Map of package associations created and their attributes |
| <a name="output_security_group_arn"></a> [security\_group\_arn](#output\_security\_group\_arn) | Amazon Resource Name (ARN) of the security group |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the security group |
| <a name="output_vpc_endpoints"></a> [vpc\_endpoints](#output\_vpc\_endpoints) | Map of VPC endpoints created and their attributes |
<!-- END_TF_DOCS -->