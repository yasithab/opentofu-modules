output "cloudfront_distribution_id" {
  description = "The identifier for the distribution."
  value       = try(one(aws_cloudfront_distribution.this).id, "")
}

output "cloudfront_distribution_arn" {
  description = "The ARN (Amazon Resource Name) for the distribution."
  value       = try(one(aws_cloudfront_distribution.this).arn, "")
}

output "cloudfront_distribution_caller_reference" {
  description = "Internal value used by CloudFront to allow future updates to the distribution configuration."
  value       = try(one(aws_cloudfront_distribution.this).caller_reference, "")
}

output "cloudfront_distribution_status" {
  description = "The current status of the distribution. Deployed if the distribution's information is fully propagated throughout the Amazon CloudFront system."
  value       = try(one(aws_cloudfront_distribution.this).status, "")
}

output "cloudfront_distribution_trusted_signers" {
  description = "List of nested attributes for active trusted signers, if the distribution is set up to serve private content with signed URLs"
  value       = try(one(aws_cloudfront_distribution.this).trusted_signers, "")
}

output "cloudfront_distribution_domain_name" {
  description = "The domain name corresponding to the distribution."
  value       = try(one(aws_cloudfront_distribution.this).domain_name, "")
}

output "cloudfront_distribution_last_modified_time" {
  description = "The date and time the distribution was last modified."
  value       = try(one(aws_cloudfront_distribution.this).last_modified_time, "")
}

output "cloudfront_distribution_in_progress_validation_batches" {
  description = "The number of invalidation batches currently in progress."
  value       = try(one(aws_cloudfront_distribution.this).in_progress_validation_batches, "")
}

output "cloudfront_distribution_etag" {
  description = "The current version of the distribution's information."
  value       = try(one(aws_cloudfront_distribution.this).etag, "")
}

output "cloudfront_distribution_hosted_zone_id" {
  description = "The CloudFront Route 53 zone ID that can be used to route an Alias Resource Record Set to."
  value       = try(one(aws_cloudfront_distribution.this).hosted_zone_id, "")
}

output "cloudfront_origin_access_identities" {
  description = "The origin access identities created"
  value       = { for k, v in aws_cloudfront_origin_access_identity.this : k => v if local.create_origin_access_identity }
}

output "cloudfront_origin_access_identity_ids" {
  description = "The IDS of the origin access identities created"
  value       = [for v in aws_cloudfront_origin_access_identity.this : v.id if local.create_origin_access_identity]
}

output "cloudfront_origin_access_identity_iam_arns" {
  description = "The IAM arns of the origin access identities created"
  value       = [for v in aws_cloudfront_origin_access_identity.this : v.iam_arn if local.create_origin_access_identity]
}

output "cloudfront_monitoring_subscription_id" {
  description = " The ID of the CloudFront monitoring subscription, which corresponds to the `distribution_id`."
  value       = try(aws_cloudfront_monitoring_subscription.this.id, "")
}

output "cloudfront_distribution_tags" {
  description = "Tags of the distribution's"
  value       = try(one(aws_cloudfront_distribution.this).tags_all, "")
}

output "cloudfront_origin_access_controls" {
  description = "The origin access controls created"
  value       = local.create_origin_access_control ? { for k, v in aws_cloudfront_origin_access_control.this : k => v } : {}
}

output "cloudfront_origin_access_controls_ids" {
  description = "The IDS of the origin access identities created"
  value       = local.create_origin_access_control ? [for v in aws_cloudfront_origin_access_control.this : v.id] : []
}

output "cloudfront_vpc_origin_ids" {
  description = "The IDS of the VPC origin created"
  value       = local.create_vpc_origin ? [for v in aws_cloudfront_vpc_origin.this : v.id] : []
}

output "cloudfront_cache_policy_ids" {
  description = "Map of cache policy name to ID for policies created by this module."
  value       = { for k, v in aws_cloudfront_cache_policy.this : k => v.id }
}

output "cloudfront_origin_request_policy_ids" {
  description = "Map of origin request policy name to ID for policies created by this module."
  value       = { for k, v in aws_cloudfront_origin_request_policy.this : k => v.id }
}

output "cloudfront_response_headers_policy_ids" {
  description = "Map of response headers policy name to ID for policies created by this module."
  value       = { for k, v in aws_cloudfront_response_headers_policy.this : k => v.id }
}

output "cloudfront_key_value_store_arns" {
  description = "Map of Key-Value Store name to ARN for stores created by this module."
  value       = { for k, v in aws_cloudfront_key_value_store.this : k => v.arn }
}

output "cloudfront_key_value_store_ids" {
  description = "Map of Key-Value Store name to ID for stores created by this module."
  value       = { for k, v in aws_cloudfront_key_value_store.this : k => v.id }
}

output "cloudfront_function_arns" {
  description = "Map of CloudFront Function name to ARN for functions created by this module."
  value       = { for k, v in aws_cloudfront_function.this : k => v.arn }
}

output "cloudfront_function_statuses" {
  description = "Map of CloudFront Function name to status for functions created by this module."
  value       = { for k, v in aws_cloudfront_function.this : k => v.status }
}

output "cloudfront_public_key_ids" {
  description = "Map of Public Key name to ID for public keys created by this module."
  value       = { for k, v in aws_cloudfront_public_key.this : k => v.id }
}

output "cloudfront_public_key_etags" {
  description = "Map of Public Key name to ETag for public keys created by this module."
  value       = { for k, v in aws_cloudfront_public_key.this : k => v.etag }
}

output "cloudfront_key_group_ids" {
  description = "Map of Key Group name to ID for key groups created by this module."
  value       = { for k, v in aws_cloudfront_key_group.this : k => v.id }
}

output "cloudfront_key_group_etags" {
  description = "Map of Key Group name to ETag for key groups created by this module."
  value       = { for k, v in aws_cloudfront_key_group.this : k => v.etag }
}

output "cloudfront_realtime_log_config_arns" {
  description = "Map of Real-time Log Config name to ARN for configs created by this module."
  value       = { for k, v in aws_cloudfront_realtime_log_config.this : k => v.arn }
}

output "cloudfront_continuous_deployment_policy_ids" {
  description = "Map of Continuous Deployment Policy key to ID for policies created by this module."
  value       = { for k, v in aws_cloudfront_continuous_deployment_policy.this : k => v.id }
}

output "cloudfront_continuous_deployment_policy_arns" {
  description = "Map of Continuous Deployment Policy key to ARN for policies created by this module."
  value       = { for k, v in aws_cloudfront_continuous_deployment_policy.this : k => v.arn }
}
