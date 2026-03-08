################################################################################
# Metric Alarm
################################################################################

locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

resource "aws_cloudwatch_metric_alarm" "this" {
  alarm_name        = var.alarm_name
  alarm_description = var.alarm_description

  comparison_operator = var.comparison_operator
  evaluation_periods  = var.evaluation_periods
  threshold           = var.threshold
  threshold_metric_id = var.threshold_metric_id
  unit                = var.unit

  metric_name        = var.metric_name
  namespace          = var.namespace
  period             = var.period
  statistic          = var.statistic
  extended_statistic = var.extended_statistic
  dimensions         = var.dimensions

  actions_enabled           = var.actions_enabled
  alarm_actions             = var.alarm_actions
  ok_actions                = var.ok_actions
  insufficient_data_actions = var.insufficient_data_actions

  datapoints_to_alarm                   = var.datapoints_to_alarm
  treat_missing_data                    = var.treat_missing_data
  evaluate_low_sample_count_percentiles = var.evaluate_low_sample_count_percentiles

  dynamic "metric_query" {
    for_each = var.metric_query

    content {
      id          = metric_query.value.id
      account_id  = try(metric_query.value.account_id, null)
      expression  = try(metric_query.value.expression, null)
      label       = try(metric_query.value.label, null)
      return_data = try(metric_query.value.return_data, null)
      period      = try(metric_query.value.period, null)

      dynamic "metric" {
        for_each = try([metric_query.value.metric], [])

        content {
          dimensions  = try(metric.value.dimensions, null)
          metric_name = metric.value.metric_name
          namespace   = metric.value.namespace
          period      = metric.value.period
          stat        = metric.value.stat
          unit        = try(metric.value.unit, null)
        }
      }
    }
  }

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}
