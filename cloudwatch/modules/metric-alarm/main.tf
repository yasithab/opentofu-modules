################################################################################
# Metric Alarm
################################################################################

locals {
  enabled = var.enabled
  name    = var.name

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

resource "aws_cloudwatch_metric_alarm" "this" {
  alarm_name        = local.name
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
      account_id  = metric_query.value.account_id
      expression  = metric_query.value.expression
      label       = metric_query.value.label
      return_data = metric_query.value.return_data
      period      = metric_query.value.period

      dynamic "metric" {
        for_each = metric_query.value.metric != null ? [metric_query.value.metric] : []

        content {
          dimensions  = metric.value.dimensions
          metric_name = metric.value.metric_name
          namespace   = metric.value.namespace
          period      = metric.value.period
          stat        = metric.value.stat
          unit        = metric.value.unit
        }
      }
    }
  }

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}
