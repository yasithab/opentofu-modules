output "flow_log_id" {
  description = "The ID of the Flow Log resource"
  value       = try(aws_flow_log.this.id, null)
}

output "flow_log_arn" {
  description = "The ARN of the Flow Log resource"
  value       = try(aws_flow_log.this.arn, null)
}

output "cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch Log Group created for flow logs (if applicable)"
  value       = try(aws_cloudwatch_log_group.this.arn, null)
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch Log Group created for flow logs (if applicable)"
  value       = try(aws_cloudwatch_log_group.this.name, null)
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket used for flow logs (if applicable)"
  value       = var.log_destination_type == "s3" ? local.log_destination : null
}

output "kinesis_firehose_arn" {
  description = "The ARN of the Kinesis Firehose delivery stream used for flow logs (if applicable)"
  value       = var.log_destination_type == "kinesis-data-firehose" ? local.log_destination : null
}

output "iam_role_arn" {
  description = "The ARN of the IAM role created for flow logs (if applicable)"
  value       = try(aws_iam_role.this.arn, null)
}

output "iam_role_name" {
  description = "The name of the IAM role created for flow logs (if applicable)"
  value       = try(aws_iam_role.this.name, null)
}

output "iam_policy_arn" {
  description = "The ARN of the IAM policy created for flow logs (if applicable)"
  value       = try(aws_iam_policy.this.arn, null)
}

output "log_destination" {
  description = "The final destination ARN used for flow logs (either specified or created)"
  value       = local.log_destination
}
