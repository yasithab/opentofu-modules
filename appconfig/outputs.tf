################################################################################
# Application
################################################################################

output "application_id" {
  description = "The AppConfig application ID"
  value       = try(aws_appconfig_application.this.id, "")
}

output "application_arn" {
  description = "The ARN of the AppConfig application"
  value       = try(aws_appconfig_application.this.arn, "")
}

output "application_name" {
  description = "The name of the AppConfig application"
  value       = try(aws_appconfig_application.this.name, "")
}

################################################################################
# Environments
################################################################################

output "environment_ids" {
  description = "Map of environment keys to their IDs"
  value       = { for k, v in aws_appconfig_environment.this : k => v.environment_id }
}

output "environment_arns" {
  description = "Map of environment keys to their ARNs"
  value       = { for k, v in aws_appconfig_environment.this : k => v.arn }
}

output "environment_states" {
  description = "Map of environment keys to their states"
  value       = { for k, v in aws_appconfig_environment.this : k => v.state }
}

################################################################################
# Configuration Profiles
################################################################################

output "configuration_profile_ids" {
  description = "Map of configuration profile keys to their profile IDs"
  value       = { for k, v in aws_appconfig_configuration_profile.this : k => v.configuration_profile_id }
}

output "configuration_profile_arns" {
  description = "Map of configuration profile keys to their ARNs"
  value       = { for k, v in aws_appconfig_configuration_profile.this : k => v.arn }
}

################################################################################
# Hosted Configuration Versions
################################################################################

output "hosted_configuration_version_numbers" {
  description = "Map of hosted configuration version keys to their version numbers"
  value       = { for k, v in aws_appconfig_hosted_configuration_version.this : k => v.version_number }
}

output "hosted_configuration_version_arns" {
  description = "Map of hosted configuration version keys to their ARNs"
  value       = { for k, v in aws_appconfig_hosted_configuration_version.this : k => v.arn }
}

################################################################################
# Deployment Strategies
################################################################################

output "deployment_strategy_ids" {
  description = "Map of deployment strategy keys to their IDs"
  value       = { for k, v in aws_appconfig_deployment_strategy.this : k => v.id }
}

output "deployment_strategy_arns" {
  description = "Map of deployment strategy keys to their ARNs"
  value       = { for k, v in aws_appconfig_deployment_strategy.this : k => v.arn }
}

################################################################################
# Deployments
################################################################################

output "deployment_numbers" {
  description = "Map of deployment keys to their deployment numbers"
  value       = { for k, v in aws_appconfig_deployment.this : k => v.deployment_number }
}

output "deployment_states" {
  description = "Map of deployment keys to their states"
  value       = { for k, v in aws_appconfig_deployment.this : k => v.state }
}

################################################################################
# Extensions
################################################################################

output "extension_ids" {
  description = "Map of extension keys to their IDs"
  value       = { for k, v in aws_appconfig_extension.this : k => v.id }
}

output "extension_arns" {
  description = "Map of extension keys to their ARNs"
  value       = { for k, v in aws_appconfig_extension.this : k => v.arn }
}

output "extension_versions" {
  description = "Map of extension keys to their version numbers"
  value       = { for k, v in aws_appconfig_extension.this : k => v.version }
}

output "extension_association_ids" {
  description = "Map of extension association keys to their IDs"
  value       = { for k, v in aws_appconfig_extension_association.this : k => v.id }
}

output "extension_association_arns" {
  description = "Map of extension association keys to their ARNs"
  value       = { for k, v in aws_appconfig_extension_association.this : k => v.arn }
}
