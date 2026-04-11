output "hub_arn" {
  description = "ARN of the Security Hub account"
  value       = try(aws_securityhub_account.this.arn, "")
}

output "hub_id" {
  description = "ID of the Security Hub account"
  value       = try(aws_securityhub_account.this.id, "")
}

output "hub_name" {
  description = "Name identifier for the Security Hub deployment"
  value       = var.name
}

output "standards_subscription_arns" {
  description = "Map of standards ARNs to their subscription ARNs"
  value       = { for k, v in aws_securityhub_standards_subscription.this : k => v.id }
}

output "member_account_ids" {
  description = "Map of member account friendly names to their account IDs"
  value       = { for k, v in aws_securityhub_member.this : k => v.account_id }
}

output "finding_aggregator_arn" {
  description = "ARN of the finding aggregator"
  value       = try(aws_securityhub_finding_aggregator.this.id, "")
}

output "action_target_arns" {
  description = "Map of action target names to their ARNs"
  value       = { for k, v in aws_securityhub_action_target.this : k => v.arn }
}
