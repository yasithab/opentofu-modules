output "connection_arn" {
  description = "ARN of the codeconnections connection"
  value       = try(aws_codeconnections_connection.this.arn, null)
}

output "connection_id" {
  description = "ARN of the codeconnections connection (id is deprecated; arn is the canonical identifier)"
  value       = try(aws_codeconnections_connection.this.arn, null)
}

output "connection_status" {
  description = "Status of the codeconnections connection"
  value       = try(aws_codeconnections_connection.this.connection_status, null)
}

output "host_arn" {
  description = "ARN of the codeconnections host"
  value       = try(aws_codeconnections_host.this.arn, null)
}

output "host_id" {
  description = "ARN of the codeconnections host (id is deprecated; arn is the canonical identifier)"
  value       = try(aws_codeconnections_host.this.arn, null)
}

