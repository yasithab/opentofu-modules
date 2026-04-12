locals {
  enabled        = var.enabled
  sqs_queue_name = var.sqs_queue_name != null ? var.sqs_queue_name : var.name
  redrive_policy = jsonencode({
    deadLetterTargetArn = var.enabled ? try(aws_sqs_queue.deadletter.arn, null) : null
    maxReceiveCount     = var.deadletter_queue_count
  })

  # Determine which statements to use for DLQ policy:
  # If custom DLQ statements provided → use them; otherwise → copy from main queue
  has_custom_dlq_policy        = try(length(var.deadletter_queue_policy_statements), 0) > 0
  deadletter_policy_statements = local.has_custom_dlq_policy ? var.deadletter_queue_policy_statements : var.queue_policy_statements
  deadletter_source_docs       = local.has_custom_dlq_policy ? var.deadletter_source_policy_documents : var.source_queue_policy_documents
  deadletter_override_docs     = local.has_custom_dlq_policy ? var.deadletter_override_policy_documents : var.override_queue_policy_documents

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

resource "aws_sqs_queue" "default" {
  name                              = var.fifo_queue ? "${local.sqs_queue_name}.fifo" : local.sqs_queue_name
  visibility_timeout_seconds        = var.visibility_timeout_seconds
  message_retention_seconds         = var.message_retention_seconds
  max_message_size                  = var.max_message_size
  delay_seconds                     = var.delay_seconds
  receive_wait_time_seconds         = var.receive_wait_time_seconds
  redrive_policy                    = var.deadletter_queue_enabled ? local.redrive_policy : var.redrive_policy
  fifo_queue                        = var.fifo_queue
  content_based_deduplication       = var.content_based_deduplication
  deduplication_scope               = var.fifo_queue && var.high_throughput_fifo_queue ? var.fifo_high_throughput_deduplication_scope : null
  fifo_throughput_limit             = var.fifo_queue && var.high_throughput_fifo_queue ? var.fifo_high_throughput_limit : null
  sqs_managed_sse_enabled           = var.sqs_managed_sse_enabled
  kms_master_key_id                 = var.kms_master_key_id
  kms_data_key_reuse_period_seconds = var.kms_data_key_reuse_period_seconds
  tags                              = local.tags

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_sqs_queue" "deadletter" {
  name                              = var.fifo_queue ? "${local.sqs_queue_name}-dlq.fifo" : "${local.sqs_queue_name}-dlq"
  visibility_timeout_seconds        = var.visibility_timeout_seconds
  message_retention_seconds         = var.message_retention_seconds
  receive_wait_time_seconds         = var.receive_wait_time_seconds
  fifo_queue                        = var.fifo_queue
  content_based_deduplication       = var.content_based_deduplication
  deduplication_scope               = var.fifo_queue && var.high_throughput_fifo_queue ? var.fifo_high_throughput_deduplication_scope : null
  fifo_throughput_limit             = var.fifo_queue && var.high_throughput_fifo_queue ? var.fifo_high_throughput_limit : null
  sqs_managed_sse_enabled           = var.sqs_managed_sse_enabled
  kms_master_key_id                 = var.kms_master_key_id
  kms_data_key_reuse_period_seconds = var.kms_data_key_reuse_period_seconds
  tags                              = merge(local.tags, { Name = var.fifo_queue ? "${local.sqs_queue_name}-dlq.fifo" : "${local.sqs_queue_name}-dlq" })

  lifecycle {
    enabled = (local.enabled && var.deadletter_queue_enabled)
  }
}

data "aws_iam_policy_document" "default" {
  count = local.enabled && var.create_queue_policy ? 1 : 0

  source_policy_documents   = var.source_queue_policy_documents
  override_policy_documents = var.override_queue_policy_documents

  dynamic "statement" {
    for_each = var.queue_policy_statements

    content {
      sid           = try(statement.value.sid, null)
      actions       = try(statement.value.actions, null)
      not_actions   = try(statement.value.not_actions, null)
      effect        = try(statement.value.effect, null)
      resources     = try(statement.value.resources, [aws_sqs_queue.default.arn])
      not_resources = try(statement.value.not_resources, null)

      dynamic "principals" {
        for_each = try(statement.value.principals, [])

        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "not_principals" {
        for_each = try(statement.value.not_principals, [])

        content {
          type        = not_principals.value.type
          identifiers = not_principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = try(statement.value.conditions, [])

        content {
          test     = condition.value.test
          values   = condition.value.values
          variable = condition.value.variable
        }
      }
    }
  }
}

resource "aws_sqs_queue_policy" "default" {
  queue_url = aws_sqs_queue.default.url
  policy    = data.aws_iam_policy_document.default[0].json

  lifecycle {
    enabled = local.enabled && var.create_queue_policy
  }
}

data "aws_iam_policy_document" "deadletter" {
  count = local.enabled && var.deadletter_queue_policy_enabled && var.deadletter_queue_enabled ? 1 : 0

  source_policy_documents   = local.deadletter_source_docs
  override_policy_documents = local.deadletter_override_docs

  dynamic "statement" {
    for_each = local.deadletter_policy_statements

    content {
      sid           = try(statement.value.sid, null)
      actions       = try(statement.value.actions, null)
      not_actions   = try(statement.value.not_actions, null)
      effect        = try(statement.value.effect, null)
      resources     = try(statement.value.resources, [aws_sqs_queue.deadletter.arn])
      not_resources = try(statement.value.not_resources, null)

      dynamic "principals" {
        for_each = try(statement.value.principals, [])

        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "not_principals" {
        for_each = try(statement.value.not_principals, [])

        content {
          type        = not_principals.value.type
          identifiers = not_principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = try(statement.value.conditions, [])

        content {
          test     = condition.value.test
          values   = condition.value.values
          variable = condition.value.variable
        }
      }
    }
  }
}

resource "aws_sqs_queue_policy" "deadletter" {
  queue_url = aws_sqs_queue.deadletter.url
  policy    = data.aws_iam_policy_document.deadletter[0].json

  lifecycle {
    enabled = local.enabled && var.deadletter_queue_policy_enabled && var.deadletter_queue_enabled
  }
}

resource "aws_sqs_queue_redrive_allow_policy" "default" {
  queue_url = aws_sqs_queue.default.url

  redrive_allow_policy = jsonencode({
    redrivePermission = var.redrive_allow_policy_permission
    sourceQueueArns   = var.redrive_allow_policy_source_queue_arns
  })

  lifecycle {
    enabled = local.enabled && var.create_redrive_allow_policy
  }
}
