################################################################################
# S3 Staging Bucket
################################################################################

output "bucket_name" {
  description = "Name of the CDK staging S3 bucket."
  value       = try(aws_s3_bucket.staging.id, "")
}

output "bucket_arn" {
  description = "ARN of the CDK staging S3 bucket."
  value       = try(aws_s3_bucket.staging.arn, "")
}

output "bucket_domain_name" {
  description = "Domain name of the CDK staging S3 bucket."
  value       = try(aws_s3_bucket.staging.bucket_domain_name, "")
}

################################################################################
# ECR Repository
################################################################################

output "ecr_repository_url" {
  description = "URL of the CDK container assets ECR repository."
  value       = try(aws_ecr_repository.this.repository_url, "")
}

output "ecr_repository_arn" {
  description = "ARN of the CDK container assets ECR repository."
  value       = try(aws_ecr_repository.this.arn, "")
}

################################################################################
# KMS Key
################################################################################

output "kms_key_arn" {
  description = "ARN of the CDK bootstrap KMS key. Empty when create_kms_key is false."
  value       = try(aws_kms_key.this.arn, "")
}

output "kms_key_alias" {
  description = "Alias of the CDK bootstrap KMS key."
  value       = try(aws_kms_alias.this.name, "")
}

################################################################################
# IAM Roles
################################################################################

output "cfn_exec_role_arn" {
  description = "ARN of the CloudFormation execution role."
  value       = try(aws_iam_role.cfn_exec.arn, "")
}

output "deploy_role_arn" {
  description = "ARN of the CDK deployment action role."
  value       = try(aws_iam_role.deploy.arn, "")
}

output "file_publishing_role_arn" {
  description = "ARN of the file (S3) publishing role."
  value       = try(aws_iam_role.file_publishing.arn, "")
}

output "image_publishing_role_arn" {
  description = "ARN of the image (ECR) publishing role."
  value       = try(aws_iam_role.image_publishing.arn, "")
}

output "lookup_role_arn" {
  description = "ARN of the context lookup role."
  value       = try(aws_iam_role.lookup.arn, "")
}

################################################################################
# SSM Parameter
################################################################################

output "bootstrap_version" {
  description = "The CDK bootstrap version stored in SSM."
  value       = try(aws_ssm_parameter.version.value, "")
}

output "ssm_parameter_name" {
  description = "Name of the SSM parameter storing the bootstrap version."
  value       = try(aws_ssm_parameter.version.name, "")
}
