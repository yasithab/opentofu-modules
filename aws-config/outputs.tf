output "configuration_recorder_id" {
  description = "The name (ID) of the AWS Config configuration recorder."
  value       = try(aws_config_configuration_recorder.this.id, "")
}

output "delivery_channel_id" {
  description = "The name (ID) of the AWS Config delivery channel."
  value       = try(aws_config_delivery_channel.this.id, "")
}

output "iam_role_arn" {
  description = "ARN of the IAM role used by the configuration recorder (created or provided)."
  value       = try(aws_iam_role.config[0].arn, coalesce(var.iam_role_arn, ""))
}

output "iam_role_name" {
  description = "Name of the IAM role used by the configuration recorder. Empty when an external role is supplied."
  value       = try(aws_iam_role.config[0].name, "")
}

output "managed_config_rule_arns" {
  description = "Map of managed Config rule name to ARN."
  value       = { for k, v in aws_config_config_rule.managed : k => v.arn }
}

output "custom_config_rule_arns" {
  description = "Map of custom Config rule name to ARN."
  value       = { for k, v in aws_config_config_rule.custom : k => v.arn }
}

output "custom_policy_config_rule_arns" {
  description = "Map of custom policy (Guard-backed) Config rule name to ARN."
  value       = { for k, v in aws_config_config_rule.custom_policy : k => v.arn }
}

output "configuration_aggregator_arn" {
  description = "ARN of the configuration aggregator. Empty when create_aggregator is false."
  value       = try(aws_config_configuration_aggregator.this.arn, "")
}

output "configuration_aggregator_id" {
  description = "ID of the configuration aggregator. Empty when create_aggregator is false."
  value       = try(aws_config_configuration_aggregator.this.id, "")
}

output "configuration_aggregator_authorization_id" {
  description = "ID of the aggregator authorization created in this (child) account. Empty when create_aggregator_authorization is false."
  value       = try(aws_config_aggregate_authorization.this.id, "")
}
