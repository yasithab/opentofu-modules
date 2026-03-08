output "resource_share_id" {
  value       = try(aws_ram_resource_share.default.id, "")
  description = "RAM resource share ID"
}
