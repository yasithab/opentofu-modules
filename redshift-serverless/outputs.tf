output "namespace_name" {
  value       = try(aws_redshiftserverless_namespace.this.id, "")
  description = "The Redshift Namespace Name."
}

output "namespace_id" {
  value       = try(aws_redshiftserverless_namespace.this.namespace_id, "")
  description = "The Redshift Namespace ID."
}

output "namespace_arn" {
  value       = try(aws_redshiftserverless_namespace.this.arn, "")
  description = "The Redshift Namespace ID."
}

output "workgroup_name" {
  value       = try(aws_redshiftserverless_workgroup.this.id, "")
  description = "The Redshift Workgroup Name."
}

output "workgroup_id" {
  value       = try(aws_redshiftserverless_workgroup.this.id, "")
  description = "The Redshift Workgroup ID."
}

output "workgroup_arn" {
  value       = try(aws_redshiftserverless_workgroup.this.arn, "")
  description = "Amazon Resource Name (ARN) of the Redshift Serverless Workgroup."
}

output "endpoint_address" {
  value       = try(aws_redshiftserverless_workgroup.this.endpoint[0].address, null)
  description = "The DNS address of the workgroup endpoint"
}

output "limit_id" {
  value       = try(aws_redshiftserverless_usage_limit.this.id, "")
  description = "The Redshift Usage Limit id."
}

output "limit_arn" {
  value       = try(aws_redshiftserverless_usage_limit.this.arn, "")
  description = "Amazon Resource Name (ARN) of the Redshift Serverless Usage Limit."
}

output "endpoint_access_arn" {
  value       = try(aws_redshiftserverless_endpoint_access.this.arn, "")
  description = "Amazon Resource Name (ARN) of the Redshift Serverless Endpoint Access."
}

output "endpoint_access_name" {
  value       = try(aws_redshiftserverless_endpoint_access.this.id, "")
  description = "Amazon Resource Name (ARN) of the Redshift Serverless Endpoint Access."
}

output "vpc_endpoint" {
  value       = try(aws_redshiftserverless_endpoint_access.this.vpc_endpoint, null)
  description = "The VPC endpoint or the Redshift Serverless workgroup"
}

output "vpc_endpoint_address" {
  value       = try(aws_redshiftserverless_endpoint_access.this.address, null)
  description = "The DNS address of the VPC endpoint"
}

output "snapshot_name" {
  value       = try(aws_redshiftserverless_snapshot.this.id, null)
  description = "The name of the snapshot."
}

output "snapshot_admin_username" {
  value       = try(aws_redshiftserverless_snapshot.this.admin_username, null)
  description = "The username of the database within a snapshot."
}

output "snapshot_namespace_arn" {
  value       = try(aws_redshiftserverless_snapshot.this.namespace_arn, null)
  description = "The Amazon Resource Name (ARN) of the namespace the snapshot was created from."
}

output "snapshot_arn" {
  value       = try(aws_redshiftserverless_snapshot.this.arn, null)
  description = "The Amazon Resource Name (ARN) of the namespace the snapshot was created from."
}

output "snapshot_accounts_with_restore_access" {
  value       = try(aws_redshiftserverless_snapshot.this.accounts_with_restore_access, null)
  description = "All of the Amazon Web Services accounts that have access to restore a snapshot to a namespace."
}

output "snapshot_owner_account" {
  value       = try(aws_redshiftserverless_snapshot.this.owner_account, null)
  description = "The owner Amazon Web Services; account of the snapshot."
}
