# S3 Object

OpenTofu module for managing S3 objects including uploads, copies, encryption, object lock, and bucket notification configuration.

> **Note:** `content` and `content_base64` are marked `sensitive = true`. Plan output will no longer show diffs of inline object content — use `source_file` with `source_hash` if you need visible change detection.

> **Warning — bucket notification exclusivity:** `aws_s3_bucket_notification` manages the *entire* notification configuration for a bucket; S3 allows only one such configuration per bucket. Do not configure notifications for the same bucket from this module and elsewhere (e.g. the `s3` module or another stack) — the configurations will overwrite each other on every apply.

## Features

- **Object Upload** - Upload objects from local files, inline string content, or base64-encoded content
- **Object Copy** - Copy objects between buckets with optional metadata replacement and ACL grants
- **Server-Side Encryption** - Support for SSE-S3 (AES256), SSE-KMS with customer-managed keys, and SSE-C with customer-provided keys
- **Storage Class Configuration** - Choose from Standard, Intelligent-Tiering, Glacier, Deep Archive, and other storage classes
- **Object Tagging** - Apply custom tags to objects independently of resource-level tags
- **Object Lock** - Retention policies (Governance or Compliance mode) and legal hold for immutable storage
- **Metadata and Cache Control** - Set custom metadata, content type, content disposition, and cache headers
- **Bucket Notifications** - Configure event notifications to Lambda, SQS, SNS, and EventBridge
- **Change Detection** - ETag and source hash tracking for automatic re-upload on content changes

## Usage

```hcl
module "s3_object" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//s3-object?depth=1&ref=master"

  name   = "config-upload"
  bucket = "my-app-config"
  key    = "config/app.json"

  content      = jsonencode({ environment = "production", debug = false })
  content_type = "application/json"

  tags = {
    Environment = "production"
  }
}
```

## Examples

## Upload File

Upload a local file to S3 with automatic change detection using the file's MD5 hash.

```hcl
module "s3_upload_file" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//s3-object?depth=1&ref=master"

  name   = "lambda-package"
  bucket = "my-deployments"
  key    = "lambda/functions/api-handler.zip"

  source_file  = "${path.module}/dist/api-handler.zip"
  etag         = filemd5("${path.module}/dist/api-handler.zip")
  content_type = "application/zip"

  tags = {
    Environment = "production"
    Team        = "backend"
  }
}
```

## Upload Inline Content

Upload inline JSON content to S3 as a configuration file.

```hcl
module "s3_upload_content" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//s3-object?depth=1&ref=master"

  name   = "app-config"
  bucket = "my-app-config"
  key    = "config/settings.json"

  content = jsonencode({
    database = {
      host     = "db.example.com"
      port     = 5432
      pool_min = 5
      pool_max = 20
    }
    cache = {
      ttl_seconds = 300
    }
  })

  content_type = "application/json"

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Upload with KMS Encryption

Upload a sensitive file encrypted with a customer-managed KMS key and S3 Bucket Keys enabled to reduce costs.

```hcl
module "s3_upload_kms" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//s3-object?depth=1&ref=master"

  name   = "secrets-config"
  bucket = "my-secure-bucket"
  key    = "secrets/database-credentials.enc"

  content      = var.database_credentials_json
  content_type = "application/json"

  server_side_encryption = "aws:kms"
  kms_key_id             = "arn:aws:kms:ap-southeast-1:123456789012:key/mrk-abc123"
  bucket_key_enabled     = true

  storage_class = "STANDARD"

  object_tags = {
    Classification = "confidential"
    DataOwner      = "security-team"
  }

  tags = {
    Environment = "production"
    Team        = "security"
  }
}
```

## Upload with Object Lock

Upload a compliance document with Compliance-mode retention and a legal hold for regulatory requirements.

```hcl
module "s3_upload_locked" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//s3-object?depth=1&ref=master"

  name   = "audit-report"
  bucket = "my-compliance-bucket"
  key    = "audit/2026/q1-report.pdf"

  source_file  = "${path.module}/reports/q1-report.pdf"
  etag         = filemd5("${path.module}/reports/q1-report.pdf")
  content_type = "application/pdf"

  object_lock_mode              = "COMPLIANCE"
  object_lock_retain_until_date = "2033-04-01T00:00:00Z"
  object_lock_legal_hold_status = "ON"

  server_side_encryption = "aws:kms"
  kms_key_id             = "arn:aws:kms:ap-southeast-1:123456789012:key/mrk-abc123"

  object_tags = {
    Classification = "regulatory"
    RetentionYears = "7"
  }

  tags = {
    Environment = "production"
    Team        = "compliance"
  }
}
```

## Upload with Custom Metadata and Cache Control

Upload a static asset with cache headers and custom metadata for a web application.

```hcl
module "s3_upload_static" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//s3-object?depth=1&ref=master"

  name   = "static-asset"
  bucket = "my-static-site"
  key    = "assets/logo.svg"

  source_file  = "${path.module}/static/logo.svg"
  etag         = filemd5("${path.module}/static/logo.svg")
  content_type = "image/svg+xml"

  cache_control       = "public, max-age=31536000, immutable"
  content_disposition = "inline"
  content_encoding    = null

  metadata = {
    "x-amz-meta-version"  = "2.1.0"
    "x-amz-meta-uploaded" = "2026-04-11"
    "x-amz-meta-checksum" = "sha256:abc123"
  }

  storage_class = "STANDARD"

  tags = {
    Environment = "production"
    Team        = "frontend"
  }
}
```

## Copy Object Between Buckets

Copy an object from a source bucket to a destination bucket with SSE-KMS encryption and replaced metadata.

```hcl
module "s3_copy" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//s3-object?depth=1&ref=master"

  name   = "data-copy"
  bucket = "my-destination-bucket"
  key    = "archive/2026/dataset.parquet"

  create_object      = false
  create_object_copy = true
  copy_source        = "my-source-bucket/raw/dataset.parquet"

  copy_metadata_directive = "REPLACE"
  content_type            = "application/x-parquet"

  metadata = {
    "x-amz-meta-copied-from" = "my-source-bucket"
    "x-amz-meta-copy-date"   = "2026-04-11"
  }

  server_side_encryption = "aws:kms"
  kms_key_id             = "arn:aws:kms:ap-southeast-1:123456789012:key/mrk-abc123"

  storage_class = "INTELLIGENT_TIERING"

  tags = {
    Environment = "production"
    Team        = "data-engineering"
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
| bucket | Name of the S3 bucket to put the object in | `string` | n/a | yes |
| bucket\_key\_enabled | Whether to use S3 Bucket Keys for SSE-KMS, reducing KMS request costs | `bool` | `true` | no |
| cache\_control | Cache-Control header value (e.g., `max-age=86400, public`) | `string` | `null` | no |
| content | Inline string content for the object. Conflicts with `source_file` and `content_base64`. Marked sensitive, so plan diffs of object content are hidden. | `string` | `null` | no |
| content\_base64 | Base64-encoded content for the object. Conflicts with `source_file` and `content`. Marked sensitive, so plan diffs of object content are hidden. | `string` | `null` | no |
| content\_disposition | Content-Disposition header value (e.g., `attachment; filename="file.txt"`) | `string` | `null` | no |
| content\_encoding | Content-Encoding header value (e.g., `gzip`) | `string` | `null` | no |
| content\_language | Content-Language header value (e.g., `en-US`) | `string` | `null` | no |
| content\_type | Standard MIME type of the object (e.g., `application/json`, `text/html`) | `string` | `null` | no |
| copy\_grant | ACL grant configuration for the copied object | <pre>list(object({<br/>    email       = optional(string)<br/>    id          = optional(string)<br/>    permissions = list(string)<br/>    type        = string<br/>    uri         = optional(string)<br/>  }))</pre> | `[]` | no |
| copy\_metadata\_directive | Whether to COPY or REPLACE metadata from the source object | `string` | `"COPY"` | no |
| copy\_source | Source object for the copy in the format `bucket/key` | `string` | `null` | no |
| create\_bucket\_notification | Whether to create bucket notification configuration | `bool` | `false` | no |
| create\_object | Whether to create the S3 object | `bool` | `true` | no |
| create\_object\_copy | Whether to create an S3 object copy | `bool` | `false` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| etag | ETag of the object. Triggers replacement when changed. Use `filemd5()` for file sources. | `string` | `null` | no |
| force\_destroy | Whether to allow the object to be deleted by removing any legal hold and adjusting retention | `bool` | `false` | no |
| key | Key (path) of the object in the bucket | `string` | n/a | yes |
| kms\_key\_id | ARN of the KMS key for SSE-KMS encryption. Required when `server_side_encryption` is `aws:kms` or `aws:kms:dsse`. | `string` | `null` | no |
| metadata | Map of custom metadata key-value pairs to store with the object | `map(string)` | `{}` | no |
| notification\_bucket | Name of the bucket for notification configuration. Defaults to `var.bucket`. | `string` | `null` | no |
| notification\_eventbridge | Whether to enable EventBridge notifications | `bool` | `false` | no |
| notification\_lambda\_functions | Map of Lambda function notification configurations | <pre>map(object({<br/>    lambda_function_arn = string<br/>    events              = list(string)<br/>    filter_prefix       = optional(string)<br/>    filter_suffix       = optional(string)<br/>  }))</pre> | `{}` | no |
| notification\_queues | Map of SQS queue notification configurations | <pre>map(object({<br/>    queue_arn     = string<br/>    events        = list(string)<br/>    filter_prefix = optional(string)<br/>    filter_suffix = optional(string)<br/>  }))</pre> | `{}` | no |
| notification\_topics | Map of SNS topic notification configurations | <pre>map(object({<br/>    topic_arn     = string<br/>    events        = list(string)<br/>    filter_prefix = optional(string)<br/>    filter_suffix = optional(string)<br/>  }))</pre> | `{}` | no |
| object\_lock\_legal\_hold\_status | Legal hold status. `ON` or `OFF`. | `string` | `null` | no |
| object\_lock\_mode | Object lock retention mode. `GOVERNANCE` or `COMPLIANCE`. | `string` | `null` | no |
| object\_lock\_retain\_until\_date | Date and time (RFC3339) until which the object lock applies | `string` | `null` | no |
| object\_tags | Map of tags to apply to the S3 object (separate from resource tags) | `map(string)` | `{}` | no |
| server\_side\_encryption | Server-side encryption algorithm. `AES256` (SSE-S3), `aws:kms` (SSE-KMS), or `aws:kms:dsse` (DSSE-KMS) | `string` | `"AES256"` | no |
| source\_file | Path to a local file to upload. Conflicts with `content` and `content_base64`. | `string` | `null` | no |
| source\_hash | Hash of the source content. Triggers replacement when changed. | `string` | `null` | no |
| storage\_class | Storage class for the object. One of: `STANDARD`, `REDUCED_REDUNDANCY`, `ONEZONE_IA`, `INTELLIGENT_TIERING`, `GLACIER`, `DEEP_ARCHIVE`, `GLACIER_IR` | `string` | `"STANDARD"` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| website\_redirect | Target URL for website redirect on the object | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| bucket\_notification\_id | ID of the bucket notification configuration (bucket name) |
| object\_arn | ARN of the S3 object |
| object\_bucket | Name of the bucket containing the object |
| object\_content\_type | Content type of the object |
| object\_copy\_etag | ETag of the copied S3 object |
| object\_copy\_id | Key of the copied S3 object |
| object\_copy\_last\_modified | Last modified date of the copied object |
| object\_copy\_source\_version\_id | Version ID of the source object that was copied |
| object\_copy\_version\_id | Version ID of the copied S3 object |
| object\_etag | ETag of the S3 object |
| object\_id | Key of the S3 object |
| object\_key | Key (path) of the object in the bucket |
| object\_kms\_key\_id | ARN of the KMS key used for encryption |
| object\_server\_side\_encryption | Server-side encryption algorithm used |
| object\_storage\_class | Storage class of the object |
| object\_version\_id | Version ID of the S3 object (if versioning is enabled on the bucket) |
<!-- END_TF_DOCS -->

</details>
