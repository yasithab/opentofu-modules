output "id" {
  description = "The policy's ID."
  value       = try(aws_iam_policy.this.id, "")
}

output "arn" {
  description = "The ARN assigned by AWS to this policy."
  value       = try(aws_iam_policy.this.arn, "")
}

output "name" {
  description = "The name of the policy."
  value       = try(aws_iam_policy.this.name, "")
}

output "description" {
  description = "The description of the policy."
  value       = try(aws_iam_policy.this.description, "")
}

output "path" {
  description = "The path of the policy in IAM."
  value       = try(aws_iam_policy.this.path, "")
}

output "policy" {
  description = "The policy document JSON."
  value       = try(aws_iam_policy.this.policy, "")
}

output "policy_id" {
  description = "The policy's ID."
  value       = try(aws_iam_policy.this.policy_id, "")
}

output "attachment_count" {
  description = "The number of entities (users, groups, roles) that the policy is attached to."
  value       = try(aws_iam_policy.this.attachment_count, "")
}

output "tags_all" {
  description = "A map of tags assigned to the resource, including those inherited from the provider."
  value       = try(aws_iam_policy.this.tags_all, {})
}
