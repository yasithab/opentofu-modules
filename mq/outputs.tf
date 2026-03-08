################################################################################
# Broker
################################################################################

output "arn" {
  description = "The ARN of the broker"
  value       = aws_mq_broker.this.arn
}

output "id" {
  description = "The ID of the broker"
  value       = aws_mq_broker.this.id
}

output "instances" {
  description = "List of information about allocated brokers (if deployment_mode is CLUSTER_MULTI_AZ)"
  value       = aws_mq_broker.this.instances
}

output "primary_ip_address" {
  description = "The IP Address of the broker"
  value       = try(aws_mq_broker.this.instances[0].ip_address, null)
}

output "primary_console_url" {
  description = "The URL of the broker's ActiveMQ Web Console"
  value       = try(aws_mq_broker.this.instances[0].console_url, null)
}

output "primary_endpoints" {
  description = "The broker's wire-level protocol endpoints"
  value       = try(aws_mq_broker.this.instances[0].endpoints, null)
}

output "configuration_revision" {
  description = "The revision of the broker configuration"
  value       = try(aws_mq_broker.this.configuration[0].revision, null)
}

output "configuration_id" {
  description = "The ID of the broker configuration"
  value       = try(aws_mq_broker.this.configuration[0].id, null)
}

################################################################################
# Security Groups
################################################################################

output "security_groups" {
  description = "The list of security groups assigned to the broker"
  value       = aws_mq_broker.this.security_groups
}

output "security_group_id" {
  description = "ID of the created security group (if created)"
  value       = var.create_security_group ? aws_security_group.this.id : null
}

output "security_group_arn" {
  description = "ARN of the created security group (if created)"
  value       = var.create_security_group ? aws_security_group.this.arn : null
}

output "security_group_name" {
  description = "Name of the created security group (if created)"
  value       = var.create_security_group ? aws_security_group.this.name : null
}

################################################################################
