################################################################################
# Resolver Rule(s)
################################################################################

output "resolver_rule_ids" {
  description = "Map of Route53 Resolver rule IDs"
  value       = { for k, v in aws_route53_resolver_rule.default : k => v.id }
}

output "resolver_rule_arns" {
  description = "Map of Route53 Resolver rule ARNs"
  value       = { for k, v in aws_route53_resolver_rule.default : k => v.arn }
}

output "resolver_rules" {
  description = "Map of Route53 Resolver rules created"
  value       = aws_route53_resolver_rule.default
}

################################################################################
# Resolver Rule Association(s)
################################################################################

output "resolver_rule_association_id" {
  description = "ID of Route53 Resolver rule associations"
  value       = { for k, v in aws_route53_resolver_rule_association.default : k => v.id }
}

output "resolver_rule_association_name" {
  description = "Name of Route53 Resolver rule associations"
  value       = { for k, v in aws_route53_resolver_rule_association.default : k => v.name }
}

output "resolver_rule_association_resolver_rule_id" {
  description = "ID of Route53 Resolver rule associations resolver rule"
  value       = { for k, v in aws_route53_resolver_rule_association.default : k => v.resolver_rule_id }
}
