################################################################################
# Cluster
################################################################################

output "arn" {
  description = "ARN that identifies the cluster"
  value       = try(aws_ecs_cluster.this.arn, null)
}

output "id" {
  description = "ID that identifies the cluster"
  value       = try(aws_ecs_cluster.this.id, null)
}

output "name" {
  description = "Name that identifies the cluster"
  value       = try(aws_ecs_cluster.this.name, null)
}

################################################################################
# CloudWatch Log Group
################################################################################

output "cloudwatch_log_group_name" {
  description = "Name of CloudWatch log group created"
  value       = try(aws_cloudwatch_log_group.this.name, null)
}

output "cloudwatch_log_group_arn" {
  description = "ARN of CloudWatch log group created"
  value       = try(aws_cloudwatch_log_group.this.arn, null)
}

################################################################################
# Cluster Capacity Providers
################################################################################

output "cluster_capacity_providers" {
  description = "Map of cluster capacity providers attributes"
  value       = { for k, v in aws_ecs_cluster_capacity_providers.this : v.id => v }
}

################################################################################
# Capacity Provider - Autoscaling Group(s)
################################################################################

output "autoscaling_capacity_providers" {
  description = "Map of autoscaling capacity providers created and their attributes"
  value       = aws_ecs_capacity_provider.this
}

################################################################################
# Node - IAM Role + Instance Profile
################################################################################

output "node_iam_role_name" {
  description = "Node IAM role name"
  value       = try(aws_iam_role.node.name, null)
}

output "node_iam_role_arn" {
  description = "Node IAM role ARN"
  value       = try(aws_iam_role.node.arn, null)
}

output "node_iam_role_unique_id" {
  description = "Stable and unique string identifying the node IAM role"
  value       = try(aws_iam_role.node.unique_id, null)
}

output "node_iam_instance_profile_name" {
  description = "Node IAM instance profile name"
  value       = try(aws_iam_instance_profile.node.name, null)
}

output "node_iam_instance_profile_arn" {
  description = "Node IAM instance profile ARN"
  value       = try(aws_iam_instance_profile.node.arn, null)
}

################################################################################
# Security Group
################################################################################

output "security_group_arn" {
  description = "Amazon Resource Name (ARN) of the cluster security group"
  value       = try(aws_security_group.this.arn, null)
}

output "security_group_id" {
  description = "ID of the cluster security group"
  value       = try(aws_security_group.this.id, null)
}

################################################################################
# Task Execution - IAM Role
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
################################################################################

output "task_exec_iam_role_name" {
  description = "Task execution IAM role name"
  value       = try(aws_iam_role.task_exec.name, null)
}

output "task_exec_iam_role_arn" {
  description = "Task execution IAM role ARN"
  value       = try(aws_iam_role.task_exec.arn, null)
}

output "task_exec_iam_role_unique_id" {
  description = "Stable and unique string identifying the task execution IAM role"
  value       = try(aws_iam_role.task_exec.unique_id, null)
}

################################################################################