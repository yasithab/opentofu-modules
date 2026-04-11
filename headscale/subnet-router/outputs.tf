################################################################################
# Auto Scaling Group
################################################################################

output "autoscaling_group_arn" {
  description = "ASG ARN"
  value       = try(aws_autoscaling_group.this.arn, null)
}

output "autoscaling_group_name" {
  description = "ASG name"
  value       = try(aws_autoscaling_group.this.name, null)
}

output "launch_template_id" {
  description = "Launch template ID"
  value       = try(aws_launch_template.this.id, null)
}

output "ami_id" {
  description = "Resolved AMI ID"
  value       = local.ami_id
}

################################################################################
# Networking
################################################################################

output "security_group_id" {
  description = "Security group ID"
  value       = try(aws_security_group.this.id, null)
}

################################################################################
# IAM
################################################################################

output "iam_role_arn" {
  description = "IAM role ARN"
  value       = try(aws_iam_role.this.arn, null)
}

output "iam_role_name" {
  description = "IAM role name"
  value       = try(aws_iam_role.this.name, null)
}

output "instance_profile_arn" {
  description = "Instance profile ARN"
  value       = try(aws_iam_instance_profile.this.arn, null)
}

################################################################################
# CloudWatch
################################################################################

output "alarm_arn" {
  description = "CloudWatch alarm ARN (null when alarm is disabled)"
  value       = try(aws_cloudwatch_metric_alarm.asg_health.arn, null)
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications (null when using existing topic or alarm is disabled)"
  value       = try(aws_sns_topic.alarm.arn, null)
}

output "log_group_name" {
  description = "CloudWatch log group name (null when logs are disabled)"
  value       = try(aws_cloudwatch_log_group.this.name, null)
}
