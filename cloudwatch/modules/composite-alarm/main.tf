################################################################################
# Composite Alarm
################################################################################

locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

resource "aws_cloudwatch_composite_alarm" "this" {
  alarm_name        = var.alarm_name
  alarm_description = var.alarm_description
  alarm_rule        = var.alarm_rule

  actions_enabled           = var.actions_enabled
  alarm_actions             = var.alarm_actions
  ok_actions                = var.ok_actions
  insufficient_data_actions = var.insufficient_data_actions

  dynamic "actions_suppressor" {
    for_each = var.actions_suppressor != null ? [var.actions_suppressor] : []

    content {
      alarm            = actions_suppressor.value.alarm
      extension_period = actions_suppressor.value.extension_period
      wait_period      = actions_suppressor.value.wait_period
    }
  }

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}
