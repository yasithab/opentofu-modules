################################################################################
# Cluster
################################################################################

output "cluster_arn" {
  description = "The ARN of the ElastiCache Cluster"
  value       = try(aws_elasticache_cluster.this.arn, null)
}

output "cluster_engine_version_actual" {
  description = "Because ElastiCache pulls the latest minor or patch for a version, this attribute returns the running version of the cache engine"
  value       = try(aws_elasticache_cluster.this.engine_version_actual, null)
}

output "cluster_cache_nodes" {
  description = "List of node objects including `id`, `address`, `port` and `availability_zone`"
  value       = try(aws_elasticache_cluster.this.cache_nodes, null)
}

output "cluster_address" {
  description = "(Memcached only) DNS name of the cache cluster without the port appended"
  value       = try(aws_elasticache_cluster.this.cluster_address, null)
}

output "cluster_configuration_endpoint" {
  description = "(Memcached only) Configuration endpoint to allow host discovery"
  value       = try(aws_elasticache_cluster.this.configuration_endpoint, null)
}

################################################################################
# Replication Group
################################################################################

output "replication_group_arn" {
  description = "ARN of the created ElastiCache Replication Group"
  value       = try(aws_elasticache_replication_group.this.arn, aws_elasticache_replication_group.global.arn, null)
}

output "replication_group_engine_version_actual" {
  description = "Because ElastiCache pulls the latest minor or patch for a version, this attribute returns the running version of the cache engine"
  value       = try(aws_elasticache_replication_group.this.engine_version_actual, aws_elasticache_replication_group.global.engine_version_actual, null)
}

output "replication_group_configuration_endpoint_address" {
  description = "Address of the replication group configuration endpoint when cluster mode is enabled"
  value       = try(aws_elasticache_replication_group.this.configuration_endpoint_address, aws_elasticache_replication_group.global.configuration_endpoint_address, null)
}

output "replication_group_id" {
  description = "ID of the ElastiCache Replication Group"
  value       = try(aws_elasticache_replication_group.this.id, aws_elasticache_replication_group.global.id, null)
}

output "replication_group_member_clusters" {
  description = "Identifiers of all the nodes that are part of this replication group"
  value       = try(aws_elasticache_replication_group.this.member_clusters, aws_elasticache_replication_group.global.member_clusters, null)
}

output "replication_group_primary_endpoint_address" {
  description = "Address of the endpoint for the primary node in the replication group, if the cluster mode is disabled"
  value       = try(aws_elasticache_replication_group.this.primary_endpoint_address, aws_elasticache_replication_group.global.primary_endpoint_address, null)
}

output "replication_group_reader_endpoint_address" {
  description = "Address of the endpoint for the reader node in the replication group, if the cluster mode is disabled"
  value       = try(aws_elasticache_replication_group.this.reader_endpoint_address, aws_elasticache_replication_group.global.reader_endpoint_address, null)
}

################################################################################
# Global Replication Group
################################################################################

output "global_replication_group_id" {
  description = "ID of the ElastiCache Global Replication Group"
  value       = try(aws_elasticache_global_replication_group.this.id, null)
}

output "global_replication_group_arn" {
  description = "ARN of the created ElastiCache Global Replication Group"
  value       = try(aws_elasticache_global_replication_group.this.arn, null)
}

output "global_replication_group_engine_version_actual" {
  description = "The full version number of the cache engine running on the members of this global replication group"
  value       = try(aws_elasticache_global_replication_group.this.engine_version_actual, null)
}

output "global_replication_group_node_groups" {
  description = "Set of node groups (shards) on the global replication group"
  value       = try(aws_elasticache_global_replication_group.this.global_node_groups, null)
}

################################################################################
# CloudWatch Log Group
################################################################################

output "cloudwatch_log_groups" {
  description = "Map of CloudWatch log groups created and their attributes, keyed by log delivery configuration key"
  value       = { for k, v in aws_cloudwatch_log_group.this : k => { name = v.name, arn = v.arn } }
}

################################################################################
# Parameter Group
################################################################################

output "parameter_group_arn" {
  description = "The AWS ARN associated with the parameter group"
  value       = try(aws_elasticache_parameter_group.this.arn, null)
}

output "parameter_group_id" {
  description = "The ElastiCache parameter group name"
  value       = try(aws_elasticache_parameter_group.this.id, null)
}

################################################################################
# Subnet Group
################################################################################

output "subnet_group_name" {
  description = "The ElastiCache subnet group name"
  value       = try(aws_elasticache_subnet_group.this.name, null)
}

################################################################################
# Security Group
################################################################################

output "security_group_arn" {
  description = "Amazon Resource Name (ARN) of the security group"
  value       = try(aws_security_group.this.arn, null)
}

output "security_group_id" {
  description = "ID of the security group"
  value       = try(aws_security_group.this.id, null)
}
