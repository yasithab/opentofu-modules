###################################################
# Web ACL Outputs
###################################################

output "web_acl_id" {
  description = "The unique identifier of the Web ACL."
  value       = try(aws_wafv2_web_acl.this.id, "")
}

output "web_acl_arn" {
  description = "The ARN of the Web ACL. Use this ARN to associate the Web ACL with a CloudFront distribution, ALB, or API Gateway stage."
  value       = try(aws_wafv2_web_acl.this.arn, "")
}

output "web_acl_name" {
  description = "The name of the Web ACL."
  value       = try(aws_wafv2_web_acl.this.name, "")
}

output "web_acl_capacity" {
  description = "The web ACL capacity units (WCUs) currently used by this web ACL."
  value       = try(aws_wafv2_web_acl.this.capacity, null)
}

output "web_acl_application_integration_url" {
  description = "The URL to use in SDK integrations with managed rule groups (for CAPTCHA and challenge actions)."
  value       = try(aws_wafv2_web_acl.this.application_integration_url, "")
}

###################################################
# IP Set Outputs
###################################################

output "ip_set_arns" {
  description = "Map of IP set name to ARN for all IP sets created by this module."
  value       = { for k, v in aws_wafv2_ip_set.this : k => v.arn }
}

output "ip_set_ids" {
  description = "Map of IP set name to ID for all IP sets created by this module."
  value       = { for k, v in aws_wafv2_ip_set.this : k => v.id }
}

###################################################
# Regex Pattern Set Outputs
###################################################

output "regex_pattern_set_arns" {
  description = "Map of regex pattern set name to ARN for all sets created by this module."
  value       = { for k, v in aws_wafv2_regex_pattern_set.this : k => v.arn }
}

output "regex_pattern_set_ids" {
  description = "Map of regex pattern set name to ID for all sets created by this module."
  value       = { for k, v in aws_wafv2_regex_pattern_set.this : k => v.id }
}

###################################################
# Rule Group Outputs
###################################################

output "rule_group_arns" {
  description = "Map of rule group name to ARN for all rule groups created by this module."
  value       = { for k, v in aws_wafv2_rule_group.this : k => v.arn }
}

output "rule_group_ids" {
  description = "Map of rule group name to ID for all rule groups created by this module."
  value       = { for k, v in aws_wafv2_rule_group.this : k => v.id }
}

###################################################
# API Key Outputs
###################################################

output "api_keys" {
  description = "Map of API key name to api_key value for all API keys created by this module."
  sensitive   = true
  value       = { for k, v in aws_wafv2_api_key.this : k => v.api_key }
}

###################################################
# Association Outputs
###################################################

output "association_ids" {
  description = "Map of association name to resource ID for all Web ACL associations created by this module."
  value       = { for k, v in aws_wafv2_web_acl_association.this : k => v.id }
}

output "rule_group_association_ids" {
  description = "Map of rule group association name to resource ID for all rule group associations created by this module."
  value       = { for k, v in aws_wafv2_web_acl_rule_group_association.this : k => v.id }
}
