################################################################################
# Runner Projects (keyed by runner: "build", "deployment")
################################################################################

output "project_arns" {
  description = "Map of runner key to CodeBuild project ARN"
  value       = { for k, v in aws_codebuild_project.this : k => v.arn }
}

output "project_names" {
  description = "Map of runner key to CodeBuild project name"
  value       = { for k, v in aws_codebuild_project.this : k => v.name }
}

output "webhook_urls" {
  description = "Map of runner key to the URL of the webhook that triggers its builds"
  value       = { for k, v in aws_codebuild_webhook.this : k => v.url }
}

################################################################################
# IAM
################################################################################

output "iam_role_arn" {
  description = "ARN of the CodeBuild IAM role (if created by this module)"
  value       = try(aws_iam_role.role_codebuild_runners.arn, null)
}

output "iam_role_name" {
  description = "Name of the CodeBuild IAM role (if created by this module)"
  value       = try(aws_iam_role.role_codebuild_runners.name, null)
}

################################################################################
# Security Group
################################################################################

output "security_group_id" {
  description = "ID of the CodeBuild security group (if created by this module)"
  value       = try(aws_security_group.codebuild_runners.id, null)
}

################################################################################
# CloudWatch Log Group
################################################################################

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for CodeBuild logs"
  value       = try(aws_cloudwatch_log_group.codebuild_runners.name, null)
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for CodeBuild logs"
  value       = try(aws_cloudwatch_log_group.codebuild_runners.arn, null)
}
