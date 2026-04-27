output "conformance_pack_arn" {
  description = "ARN of the account-level conformance pack. Null when create_organization_conformance_pack is true."
  value       = local.enabled && !var.create_organization_conformance_pack ? aws_config_conformance_pack.this.arn : null
}

output "conformance_pack_id" {
  description = "ID (name) of the account-level conformance pack. Null when create_organization_conformance_pack is true."
  value       = local.enabled && !var.create_organization_conformance_pack ? aws_config_conformance_pack.this.id : null
}

output "organization_conformance_pack_arn" {
  description = "ARN of the organization conformance pack. Null when create_organization_conformance_pack is false."
  value       = local.enabled && var.create_organization_conformance_pack ? aws_config_organization_conformance_pack.this.arn : null
}

output "organization_conformance_pack_id" {
  description = "ID (name) of the organization conformance pack. Null when create_organization_conformance_pack is false."
  value       = local.enabled && var.create_organization_conformance_pack ? aws_config_organization_conformance_pack.this.id : null
}
