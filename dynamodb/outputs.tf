output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = try(aws_dynamodb_table.this.arn, aws_dynamodb_table.autoscaled.arn, aws_dynamodb_table.autoscaled_gsi_ignore.arn, "")
}

output "dynamodb_table_id" {
  description = "ID of the DynamoDB table"
  value       = try(aws_dynamodb_table.this.id, aws_dynamodb_table.autoscaled.id, aws_dynamodb_table.autoscaled_gsi_ignore.id, "")
}

output "dynamodb_table_stream_arn" {
  description = "The ARN of the Table Stream. Only available when var.stream_enabled is true"
  value       = var.stream_enabled ? try(aws_dynamodb_table.this.stream_arn, aws_dynamodb_table.autoscaled.stream_arn, aws_dynamodb_table.autoscaled_gsi_ignore.stream_arn, "") : null
}

output "dynamodb_table_stream_label" {
  description = "A timestamp, in ISO 8601 format of the Table Stream. Only available when var.stream_enabled is true"
  value       = var.stream_enabled ? try(aws_dynamodb_table.this.stream_label, aws_dynamodb_table.autoscaled.stream_label, aws_dynamodb_table.autoscaled_gsi_ignore.stream_label, "") : null
}

output "dynamodb_resource_policy_id" {
  description = "The ID of the DynamoDB resource policy, same as the resource ARN"
  value       = try(aws_dynamodb_resource_policy.this.id, null)
}
