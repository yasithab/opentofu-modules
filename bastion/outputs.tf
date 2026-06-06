################################################################################
# Instance Mode
################################################################################

output "instance_id" {
  description = "The ID of the bastion instance (null in ha_mode)"
  value       = try(aws_instance.this.id, null)
}

output "instance_arn" {
  description = "The ARN of the bastion instance (null in ha_mode)"
  value       = try(aws_instance.this.arn, null)
}

output "private_ip" {
  description = "Private IP address of the bastion instance (null in ha_mode)"
  value       = try(aws_instance.this.private_ip, null)
}

output "instance_state" {
  description = "The state of the bastion instance (null in ha_mode)"
  value       = try(aws_instance.this.instance_state, null)
}

output "patch_baseline_id" {
  description = "ID of the SSM patch baseline (null in ha_mode)"
  value       = try(aws_ssm_patch_baseline.this.id, null)
}

output "maintenance_window_id" {
  description = "ID of the SSM maintenance window (null in ha_mode)"
  value       = try(aws_ssm_maintenance_window.this.id, null)
}

output "auto_recovery_alarm_arn" {
  description = "ARN of the auto-recovery CloudWatch alarm (null in ha_mode)"
  value       = try(aws_cloudwatch_metric_alarm.auto_recovery.arn, null)
}

################################################################################
# HA Mode (ASG)
################################################################################

output "autoscaling_group_arn" {
  description = "ARN of the bastion Auto Scaling Group (null when ha_mode = false)"
  value       = try(aws_autoscaling_group.this.arn, null)
}

output "autoscaling_group_name" {
  description = "Name of the bastion Auto Scaling Group (null when ha_mode = false)"
  value       = try(aws_autoscaling_group.this.name, null)
}

output "launch_template_id" {
  description = "ID of the bastion launch template (null when ha_mode = false)"
  value       = try(aws_launch_template.this.id, null)
}

################################################################################
# Shared
################################################################################

output "security_group_id" {
  description = "ID of the bastion security group (null if using external security groups)"
  value       = try(aws_security_group.this.id, null)
}

output "iam_role_arn" {
  description = "ARN of the bastion IAM role"
  value       = try(aws_iam_role.this.arn, null)
}

output "iam_role_name" {
  description = "Name of the bastion IAM role"
  value       = try(aws_iam_role.this.name, null)
}

output "iam_instance_profile_arn" {
  description = "ARN of the bastion instance profile"
  value       = try(aws_iam_instance_profile.this.arn, null)
}

output "eip_id" {
  description = "Allocation ID of the Elastic IP (null if not public)"
  value       = try(aws_eip.this.id, null)
}

output "eip_public_ip" {
  description = "Elastic IP address (null if not public)"
  value       = try(aws_eip.this.public_ip, null)
}

output "session_log_group_name" {
  description = "CloudWatch log group name for SSM session logs"
  value       = try(aws_cloudwatch_log_group.ssm_sessions.name, null)
}

output "session_log_group_arn" {
  description = "CloudWatch log group ARN for SSM session logs"
  value       = try(aws_cloudwatch_log_group.ssm_sessions.arn, null)
}
