output "security_group_arn" {
  description = "The ARN of the security group"
  value       = try(aws_security_group.this.arn, aws_security_group.this_name_prefix.arn, "")
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = try(aws_security_group.this.id, aws_security_group.this_name_prefix.id, "")
}

output "security_group_vpc_id" {
  description = "The VPC ID"
  value       = try(aws_security_group.this.vpc_id, aws_security_group.this_name_prefix.vpc_id, "")
}

output "security_group_owner_id" {
  description = "The owner ID"
  value       = try(aws_security_group.this.owner_id, aws_security_group.this_name_prefix.owner_id, "")
}

output "security_group_name" {
  description = "The name of the security group"
  value       = try(aws_security_group.this.name, aws_security_group.this_name_prefix.name, "")
}

output "security_group_description" {
  description = "The description of the security group"
  value       = try(aws_security_group.this.description, aws_security_group.this_name_prefix.description, "")
}

output "ingress_rule_ids" {
  description = "Map of created ingress rule IDs, keyed by composite rule key (e.g. \"https/ipv4/10.0.0.0/16\", \"app/sg\", \"intra/self\")"
  value       = try({ for k, rule in aws_vpc_security_group_ingress_rule.this : k => rule.security_group_rule_id }, {})
}

output "egress_rule_ids" {
  description = "Map of created egress rule IDs, keyed by composite rule key (e.g. \"all/ipv4/0.0.0.0/0\", \"endpoints/pl/pl-12345678\")"
  value       = try({ for k, rule in aws_vpc_security_group_egress_rule.this : k => rule.security_group_rule_id }, {})
}

output "ingress_rule_arns" {
  description = "Map of created ingress rule ARNs, keyed by composite rule key"
  value       = try({ for k, rule in aws_vpc_security_group_ingress_rule.this : k => rule.arn }, {})
}

output "egress_rule_arns" {
  description = "Map of created egress rule ARNs, keyed by composite rule key"
  value       = try({ for k, rule in aws_vpc_security_group_egress_rule.this : k => rule.arn }, {})
}
