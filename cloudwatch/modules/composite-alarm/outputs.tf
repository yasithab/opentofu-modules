################################################################################
# Composite Alarm
################################################################################

output "alarm_arn" {
  description = "The ARN of the composite alarm."
  value       = try(aws_cloudwatch_composite_alarm.this.arn, null)
}

output "alarm_id" {
  description = "The ID of the composite alarm."
  value       = try(aws_cloudwatch_composite_alarm.this.id, null)
}

output "alarm_name" {
  description = "The name of the composite alarm."
  value       = try(aws_cloudwatch_composite_alarm.this.alarm_name, null)
}
