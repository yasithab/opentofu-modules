################################################################################
# Encryption Configuration
################################################################################

output "encryption_config_id" {
  description = "Identifier of the X-Ray encryption configuration."
  value       = try(aws_xray_encryption_config.this.id, "")
}

output "encryption_config_key_id" {
  description = "KMS key ID used for X-Ray trace encryption."
  value       = try(aws_xray_encryption_config.this.key_id, "")
}

################################################################################
# Sampling Rules
################################################################################

output "sampling_rule_arns" {
  description = "Map of sampling rule names to their ARNs."
  value = {
    for k, v in aws_xray_sampling_rule.this : k => v.arn
  }
}

output "sampling_rule_names" {
  description = "Map of sampling rule keys to their names."
  value = {
    for k, v in aws_xray_sampling_rule.this : k => v.rule_name
  }
}

################################################################################
# Groups
################################################################################

output "group_arns" {
  description = "Map of group names to their ARNs."
  value = {
    for k, v in aws_xray_group.this : k => v.arn
  }
}

output "group_names" {
  description = "Map of group keys to their names."
  value = {
    for k, v in aws_xray_group.this : k => v.group_name
  }
}

################################################################################
# Resource Policies
################################################################################

output "resource_policy_names" {
  description = "Map of resource policy keys to their names."
  value = {
    for k, v in aws_xray_resource_policy.this : k => v.policy_name
  }
}

################################################################################
