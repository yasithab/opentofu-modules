output "resource_share_id" {
  value       = try(aws_ram_resource_share.default.id, "")
  description = "RAM resource share ID"
}

output "resource_share_arn" {
  value       = try(aws_ram_resource_share.default.arn, "")
  description = "RAM resource share ARN"
}

output "resource_association_id" {
  value       = try(aws_ram_resource_association.default.id, "")
  description = "ID of the RAM resource association"
}

output "principal_associations" {
  value       = try({ for k, v in aws_ram_principal_association.default : k => v.id }, {})
  description = "Map of principal to RAM principal association ID"
}

output "sharing_with_organization_enabled" {
  value       = try(aws_ram_sharing_with_organization.default.id, "") != ""
  description = "Whether resource sharing with AWS Organizations is enabled by this module"
}
