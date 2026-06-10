# Cost and Usage Report

Provisions AWS Cost and Usage Reports (CUR) with configurable report definitions, S3 bucket delivery, compression formats, and schema elements.

> **Region constraint — us-east-1 only:** the `aws_cur_report_definition` API is only available in `us-east-1`. The module enforces this with a precondition and will fail the plan if the AWS provider is configured for any other region. Configure the provider (or an aliased provider passed to this module) for `us-east-1`; `s3_region` controls where reports are delivered and may be any region.

> **Custom lifecycle rules:** set `s3_lifecycle_rules` to fully control the report bucket's lifecycle configuration (multiple rules, prefixes, transitions). When unset, a default rule (GLACIER transition after `s3_lifecycle_glacier_transition_days`, expiration after `s3_lifecycle_expiration_days`) is used. Rules only apply when `enable_s3_lifecycle = true`.

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
| additional\_artifacts | List of additional artifacts. Valid values: REDSHIFT, QUICKSIGHT, ATHENA. | `list(string)` | <pre>[<br/>  "ATHENA"<br/>]</pre> | no |
| additional\_schema\_elements | List of additional schema elements. Valid values: RESOURCES, SPLIT\_COST\_ALLOCATION\_DATA. | `list(string)` | <pre>[<br/>  "RESOURCES"<br/>]</pre> | no |
| compression | Compression format for the report. Valid values: ZIP, GZIP, Parquet. | `string` | `"Parquet"` | no |
| create\_s3\_bucket | Whether to create an S3 bucket for report delivery. | `bool` | `true` | no |
| create\_s3\_bucket\_policy | Whether to create the S3 bucket policy allowing CUR service to write reports. | `bool` | `true` | no |
| enable\_s3\_lifecycle | Whether to enable S3 lifecycle rules for transitioning and expiring report data. | `bool` | `false` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| format | The format for the report. Valid values: textORcsv, Parquet. | `string` | `"Parquet"` | no |
| name | Name used for the CUR report and as a default for related resources. | `string` | n/a | yes |
| refresh\_closed\_reports | Whether AWS updates the report after it has been finalized if AWS applies refunds, credits, or support fees to the account. | `bool` | `true` | no |
| report\_name | Name of the Cost and Usage Report. If null, uses var.name. | `string` | `null` | no |
| report\_versioning | Whether to overwrite previous report versions or create new versions. Valid values: CREATE\_NEW\_REPORT, OVERWRITE\_REPORT. | `string` | `"OVERWRITE_REPORT"` | no |
| s3\_bucket\_force\_destroy | Whether to force destroy the S3 bucket when removing the module (deletes all objects). | `bool` | `false` | no |
| s3\_bucket\_key\_enabled | Whether to use an S3 Bucket Key for SSE-KMS encryption. | `bool` | `true` | no |
| s3\_bucket\_name | Name of the S3 bucket for CUR delivery. Required when create\_s3\_bucket is false. | `string` | n/a | yes |
| s3\_kms\_key\_id | ARN of the KMS key to use for S3 bucket encryption. Only used when s3\_sse\_algorithm is aws:kms. | `string` | `null` | no |
| s3\_lifecycle\_expiration\_days | Number of days before expiring (deleting) report objects. | `number` | `2555` | no |
| s3\_lifecycle\_glacier\_transition\_days | Number of days before transitioning report objects to Glacier storage. | `number` | `365` | no |
| s3\_lifecycle\_rules | List of lifecycle rules for the report bucket, applied when enable\_s3\_lifecycle is true. When null (default), a single rule transitioning objects to GLACIER after s3\_lifecycle\_glacier\_transition\_days and expiring them after s3\_lifecycle\_expiration\_days is used (previous behaviour). | <pre>list(object({<br/>    id     = string<br/>    status = optional(string, "Enabled")<br/>    prefix = optional(string)<br/>    transitions = optional(list(object({<br/>      days          = number<br/>      storage_class = string<br/>    })), [])<br/>    expiration_days = optional(number)<br/>  }))</pre> | `null` | no |
| s3\_prefix | S3 key prefix for the report delivery location. | `string` | `"cur/"` | no |
| s3\_region | The region of the S3 bucket for CUR delivery. | `string` | `"us-east-1"` | no |
| s3\_sse\_algorithm | Server-side encryption algorithm for the S3 bucket. Valid values: aws:kms, AES256. | `string` | `"AES256"` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| time\_unit | The frequency at which report data is measured and displayed. Valid values: HOURLY, DAILY, MONTHLY. | `string` | `"DAILY"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| report\_arn | The ARN of the Cost and Usage Report definition. |
| report\_id | The ID of the Cost and Usage Report definition. |
| report\_name | The name of the Cost and Usage Report. |
| report\_s3\_bucket | The S3 bucket where the CUR report is delivered. |
| report\_s3\_prefix | The S3 prefix for the CUR report delivery location. |
| report\_s3\_region | The S3 region of the CUR report bucket. |
| s3\_bucket\_arn | The ARN of the S3 bucket created for CUR delivery. |
| s3\_bucket\_domain\_name | The domain name of the S3 bucket. |
| s3\_bucket\_id | The name (ID) of the S3 bucket created for CUR delivery. |
<!-- END_TF_DOCS -->

</details>
