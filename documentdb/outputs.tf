################################################################################
# Cluster
################################################################################

output "cluster_arn" {
  description = "The ARN of the DocumentDB cluster."
  value       = try(aws_docdb_cluster.this.arn, "")
}

output "cluster_id" {
  description = "The DocumentDB cluster identifier."
  value       = try(aws_docdb_cluster.this.id, "")
}

output "cluster_name" {
  description = "The cluster identifier (name)."
  value       = try(aws_docdb_cluster.this.cluster_identifier, "")
}

output "cluster_endpoint" {
  description = "The DNS address of the DocumentDB cluster (writer endpoint)."
  value       = try(aws_docdb_cluster.this.endpoint, "")
}

output "cluster_reader_endpoint" {
  description = "A read-only endpoint for the DocumentDB cluster, automatically load-balanced across replicas."
  value       = try(aws_docdb_cluster.this.reader_endpoint, "")
}

output "cluster_port" {
  description = "The port on which the cluster accepts connections."
  value       = try(aws_docdb_cluster.this.port, "")
}

output "cluster_resource_id" {
  description = "The resource ID of the DocumentDB cluster."
  value       = try(aws_docdb_cluster.this.cluster_resource_id, "")
}

output "cluster_master_username" {
  description = "The master username for the DocumentDB cluster."
  value       = try(aws_docdb_cluster.this.master_username, "")
  sensitive   = true
}

################################################################################
# Cluster Instances
################################################################################

output "cluster_instances" {
  description = "Map of cluster instances and their attributes."
  value       = aws_docdb_cluster_instance.this
  sensitive   = true
}

################################################################################
# Subnet Group
################################################################################

output "subnet_group_arn" {
  description = "The ARN of the DocumentDB subnet group."
  value       = try(aws_docdb_subnet_group.this.arn, "")
}

output "subnet_group_id" {
  description = "The name (ID) of the DocumentDB subnet group."
  value       = try(aws_docdb_subnet_group.this.id, "")
}

################################################################################
# Parameter Group
################################################################################

output "cluster_parameter_group_arn" {
  description = "The ARN of the DocumentDB cluster parameter group."
  value       = try(aws_docdb_cluster_parameter_group.this.arn, "")
}

output "cluster_parameter_group_id" {
  description = "The name (ID) of the DocumentDB cluster parameter group."
  value       = try(aws_docdb_cluster_parameter_group.this.id, "")
}

################################################################################
# Security Group
################################################################################

output "security_group_id" {
  description = "The ID of the security group created for the DocumentDB cluster."
  value       = try(aws_security_group.this.id, "")
}

################################################################################
# CloudWatch Log Group
################################################################################

output "cloudwatch_log_group_arns" {
  description = "Map of CloudWatch log group names to ARNs."
  value       = { for k, v in aws_cloudwatch_log_group.this : k => v.arn }
}
