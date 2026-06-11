################################################################################
# Compute Environment
################################################################################

output "compute_environment_arn" {
  description = "The ARN of the Batch compute environment."
  value       = try(aws_batch_compute_environment.this.arn, "")
}

output "compute_environment_id" {
  description = "The ID of the Batch compute environment."
  value       = try(aws_batch_compute_environment.this.id, "")
}

output "compute_environment_name" {
  description = "The name of the Batch compute environment."
  value       = try(aws_batch_compute_environment.this.name, "")
}

output "compute_environment_status" {
  description = "The current status of the Batch compute environment."
  value       = try(aws_batch_compute_environment.this.status, "")
}

################################################################################
# Job Queue
################################################################################

output "job_queue_arns" {
  description = "Map of job queue ARNs."
  value       = { for k, v in aws_batch_job_queue.this : k => try(v.arn, "") }
}

output "job_queue_ids" {
  description = "Map of job queue IDs."
  value       = { for k, v in aws_batch_job_queue.this : k => try(v.id, "") }
}

################################################################################
# Scheduling Policy
################################################################################

output "scheduling_policy_arns" {
  description = "Map of scheduling policy ARNs."
  value       = { for k, v in aws_batch_scheduling_policy.this : k => try(v.arn, "") }
}

################################################################################
# Job Definition
################################################################################

output "job_definition_arns" {
  description = "Map of job definition ARNs."
  value       = { for k, v in aws_batch_job_definition.this : k => try(v.arn, "") }
}

output "job_definition_ids" {
  description = "Map of job definition IDs."
  value       = { for k, v in aws_batch_job_definition.this : k => try(v.id, "") }
}

################################################################################
# Security Group
################################################################################

output "security_group_id" {
  description = "The ID of the Batch compute environment security group."
  value       = try(aws_security_group.this.id, "")
}

output "security_group_arn" {
  description = "The ARN of the Batch compute environment security group."
  value       = try(aws_security_group.this.arn, "")
}

################################################################################
# IAM
################################################################################

output "service_role_arn" {
  description = "The effective ARN of the Batch service IAM role (created by the module or passed via `service_role_arn`)."
  # try() wraps coalesce(): with the module disabled and no override variable
  # every argument is null and a bare coalesce() errors during plan.
  value = try(coalesce(try(aws_iam_role.service.arn, null), var.service_role_arn), "")
}

output "execution_role_arn" {
  description = "The effective ARN of the Batch execution IAM role (created by the module or passed via `execution_role_arn`)."
  value       = try(coalesce(try(aws_iam_role.execution.arn, null), var.execution_role_arn), "")
}

output "job_role_arn" {
  description = "The effective ARN of the Batch job IAM role (created by the module or passed via `job_role_arn`)."
  value       = try(coalesce(try(aws_iam_role.job.arn, null), var.job_role_arn), "")
}
