locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

resource "aws_kinesis_stream" "default" {
  region = var.region

  name                      = var.name
  shard_count               = var.stream_mode != "ON_DEMAND" ? var.shard_count : null
  retention_period          = var.retention_period
  shard_level_metrics       = var.shard_level_metrics
  enforce_consumer_deletion = var.enforce_consumer_deletion
  encryption_type           = var.encryption_type
  kms_key_id                = var.kms_key_id
  max_record_size_in_kib    = var.max_record_size_in_kib

  dynamic "stream_mode_details" {
    for_each = var.stream_mode != null ? ["true"] : []
    content {
      stream_mode = var.stream_mode
    }
  }

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_kinesis_stream_consumer" "default" {
  count = local.enabled ? var.consumer_count : 0

  region = var.region

  name       = format("%s-consumer-%s", var.name, count.index)
  stream_arn = try(aws_kinesis_stream.default.arn, null)

  tags = local.tags
}
