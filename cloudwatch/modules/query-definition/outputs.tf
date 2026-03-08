################################################################################
# Query Definition
################################################################################

output "query_definition_id" {
  description = "The ID of the CloudWatch Logs Insights query definition."
  value       = try(aws_cloudwatch_query_definition.this.query_definition_id, null)
}

output "query_definition_name" {
  description = "The name of the CloudWatch Logs Insights query definition."
  value       = try(aws_cloudwatch_query_definition.this.name, null)
}
