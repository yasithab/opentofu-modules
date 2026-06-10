################################################################################
# Log Group
################################################################################

output "log_group_name" {
  description = "The name of the CloudWatch Log Group."
  value       = try(aws_cloudwatch_log_group.this.name, null)
}

output "log_group_arn" {
  description = "The ARN of the CloudWatch Log Group."
  value       = try(aws_cloudwatch_log_group.this.arn, null)
}

output "log_group_retention_in_days" {
  description = "The number of days log events are retained."
  value       = try(aws_cloudwatch_log_group.this.retention_in_days, null)
}

output "log_group_kms_key_id" {
  description = "The ARN of the KMS key used to encrypt log data."
  value       = try(aws_cloudwatch_log_group.this.kms_key_id, null)
}

################################################################################
# Log Stream(s)
################################################################################

output "log_streams" {
  description = "Map of log streams created and their attributes."
  value       = aws_cloudwatch_log_stream.this
}

################################################################################
# Data Protection Policy
################################################################################

output "data_protection_policy_id" {
  description = "The name of the log group the data protection policy is attached to (if created)."
  value       = try(aws_cloudwatch_log_data_protection_policy.this.id, null)
}

################################################################################
# Log Anomaly Detector
################################################################################

output "anomaly_detector_arn" {
  description = "The ARN of the log anomaly detector (if created)."
  value       = try(aws_cloudwatch_log_anomaly_detector.this.arn, null)
}
