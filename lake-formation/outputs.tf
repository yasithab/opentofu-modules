output "data_lake_settings_id" {
  description = "ID of the Lake Formation data lake settings (same as catalog ID)"
  value       = try(aws_lakeformation_data_lake_settings.this.id, "")
}

output "data_lake_settings_admins" {
  description = "List of Lake Formation administrator principal ARNs"
  value       = try(aws_lakeformation_data_lake_settings.this.admins, [])
}

output "resource_arns" {
  description = "Map of registered resource keys to their ARNs"
  value       = { for k, v in aws_lakeformation_resource.this : k => try(v.arn, "") }
}

output "lf_tag_keys" {
  description = "Map of LF-Tag keys to their values"
  value       = { for k, v in aws_lakeformation_lf_tag.this : k => try(v.values, []) }
}

output "database_permission_ids" {
  description = "Map of database permission keys to their IDs"
  value       = { for k, v in aws_lakeformation_permissions.database : k => try(v.id, "") }
}

output "table_permission_ids" {
  description = "Map of table permission keys to their IDs"
  value       = { for k, v in aws_lakeformation_permissions.table : k => try(v.id, "") }
}

output "table_with_columns_permission_ids" {
  description = "Map of column-level permission keys to their IDs"
  value       = { for k, v in aws_lakeformation_permissions.table_with_columns : k => try(v.id, "") }
}

output "data_cells_filter_names" {
  description = "Map of data cells filter keys to their names"
  value       = { for k, v in aws_lakeformation_data_cells_filter.this : k => k }
}
