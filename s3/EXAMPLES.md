# S3 Module - Examples

## Basic Private Bucket

Create a private S3 bucket with all public access blocked and TLS enforcement enabled.

```hcl
module "s3_bucket" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//s3?depth=1&ref=v2.0.0"

  enabled = true
  bucket  = "my-app-assets-prod-eu-west-1"

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Bucket with Versioning and Server-Side Encryption

Enable object versioning and KMS encryption for a bucket storing sensitive application data.

```hcl
module "s3_encrypted" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//s3?depth=1&ref=v2.0.0"

  enabled = true
  bucket  = "my-app-data-prod-eu-west-1"

  versioning = {
    enabled = "Enabled"
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = "arn:aws:kms:eu-west-1:123456789012:key/mrk-00000000000000000000000000000000"
      }
      bucket_key_enabled = true
    }
  }

  attach_deny_insecure_transport_policy    = true
  attach_deny_incorrect_kms_key_sse        = true
  allowed_kms_key_arn                      = "arn:aws:kms:eu-west-1:123456789012:key/mrk-00000000000000000000000000000000"
  attach_deny_unencrypted_object_uploads   = true

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = {
    Environment  = "production"
    DataClass    = "confidential"
    Team         = "security"
  }
}
```

## Logging Bucket for ALB Access Logs

Create a dedicated bucket to receive ALB and NLB access logs, with appropriate delivery policy attached.

```hcl
module "s3_alb_logs" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//s3?depth=1&ref=v2.0.0"

  enabled = true
  bucket  = "my-alb-access-logs-prod-eu-west-1"

  attach_lb_log_delivery_policy = true
  attach_deny_insecure_transport_policy = true

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  lifecycle_rule = [
    {
      id      = "expire-old-logs"
      enabled = true
      expiration = {
        days = 90
      }
      noncurrent_version_expiration = {
        noncurrent_days = 30
      }
    }
  ]

  tags = {
    Environment = "production"
    Purpose     = "access-logs"
    Team        = "platform"
  }
}
```

## Bucket with Lifecycle Rules, Replication, and EventBridge Notifications

Advanced configuration for a data lake bucket with intelligent tiering, cross-region replication, and EventBridge event forwarding.

```hcl
module "s3_data_lake" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//s3?depth=1&ref=v2.0.0"

  enabled = true
  bucket  = "my-data-lake-primary-eu-west-1"

  versioning = {
    enabled = "Enabled"
  }

  lifecycle_rule = [
    {
      id      = "transition-to-ia"
      enabled = true
      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        },
      ]
      noncurrent_version_transition = [
        {
          noncurrent_days = 30
          storage_class   = "STANDARD_IA"
        },
      ]
      noncurrent_version_expiration = {
        noncurrent_days = 180
      }
    }
  ]

  intelligent_tiering = {
    general = {
      status = "Enabled"
      tiering = {
        ARCHIVE_ACCESS = {
          days = 90
        }
        DEEP_ARCHIVE_ACCESS = {
          days = 180
        }
      }
    }
  }

  notification_eventbridge = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  attach_deny_insecure_transport_policy = true

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = {
    Environment = "production"
    DataClass   = "internal"
    Team        = "data-platform"
  }
}
```
