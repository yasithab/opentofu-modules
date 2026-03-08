output "bucket_id" {
  description = "The name of the bucket."
  value       = try(aws_s3_bucket_policy.this.id, aws_s3_bucket.this.id, "")
}

output "bucket_arn" {
  description = "The ARN of the bucket. Will be of format arn:aws:s3:::bucketname."
  value       = try(aws_s3_bucket.this.arn, "")
}

output "bucket_domain_name" {
  description = "The bucket domain name. Will be of format bucketname.s3.amazonaws.com."
  value       = try(aws_s3_bucket.this.bucket_domain_name, "")
}

output "bucket_regional_domain_name" {
  description = "The bucket region-specific domain name. The bucket domain name including the region name, please refer here for format. Note: The AWS CloudFront allows specifying S3 region-specific endpoint when creating S3 origin, it will prevent redirect issues from CloudFront to S3 Origin URL."
  value       = try(aws_s3_bucket.this.bucket_regional_domain_name, "")
}

output "bucket_hosted_zone_id" {
  description = "The Route 53 Hosted Zone ID for this bucket's region."
  value       = try(aws_s3_bucket.this.hosted_zone_id, "")
}

output "bucket_lifecycle_configuration_rules" {
  description = "The lifecycle rules of the bucket, if the bucket is configured with lifecycle rules. If not, this will be an empty string."
  value       = try(aws_s3_bucket_lifecycle_configuration.this.rule, "")
}

output "bucket_policy" {
  description = "The policy of the bucket, if the bucket is configured with a policy. If not, this will be an empty string."
  value       = try(aws_s3_bucket_policy.this.policy, "")
}

output "bucket_region" {
  description = "The AWS region this bucket resides in."
  value       = try(aws_s3_bucket.this.region, "")
}

output "bucket_website_endpoint" {
  description = "The website endpoint, if the bucket is configured with a website. If not, this will be an empty string."
  value       = try(aws_s3_bucket_website_configuration.this.website_endpoint, "")
}

output "bucket_website_domain" {
  description = "The domain of the website endpoint, if the bucket is configured with a website. If not, this will be an empty string. This is used to create Route 53 alias records."
  value       = try(aws_s3_bucket_website_configuration.this.website_domain, "")
}
