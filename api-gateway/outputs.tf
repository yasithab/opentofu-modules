output "id" {
  description = "The ID of the REST API"
  value       = try(aws_api_gateway_rest_api.this.id, null)
}

output "root_resource_id" {
  description = "The resource ID of the REST API's root"
  value       = try(aws_api_gateway_rest_api.this.root_resource_id, null)
}

output "created_date" {
  description = "The date the REST API was created"
  value       = try(aws_api_gateway_rest_api.this.created_date, null)
}

output "execution_arn" {
  description = <<EOF
    The execution ARN part to be used in lambda_permission's source_arn when allowing API Gateway to invoke a Lambda 
    function, e.g., arn:aws:execute-api:eu-west-2:123456789012:z4675bid1j, which can be concatenated with allowed stage, 
    method and resource path.The ARN of the Lambda function that will be executed.
    EOF
  value       = try(aws_api_gateway_rest_api.this.execution_arn, null)
}

output "arn" {
  description = "The ARN of the REST API"
  value       = try(aws_api_gateway_rest_api.this.arn, null)
}

output "invoke_url" {
  description = "The URL to invoke the REST API"
  value       = try(aws_api_gateway_stage.this.invoke_url, null)
}

output "stage_arn" {
  description = "The ARN of the gateway stage"
  value       = try(aws_api_gateway_stage.this.arn, null)
}

output "stage_name" {
  description = "The name of the gateway stage"
  value       = try(aws_api_gateway_stage.this.stage_name, null)
}

output "log_group_name" {
  description = "The name of the CloudWatch log group for access logs"
  value       = try(aws_cloudwatch_log_group.this.name, null)
}

output "log_group_arn" {
  description = "The ARN of the CloudWatch log group for access logs"
  value       = try(aws_cloudwatch_log_group.this.arn, null)
}

output "vpc_link_id" {
  description = "The ID of the VPC Link (if created)"
  value       = try(aws_api_gateway_vpc_link.this.id, null)
}

output "vpc_link_arn" {
  description = "The ARN of the VPC Link (if created)"
  value       = try(aws_api_gateway_vpc_link.this.arn, null)
}

output "api_gateway_account_cloudwatch_role_arn" {
  description = "The ARN of the IAM role used for the region-wide API Gateway account CloudWatch settings (if created)"
  value       = try(aws_iam_role.api_gateway_account.arn, null)
}

output "usage_plan_ids" {
  description = "Map of usage plan keys to their IDs"
  value       = { for k, v in aws_api_gateway_usage_plan.this : k => v.id }
}

output "usage_plan_arns" {
  description = "Map of usage plan keys to their ARNs"
  value       = { for k, v in aws_api_gateway_usage_plan.this : k => v.arn }
}

output "api_key_ids" {
  description = "Map of API key keys to their IDs"
  value       = { for k, v in aws_api_gateway_api_key.this : k => v.id }
}

output "api_key_values" {
  description = "Map of API key keys to their generated key values"
  value       = { for k, v in aws_api_gateway_api_key.this : k => v.value }
  sensitive   = true
}

output "domain_name" {
  description = "The custom domain name (if created)"
  value       = try(aws_api_gateway_domain_name.this.domain_name, null)
}

output "domain_name_arn" {
  description = "The ARN of the custom domain name (if created)"
  value       = try(aws_api_gateway_domain_name.this.arn, null)
}

output "domain_cloudfront_domain_name" {
  description = "The CloudFront distribution domain name for an EDGE custom domain - create an alias record pointing to this"
  value       = try(aws_api_gateway_domain_name.this.cloudfront_domain_name, null)
}

output "domain_cloudfront_zone_id" {
  description = "The CloudFront hosted zone ID for an EDGE custom domain"
  value       = try(aws_api_gateway_domain_name.this.cloudfront_zone_id, null)
}

output "domain_regional_domain_name" {
  description = "The regional domain name for a REGIONAL custom domain - create an alias record pointing to this"
  value       = try(aws_api_gateway_domain_name.this.regional_domain_name, null)
}

output "domain_regional_zone_id" {
  description = "The regional hosted zone ID for a REGIONAL custom domain"
  value       = try(aws_api_gateway_domain_name.this.regional_zone_id, null)
}

output "base_path_mapping_id" {
  description = "The ID of the base path mapping (if created)"
  value       = try(aws_api_gateway_base_path_mapping.this.id, null)
}

output "waf_web_acl_association_id" {
  description = "The ID of the WAFv2 web ACL association (if created)"
  value       = try(aws_wafv2_web_acl_association.this.id, null)
}
