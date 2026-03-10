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
| <a name="input_attributes"></a> [attributes](#input\_attributes) | List of nested attribute definitions. Only required for hash\_key and range\_key attributes. Each attribute has two properties: name - (Required) The name of the attribute, type - (Required) Attribute type, which must be a scalar type: S, N, or B for (S)tring, (N)umber or (B)inary data | `list(map(string))` | `[]` | no |
| <a name="input_autoscaling_defaults"></a> [autoscaling\_defaults](#input\_autoscaling\_defaults) | A map of default autoscaling settings | `map(string)` | <pre>{<br/>  "scale_in_cooldown": 0,<br/>  "scale_out_cooldown": 0,<br/>  "target_value": 70<br/>}</pre> | no |
| <a name="input_autoscaling_enabled"></a> [autoscaling\_enabled](#input\_autoscaling\_enabled) | Whether or not to enable autoscaling. See note in README about this setting | `bool` | `false` | no |
| <a name="input_autoscaling_indexes"></a> [autoscaling\_indexes](#input\_autoscaling\_indexes) | A map of index autoscaling configurations. See example in examples/autoscaling | `map(map(string))` | `{}` | no |
| <a name="input_autoscaling_read"></a> [autoscaling\_read](#input\_autoscaling\_read) | A map of read autoscaling settings. `max_capacity` is the only required key. See example in examples/autoscaling | `map(string)` | `{}` | no |
| <a name="input_autoscaling_write"></a> [autoscaling\_write](#input\_autoscaling\_write) | A map of write autoscaling settings. `max_capacity` is the only required key. See example in examples/autoscaling | `map(string)` | `{}` | no |
| <a name="input_billing_mode"></a> [billing\_mode](#input\_billing\_mode) | Controls how you are billed for read/write throughput and how you manage capacity. The valid values are PROVISIONED or PAY\_PER\_REQUEST | `string` | `"PAY_PER_REQUEST"` | no |
| <a name="input_deletion_protection_enabled"></a> [deletion\_protection\_enabled](#input\_deletion\_protection\_enabled) | Enables deletion protection for table | `bool` | `true` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Controls if DynamoDB table and associated resources are created | `bool` | `true` | no |
| <a name="input_global_secondary_indexes"></a> [global\_secondary\_indexes](#input\_global\_secondary\_indexes) | Describe a GSI for the table; subject to the normal limits on the number of GSIs, projected attributes, etc. | `any` | `[]` | no |
| <a name="input_global_table_witness"></a> [global\_table\_witness](#input\_global\_table\_witness) | Configuration for a witness region in a Multi-Region Strong Consistency (MRSC) global table. Must be used alongside a single replica with consistency\_mode set to STRONG. Requires an object with region\_name (required). | <pre>object({<br/>    region_name = string<br/>  })</pre> | `null` | no |
| <a name="input_hash_key"></a> [hash\_key](#input\_hash\_key) | The attribute to use as the hash (partition) key. Must also be defined as an attribute | `string` | `null` | no |
| <a name="input_ignore_changes_global_secondary_index"></a> [ignore\_changes\_global\_secondary\_index](#input\_ignore\_changes\_global\_secondary\_index) | Whether to ignore changes lifecycle to global secondary indices, useful for provisioned tables with scaling | `bool` | `false` | no |
| <a name="input_import_table"></a> [import\_table](#input\_import\_table) | Configurations for importing s3 data into a new table. | `any` | `{}` | no |
| <a name="input_local_secondary_indexes"></a> [local\_secondary\_indexes](#input\_local\_secondary\_indexes) | Describe an LSI on the table; these can only be allocated at creation so you cannot change this definition after you have created the resource. | `any` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the DynamoDB table | `string` | `null` | no |
| <a name="input_on_demand_throughput"></a> [on\_demand\_throughput](#input\_on\_demand\_throughput) | Sets the maximum number of read and write units for the specified on-demand table | `any` | `{}` | no |
| <a name="input_point_in_time_recovery_enabled"></a> [point\_in\_time\_recovery\_enabled](#input\_point\_in\_time\_recovery\_enabled) | Whether to enable point-in-time recovery | `bool` | `true` | no |
| <a name="input_point_in_time_recovery_period_in_days"></a> [point\_in\_time\_recovery\_period\_in\_days](#input\_point\_in\_time\_recovery\_period\_in\_days) | The number of days for which continuous backups are retained for point-in-time recovery. Valid values are between 1 and 35. Defaults to 35 when not specified. | `number` | `null` | no |
| <a name="input_range_key"></a> [range\_key](#input\_range\_key) | The attribute to use as the range (sort) key. Must also be defined as an attribute | `string` | `null` | no |
| <a name="input_read_capacity"></a> [read\_capacity](#input\_read\_capacity) | The number of read units for this table. If the billing\_mode is PROVISIONED, this field should be greater than 0 | `number` | `null` | no |
| <a name="input_replica_regions"></a> [replica\_regions](#input\_replica\_regions) | Region names for creating replicas for a global DynamoDB table. | `any` | `[]` | no |
| <a name="input_resource_policy"></a> [resource\_policy](#input\_resource\_policy) | An AWS resource-based policy document in JSON format to attach to the DynamoDB table. Set to null to not create a resource policy | `string` | `null` | no |
| <a name="input_resource_policy_confirm_remove_self_access"></a> [resource\_policy\_confirm\_remove\_self\_access](#input\_resource\_policy\_confirm\_remove\_self\_access) | Set to true to confirm removal of your own permissions from the DynamoDB resource policy. Required when removing access to yourself from the policy | `bool` | `null` | no |
| <a name="input_restore_date_time"></a> [restore\_date\_time](#input\_restore\_date\_time) | Time of the point-in-time recovery point to restore. | `string` | `null` | no |
| <a name="input_restore_source_name"></a> [restore\_source\_name](#input\_restore\_source\_name) | Name of the table to restore. Must match the name of an existing table. | `string` | `null` | no |
| <a name="input_restore_source_table_arn"></a> [restore\_source\_table\_arn](#input\_restore\_source\_table\_arn) | ARN of the source table to restore. Must be supplied for cross-region restores. | `string` | `null` | no |
| <a name="input_restore_to_latest_time"></a> [restore\_to\_latest\_time](#input\_restore\_to\_latest\_time) | If set, restores table to the most recent point-in-time recovery point. | `bool` | `null` | no |
| <a name="input_server_side_encryption_enabled"></a> [server\_side\_encryption\_enabled](#input\_server\_side\_encryption\_enabled) | Whether or not to enable encryption at rest using an AWS managed KMS customer master key (CMK) | `bool` | `true` | no |
| <a name="input_server_side_encryption_kms_key_arn"></a> [server\_side\_encryption\_kms\_key\_arn](#input\_server\_side\_encryption\_kms\_key\_arn) | The ARN of the CMK that should be used for the AWS KMS encryption. This attribute should only be specified if the key is different from the default DynamoDB CMK, alias/aws/dynamodb. | `string` | `null` | no |
| <a name="input_stream_enabled"></a> [stream\_enabled](#input\_stream\_enabled) | Indicates whether Streams are to be enabled (true) or disabled (false). | `bool` | `false` | no |
| <a name="input_stream_view_type"></a> [stream\_view\_type](#input\_stream\_view\_type) | When an item in the table is modified, StreamViewType determines what information is written to the table's stream. Valid values are KEYS\_ONLY, NEW\_IMAGE, OLD\_IMAGE, NEW\_AND\_OLD\_IMAGES. | `string` | `null` | no |
| <a name="input_table_class"></a> [table\_class](#input\_table\_class) | The storage class of the table. Valid values are STANDARD and STANDARD\_INFREQUENT\_ACCESS | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Updated Terraform resource management timeouts | `map(string)` | <pre>{<br/>  "create": "10m",<br/>  "delete": "10m",<br/>  "update": "60m"<br/>}</pre> | no |
| <a name="input_ttl_attribute_name"></a> [ttl\_attribute\_name](#input\_ttl\_attribute\_name) | The name of the table attribute to store the TTL timestamp in | `string` | `null` | no |
| <a name="input_ttl_enabled"></a> [ttl\_enabled](#input\_ttl\_enabled) | Indicates whether ttl is enabled | `bool` | `false` | no |
| <a name="input_warm_throughput"></a> [warm\_throughput](#input\_warm\_throughput) | Sets the number of warm read and write units for the DynamoDB table. Only valid for tables with PROVISIONED billing mode | `any` | `{}` | no |
| <a name="input_write_capacity"></a> [write\_capacity](#input\_write\_capacity) | The number of write units for this table. If the billing\_mode is PROVISIONED, this field should be greater than 0 | `number` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dynamodb_resource_policy_id"></a> [dynamodb\_resource\_policy\_id](#output\_dynamodb\_resource\_policy\_id) | The ID of the DynamoDB resource policy, same as the resource ARN |
| <a name="output_dynamodb_table_arn"></a> [dynamodb\_table\_arn](#output\_dynamodb\_table\_arn) | ARN of the DynamoDB table |
| <a name="output_dynamodb_table_id"></a> [dynamodb\_table\_id](#output\_dynamodb\_table\_id) | ID of the DynamoDB table |
| <a name="output_dynamodb_table_stream_arn"></a> [dynamodb\_table\_stream\_arn](#output\_dynamodb\_table\_stream\_arn) | The ARN of the Table Stream. Only available when var.stream\_enabled is true |
| <a name="output_dynamodb_table_stream_label"></a> [dynamodb\_table\_stream\_label](#output\_dynamodb\_table\_stream\_label) | A timestamp, in ISO 8601 format of the Table Stream. Only available when var.stream\_enabled is true |
<!-- END_TF_DOCS -->