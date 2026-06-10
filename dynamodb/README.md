# Amazon DynamoDB

OpenTofu module for provisioning and managing Amazon DynamoDB tables with support for autoscaling, global tables, encryption, and point-in-time recovery.

## Features

- **Flexible Billing** - Supports both PAY_PER_REQUEST (on-demand) and PROVISIONED capacity modes with configurable read/write throughput
- **Autoscaling** - Built-in Application Auto Scaling for read/write capacity and global secondary index throughput with customizable scaling policies
- **Global Tables** - Multi-region replication with configurable replica regions, strong consistency mode, and global table witness support
- **Secondary Indexes** - Full support for both global secondary indexes (GSI) and local secondary indexes (LSI) with on-demand throughput and warm throughput options
- **Encryption** - Server-side encryption enabled by default with optional custom KMS key support
- **Point-in-Time Recovery** - Enabled by default with configurable retention period (up to 35 days)
- **TTL Support** - Configurable time-to-live attribute for automatic item expiration
- **DynamoDB Streams** - Optional change data capture with configurable stream view types
- **Resource Policies** - Attach resource-based IAM policies directly to tables
- **S3 Import** - Import data from S3 during table creation with CSV format support
- **Deletion Protection** - Enabled by default to prevent accidental table deletion

## Usage

```hcl
module "dynamodb" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//dynamodb?depth=1&ref=master"

  name     = "my-table"
  hash_key = "id"

  attributes = [
    { name = "id", type = "S" }
  ]

  tags = {
    Environment = "production"
  }
}
```


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11.0 |
| aws | >= 6.49, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.49, < 7.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| attributes | List of nested attribute definitions. Only required for hash\_key and range\_key attributes. Each attribute has two properties: name - (Required) The name of the attribute, type - (Required) Attribute type, which must be a scalar type: S, N, or B for (S)tring, (N)umber or (B)inary data | `list(map(string))` | `[]` | no |
| autoscaling\_defaults | A map of default autoscaling settings | `map(string)` | <pre>{<br/>  "scale_in_cooldown": 0,<br/>  "scale_out_cooldown": 0,<br/>  "target_value": 70<br/>}</pre> | no |
| autoscaling\_enabled | Whether or not to enable autoscaling. See note in README about this setting | `bool` | `false` | no |
| autoscaling\_indexes | A map of index autoscaling configurations. See example in examples/autoscaling | `map(map(string))` | `{}` | no |
| autoscaling\_read | A map of read autoscaling settings. `max_capacity` is the only required key. `min_capacity` is used when `read_capacity` is not set. See example in examples/autoscaling | `map(string)` | `{}` | no |
| autoscaling\_write | A map of write autoscaling settings. `max_capacity` is the only required key. `min_capacity` is used when `write_capacity` is not set. See example in examples/autoscaling | `map(string)` | `{}` | no |
| billing\_mode | Controls how you are billed for read/write throughput and how you manage capacity. The valid values are PROVISIONED or PAY\_PER\_REQUEST | `string` | `"PAY_PER_REQUEST"` | no |
| deletion\_protection\_enabled | Enables deletion protection for table | `bool` | `true` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| global\_secondary\_indexes | Describe a GSI for the table; subject to the normal limits on the number of GSIs, projected attributes, etc. | `any` | `[]` | no |
| global\_table\_witness | Configuration for a witness region in a Multi-Region Strong Consistency (MRSC) global table. Must be used alongside a single replica with consistency\_mode set to STRONG. Requires an object with region\_name (required). | <pre>object({<br/>    region_name = string<br/>  })</pre> | `null` | no |
| hash\_key | The attribute to use as the hash (partition) key. Must also be defined as an attribute | `string` | n/a | yes |
| ignore\_changes\_global\_secondary\_index | Whether to ignore changes lifecycle to global secondary indices, useful for provisioned tables with scaling | `bool` | `false` | no |
| import\_table | Configurations for importing s3 data into a new table. | `any` | `{}` | no |
| local\_secondary\_indexes | Describe an LSI on the table; these can only be allocated at creation so you cannot change this definition after you have created the resource. | `any` | `[]` | no |
| name | Name of the DynamoDB table | `string` | `null` | no |
| on\_demand\_throughput | Sets the maximum number of read and write units for the specified on-demand table | `any` | `{}` | no |
| point\_in\_time\_recovery\_enabled | Whether to enable point-in-time recovery | `bool` | `true` | no |
| point\_in\_time\_recovery\_period\_in\_days | The number of days for which continuous backups are retained for point-in-time recovery. Valid values are between 1 and 35. Defaults to 35 when not specified. | `number` | `null` | no |
| range\_key | The attribute to use as the range (sort) key. Must also be defined as an attribute | `string` | `null` | no |
| read\_capacity | The number of read units for this table. If the billing\_mode is PROVISIONED, this field should be greater than 0 | `number` | `null` | no |
| replica\_regions | Region names for creating replicas for a global DynamoDB table. | `any` | `[]` | no |
| resource\_policy | An AWS resource-based policy document in JSON format to attach to the DynamoDB table. Set to null to not create a resource policy | `string` | `null` | no |
| resource\_policy\_confirm\_remove\_self\_access | Set to true to confirm removal of your own permissions from the DynamoDB resource policy. Required when removing access to yourself from the policy | `bool` | `null` | no |
| restore\_date\_time | Time of the point-in-time recovery point to restore. | `string` | `null` | no |
| restore\_source\_name | Name of the table to restore. Must match the name of an existing table. | `string` | `null` | no |
| restore\_source\_table\_arn | ARN of the source table to restore. Must be supplied for cross-region restores. | `string` | `null` | no |
| restore\_to\_latest\_time | If set, restores table to the most recent point-in-time recovery point. | `bool` | `null` | no |
| server\_side\_encryption\_enabled | Whether or not to enable encryption at rest using an AWS managed KMS customer master key (CMK) | `bool` | `true` | no |
| server\_side\_encryption\_kms\_key\_arn | The ARN of the CMK that should be used for the AWS KMS encryption. This attribute should only be specified if the key is different from the default DynamoDB CMK, alias/aws/dynamodb. | `string` | `null` | no |
| stream\_enabled | Indicates whether Streams are to be enabled (true) or disabled (false). | `bool` | `false` | no |
| stream\_view\_type | When an item in the table is modified, StreamViewType determines what information is written to the table's stream. Valid values are KEYS\_ONLY, NEW\_IMAGE, OLD\_IMAGE, NEW\_AND\_OLD\_IMAGES. | `string` | `null` | no |
| table\_class | The storage class of the table. Valid values are STANDARD and STANDARD\_INFREQUENT\_ACCESS | `string` | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| timeouts | Updated Terraform resource management timeouts | `map(string)` | <pre>{<br/>  "create": "10m",<br/>  "delete": "10m",<br/>  "update": "60m"<br/>}</pre> | no |
| ttl\_attribute\_name | The name of the table attribute to store the TTL timestamp in | `string` | `null` | no |
| ttl\_enabled | Indicates whether ttl is enabled | `bool` | `false` | no |
| warm\_throughput | Sets the number of warm read and write units for the DynamoDB table. Only valid for tables with PROVISIONED billing mode | `any` | `{}` | no |
| write\_capacity | The number of write units for this table. If the billing\_mode is PROVISIONED, this field should be greater than 0 | `number` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| dynamodb\_resource\_policy\_id | The ID of the DynamoDB resource policy, same as the resource ARN |
| dynamodb\_table\_arn | ARN of the DynamoDB table |
| dynamodb\_table\_id | ID of the DynamoDB table |
| dynamodb\_table\_stream\_arn | The ARN of the Table Stream. Only available when var.stream\_enabled is true |
| dynamodb\_table\_stream\_label | A timestamp, in ISO 8601 format of the Table Stream. Only available when var.stream\_enabled is true |
<!-- END_TF_DOCS -->

## Examples

## Basic Usage

A simple on-demand table with a single partition key and encryption enabled (default).

```hcl
module "dynamodb_table" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//dynamodb?depth=1&ref=master"

  enabled = true
  name    = "orders"

  hash_key = "OrderId"

  attributes = [
    { name = "OrderId", type = "S" }
  ]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## With Sort Key and TTL

A table with both a partition key and range key, plus TTL to automatically expire old items.

```hcl
module "dynamodb_sessions" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//dynamodb?depth=1&ref=master"

  enabled = true
  name    = "user-sessions"

  hash_key  = "UserId"
  range_key = "SessionId"

  attributes = [
    { name = "UserId",    type = "S" },
    { name = "SessionId", type = "S" }
  ]

  ttl_enabled        = true
  ttl_attribute_name = "ExpiresAt"

  point_in_time_recovery_enabled = true

  tags = {
    Environment = "production"
    Team        = "auth"
  }
}
```

## With Global Secondary Index and KMS Encryption

A table with a GSI for query flexibility and a customer-managed KMS key for encryption.

```hcl
module "dynamodb_products" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//dynamodb?depth=1&ref=master"

  enabled = true
  name    = "products"

  hash_key  = "ProductId"
  range_key = "Category"

  attributes = [
    { name = "ProductId", type = "S" },
    { name = "Category",  type = "S" },
    { name = "CreatedAt", type = "N" }
  ]

  global_secondary_indexes = [
    {
      name            = "CategoryCreatedAtIndex"
      projection_type = "ALL"
      key_schema = [
        { attribute_name = "Category",  key_type = "HASH" },
        { attribute_name = "CreatedAt", key_type = "RANGE" }
      ]
    }
  ]

  server_side_encryption_enabled     = true
  server_side_encryption_kms_key_arn = "arn:aws:kms:ap-southeast-1:123456789012:key/mrk-abc123def456"

  tags = {
    Environment = "production"
    Team        = "catalogue"
  }
}
```

## Provisioned Capacity with Autoscaling

A provisioned billing mode table with Application Auto Scaling to handle variable read/write workloads.

```hcl
module "dynamodb_events" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//dynamodb?depth=1&ref=master"

  enabled = true
  name    = "events"

  hash_key  = "EventId"
  range_key = "Timestamp"

  attributes = [
    { name = "EventId",   type = "S" },
    { name = "Timestamp", type = "N" }
  ]

  billing_mode   = "PROVISIONED"
  read_capacity  = 10
  write_capacity = 10

  autoscaling_enabled = true

  autoscaling_read = {
    scale_in_cooldown  = 50
    scale_out_cooldown = 40
    target_value       = 70
    max_capacity       = 100
  }

  autoscaling_write = {
    scale_in_cooldown  = 50
    scale_out_cooldown = 40
    target_value       = 70
    max_capacity       = 50
  }

  stream_enabled    = true
  stream_view_type  = "NEW_AND_OLD_IMAGES"

  tags = {
    Environment = "production"
    Team        = "data"
  }
}
```
