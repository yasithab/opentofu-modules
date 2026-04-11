output "account_id" {
  description = "ID of the Macie account"
  value       = try(aws_macie2_account.this.id, "")
}

output "account_arn" {
  description = "ARN of the Macie account (service-linked role ARN)"
  value       = try(aws_macie2_account.this.service_role, "")
}

output "name" {
  description = "Name identifier for the Macie deployment"
  value       = var.name
}

output "classification_job_ids" {
  description = "Map of classification job names to their IDs"
  value       = { for k, v in aws_macie2_classification_job.this : k => v.id }
}

output "classification_job_arns" {
  description = "Map of classification job names to their ARNs"
  value       = { for k, v in aws_macie2_classification_job.this : k => try(v.job_arn, "") }
}

output "custom_data_identifier_ids" {
  description = "Map of custom data identifier names to their IDs"
  value       = { for k, v in aws_macie2_custom_data_identifier.this : k => v.id }
}

output "custom_data_identifier_arns" {
  description = "Map of custom data identifier names to their ARNs"
  value       = { for k, v in aws_macie2_custom_data_identifier.this : k => try(v.arn, "") }
}


output "member_account_ids" {
  description = "Map of member account friendly names to their account IDs"
  value       = { for k, v in aws_macie2_member.this : k => v.account_id }
}

output "classification_export_configuration_id" {
  description = "ID of the classification export configuration"
  value       = try(aws_macie2_classification_export_configuration.this.id, "")
}
