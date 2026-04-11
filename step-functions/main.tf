locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  role_arn       = var.create_role ? aws_iam_role.this.arn : var.role_arn
  log_group_name = coalesce(var.log_group_name, "/aws/states/${var.name}")
  log_group_arn  = var.create_log_group ? aws_cloudwatch_log_group.this.arn : var.existing_log_group_arn
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

################################################################################
# State Machine
################################################################################

resource "aws_sfn_state_machine" "this" {
  name       = var.name
  role_arn   = local.role_arn
  definition = var.definition
  type       = var.type
  publish    = var.publish

  dynamic "logging_configuration" {
    for_each = var.logging_enabled ? [1] : []

    content {
      log_destination        = "${local.log_group_arn}:*"
      include_execution_data = var.logging_include_execution_data
      level                  = var.logging_level
    }
  }

  dynamic "tracing_configuration" {
    for_each = var.tracing_enabled ? [1] : []

    content {
      enabled = true
    }
  }

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}

################################################################################
# CloudWatch Log Group
################################################################################

resource "aws_cloudwatch_log_group" "this" {
  name              = local.log_group_name
  retention_in_days = var.log_group_retention_in_days
  kms_key_id        = var.log_group_kms_key_id

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_log_group
  }
}

################################################################################
# IAM Role
################################################################################

data "aws_iam_policy_document" "assume_role" {
  count = var.enabled && var.create_role ? 1 : 0

  statement {
    sid     = "StepFunctionsAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = var.trusted_service_principals
    }

    dynamic "principals" {
      for_each = length(var.trusted_account_arns) > 0 ? [1] : []

      content {
        type        = "AWS"
        identifiers = var.trusted_account_arns
      }
    }
  }
}

resource "aws_iam_role" "this" {
  name                  = coalesce(var.role_name, "${var.name}-role")
  description           = var.role_description
  path                  = var.role_path
  permissions_boundary  = var.role_permissions_boundary
  force_detach_policies = var.role_force_detach_policies
  assume_role_policy    = data.aws_iam_policy_document.assume_role[0].json

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_role
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = { for k, v in var.role_policy_arns : k => v if local.enabled && var.create_role }

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "this" {
  for_each = { for k, v in var.role_inline_policies : k => v if local.enabled && var.create_role }

  name   = each.key
  role   = aws_iam_role.this.id
  policy = each.value
}

# Logging policy - grant the state machine role permission to write logs
data "aws_iam_policy_document" "logging" {
  count = var.enabled && var.create_role && var.logging_enabled ? 1 : 0

  statement {
    sid    = "CloudWatchLogsDelivery"
    effect = "Allow"

    actions = [
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups",
      "logs:PutLogEvents",
      "logs:CreateLogStream",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "logging" {
  name   = "${var.name}-logging"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.logging[0].json

  lifecycle {
    enabled = local.enabled && var.create_role && var.logging_enabled
  }
}

# X-Ray tracing policy
data "aws_iam_policy_document" "tracing" {
  count = var.enabled && var.create_role && var.tracing_enabled ? 1 : 0

  statement {
    sid    = "XRayTracing"
    effect = "Allow"

    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "tracing" {
  name   = "${var.name}-tracing"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.tracing[0].json

  lifecycle {
    enabled = local.enabled && var.create_role && var.tracing_enabled
  }
}

################################################################################
# CloudWatch Alarms
################################################################################

resource "aws_cloudwatch_metric_alarm" "execution_failed" {
  alarm_name          = "${var.name}-execution-failed"
  alarm_description   = "Step Functions state machine ${var.name} has failed executions"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_execution_failed_evaluation_periods
  metric_name         = "ExecutionsFailed"
  namespace           = "AWS/States"
  period              = var.alarm_execution_failed_period
  statistic           = "Sum"
  threshold           = var.alarm_execution_failed_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    StateMachineArn = aws_sfn_state_machine.this.arn
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_alarms
  }
}

resource "aws_cloudwatch_metric_alarm" "execution_throttled" {
  alarm_name          = "${var.name}-execution-throttled"
  alarm_description   = "Step Functions state machine ${var.name} has throttled executions"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionThrottled"
  namespace           = "AWS/States"
  period              = 300
  statistic           = "Sum"
  threshold           = var.alarm_execution_throttled_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    StateMachineArn = aws_sfn_state_machine.this.arn
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_alarms
  }
}

resource "aws_cloudwatch_metric_alarm" "execution_timed_out" {
  alarm_name          = "${var.name}-execution-timed-out"
  alarm_description   = "Step Functions state machine ${var.name} has timed out executions"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsTimedOut"
  namespace           = "AWS/States"
  period              = 300
  statistic           = "Sum"
  threshold           = var.alarm_execution_timed_out_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    StateMachineArn = aws_sfn_state_machine.this.arn
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_alarms
  }
}

################################################################################
# EventBridge Rules (Event Source Mapping)
################################################################################

resource "aws_cloudwatch_event_rule" "this" {
  for_each = { for k, v in var.event_rules : k => v if local.enabled }

  name                = try(each.value.name, "${var.name}-${each.key}")
  description         = try(each.value.description, null)
  schedule_expression = try(each.value.schedule_expression, null)
  event_pattern       = try(each.value.event_pattern, null)
  state               = try(each.value.is_enabled, true) ? "ENABLED" : "DISABLED"

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "this" {
  for_each = { for k, v in var.event_rules : k => v if local.enabled }

  rule     = aws_cloudwatch_event_rule.this[each.key].name
  arn      = aws_sfn_state_machine.this.arn
  role_arn = var.create_event_role ? aws_iam_role.events.arn : var.event_role_arn
  input    = try(each.value.input, null)
}

# EventBridge IAM Role
data "aws_iam_policy_document" "events_assume_role" {
  count = var.enabled && var.create_event_role ? 1 : 0

  statement {
    sid     = "EventBridgeAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "events" {
  name               = "${var.name}-events-role"
  assume_role_policy = data.aws_iam_policy_document.events_assume_role[0].json

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_event_role
  }
}

data "aws_iam_policy_document" "events" {
  count = var.enabled && var.create_event_role ? 1 : 0

  statement {
    sid       = "AllowStartExecution"
    effect    = "Allow"
    actions   = ["states:StartExecution"]
    resources = [aws_sfn_state_machine.this.arn]
  }
}

resource "aws_iam_role_policy" "events" {
  name   = "${var.name}-events-policy"
  role   = aws_iam_role.events.id
  policy = data.aws_iam_policy_document.events[0].json

  lifecycle {
    enabled = local.enabled && var.create_event_role
  }
}
