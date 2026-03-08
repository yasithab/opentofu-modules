################################################################################
# Build Runner
################################################################################

output "build_runner_project_arn" {
  description = "ARN of the CodeBuild build runner project"
  value       = try(aws_codebuild_project.codebuild_build_runner.arn, null)
}

output "build_runner_project_name" {
  description = "Name of the CodeBuild build runner project"
  value       = try(aws_codebuild_project.codebuild_build_runner.name, null)
}

output "build_runner_webhook_url" {
  description = "URL of the webhook to trigger builds for the build runner"
  value       = try(aws_codebuild_webhook.codebuild_build_runner.url, null)
}

################################################################################
# Deployment Runner
################################################################################

output "deployment_runner_project_arn" {
  description = "ARN of the CodeBuild deployment runner project"
  value       = try(aws_codebuild_project.codebuild_deployment_runner.arn, null)
}

output "deployment_runner_project_name" {
  description = "Name of the CodeBuild deployment runner project"
  value       = try(aws_codebuild_project.codebuild_deployment_runner.name, null)
}

output "deployment_runner_webhook_url" {
  description = "URL of the webhook to trigger builds for the deployment runner"
  value       = try(aws_codebuild_webhook.codebuild_deployment_runner.url, null)
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
