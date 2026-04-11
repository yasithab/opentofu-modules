################################################################################
# Organization
################################################################################

output "organization_arn" {
  description = "ARN of the organization."
  value       = try(aws_organizations_organization.this.arn, "")
}

output "organization_id" {
  description = "Identifier of the organization."
  value       = try(aws_organizations_organization.this.id, "")
}

output "organization_name" {
  description = "Name identifier for the organization module instance."
  value       = var.name
}

output "master_account_arn" {
  description = "ARN of the master (management) account."
  value       = try(aws_organizations_organization.this.master_account_arn, "")
}

output "master_account_id" {
  description = "ID of the master (management) account."
  value       = try(aws_organizations_organization.this.master_account_id, "")
}

output "master_account_email" {
  description = "Email address of the master (management) account."
  value       = try(aws_organizations_organization.this.master_account_email, "")
}

output "roots" {
  description = "List of organization roots with their IDs, ARNs, names, and policy types."
  value       = try(aws_organizations_organization.this.roots, [])
}

output "non_master_accounts" {
  description = "List of non-master accounts in the organization."
  value       = try(aws_organizations_organization.this.non_master_accounts, [])
}

################################################################################
# Organizational Units
################################################################################

output "organizational_unit_ids" {
  description = "Map of OU keys to their IDs."
  value = merge(
    { for k, v in aws_organizations_organizational_unit.root : k => v.id },
    { for k, v in aws_organizations_organizational_unit.child : k => v.id },
  )
}

output "organizational_unit_arns" {
  description = "Map of OU keys to their ARNs."
  value = merge(
    { for k, v in aws_organizations_organizational_unit.root : k => v.arn },
    { for k, v in aws_organizations_organizational_unit.child : k => v.arn },
  )
}

################################################################################
# Accounts
################################################################################

output "account_ids" {
  description = "Map of account keys to their IDs."
  value       = { for k, v in aws_organizations_account.this : k => v.id }
}

output "account_arns" {
  description = "Map of account keys to their ARNs."
  value       = { for k, v in aws_organizations_account.this : k => v.arn }
}

################################################################################
# Policies
################################################################################

output "policy_ids" {
  description = "Map of policy keys to their IDs."
  value       = { for k, v in aws_organizations_policy.this : k => v.id }
}

output "policy_arns" {
  description = "Map of policy keys to their ARNs."
  value       = { for k, v in aws_organizations_policy.this : k => v.arn }
}

################################################################################
# Resource Policy
################################################################################

output "resource_policy_arn" {
  description = "ARN of the organization resource policy."
  value       = try(aws_organizations_resource_policy.this.arn, "")
}

output "resource_policy_id" {
  description = "ID of the organization resource policy."
  value       = try(aws_organizations_resource_policy.this.id, "")
}
