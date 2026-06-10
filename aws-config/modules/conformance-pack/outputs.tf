output "conformance_pack_arn" {
  description = "ARN of the account-level conformance pack. Empty when create_organization_conformance_pack is true."
  value       = try(aws_config_conformance_pack.this.arn, "")
}

output "conformance_pack_id" {
  description = "ID (name) of the account-level conformance pack. Empty when create_organization_conformance_pack is true."
  value       = try(aws_config_conformance_pack.this.id, "")
}

output "organization_conformance_pack_arn" {
  description = "ARN of the organization conformance pack. Empty when create_organization_conformance_pack is false."
  value       = try(aws_config_organization_conformance_pack.this.arn, "")
}

output "organization_conformance_pack_id" {
  description = "ID (name) of the organization conformance pack. Empty when create_organization_conformance_pack is false."
  value       = try(aws_config_organization_conformance_pack.this.id, "")
}
