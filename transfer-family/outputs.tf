################################################################################
# Server
################################################################################

output "server_arn" {
  description = "The ARN of the Transfer Family server."
  value       = try(aws_transfer_server.this.arn, "")
}

output "server_id" {
  description = "The ID of the Transfer Family server."
  value       = try(aws_transfer_server.this.id, "")
}

output "server_name" {
  description = "The name of the Transfer Family server."
  value       = try(var.name, "")
}

output "server_endpoint" {
  description = "The endpoint of the Transfer Family server."
  value       = try(aws_transfer_server.this.endpoint, "")
}

output "server_host_key_fingerprint" {
  description = "The host key fingerprint of the Transfer Family server."
  value       = try(aws_transfer_server.this.host_key_fingerprint, "")
}

################################################################################
# Users
################################################################################

output "user_arns" {
  description = "Map of Transfer Family user ARNs."
  value       = { for k, v in aws_transfer_user.this : k => try(v.arn, "") }
}

output "user_names" {
  description = "Map of Transfer Family user names."
  value       = { for k, v in aws_transfer_user.this : k => try(v.user_name, "") }
}

################################################################################
# Workflows
################################################################################

output "workflow_ids" {
  description = "Map of Transfer Family workflow IDs."
  value       = { for k, v in aws_transfer_workflow.this : k => try(v.id, "") }
}

output "workflow_arns" {
  description = "Map of Transfer Family workflow ARNs."
  value       = { for k, v in aws_transfer_workflow.this : k => try(v.arn, "") }
}

################################################################################
# Route53
################################################################################

output "route53_record_fqdns" {
  description = "Map of Route53 record FQDNs for custom hostnames."
  value       = { for k, v in aws_route53_record.this : k => try(v.fqdn, "") }
}

################################################################################
# IAM
################################################################################

output "logging_role_arn" {
  description = "The ARN of the Transfer Family logging IAM role."
  value       = try(aws_iam_role.logging.arn, "")
}
