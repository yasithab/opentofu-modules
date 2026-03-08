################################################################################
# Group
################################################################################

output "group_arn" {
  description = "The ARN that identifies the user group"
  value       = try(aws_elasticache_user_group.this.arn, null)
}

output "group_id" {
  description = "The user group identifier"
  value       = try(aws_elasticache_user_group.this.id, null)
}

################################################################################
# User(s)
################################################################################

output "users" {
  description = "A map of users created and their attributes"
  value       = aws_elasticache_user.this
}
