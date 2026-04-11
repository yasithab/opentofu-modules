output "enabler_id" {
  description = "ID of the Inspector enabler resource"
  value       = try(aws_inspector2_enabler.this.id, "")
}

output "enabler_arn" {
  description = "ARN of the Inspector enabler resource (composite of account IDs and resource types)"
  value       = try(aws_inspector2_enabler.this.id, "")
}

output "name" {
  description = "Name identifier for the Inspector deployment"
  value       = var.name
}

output "delegated_admin_account_id" {
  description = "Account ID of the delegated administrator for Inspector"
  value       = try(aws_inspector2_delegated_admin_account.this.id, "")
}

output "member_account_ids" {
  description = "Set of member account IDs associated with Inspector"
  value       = toset([for k, v in aws_inspector2_member_association.this : v.account_id])
}

output "filter_ids" {
  description = "Map of filter names to their IDs"
  value       = { for k, v in aws_inspector2_filter.this : k => v.id }
}

output "filter_arns" {
  description = "Map of filter names to their ARNs"
  value       = { for k, v in aws_inspector2_filter.this : k => v.arn }
}

