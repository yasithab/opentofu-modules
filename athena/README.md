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
