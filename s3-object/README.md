# S3 Object

OpenTofu module for managing S3 objects including uploads, copies, encryption, object lock, and bucket notification configuration.

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
