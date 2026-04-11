output "workgroup_arn" {
  description = "ARN of the Athena workgroup"
  value       = try(aws_athena_workgroup.this.arn, "")
}

output "workgroup_id" {
  description = "ID of the Athena workgroup"
  value       = try(aws_athena_workgroup.this.id, "")
}

output "workgroup_name" {
  description = "Name of the Athena workgroup"
  value       = try(aws_athena_workgroup.this.name, "")
}

output "named_query_ids" {
  description = "Map of named query names to their IDs"
  value       = { for k, v in aws_athena_named_query.this : k => try(v.id, "") }
}

output "data_catalog_names" {
  description = "Map of data catalog names to their names"
  value       = { for k, v in aws_athena_data_catalog.this : k => try(v.name, "") }
}

output "database_names" {
  description = "Map of database keys to their names"
  value       = { for k, v in aws_athena_database.this : k => try(v.name, "") }
}
