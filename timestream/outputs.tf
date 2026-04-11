################################################################################
# Database
################################################################################

output "database_arn" {
  description = "The ARN of the Timestream database."
  value       = try(aws_timestreamwrite_database.this.arn, "")
}

output "database_id" {
  description = "The name (ID) of the Timestream database."
  value       = try(aws_timestreamwrite_database.this.id, "")
}

output "database_name" {
  description = "The name of the Timestream database."
  value       = try(aws_timestreamwrite_database.this.database_name, "")
}

output "database_kms_key_id" {
  description = "The KMS key ID used to encrypt the Timestream database."
  value       = try(aws_timestreamwrite_database.this.kms_key_id, "")
}

output "database_table_count" {
  description = "The total number of tables in the Timestream database."
  value       = try(aws_timestreamwrite_database.this.table_count, "")
}

################################################################################
# Tables
################################################################################

output "tables" {
  description = "Map of created Timestream tables and their attributes."
  value       = aws_timestreamwrite_table.this
}

output "table_arns" {
  description = "Map of table names to their ARNs."
  value       = { for k, v in aws_timestreamwrite_table.this : k => v.arn }
}

output "table_names" {
  description = "Map of table keys to their names."
  value       = { for k, v in aws_timestreamwrite_table.this : k => v.table_name }
}
