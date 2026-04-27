output "configuration_recorder_id" {
  description = "The name (ID) of the AWS Config configuration recorder."
  value       = local.enabled ? aws_config_configuration_recorder.this.id : null
}

output "delivery_channel_id" {
  description = "The name (ID) of the AWS Config delivery channel."
  value       = local.enabled && var.delivery_channel_s3_bucket_name != null ? aws_config_delivery_channel.this.id : null
}

output "iam_role_arn" {
  description = "ARN of the IAM role used by the configuration recorder (created or provided)."
  value       = local.create_iam_role ? aws_iam_role.config[0].arn : var.iam_role_arn
}

output "iam_role_name" {
  description = "Name of the IAM role used by the configuration recorder (created or provided)."
  value       = local.create_iam_role ? aws_iam_role.config[0].name : null
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
  description = "ARN of the configuration aggregator. Null when create_aggregator is false."
  value       = local.enabled && var.create_aggregator ? aws_config_configuration_aggregator.this.arn : null
}

output "configuration_aggregator_id" {
  description = "ID of the configuration aggregator. Null when create_aggregator is false."
  value       = local.enabled && var.create_aggregator ? aws_config_configuration_aggregator.this.id : null
}

output "configuration_aggregator_authorization_id" {
  description = "ID of the aggregator authorization created in this (child) account. Null when create_aggregator_authorization is false."
  value       = local.create_aggregator_auth ? aws_config_aggregate_authorization.this.id : null
}
