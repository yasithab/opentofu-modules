output "record_name" {
  description = "The name of the record"
  value       = { for k, v in aws_route53_record.default : k => v.name }
}

output "record_fqdn" {
  description = "FQDN built using the zone domain and name"
  value       = { for k, v in aws_route53_record.default : k => v.fqdn }
}

output "health_check_ids" {
  description = "Map of health check names to their IDs"
  value       = { for k, v in aws_route53_health_check.default : k => v.id }
}

output "health_check_arns" {
  description = "Map of health check names to their ARNs"
  value       = { for k, v in aws_route53_health_check.default : k => v.arn }
}
