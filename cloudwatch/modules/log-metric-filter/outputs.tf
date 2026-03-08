################################################################################
# Log Metric Filter
################################################################################

output "metric_filter_id" {
  description = "The ID of the CloudWatch Log Metric Filter."
  value       = try(aws_cloudwatch_log_metric_filter.this.id, null)
}

output "metric_filter_name" {
  description = "The name of the CloudWatch Log Metric Filter."
  value       = try(aws_cloudwatch_log_metric_filter.this.name, null)
}

output "metric_filter_log_group_name" {
  description = "The name of the log group associated with the metric filter."
  value       = try(aws_cloudwatch_log_metric_filter.this.log_group_name, null)
}
