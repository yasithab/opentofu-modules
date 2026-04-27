locals {
  enabled = var.enabled
  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  create_object       = local.enabled && var.create_object
  create_object_copy  = local.enabled && var.create_object_copy
  create_notification = local.enabled && var.create_bucket_notification
}

################################################################################
# S3 Object
################################################################################

resource "aws_s3_object" "this" {
  bucket = var.bucket
  key    = var.key

  # Content source (mutually exclusive)
  source         = var.source_file
  content        = var.content
  content_base64 = var.content_base64

  # Content headers
  content_type        = var.content_type
  content_disposition = var.content_disposition
  content_encoding    = var.content_encoding
  content_language    = var.content_language
  cache_control       = var.cache_control

  # Change detection
  etag        = var.etag
  source_hash = var.source_hash

  # Storage
  storage_class = var.storage_class

  # Server-side encryption
  server_side_encryption = var.server_side_encryption
  kms_key_id             = var.kms_key_id
  bucket_key_enabled     = var.bucket_key_enabled

  # Metadata
  metadata         = var.metadata
  website_redirect = var.website_redirect

  # Object lock
  object_lock_mode              = var.object_lock_mode
  object_lock_retain_until_date = var.object_lock_retain_until_date
  object_lock_legal_hold_status = var.object_lock_legal_hold_status
  force_destroy                 = var.force_destroy

  # Tags
  tags = merge(local.tags, var.object_tags)

  lifecycle {
    enabled = local.create_object
  }
}

################################################################################
# S3 Object Copy
################################################################################

resource "aws_s3_object_copy" "this" {
  bucket = var.bucket
  key    = var.key
  source = var.copy_source

  # Content headers (REPLACE directive)
  content_type        = var.content_type
  content_disposition = var.content_disposition
  content_encoding    = var.content_encoding
  content_language    = var.content_language
  cache_control       = var.cache_control

  # Storage
  storage_class = var.storage_class

  # Encryption
  server_side_encryption = var.server_side_encryption
  kms_key_id             = var.kms_key_id

  # Metadata
  metadata           = var.metadata
  metadata_directive = var.copy_metadata_directive

  # Object lock
  object_lock_mode              = var.object_lock_mode
  object_lock_retain_until_date = var.object_lock_retain_until_date
  object_lock_legal_hold_status = var.object_lock_legal_hold_status

  dynamic "grant" {
    for_each = var.copy_grant

    content {
      email       = try(grant.value.email, null)
      id          = try(grant.value.id, null)
      permissions = grant.value.permissions
      type        = grant.value.type
      uri         = try(grant.value.uri, null)
    }
  }

  tags = merge(local.tags, var.object_tags)

  lifecycle {
    enabled = local.create_object_copy
  }
}

################################################################################
# Bucket Notification Configuration
################################################################################

resource "aws_s3_bucket_notification" "this" {
  bucket      = coalesce(var.notification_bucket, var.bucket)
  eventbridge = var.notification_eventbridge

  dynamic "lambda_function" {
    for_each = var.notification_lambda_functions

    content {
      id                  = lambda_function.key
      lambda_function_arn = lambda_function.value.lambda_function_arn
      events              = lambda_function.value.events
      filter_prefix       = try(lambda_function.value.filter_prefix, null)
      filter_suffix       = try(lambda_function.value.filter_suffix, null)
    }
  }

  dynamic "queue" {
    for_each = var.notification_queues

    content {
      id            = queue.key
      queue_arn     = queue.value.queue_arn
      events        = queue.value.events
      filter_prefix = try(queue.value.filter_prefix, null)
      filter_suffix = try(queue.value.filter_suffix, null)
    }
  }

  dynamic "topic" {
    for_each = var.notification_topics

    content {
      id            = topic.key
      topic_arn     = topic.value.topic_arn
      events        = topic.value.events
      filter_prefix = try(topic.value.filter_prefix, null)
      filter_suffix = try(topic.value.filter_suffix, null)
    }
  }

  lifecycle {
    enabled = local.create_notification
  }
}
