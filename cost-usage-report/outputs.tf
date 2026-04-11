################################################################################
# Report Definition
################################################################################

output "report_arn" {
  description = "The ARN of the Cost and Usage Report definition."
  value       = try(aws_cur_report_definition.this.arn, "")
}

output "report_id" {
  description = "The ID of the Cost and Usage Report definition."
  value       = try(aws_cur_report_definition.this.id, "")
}

output "report_name" {
  description = "The name of the Cost and Usage Report."
  value       = try(aws_cur_report_definition.this.report_name, "")
}

output "report_s3_bucket" {
  description = "The S3 bucket where the CUR report is delivered."
  value       = try(aws_cur_report_definition.this.s3_bucket, "")
}

output "report_s3_prefix" {
  description = "The S3 prefix for the CUR report delivery location."
  value       = try(aws_cur_report_definition.this.s3_prefix, "")
}

output "report_s3_region" {
  description = "The S3 region of the CUR report bucket."
  value       = try(aws_cur_report_definition.this.s3_region, "")
}

################################################################################
# S3 Bucket
################################################################################

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket created for CUR delivery."
  value       = try(aws_s3_bucket.this.arn, "")
}

output "s3_bucket_id" {
  description = "The name (ID) of the S3 bucket created for CUR delivery."
  value       = try(aws_s3_bucket.this.id, "")
}

output "s3_bucket_domain_name" {
  description = "The domain name of the S3 bucket."
  value       = try(aws_s3_bucket.this.bucket_domain_name, "")
}
