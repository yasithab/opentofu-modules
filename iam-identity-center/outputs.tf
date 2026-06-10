output "account_assignment_data" {
  value       = try(local.flatten_account_assignment_data, [])
  description = "Tuple containing account assignment data"
}

output "principals_and_assignments" {
  value       = try(local.principals_and_their_account_assignments, {})
  description = "Map containing account assignment data"
}

output "sso_groups_ids" {
  value       = try({ for k, v in aws_identitystore_group.sso_groups : k => v.group_id }, {})
  description = "A map of SSO groups ids created by this module"
}

output "permission_sets_arns" {
  value       = try({ for k, v in aws_ssoadmin_permission_set.pset : k => v.arn }, {})
  description = "A map of permission set ARNs created by this module, keyed by permission set name"
}

output "sso_applications_arns" {
  value       = try({ for k, v in aws_ssoadmin_application.sso_apps : k => v.application_arn }, {})
  description = "A map of SSO Applications ARNs created by this module"
}

output "sso_applications_group_assignments" {
  value       = try({ for k, v in aws_ssoadmin_application_assignment.sso_apps_groups_assignments : k => v.principal_id }, {})
  description = "A map of SSO Applications assignments with groups created by this module"
}

output "sso_applications_user_assignments" {
  value       = try({ for k, v in aws_ssoadmin_application_assignment.sso_apps_users_assignments : k => v.principal_id }, {})
  description = "A map of SSO Applications assignments with users created by this module"
}

output "trusted_token_issuer_arns" {
  value       = try({ for k, v in aws_ssoadmin_trusted_token_issuer.this : k => v.arn }, {})
  description = "A map of trusted token issuer ARNs created by this module"
}
