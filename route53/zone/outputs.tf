output "zone_id" {
  description = "Zone ID of Route53 zone"
  value       = { for k, v in aws_route53_zone.default : k => v.zone_id }
}

output "zone_arn" {
  description = "Zone ARN of Route53 zone"
  value       = { for k, v in aws_route53_zone.default : k => v.arn }
}

output "name_servers" {
  description = "Name servers of Route53 zone"
  value       = { for k, v in aws_route53_zone.default : k => v.name_servers }
}

output "zone_name" {
  description = "Name of Route53 zone"
  value       = { for k, v in aws_route53_zone.default : k => v.name }
}

output "static_zone_name" {
  description = "Name of Route53 zone created statically to avoid invalid count argument error when creating records and zones simmultaneously"
  value       = { for k, v in var.zones : k => lookup(v, "domain_name", k) if local.enabled }
}
