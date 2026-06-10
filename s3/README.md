# S3

Provisions Amazon S3 buckets with comprehensive support for access controls, encryption, versioning, lifecycle management, replication, logging, and security policies.

## Notes

- **TLS-only by default** (security): `attach_deny_insecure_transport_policy` defaults to `true`, so every bucket gets a TLS-only (deny non-SSL transport) bucket policy and non-TLS clients are denied. This means a bucket policy is attached by default; custom `policy` documents are merged with the deny statement. Set `attach_deny_insecure_transport_policy = false` to opt out.
- `attach_deny_incorrect_kms_key_sse = true` requires `allowed_kms_key_arn`.
- Replication requires a role: set `replication_configuration.role` or `create_bucket_replication_role = true`.

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

  name   = "my-app-assets-prod-eu-west-1"

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
  name    = "my-app-assets-prod-eu-west-1"

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
  name    = "my-app-data-prod-eu-west-1"

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
  name    = "my-alb-access-logs-prod-eu-west-1"

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
  name    = "my-data-lake-primary-eu-west-1"

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
| abac\_enabled | Whether to enable Attribute Based Access Control (ABAC) for the S3 bucket, allowing tag-based authorization in IAM policies. | `bool` | `false` | no |
| acceleration\_status | (Optional) Sets the accelerate configuration of an existing bucket. Can be Enabled or Suspended. | `string` | `null` | no |
| access\_log\_delivery\_policy\_source\_accounts | (Optional) List of AWS Account IDs should be allowed to deliver access logs to this bucket. | `list(string)` | `[]` | no |
| access\_log\_delivery\_policy\_source\_buckets | (Optional) List of S3 bucket ARNs which should be allowed to deliver access logs to this bucket. | `list(string)` | `[]` | no |
| acl | (Optional) The canned ACL to apply. Conflicts with `grant` | `string` | `null` | no |
| allowed\_kms\_key\_arn | The ARN of KMS key which should be allowed in PutObject | `string` | `null` | no |
| analytics\_configuration | Map containing bucket analytics configuration. | `any` | `{}` | no |
| analytics\_self\_source\_destination | Whether or not the analytics source bucket is also the destination bucket. | `bool` | `false` | no |
| analytics\_source\_account\_id | The analytics source account id. | `string` | `null` | no |
| analytics\_source\_bucket\_arn | The analytics source bucket ARN. | `string` | `null` | no |
| attach\_access\_log\_delivery\_policy | Controls if S3 bucket should have S3 access log delivery policy attached | `bool` | `false` | no |
| attach\_analytics\_destination\_policy | Controls if S3 bucket should have bucket analytics destination policy attached. | `bool` | `false` | no |
| attach\_deny\_incorrect\_encryption\_headers | Controls if S3 bucket should deny incorrect encryption headers policy attached. | `bool` | `false` | no |
| attach\_deny\_incorrect\_kms\_key\_sse | Controls if S3 bucket policy should deny usage of incorrect KMS key SSE. | `bool` | `false` | no |
| attach\_deny\_insecure\_transport\_policy | Controls if S3 bucket should have deny non-SSL transport policy attached. Defaults to `true` (TLS-only bucket policy); set to `false` to opt out. | `bool` | `true` | no |
| attach\_deny\_unencrypted\_object\_uploads | Controls if S3 bucket should deny unencrypted object uploads policy attached. | `bool` | `false` | no |
| attach\_elb\_log\_delivery\_policy | Controls if S3 bucket should have ELB log delivery policy attached | `bool` | `false` | no |
| attach\_inventory\_destination\_policy | Controls if S3 bucket should have bucket inventory destination policy attached. | `bool` | `false` | no |
| attach\_lb\_log\_delivery\_policy | Controls if S3 bucket should have ALB/NLB log delivery policy attached | `bool` | `false` | no |
| attach\_policy | Controls if S3 bucket should have bucket policy attached (set to `true` to use value of `policy` as bucket policy) | `bool` | `false` | no |
| attach\_public\_policy | Controls if a user defined public bucket policy will be attached (set to `false` to allow upstream to apply defaults to the bucket) | `bool` | `true` | no |
| attach\_require\_latest\_tls\_policy | Controls if S3 bucket should require the latest version of TLS | `bool` | `false` | no |
| block\_public\_acls | Whether Amazon S3 should block public ACLs for this bucket. | `bool` | `true` | no |
| block\_public\_policy | Whether Amazon S3 should block public bucket policies for this bucket. | `bool` | `true` | no |
| control\_object\_ownership | Whether to manage S3 Bucket Ownership Controls on this bucket. | `bool` | `false` | no |
| cors\_rule | List of maps containing rules for Cross-Origin Resource Sharing. | `any` | `[]` | no |
| create\_bucket\_replication\_role | Create S3 bucket replication role | `bool` | `false` | no |
| destination\_bucket\_name | Name of destination bucket to replicate data | `string` | `null` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| force\_destroy | (Optional, Default:false ) A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable. | `bool` | `false` | no |
| grant | An ACL policy grant. Conflicts with `acl` | `any` | `[]` | no |
| ignore\_public\_acls | Whether Amazon S3 should ignore public ACLs for this bucket. | `bool` | `true` | no |
| intelligent\_tiering | Map containing intelligent tiering configuration. | `any` | `{}` | no |
| inventory\_configuration | Map containing S3 inventory configuration. | `any` | `{}` | no |
| inventory\_self\_source\_destination | Whether or not the inventory source bucket is also the destination bucket. | `bool` | `false` | no |
| inventory\_source\_account\_id | The inventory source account id. | `string` | `null` | no |
| inventory\_source\_bucket\_arn | The inventory source bucket ARN. | `string` | `null` | no |
| lifecycle\_rule | List of maps containing configuration of object lifecycle management. | `any` | `[]` | no |
| logging | Map containing access bucket logging configuration. | `any` | `{}` | no |
| metric\_configuration | Map containing bucket metric configuration. | `any` | `[]` | no |
| name | (Optional, Forces new resource) The name of the bucket. If omitted, Terraform will assign a random, unique name. | `string` | `null` | no |
| name\_prefix | (Optional, Forces new resource) Creates a unique bucket name beginning with the specified prefix. Conflicts with name. | `string` | `null` | no |
| notification\_configuration | JSON-encoded map containing lambda\_function, queue, and topic notification configurations. Alternative to individual notification variables. | `string` | `null` | no |
| notification\_eventbridge | Whether to enable Amazon EventBridge notifications for the S3 bucket | `bool` | `false` | no |
| notification\_lambda\_functions | List of Lambda function notification configurations | `any` | `[]` | no |
| notification\_queues | List of SQS queue notification configurations | `any` | `[]` | no |
| notification\_topics | List of SNS topic notification configurations | `any` | `[]` | no |
| object\_lock\_configuration | Map containing S3 object locking configuration. | `any` | `{}` | no |
| object\_lock\_enabled | Whether S3 bucket should have an Object Lock configuration enabled. | `bool` | `false` | no |
| object\_ownership | Object ownership. Valid values: BucketOwnerEnforced, BucketOwnerPreferred or ObjectWriter. 'BucketOwnerEnforced': ACLs are disabled, and the bucket owner automatically owns and has full control over every object in the bucket. 'BucketOwnerPreferred': Objects uploaded to the bucket change ownership to the bucket owner if the objects are uploaded with the bucket-owner-full-control canned ACL. 'ObjectWriter': The uploading account will own the object if the object is uploaded with the bucket-owner-full-control canned ACL. | `string` | `"BucketOwnerEnforced"` | no |
| owner | Bucket owner's display name and ID. Conflicts with `acl` | `map(string)` | `{}` | no |
| policy | (Optional) A valid bucket policy JSON document. Note that if the policy document is not specific enough (but still valid), Terraform may view the policy as constantly changing in a terraform plan. In this case, please make sure you use the verbose/specific version of the policy. For more information about building AWS IAM policy documents with Terraform, see the AWS IAM Policy Document Guide. | `string` | `null` | no |
| replication\_configuration | Map containing cross-region replication configuration. | `any` | `{}` | no |
| request\_payer | (Optional) Specifies who should bear the cost of Amazon S3 data transfer. Can be either BucketOwner or Requester. By default, the owner of the S3 bucket would incur the costs of any data transfer. See Requester Pays Buckets developer guide for more information. | `string` | `null` | no |
| restrict\_public\_buckets | Whether Amazon S3 should restrict public bucket policies for this bucket. | `bool` | `true` | no |
| s3\_bucket\_public\_access\_block\_skip\_destroy | Indicates whether the bucket public access block should be destroyed on bucket deletion | `bool` | `false` | no |
| server\_side\_encryption\_configuration | Map containing server-side encryption configuration. | `any` | `{}` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| transition\_default\_minimum\_object\_size | The default minimum object size behavior applied to the lifecycle configuration. Valid values: all\_storage\_classes\_128K (default), varies\_by\_storage\_class | `string` | `null` | no |
| versioning | Map containing versioning configuration. | `map(string)` | `{}` | no |
| website | Map containing static web-site hosting or redirect configuration. | `any` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| bucket\_arn | The ARN of the bucket. Will be of format arn:aws:s3:::bucketname. |
| bucket\_domain\_name | The bucket domain name. Will be of format bucketname.s3.amazonaws.com. |
| bucket\_hosted\_zone\_id | The Route 53 Hosted Zone ID for this bucket's region. |
| bucket\_id | The name of the bucket. |
| bucket\_lifecycle\_configuration\_rules | The lifecycle rules of the bucket, if the bucket is configured with lifecycle rules. If not, this will be an empty string. |
| bucket\_policy | The policy of the bucket, if the bucket is configured with a policy. If not, this will be an empty string. |
| bucket\_region | The AWS region this bucket resides in. |
| bucket\_regional\_domain\_name | The bucket region-specific domain name. The bucket domain name including the region name, please refer here for format. Note: The AWS CloudFront allows specifying S3 region-specific endpoint when creating S3 origin, it will prevent redirect issues from CloudFront to S3 Origin URL. |
| bucket\_website\_domain | The domain of the website endpoint, if the bucket is configured with a website. If not, this will be an empty string. This is used to create Route 53 alias records. |
| bucket\_website\_endpoint | The website endpoint, if the bucket is configured with a website. If not, this will be an empty string. |
<!-- END_TF_DOCS -->

</details>
