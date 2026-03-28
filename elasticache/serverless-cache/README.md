<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.11.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.38.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.38.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cache_name"></a> [cache\_name](#input\_cache\_name) | The name which serves as a unique identifier to the serverless cache. | `string` | `null` | no |
| <a name="input_cache_usage_limits"></a> [cache\_usage\_limits](#input\_cache\_usage\_limits) | Sets the cache usage limits for storage and ElastiCache Processing Units for the cache. | `map(any)` | `{}` | no |
| <a name="input_daily_snapshot_time"></a> [daily\_snapshot\_time](#input\_daily\_snapshot\_time) | The daily time that snapshots will be created from the new serverless cache. Only supported for engine type `redis`. Defaults to 0. | `string` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | User-created description for the serverless cache. | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Determines whether serverless resource will be created. | `bool` | `true` | no |
| <a name="input_engine"></a> [engine](#input\_engine) | Name of the cache engine to be used for this cache cluster. Valid values are `memcached` or `redis`. | `string` | `"redis"` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | ARN of the customer managed key for encrypting the data at rest. If no KMS key is provided, a default service key is used. | `string` | `null` | no |
| <a name="input_major_engine_version"></a> [major\_engine\_version](#input\_major\_engine\_version) | The version of the cache engine that will be used to create the serverless cache. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | Region where the resource(s) will be managed. Defaults to the region set in the provider configuration | `string` | `null` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | One or more VPC security groups associated with the serverless cache. | `list(string)` | `[]` | no |
| <a name="input_snapshot_arns_to_restore"></a> [snapshot\_arns\_to\_restore](#input\_snapshot\_arns\_to\_restore) | The list of ARN(s) of the snapshot that the new serverless cache will be created from. Available for Redis only. | `list(string)` | `null` | no |
| <a name="input_snapshot_retention_limit"></a> [snapshot\_retention\_limit](#input\_snapshot\_retention\_limit) | (Redis only) The number of snapshots that will be retained for the serverless cache that is being created. | `number` | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | A list of the identifiers of the subnets where the VPC endpoint for the serverless cache will be deployed. | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Define maximum timeout for creating, updating, and deleting serverless resources. | `map(string)` | `{}` | no |
| <a name="input_user_group_id"></a> [user\_group\_id](#input\_user\_group\_id) | The identifier of the UserGroup to be associated with the serverless cache. Available for Redis only. Default is NULL. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_serverless_cache_arn"></a> [serverless\_cache\_arn](#output\_serverless\_cache\_arn) | The amazon resource name of the serverless cache |
| <a name="output_serverless_cache_create_time"></a> [serverless\_cache\_create\_time](#output\_serverless\_cache\_create\_time) | Timestamp of when the serverless cache was created |
| <a name="output_serverless_cache_endpoint"></a> [serverless\_cache\_endpoint](#output\_serverless\_cache\_endpoint) | Represents the information required for client programs to connect to a cache node |
| <a name="output_serverless_cache_full_engine_version"></a> [serverless\_cache\_full\_engine\_version](#output\_serverless\_cache\_full\_engine\_version) | The name and version number of the engine the serverless cache is compatible with |
| <a name="output_serverless_cache_major_engine_version"></a> [serverless\_cache\_major\_engine\_version](#output\_serverless\_cache\_major\_engine\_version) | The version number of the engine the serverless cache is compatible with |
| <a name="output_serverless_cache_reader_endpoint"></a> [serverless\_cache\_reader\_endpoint](#output\_serverless\_cache\_reader\_endpoint) | Represents the information required for client programs to connect to a cache node |
| <a name="output_serverless_cache_status"></a> [serverless\_cache\_status](#output\_serverless\_cache\_status) | The current status of the serverless cache. The allowed values are CREATING, AVAILABLE, DELETING, CREATE-FAILED and MODIFYING |
<!-- END_TF_DOCS -->