################################################################################
# Metric Stream
################################################################################

output "metric_stream_arn" {
  description = "The ARN of the CloudWatch Metric Stream."
  value       = try(aws_cloudwatch_metric_stream.this.arn, null)
}

output "metric_stream_name" {
  description = "The name of the CloudWatch Metric Stream."
  value       = try(aws_cloudwatch_metric_stream.this.name, null)
}

output "metric_stream_creation_date" {
  description = "The date the metric stream was created."
  value       = try(aws_cloudwatch_metric_stream.this.creation_date, null)
}

output "metric_stream_last_update_date" {
  description = "The date the metric stream was last updated."
  value       = try(aws_cloudwatch_metric_stream.this.last_update_date, null)
}

output "metric_stream_state" {
  description = "The state of the metric stream (running or stopped)."
  value       = try(aws_cloudwatch_metric_stream.this.state, null)
}
