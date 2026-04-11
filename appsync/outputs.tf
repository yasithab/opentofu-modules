################################################################################
# GraphQL API
################################################################################

output "api_arn" {
  description = "The ARN of the AppSync GraphQL API."
  value       = try(aws_appsync_graphql_api.this.arn, "")
}

output "api_id" {
  description = "The ID of the AppSync GraphQL API."
  value       = try(aws_appsync_graphql_api.this.id, "")
}

output "api_name" {
  description = "The name of the AppSync GraphQL API."
  value       = try(aws_appsync_graphql_api.this.name, "")
}

output "api_uris" {
  description = "Map of URIs for the AppSync GraphQL API (GRAPHQL, REALTIME)."
  value       = try(aws_appsync_graphql_api.this.uris, {})
}

################################################################################
# API Keys
################################################################################

output "api_key_ids" {
  description = "Map of API key IDs."
  value       = { for k, v in aws_appsync_api_key.this : k => try(v.id, "") }
}

output "api_key_keys" {
  description = "Map of API key values."
  value       = { for k, v in aws_appsync_api_key.this : k => try(v.key, "") }
  sensitive   = true
}

################################################################################
# Data Sources
################################################################################

output "datasource_arns" {
  description = "Map of data source ARNs."
  value       = { for k, v in aws_appsync_datasource.this : k => try(v.arn, "") }
}

################################################################################
# Functions
################################################################################

output "function_ids" {
  description = "Map of AppSync function IDs."
  value       = { for k, v in aws_appsync_function.this : k => try(v.function_id, "") }
}

output "function_arns" {
  description = "Map of AppSync function ARNs."
  value       = { for k, v in aws_appsync_function.this : k => try(v.arn, "") }
}

################################################################################
# Resolvers
################################################################################

output "resolver_arns" {
  description = "Map of resolver ARNs."
  value       = { for k, v in aws_appsync_resolver.this : k => try(v.arn, "") }
}

################################################################################
# API Cache
################################################################################

output "api_cache_id" {
  description = "The ID of the API cache."
  value       = try(aws_appsync_api_cache.this.id, "")
}

################################################################################
# Domain Name
################################################################################

output "domain_name" {
  description = "The custom domain name."
  value       = try(aws_appsync_domain_name.this.domain_name, "")
}

output "domain_appsync_domain_name" {
  description = "The AppSync-provided domain name for CNAME configuration."
  value       = try(aws_appsync_domain_name.this.appsync_domain_name, "")
}

output "domain_hosted_zone_id" {
  description = "The hosted zone ID for the AppSync domain."
  value       = try(aws_appsync_domain_name.this.hosted_zone_id, "")
}

################################################################################
# IAM
################################################################################

output "logging_role_arn" {
  description = "The ARN of the AppSync logging IAM role."
  value       = try(aws_iam_role.logging.arn, "")
}
