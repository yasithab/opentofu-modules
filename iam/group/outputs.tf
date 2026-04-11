output "name" {
  description = "The name of the IAM group."
  value       = try(aws_iam_group.this.name, "")
}

output "id" {
  description = "The group's ID."
  value       = try(aws_iam_group.this.id, "")
}

output "arn" {
  description = "The ARN assigned by AWS for this group."
  value       = try(aws_iam_group.this.arn, "")
}

output "unique_id" {
  description = "The unique ID assigned by AWS."
  value       = try(aws_iam_group.this.unique_id, "")
}

output "path" {
  description = "The path of the group in IAM."
  value       = try(aws_iam_group.this.path, "")
}

output "membership_name" {
  description = "The name of the group membership resource."
  value       = try(aws_iam_group_membership.this.name, "")
}

output "membership_users" {
  description = "The list of IAM user names in the group."
  value       = try(aws_iam_group_membership.this.users, [])
}

output "attached_policy_arns" {
  description = "The set of managed policy ARNs attached to the group."
  value       = [for k, v in aws_iam_group_policy_attachment.this : v.policy_arn]
}

output "inline_policy_names" {
  description = "The list of inline policy names attached to the group."
  value       = [for k, v in aws_iam_group_policy.this : v.name]
}
