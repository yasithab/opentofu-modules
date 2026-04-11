################################################################################
# State Machine
################################################################################

output "state_machine_id" {
  description = "The ID of the state machine"
  value       = try(aws_sfn_state_machine.this.id, "")
}

output "state_machine_arn" {
  description = "The ARN of the state machine"
  value       = try(aws_sfn_state_machine.this.arn, "")
}

output "state_machine_name" {
  description = "The name of the state machine"
  value       = try(aws_sfn_state_machine.this.name, "")
}

output "state_machine_creation_date" {
  description = "The date the state machine was created"
  value       = try(aws_sfn_state_machine.this.creation_date, "")
}

output "state_machine_status" {
  description = "The current status of the state machine"
  value       = try(aws_sfn_state_machine.this.status, "")
}

output "state_machine_revision_id" {
  description = "The revision identifier for the state machine"
  value       = try(aws_sfn_state_machine.this.revision_id, "")
}

################################################################################
# IAM Role
################################################################################

output "role_arn" {
  description = "The ARN of the IAM role created for the state machine"
  value       = try(aws_iam_role.this.arn, "")
}

output "role_name" {
  description = "The name of the IAM role created for the state machine"
  value       = try(aws_iam_role.this.name, "")
}

output "role_id" {
  description = "The ID of the IAM role"
  value       = try(aws_iam_role.this.id, "")
}

output "role_unique_id" {
  description = "The unique ID of the IAM role"
  value       = try(aws_iam_role.this.unique_id, "")
}

################################################################################
# CloudWatch Log Group
################################################################################

output "log_group_arn" {
  description = "The ARN of the CloudWatch log group"
  value       = try(aws_cloudwatch_log_group.this.arn, "")
}

output "log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = try(aws_cloudwatch_log_group.this.name, "")
}

################################################################################
# CloudWatch Alarms
################################################################################

output "alarm_execution_failed_arn" {
  description = "The ARN of the execution failed CloudWatch alarm"
  value       = try(aws_cloudwatch_metric_alarm.execution_failed.arn, "")
}

output "alarm_execution_throttled_arn" {
  description = "The ARN of the execution throttled CloudWatch alarm"
  value       = try(aws_cloudwatch_metric_alarm.execution_throttled.arn, "")
}

output "alarm_execution_timed_out_arn" {
  description = "The ARN of the execution timed out CloudWatch alarm"
  value       = try(aws_cloudwatch_metric_alarm.execution_timed_out.arn, "")
}

################################################################################
# EventBridge
################################################################################

output "event_rule_arns" {
  description = "Map of EventBridge rule ARNs"
  value       = { for k, v in aws_cloudwatch_event_rule.this : k => v.arn }
}

output "event_rule_names" {
  description = "Map of EventBridge rule names"
  value       = { for k, v in aws_cloudwatch_event_rule.this : k => v.name }
}

output "event_role_arn" {
  description = "The ARN of the IAM role created for EventBridge"
  value       = try(aws_iam_role.events.arn, "")
}
