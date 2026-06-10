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

output "key_signing_key_ds_record" {
  description = "Map of zone keys to the DS record to add to the parent zone to establish the DNSSEC chain of trust"
  value       = { for k, v in aws_route53_key_signing_key.this : k => v.ds_record }
}

output "key_signing_key_tag" {
  description = "Map of zone keys to the key signing key tag"
  value       = { for k, v in aws_route53_key_signing_key.this : k => v.key_tag }
}

output "key_signing_key_public_key" {
  description = "Map of zone keys to the key signing key public key"
  value       = { for k, v in aws_route53_key_signing_key.this : k => v.public_key }
}

output "dnssec_signing_status" {
  description = "Map of zone keys to the DNSSEC signing status of the hosted zone"
  value       = { for k, v in aws_route53_hosted_zone_dnssec.this : k => v.signing_status }
}

output "query_log_ids" {
  description = "Map of zone keys to the Route53 query log configuration IDs"
  value       = { for k, v in aws_route53_query_log.this : k => v.id }
}

output "query_log_group_arns" {
  description = "Map of zone keys to the ARNs of module-created query log CloudWatch log groups"
  value       = { for k, v in aws_cloudwatch_log_group.query_log : k => v.arn }
}
