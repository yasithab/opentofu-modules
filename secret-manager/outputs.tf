################################################################################
# Secret
################################################################################

output "secret_arn" {
  description = "The ARN of the secret"
  value       = try(aws_secretsmanager_secret.this.arn, null)
}

output "secret_id" {
  description = "The ID of the secret"
  value       = try(aws_secretsmanager_secret.this.id, null)
}

output "secret_name" {
  description = "The name of the secret"
  value       = try(aws_secretsmanager_secret.this.name, null)
}

output "secret_replica" {
  description = "Attributes of the replica created"
  value       = try(aws_secretsmanager_secret.this.replica, null)
}

output "secret_string" {
  description = "The secret string"
  sensitive   = true
  value       = try(aws_secretsmanager_secret_version.this.secret_string, aws_secretsmanager_secret_version.ignore_changes.secret_string, null)
}

output "secret_binary" {
  description = "The secret binary"
  sensitive   = true
  value       = try(aws_secretsmanager_secret_version.this.secret_binary, aws_secretsmanager_secret_version.ignore_changes.secret_binary, null)
}

################################################################################
# Version
################################################################################

output "secret_version_id" {
  description = "The unique identifier of the version of the secret"
  value       = try(aws_secretsmanager_secret_version.this.version_id, aws_secretsmanager_secret_version.ignore_changes.version_id, null)
}
