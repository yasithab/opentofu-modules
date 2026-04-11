################################################################################
# Launch Template
################################################################################

output "launch_template_id" {
  description = "The ID of the launch template"
  value       = try(aws_launch_template.this.id, "")
}

output "launch_template_arn" {
  description = "The ARN of the launch template"
  value       = try(aws_launch_template.this.arn, "")
}

output "launch_template_name" {
  description = "The name of the launch template"
  value       = try(aws_launch_template.this.name, "")
}

output "launch_template_latest_version" {
  description = "The latest version of the launch template"
  value       = try(aws_launch_template.this.latest_version, "")
}

output "launch_template_default_version" {
  description = "The default version of the launch template"
  value       = try(aws_launch_template.this.default_version, "")
}

################################################################################
# Auto Scaling Group
################################################################################

output "autoscaling_group_id" {
  description = "The ID of the Auto Scaling Group"
  value       = try(aws_autoscaling_group.this.id, "")
}

output "autoscaling_group_arn" {
  description = "The ARN of the Auto Scaling Group"
  value       = try(aws_autoscaling_group.this.arn, "")
}

output "autoscaling_group_name" {
  description = "The name of the Auto Scaling Group"
  value       = try(aws_autoscaling_group.this.name, "")
}

output "autoscaling_group_min_size" {
  description = "The minimum size of the Auto Scaling Group"
  value       = try(aws_autoscaling_group.this.min_size, "")
}

output "autoscaling_group_max_size" {
  description = "The maximum size of the Auto Scaling Group"
  value       = try(aws_autoscaling_group.this.max_size, "")
}

output "autoscaling_group_desired_capacity" {
  description = "The desired capacity of the Auto Scaling Group"
  value       = try(aws_autoscaling_group.this.desired_capacity, "")
}

output "autoscaling_group_availability_zones" {
  description = "The availability zones of the Auto Scaling Group"
  value       = try(aws_autoscaling_group.this.availability_zones, [])
}

output "autoscaling_group_vpc_zone_identifier" {
  description = "The VPC zone identifier (subnets) of the Auto Scaling Group"
  value       = try(aws_autoscaling_group.this.vpc_zone_identifier, [])
}

output "autoscaling_group_health_check_type" {
  description = "The health check type of the Auto Scaling Group"
  value       = try(aws_autoscaling_group.this.health_check_type, "")
}

################################################################################
# IAM
################################################################################

output "iam_role_arn" {
  description = "The ARN of the IAM role"
  value       = try(aws_iam_role.this.arn, "")
}

output "iam_role_name" {
  description = "The name of the IAM role"
  value       = try(aws_iam_role.this.name, "")
}

output "iam_instance_profile_arn" {
  description = "The ARN of the IAM instance profile"
  value       = try(aws_iam_instance_profile.this.arn, "")
}

output "iam_instance_profile_name" {
  description = "The name of the IAM instance profile"
  value       = try(aws_iam_instance_profile.this.name, "")
}

output "iam_instance_profile_id" {
  description = "The ID of the IAM instance profile"
  value       = try(aws_iam_instance_profile.this.id, "")
}

################################################################################
# Security Group
################################################################################

output "security_group_id" {
  description = "The ID of the security group"
  value       = try(aws_security_group.this.id, "")
}

output "security_group_arn" {
  description = "The ARN of the security group"
  value       = try(aws_security_group.this.arn, "")
}

output "security_group_name" {
  description = "The name of the security group"
  value       = try(aws_security_group.this.name, "")
}

output "security_group_vpc_id" {
  description = "The VPC ID of the security group"
  value       = try(aws_security_group.this.vpc_id, "")
}

################################################################################
# Scaling Policies
################################################################################

output "scaling_policy_arns" {
  description = "Map of scaling policy ARNs"
  value       = { for k, v in aws_autoscaling_policy.this : k => v.arn }
}

output "scaling_policy_names" {
  description = "Map of scaling policy names"
  value       = { for k, v in aws_autoscaling_policy.this : k => v.name }
}

################################################################################
# Scheduled Actions
################################################################################

output "scheduled_action_arns" {
  description = "Map of scheduled action ARNs"
  value       = { for k, v in aws_autoscaling_schedule.this : k => v.arn }
}
