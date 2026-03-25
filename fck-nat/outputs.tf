################################################################################
# Instance
################################################################################

output "instance_id" {
  description = "EC2 instance ID (null in HA mode)"
  value       = try(aws_instance.this.id, null)
}

output "ami_id" {
  description = "Resolved AMI ID"
  value       = local.ami_id
}

output "launch_template_id" {
  description = "Launch template ID"
  value       = try(aws_launch_template.this.id, null)
}

################################################################################
# Auto Scaling Group
################################################################################

output "autoscaling_group_arn" {
  description = "ASG ARN (null in non-HA mode)"
  value       = try(aws_autoscaling_group.this.arn, null)
}

################################################################################
# Networking
################################################################################

output "eni_id" {
  description = "Static ENI ID"
  value       = try(aws_network_interface.this.id, null)
}

output "eni_private_ip" {
  description = "Private IP of the static ENI"
  value       = try(aws_network_interface.this.private_ip, null)
}

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
