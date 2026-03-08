output "role_arn" {
  description = "ARN of the GitHub Actions IAM role"
  value       = try(aws_iam_role.github_actions.arn, null)
}

output "role_name" {
  description = "Name of the GitHub Actions IAM role"
  value       = try(aws_iam_role.github_actions.name, null)
}

output "policy_arn" {
  description = "ARN of the GitHub Actions IAM policy"
  value       = try(aws_iam_policy.github_actions.arn, null)
}

output "policy_name" {
  description = "Name of the GitHub Actions IAM policy"
  value       = try(aws_iam_policy.github_actions.name, null)
}