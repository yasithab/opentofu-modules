################################################################################
# Metric Alarm
################################################################################

output "alarm_arn" {
  description = "The ARN of the CloudWatch Metric Alarm."
  value       = try(aws_cloudwatch_metric_alarm.this.arn, null)
}

output "alarm_id" {
  description = "The ID of the CloudWatch Metric Alarm."
  value       = try(aws_cloudwatch_metric_alarm.this.id, null)
}

output "alarm_name" {
  description = "The name of the CloudWatch Metric Alarm."
  value       = try(aws_cloudwatch_metric_alarm.this.alarm_name, null)
}
