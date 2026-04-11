# S3

Provisions Amazon S3 buckets with comprehensive support for access controls, encryption, versioning, lifecycle management, replication, logging, and security policies.

## Features

- **Access Control** - Configure bucket ACLs, ownership controls, and public access blocks to enforce least-privilege access
- **Security Policies** - Attach pre-built bucket policies for TLS enforcement, insecure transport denial, incorrect encryption header denial, and unencrypted upload prevention
- **Log Delivery Policies** - Built-in support for ELB, ALB/NLB, S3 access log, and inventory destination delivery policies
- **Server-Side Encryption** - Configure SSE-S3, SSE-KMS, or SSE-KMS with bucket keys, and enforce correct KMS key usage via policy
- **Versioning** - Enable or suspend object versioning for data protection and recovery
- **Lifecycle Rules** - Define transition, expiration, and noncurrent version cleanup rules to optimize storage costs
- **Intelligent Tiering** - Configure S3 Intelligent-Tiering archive access tiers for automatic cost optimization
- **CORS Configuration** - Set cross-origin resource sharing rules for browser-based access
- **Logging** - Configure server access logging to a target bucket with optional prefix and key format settings
- **Object Lock** - Enable object lock for WORM (Write Once Read Many) compliance requirements
- **EventBridge Notifications** - Enable Amazon EventBridge integration for event-driven architectures
- **Metric Configuration** - Define request metrics and filters for monitoring bucket usage patterns
- **Event Notifications** - S3 event notifications to Lambda, SQS, and SNS targets for object-level events
- **Static Website Hosting** - Configure index and error documents for S3-hosted static websites
- **S3 Inventory** - Scheduled inventory reports for auditing object metadata across buckets
- **Analytics Configuration** - Storage class analysis to identify optimization opportunities

## Usage

```hcl
module "s3_bucket" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//s3?depth=1&ref=master"

  bucket = "my-app-assets-prod-eu-west-1"

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = {
    Environment = "production"
  }
}
```


## Examples

## Basic Private Bucket

Create a private S3 bucket with all public access blocked and TLS enforcement enabled.

```hcl
module "s3_bucket" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//s3?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//s3?depth=1&ref=master"

  enabled = true
  bucket  = "my-app-data-prod-eu-west-1"

  versioning = {
    enabled = true
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
  source = "git::https://github.com/yasithab/opentofu-modules.git//s3?depth=1&ref=master"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//s3?depth=1&ref=master"

  enabled = true
  bucket  = "my-data-lake-primary-eu-west-1"

  versioning = {
    enabled = true
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
