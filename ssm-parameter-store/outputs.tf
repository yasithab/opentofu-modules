#######################
# SSM Parameter values
#######################

locals {
  # Only one of the two resources is enabled at a time; coalesce picks the
  # populated value. Sensitivity is preserved end-to-end (no nonsensitive()).
  stored_value = try(coalesce(
    try(aws_ssm_parameter.this.value, null),
    try(aws_ssm_parameter.ignore_value.value, null),
  ), null)
  stored_insecure_value = try(coalesce(
    try(aws_ssm_parameter.this.insecure_value, null),
    try(aws_ssm_parameter.ignore_value.insecure_value, null),
  ), null)
  raw_value = try(coalesce(local.stored_value, local.stored_insecure_value), null)
}

output "raw_value" {
  description = "Raw value of the parameter (as it is stored in SSM). Use 'value' output to get jsondecode'd value"
  value       = local.raw_value
  sensitive   = true
}

output "value" {
  description = "Parameter value after jsondecode(). Probably this is what you are looking for"
  value       = try(jsondecode(local.raw_value), local.raw_value)
  sensitive   = true
}

output "insecure_value" {
  description = "Insecure value of the parameter. Only populated for String type parameters; null for StringList and SecureString"
  value       = local.string_type ? nonsensitive(local.stored_insecure_value) : null
}

output "secure_value" {
  description = "Secure value of the parameter"
  value       = local.stored_value
  sensitive   = true
}

output "secure_type" {
  description = "Whether SSM parameter is a SecureString or not?"
  value       = local.secure_type
}

################
# SSM Parameter
################

output "ssm_parameter_arn" {
  description = "The ARN of the parameter"
  value       = try(aws_ssm_parameter.this.arn, aws_ssm_parameter.ignore_value.arn, null)
}

output "ssm_parameter_version" {
  description = "Version of the parameter"
  value       = try(aws_ssm_parameter.this.version, aws_ssm_parameter.ignore_value.version, null)
}

output "ssm_parameter_name" {
  description = "Name of the parameter"
  value       = try(aws_ssm_parameter.this.name, aws_ssm_parameter.ignore_value.name, null)
}

output "ssm_parameter_type" {
  description = "Type of the parameter"
  value       = try(aws_ssm_parameter.this.type, aws_ssm_parameter.ignore_value.type, null)
}

output "ssm_parameter_tags_all" {
  description = "All tags used for the parameter"
  value       = try(aws_ssm_parameter.this.tags_all, aws_ssm_parameter.ignore_value.tags_all, null)
}
