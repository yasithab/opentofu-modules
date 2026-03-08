################################################################################
# FMS Admin Account Outputs
################################################################################

output "admin_account_id" {
  description = "AWS account ID of the FMS administrator account."
  value       = var.associate_admin_account ? aws_fms_admin_account.this.id : null
}

################################################################################
# WAFv2 Policy Outputs
################################################################################

output "waf_v2_policy_ids" {
  description = "Map of WAFv2 policy names to their IDs."
  value       = { for k, v in aws_fms_policy.waf_v2 : k => v.id }
}

output "waf_v2_policy_arns" {
  description = "Map of WAFv2 policy names to their ARNs."
  value       = { for k, v in aws_fms_policy.waf_v2 : k => v.arn }
}
