output "policy_id" {
  description = "ID of the created tag policy"
  value       = try(aws_organizations_policy.this.id, "")
}

output "policy_arn" {
  description = "The ARN of the created tag policy"
  value       = try(aws_organizations_policy.this.arn, "")
}

output "attached_ou_ids" {
  description = "List of OU IDs the policy is attached to"
  value       = var.attach_to_org ? [] : try([for attachment in aws_organizations_policy_attachment.attach_ous : attachment.target_id], [])
}

output "attached_org_root_id" {
  description = "Organization root ID the policy is attached to if the policy is attached to the root"
  value       = var.attach_to_org ? try(data.aws_organizations_organization.org[0].roots[0].id, null) : null
}
