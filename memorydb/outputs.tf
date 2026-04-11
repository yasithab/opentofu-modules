################################################################################
# Cluster
################################################################################

output "cluster_arn" {
  description = "The ARN of the MemoryDB cluster."
  value       = try(aws_memorydb_cluster.this.arn, "")
}

output "cluster_id" {
  description = "The name (ID) of the MemoryDB cluster."
  value       = try(aws_memorydb_cluster.this.id, "")
}

output "cluster_name" {
  description = "The name of the MemoryDB cluster."
  value       = try(aws_memorydb_cluster.this.name, "")
}

output "cluster_endpoint" {
  description = "The cluster endpoint address and port."
  value       = try(aws_memorydb_cluster.this.cluster_endpoint, "")
}

output "cluster_engine_version" {
  description = "The engine version of the MemoryDB cluster."
  value       = try(aws_memorydb_cluster.this.engine_version, "")
}

output "shards" {
  description = "Set of shards in this cluster."
  value       = try(aws_memorydb_cluster.this.shards, [])
}

################################################################################
# Subnet Group
################################################################################

output "subnet_group_arn" {
  description = "The ARN of the subnet group."
  value       = try(aws_memorydb_subnet_group.this.arn, "")
}

output "subnet_group_id" {
  description = "The name (ID) of the subnet group."
  value       = try(aws_memorydb_subnet_group.this.id, "")
}

################################################################################
# Parameter Group
################################################################################

output "parameter_group_arn" {
  description = "The ARN of the parameter group."
  value       = try(aws_memorydb_parameter_group.this.arn, "")
}

output "parameter_group_id" {
  description = "The name (ID) of the parameter group."
  value       = try(aws_memorydb_parameter_group.this.id, "")
}

################################################################################
# ACL
################################################################################

output "acl_arn" {
  description = "The ARN of the ACL."
  value       = try(aws_memorydb_acl.this.arn, "")
}

output "acl_id" {
  description = "The name (ID) of the ACL."
  value       = try(aws_memorydb_acl.this.id, "")
}

################################################################################
# Users
################################################################################

output "users" {
  description = "Map of created MemoryDB users and their attributes."
  value       = aws_memorydb_user.this
}
