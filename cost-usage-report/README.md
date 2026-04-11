# Cost and Usage Report

Provisions AWS Cost and Usage Reports (CUR) with configurable report definitions, S3 bucket delivery, compression formats, and schema elements.

## Features

- **Report Definition** - Create CUR reports with configurable time granularity (hourly, daily, monthly)
- **S3 Bucket Configuration** - Optionally create a dedicated S3 bucket with encryption, versioning, and public access blocking for secure report delivery
- **Report Versioning** - Choose between overwriting previous reports or creating new report versions
- **Compression Formats** - Support for ZIP, GZIP, and Parquet compression to optimize storage costs
- **Additional Schema Elements** - Include RESOURCES and SPLIT_COST_ALLOCATION_DATA for detailed cost breakdowns
- **Refresh Closed Reports** - Optionally refresh finalized reports when AWS applies refunds, credits, or support fees
- **S3 Bucket Policy** - Automatically configure the bucket policy to allow the CUR billing service to deliver reports
- **S3 Lifecycle Rules** - Optional lifecycle configuration for transitioning old reports to Glacier and eventual expiration
- **Athena Integration** - Default support for Athena as an additional artifact for querying reports directly

## Usage

```hcl
module "cur" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cost-usage-report?depth=1&ref=master"

  name           = "monthly-cost-report"
  s3_bucket_name = "my-org-cur-reports"
  time_unit      = "MONTHLY"

  tags = {
    Environment = "management"
  }
}
```

## Examples

### Daily Parquet Report with Athena

Daily CUR report in Parquet format with Athena integration for SQL querying.

```hcl
module "cur_daily" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cost-usage-report?depth=1&ref=master"

  enabled = true
  name    = "daily-cost-report"

  time_unit                  = "DAILY"
  format                     = "Parquet"
  compression                = "Parquet"
  additional_schema_elements = ["RESOURCES"]
  additional_artifacts       = ["ATHENA"]
  refresh_closed_reports     = true
  report_versioning          = "OVERWRITE_REPORT"

  create_s3_bucket = true
  s3_bucket_name   = "myorg-cur-reports-prod"
  s3_region        = "us-east-1"
  s3_prefix        = "daily/"

  tags = {
    Environment = "management"
    Team        = "finops"
  }
}
```

### Hourly CSV Report with KMS Encryption

Hourly granularity report in CSV format with KMS-encrypted S3 bucket and lifecycle rules.

```hcl
module "cur_hourly" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cost-usage-report?depth=1&ref=master"

  enabled = true
  name    = "hourly-detailed-report"

  time_unit                  = "HOURLY"
  format                     = "textORcsv"
  compression                = "GZIP"
  additional_schema_elements = ["RESOURCES", "SPLIT_COST_ALLOCATION_DATA"]
  refresh_closed_reports     = true
  report_versioning          = "CREATE_NEW_REPORT"

  create_s3_bucket  = true
  s3_bucket_name    = "myorg-cur-hourly-prod"
  s3_region         = "us-east-1"
  s3_prefix         = "hourly/"
  s3_sse_algorithm  = "aws:kms"
  s3_kms_key_id     = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"

  enable_s3_lifecycle                  = true
  s3_lifecycle_glacier_transition_days = 180
  s3_lifecycle_expiration_days         = 1825

  tags = {
    Environment = "management"
    Team        = "finops"
    DataClass   = "billing"
  }
}
```

### Using an Existing S3 Bucket

Monthly report delivered to a pre-existing S3 bucket (no bucket creation).

```hcl
module "cur_existing_bucket" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cost-usage-report?depth=1&ref=master"

  enabled = true
  name    = "monthly-summary"

  time_unit   = "MONTHLY"
  format      = "Parquet"
  compression = "Parquet"

  create_s3_bucket        = false
  create_s3_bucket_policy = false
  s3_bucket_name          = "existing-cur-bucket"
  s3_region               = "us-east-1"
  s3_prefix               = "monthly/"

  additional_schema_elements = ["RESOURCES"]
  refresh_closed_reports     = true

  tags = {
    Environment = "management"
    Team        = "finops"
  }
}
```
