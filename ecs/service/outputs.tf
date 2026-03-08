################################################################################
# Service
################################################################################

output "id" {
  description = "ARN that identifies the service"
  value       = try(aws_ecs_service.this.id, aws_ecs_service.ignore_task_definition.id, null)
}

output "name" {
  description = "Name of the service"
  value       = try(aws_ecs_service.this.name, aws_ecs_service.ignore_task_definition.name, null)
}

################################################################################
# IAM Role
################################################################################

output "iam_role_name" {
  description = "Service IAM role name"
  value       = try(aws_iam_role.service.name, null)
}

output "iam_role_arn" {
  description = "Service IAM role ARN"
  value       = try(aws_iam_role.service.arn, var.iam_role_arn)
}

output "iam_role_unique_id" {
  description = "Stable and unique string identifying the service IAM role"
  value       = try(aws_iam_role.service.unique_id, null)
}

################################################################################
# Container Definition
################################################################################

output "container_definitions" {
  description = "Container definitions"
  value       = module.container_definition
}

################################################################################
# Task Definition
################################################################################

output "task_definition_arn" {
  description = "Full ARN of the Task Definition (including both `family` and `revision`)"
  value       = try(aws_ecs_task_definition.this.arn, var.task_definition_arn)
}

output "task_definition_revision" {
  description = "Revision of the task in a particular family"
  value       = try(aws_ecs_task_definition.this.revision, null)
}

output "task_definition_family" {
  description = "The unique name of the task definition"
  value       = try(aws_ecs_task_definition.this.family, null)
}

output "task_definition_family_revision" {
  description = "The family and revision (family:revision) of the task definition"
  value       = "${try(aws_ecs_task_definition.this.family, "")}:${local.max_task_def_revision}"
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
  value       = try(aws_iam_role.task_exec.arn, var.task_exec_iam_role_arn)
}

output "task_exec_iam_role_unique_id" {
  description = "Stable and unique string identifying the task execution IAM role"
  value       = try(aws_iam_role.task_exec.unique_id, null)
}

################################################################################
# Tasks - IAM role
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html
################################################################################

output "tasks_iam_role_name" {
  description = "Tasks IAM role name"
  value       = try(aws_iam_role.tasks.name, null)
}

output "tasks_iam_role_arn" {
  description = "Tasks IAM role ARN"
  value       = try(aws_iam_role.tasks.arn, var.tasks_iam_role_arn)
}

output "tasks_iam_role_unique_id" {
  description = "Stable and unique string identifying the tasks IAM role"
  value       = try(aws_iam_role.tasks.unique_id, null)
}

################################################################################
# Task Set
################################################################################

output "task_set_id" {
  description = "The ID of the task set"
  value       = try(aws_ecs_task_set.this.task_set_id, aws_ecs_task_set.ignore_task_definition.task_set_id, null)
}

output "task_set_arn" {
  description = "The Amazon Resource Name (ARN) that identifies the task set"
  value       = try(aws_ecs_task_set.this.arn, aws_ecs_task_set.ignore_task_definition.arn, null)
}

output "task_set_stability_status" {
  description = "The stability status. This indicates whether the task set has reached a steady state"
  value       = try(aws_ecs_task_set.this.stability_status, aws_ecs_task_set.ignore_task_definition.stability_status, null)
}

output "task_set_status" {
  description = "The status of the task set"
  value       = try(aws_ecs_task_set.this.status, aws_ecs_task_set.ignore_task_definition.status, null)
}

################################################################################
# Autoscaling
################################################################################

output "autoscaling_policies" {
  description = "Map of autoscaling policies and their attributes"
  value       = aws_appautoscaling_policy.this
}

output "autoscaling_scheduled_actions" {
  description = "Map of autoscaling scheduled actions and their attributes"
  value       = aws_appautoscaling_scheduled_action.this
}

################################################################################
# Infrastructure - IAM Role
# Required for managed EBS volumes and VPC Lattice
################################################################################

output "infrastructure_iam_role_name" {
  description = "Infrastructure IAM role name"
  value       = try(aws_iam_role.infrastructure.name, null)
}

output "infrastructure_iam_role_arn" {
  description = "Infrastructure IAM role ARN"
  value       = try(aws_iam_role.infrastructure.arn, var.infrastructure_iam_role_arn)
}

output "infrastructure_iam_role_unique_id" {
  description = "Stable and unique string identifying the infrastructure IAM role"
  value       = try(aws_iam_role.infrastructure.unique_id, null)
}

################################################################################
# Service Connect - CloudWatch Log Group
################################################################################

output "service_connect_log_group_name" {
  description = "Name of the CloudWatch log group created for Service Connect"
  value       = try(aws_cloudwatch_log_group.service_connect.name, null)
}

output "service_connect_log_group_arn" {
  description = "ARN of the CloudWatch log group created for Service Connect"
  value       = try(aws_cloudwatch_log_group.service_connect.arn, null)
}

################################################################################
# Security Group
################################################################################

output "security_group_arn" {
  description = "Amazon Resource Name (ARN) of the security group"
  value       = try(aws_security_group.this.arn, null)
}

output "security_group_id" {
  description = "ID of the security group"
  value       = try(aws_security_group.this.id, null)
}

################################################################################
