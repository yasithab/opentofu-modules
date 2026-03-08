# Kinesis Delivery Stream
output "kinesis_firehose_arn" {
  description = "The ARN of the Kinesis Firehose Stream"
  value       = try(aws_kinesis_firehose_delivery_stream.this.arn, null)
}

output "kinesis_firehose_name" {
  description = "The name of the Kinesis Firehose Stream"
  value       = try(aws_kinesis_firehose_delivery_stream.this.name, null)
}

output "kinesis_firehose_destination_id" {
  description = "The Destination id of the Kinesis Firehose Stream"
  value       = try(aws_kinesis_firehose_delivery_stream.this.destination_id, null)
}

output "kinesis_firehose_version_id" {
  description = "The Version id of the Kinesis Firehose Stream"
  value       = try(aws_kinesis_firehose_delivery_stream.this.version_id, null)
}

# CloudWatch Log Group
output "kinesis_firehose_cloudwatch_log_group_arn" {
  description = "The ARN of the created Cloudwatch Log Group"
  value       = try(aws_cloudwatch_log_group.log.arn, "")
}

output "kinesis_firehose_cloudwatch_log_group_name" {
  description = "The name of the created Cloudwatch Log Group"
  value       = try(aws_cloudwatch_log_group.log.name, "")
}

output "kinesis_firehose_cloudwatch_log_delivery_stream_arn" {
  description = "The ARN of the created Cloudwatch Log Group Stream to delivery"
  value       = try(aws_cloudwatch_log_stream.destination.arn, "")
}

output "kinesis_firehose_cloudwatch_log_delivery_stream_name" {
  description = "The name of the created Cloudwatch Log Group Stream to delivery"
  value       = try(aws_cloudwatch_log_stream.destination.name, "")
}

output "kinesis_firehose_cloudwatch_log_backup_stream_arn" {
  description = "The ARN of the created Cloudwatch Log Group Stream to backup"
  value       = try(aws_cloudwatch_log_stream.backup.arn, "")
}

output "kinesis_firehose_cloudwatch_log_backup_stream_name" {
  description = "The name of the created Cloudwatch Log Group Stream to backup"
  value       = try(aws_cloudwatch_log_stream.backup.name, "")
}

# IAM
output "kinesis_firehose_role_arn" {
  description = "The ARN of the IAM role created for Kinesis Firehose Stream"
  value       = try(aws_iam_role.firehose.arn, "")
}

output "s3_cross_account_bucket_policy" {
  description = "Bucket Policy to S3 Bucket Destination when the bucket belongs to another account"
  value       = try(data.aws_iam_policy_document.cross_account_s3[0].json, "")
}

output "opensearch_iam_service_linked_role_arn" {
  description = "The ARN of the Opensearch IAM Service linked role"
  value       = try(aws_iam_service_linked_role.opensearch.arn, "")
}

output "elasticsearch_cross_account_service_policy" {
  description = "Elasticsearch Service policy when the opensearch domain belongs to another account"
  value       = try(data.aws_iam_policy_document.cross_account_elasticsearch[0].json, "")
}

output "opensearch_cross_account_service_policy" {
  description = "Opensearch Service policy when the opensearch domain belongs to another account"
  value       = try(data.aws_iam_policy_document.cross_account_opensearch[0].json, "")
}

output "opensearchserverless_cross_account_service_policy" {
  description = "Opensearch Serverless Service policy when the opensearch domain belongs to another account"
  value       = try(data.aws_iam_policy_document.cross_account_opensearchserverless[0].json, "")
}


output "opensearchserverless_iam_service_linked_role_arn" {
  description = "The ARN of the Opensearch Serverless IAM Service linked role"
  value       = try(aws_iam_service_linked_role.opensearchserverless.arn, "")
}

output "application_role_arn" {
  description = "The ARN of the IAM role created for Kinesis Firehose Stream Source"
  value       = try(aws_iam_role.application.arn, "")
}

output "application_role_name" {
  description = "The Name of the IAM role created for Kinesis Firehose Stream Source Source"
  value       = try(aws_iam_role.application.name, "")
}

output "application_role_policy_arn" {
  description = "The ARN of the IAM policy created for Kinesis Firehose Stream Source"
  value       = try(aws_iam_policy.application.arn, "")
}

output "application_role_policy_name" {
  description = "The Name of the IAM policy created for Kinesis Firehose Stream Source Source"
  value       = try(aws_iam_policy.application.name, "")
}

# Security Group
output "firehose_security_group_id" {
  description = "Security Group ID associated to Firehose Stream. Only Supported for elasticsearch destination"
  value       = local.search_destination_vpc_create_firehose_sg ? aws_security_group.firehose.id : null
}

output "firehose_security_group_name" {
  description = "Security Group Name associated to Firehose Stream. Only Supported for elasticsearch destination"
  value       = local.search_destination_vpc_create_firehose_sg ? aws_security_group.firehose.name : null
}

output "destination_security_group_id" {
  description = "Security Group ID associated to destination"
  value       = local.vpc_create_destination_group ? aws_security_group.destination.id : null
}

output "destination_security_group_name" {
  description = "Security Group Name associated to destination"
  value       = local.vpc_create_destination_group ? aws_security_group.destination.name : null
}

output "firehose_security_group_rule_ids" {
  description = "Security Group Rules IDs created in Firehose Stream Security group. Only supported for elasticsearch/opensearch destination"
  value       = local.search_destination_vpc_configure_existing_firehose_sg ? (var.vpc_security_group_same_as_destination ? [for k, v in aws_vpc_security_group_ingress_rule.firehose_existing_self : v.id] : [for k, v in aws_vpc_security_group_egress_rule.firehose_existing_egress : v.id]) : null
}

output "destination_security_group_rule_ids" {
  description = "Security Group Rules IDs created in Destination Security group"
  value       = local.vpc_configure_destination_group ? (local.is_search_destination ? { for k, v in aws_vpc_security_group_ingress_rule.destination_existing_from_sg : k => v.id } : { for k, v in aws_vpc_security_group_ingress_rule.destination_existing_from_cidr : k => v.id }) : null
}

output "firehose_cidr_blocks" {
  description = "Firehose stream cidr blocks to unblock on destination security group"
  value       = contains(["splunk", "redshift"], local.destination) ? local.firehose_cidr_blocks[local.destination][data.aws_region.current.region] : null
}
