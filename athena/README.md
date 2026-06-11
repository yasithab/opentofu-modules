# Amazon Athena

OpenTofu module for provisioning and managing AWS Athena workgroups, named queries, data catalogs, and databases.

> **Note:** `result_output_location` is required when `enforce_workgroup_configuration = true` (the default) — an enforced workgroup without a result location would leave queries with nowhere to write results.

## Features

- **Workgroup Management** - Create and configure Athena workgroups with engine version selection, state control, and force destroy options
- **Query Result Configuration** - S3 output location with encryption (SSE_S3, SSE_KMS, CSE_KMS) and ACL controls
- **Cost Controls** - Bytes scanned cutoff per query to prevent runaway costs, with enforced workgroup configuration
- **Named Queries** - Pre-defined reusable queries associated with databases and workgroups
- **Data Catalogs** - Register external catalogs (Glue, Lambda, Hive) for federated queries
- **Databases** - Manage Athena databases with optional encryption and S3 bucket configuration
- **CloudWatch Metrics** - Publish workgroup metrics to CloudWatch for monitoring (enabled by default)
- **Requester Pays** - Optional requester pays support for cross-account data access
- **Prepared Statements** - Parameterised SQL statements registered in the workgroup (`prepared_statements`)
- **Capacity Reservation** - Optional dedicated DPU processing capacity for the workgroup's queries (`capacity_reservation`)

## Usage

```hcl
module "athena" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//athena?depth=1&ref=master"

  name                   = "analytics-workgroup"
  result_output_location = "s3://my-athena-results/output/"

  tags = {
    Environment = "production"
  }
}
```

## Examples

### Basic Workgroup with Cost Controls

A workgroup with enforced configuration and a bytes scanned limit to control query costs.

```hcl
module "athena_basic" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//athena?depth=1&ref=master"

  enabled = true
  name    = "data-team-workgroup"

  engine_version                     = "Athena engine version 3"
  enforce_workgroup_configuration    = true
  publish_cloudwatch_metrics_enabled = true
  bytes_scanned_cutoff_per_query     = 10737418240 # 10 GB

  result_output_location    = "s3://athena-results-bucket/data-team/"
  result_encryption_option  = "SSE_S3"

  tags = {
    Environment = "production"
    Team        = "data"
  }
}
```

### Workgroup with KMS Encryption and Named Queries

A workgroup using KMS encryption for results and pre-defined named queries for common analytics patterns.

```hcl
module "athena_encrypted" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//athena?depth=1&ref=master"

  enabled = true
  name    = "secure-analytics"

  result_output_location        = "s3://secure-athena-results/output/"
  result_encryption_option      = "SSE_KMS"
  result_encryption_kms_key_arn = "arn:aws:kms:ap-southeast-1:123456789012:key/mrk-abc123def456"

  databases = {
    analytics = {
      bucket  = "analytics-data-bucket"
      comment = "Analytics database for product metrics"
    }
  }

  named_queries = {
    daily_active_users = {
      database    = "analytics"
      query       = "SELECT date, COUNT(DISTINCT user_id) AS dau FROM events WHERE date = current_date - interval '1' day GROUP BY date"
      description = "Calculate daily active users"
    }
    top_products = {
      database    = "analytics"
      query       = "SELECT product_id, COUNT(*) AS views FROM page_views WHERE date >= current_date - interval '7' day GROUP BY product_id ORDER BY views DESC LIMIT 100"
      description = "Top 100 products by views in the last 7 days"
    }
  }

  tags = {
    Environment = "production"
    Team        = "analytics"
  }
}
```

### Federated Query with Glue Data Catalog

A workgroup configured with a Glue data catalog for querying across multiple data sources.

```hcl
module "athena_federated" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//athena?depth=1&ref=master"

  enabled = true
  name    = "federated-queries"

  result_output_location   = "s3://athena-results/federated/"
  result_encryption_option = "SSE_S3"

  data_catalogs = {
    glue_catalog = {
      description = "AWS Glue Data Catalog"
      type        = "GLUE"
      parameters = {
        catalog-id = "123456789012"
      }
    }
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

### Prepared Statements and Capacity Reservation

A workgroup with parameterised prepared statements and a dedicated capacity reservation for predictable query performance.

```hcl
module "athena_reserved" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//athena?depth=1&ref=master"

  enabled = true
  name    = "reporting-workgroup"

  result_output_location   = "s3://athena-results/reporting/"
  result_encryption_option = "SSE_S3"

  prepared_statements = {
    user_events_by_day = {
      query_statement = "SELECT * FROM analytics.events WHERE event_date = ? AND user_id = ?"
      description     = "Fetch events for a user on a given day"
    }
    orders_above_total = {
      query_statement = "SELECT order_id, total FROM sales.orders WHERE total > ?"
    }
  }

  capacity_reservation = {
    name        = "reporting-capacity"
    target_dpus = 24
  }

  tags = {
    Environment = "production"
    Team        = "reporting"
  }
}
```

## Reference

<details>
<summary>Requirements, providers, inputs and outputs (generated by terraform-docs)</summary>

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
| bytes\_scanned\_cutoff\_per\_query | Maximum number of bytes scanned per query. Queries exceeding this limit are cancelled. Set to control costs | `number` | `null` | no |
| capacity\_reservation | Athena capacity reservation configuration (dedicated DPU processing capacity). Set to `null` (default) to skip. `name` defaults to the workgroup name; `target_dpus` minimum is 24 | <pre>object({<br/>    name        = optional(string)<br/>    target_dpus = number<br/>  })</pre> | `null` | no |
| data\_catalogs | Map of data catalogs to create. Each key is the catalog name. Values must include 'type' (LAMBDA, GLUE, HIVE) and 'parameters' | <pre>map(object({<br/>    description = optional(string)<br/>    type        = string<br/>    parameters  = map(string)<br/>  }))</pre> | `{}` | no |
| databases | Map of Athena databases to create. Each key is the database name. Supports optional bucket, comment, encryption, and ACL settings | `any` | `{}` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| enforce\_workgroup\_configuration | Whether users must use workgroup settings when running queries. Enforces security and cost controls | `bool` | `true` | no |
| engine\_version | The Athena engine version for running queries (e.g., 'Athena engine version 3') | `string` | `null` | no |
| execution\_role | IAM role ARN used to access the user's resources while running the query | `string` | `null` | no |
| force\_destroy | Whether to force destroy the workgroup and its named queries | `bool` | `false` | no |
| name | Name of the Athena workgroup | `string` | n/a | yes |
| named\_queries | Map of named queries to create. Each key is the query name. Values must include 'database' and 'query', optionally 'description' | <pre>map(object({<br/>    database    = string<br/>    query       = string<br/>    description = optional(string)<br/>  }))</pre> | `{}` | no |
| prepared\_statements | Map of prepared statements to create in the workgroup. Each key is the statement name (must start with a letter or underscore and contain only alphanumerics/underscores). Values must include 'query\_statement', optionally 'description' | <pre>map(object({<br/>    query_statement = string<br/>    description     = optional(string)<br/>  }))</pre> | `{}` | no |
| publish\_cloudwatch\_metrics\_enabled | Whether CloudWatch metrics are enabled for the workgroup | `bool` | `true` | no |
| requester\_pays\_enabled | Whether requester pays is enabled for the workgroup. If enabled, the requester pays for data access charges | `bool` | `false` | no |
| result\_acl\_s3\_owner | S3 ACL option for query results. Valid value: BUCKET\_OWNER\_FULL\_CONTROL | `string` | `null` | no |
| result\_encryption\_kms\_key\_arn | KMS key ARN used to encrypt query results. Required when encryption\_option is SSE\_KMS or CSE\_KMS | `string` | `null` | no |
| result\_encryption\_option | Encryption method for query results. Valid values: SSE\_S3, SSE\_KMS, CSE\_KMS | `string` | `"SSE_S3"` | no |
| result\_expected\_bucket\_owner | Expected owner of the S3 results bucket (AWS account ID) | `string` | `null` | no |
| result\_output\_location | S3 location for Athena query results (e.g., 's3://bucket-name/prefix/') | `string` | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| workgroup\_description | Description of the Athena workgroup | `string` | `null` | no |
| workgroup\_state | State of the workgroup. Valid values are ENABLED or DISABLED | `string` | `"ENABLED"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| capacity\_reservation\_allocated\_dpus | Number of DPUs currently allocated to the capacity reservation |
| capacity\_reservation\_arn | ARN of the Athena capacity reservation |
| capacity\_reservation\_status | Status of the Athena capacity reservation |
| data\_catalog\_names | Map of data catalog names to their names |
| database\_names | Map of database keys to their names |
| named\_query\_ids | Map of named query names to their IDs |
| prepared\_statement\_names | Map of prepared statement keys to their names |
| workgroup\_arn | ARN of the Athena workgroup |
| workgroup\_id | ID of the Athena workgroup |
| workgroup\_name | Name of the Athena workgroup |
<!-- END_TF_DOCS -->

</details>
