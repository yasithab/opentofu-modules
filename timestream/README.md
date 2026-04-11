# Timestream

Provisions Amazon Timestream databases and tables with configurable retention policies, magnetic store write properties, KMS encryption, and schema definitions.

## Features

- **Database with KMS Encryption** - Create Timestream databases encrypted with AWS KMS customer-managed or default keys
- **Multiple Tables** - Define multiple tables per database with independent configurations
- **Retention Policies** - Configure memory store and magnetic store retention periods independently per table
- **Magnetic Store Writes** - Enable magnetic store write properties with optional rejected data routing to S3
- **Schema Definition** - Configure composite partition keys for optimized query performance
- **Sensible Defaults** - 24-hour memory store retention and 73,000-day (200-year) magnetic store retention by default

## Usage

```hcl
module "timestream" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//timestream?depth=1&ref=master"

  name = "iot-metrics"

  tables = {
    sensor_data = {
      table_name                    = "sensor_data"
      memory_store_retention_hours  = 24
      magnetic_store_retention_days = 365
    }
  }

  tags = {
    Environment = "production"
  }
}
```

## Examples

### Basic Timestream Database with Single Table

Single database and table with default retention settings.

```hcl
module "timestream" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//timestream?depth=1&ref=master"

  enabled = true
  name    = "app-metrics"

  tables = {
    events = {
      table_name                    = "events"
      memory_store_retention_hours  = 48
      magnetic_store_retention_days = 730
    }
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

### With KMS Encryption and Magnetic Store Writes

Encrypted database with magnetic store writes and rejected data routing to S3.

```hcl
module "timestream_encrypted" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//timestream?depth=1&ref=master"

  enabled    = true
  name       = "iot-telemetry"
  kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"

  tables = {
    sensor_readings = {
      table_name                    = "sensor_readings"
      memory_store_retention_hours  = 12
      magnetic_store_retention_days = 1825

      magnetic_store_write_properties = {
        enable_magnetic_store_writes = true
        magnetic_store_rejected_data_location = {
          s3_bucket_name       = "my-rejected-data-bucket"
          s3_encryption_option = "SSE_KMS"
          s3_kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"
          s3_object_key_prefix = "rejected/"
        }
      }
    }

    device_status = {
      table_name                    = "device_status"
      memory_store_retention_hours  = 24
      magnetic_store_retention_days = 365
    }
  }

  tags = {
    Environment = "production"
    Team        = "iot"
    DataClass   = "telemetry"
  }
}
```

### With Schema Definition (Composite Partition Key)

Timestream table with a composite partition key for optimized query patterns.

```hcl
module "timestream_schema" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//timestream?depth=1&ref=master"

  enabled = true
  name    = "analytics-db"

  tables = {
    page_views = {
      table_name                    = "page_views"
      memory_store_retention_hours  = 6
      magnetic_store_retention_days = 365

      schema = {
        composite_partition_key = {
          enforcement_in_record = "REQUIRED"
          name                  = "tenant_id"
          type                  = "DIMENSION"
        }
      }
    }
  }

  tags = {
    Environment = "production"
    Team        = "analytics"
  }
}
```
