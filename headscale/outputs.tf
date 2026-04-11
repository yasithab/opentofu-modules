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
# Elastic IP
################################################################################

output "eip_public_ip" {
  description = "Elastic IP address (null when EIP is not used). Returns the IP for both created and existing EIPs."
  value       = try(local.eip_public_ip, null)
}

output "eip_allocation_id" {
  description = "Elastic IP allocation ID (null when EIP is not used)"
  value       = local.has_eip ? local.eip_allocation_id : null
}

################################################################################
# DNS
################################################################################

output "dns_fqdn" {
  description = "Fully qualified domain name (when Route53 is configured)"
  value       = try(aws_route53_record.this.fqdn, null)
}

output "dns_ip" {
  description = "IP address used for DNS records. Use this to configure external DNS providers (Cloudflare, etc.). Returns EIP public IP."
  value       = try(local.dns_ip, null)
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

################################################################################
# Metrics
################################################################################

output "metrics_url" {
  description = "Prometheus metrics endpoint URL (accessible only from the instance itself via SSM)"
  value       = "http://127.0.0.1:${var.metrics_port}/metrics"
}

################################################################################
# Headscale
################################################################################

output "server_url" {
  description = "Headscale server URL for client configuration"
  value       = var.server_url
}

output "data_volume_id" {
  description = "EBS data volume ID (null when data volume is disabled)"
  value       = try(aws_ebs_volume.data.id, null)
}

output "snapshot_policy_id" {
  description = "DLM lifecycle policy ID for data volume snapshots (null when snapshots are disabled)"
  value       = try(aws_dlm_lifecycle_policy.data_volume.id, null)
}

