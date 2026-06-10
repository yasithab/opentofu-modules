locals {
  written_parameters = merge(aws_ssm_parameter.default, aws_ssm_parameter.ignore_value_changes)

  # Single maps keyed by parameter name keep names, values, and ARNs aligned
  # (no compact(), which previously could shift lists out of alignment).
  parameter_value_map = merge(
    { for name, p in local.written_parameters : name => coalesce(p.value, p.insecure_value, "") },
    { for name, p in data.aws_ssm_parameter.read : name => p.value },
  )

  parameter_arn_map = merge(
    { for name, p in local.written_parameters : name => p.arn },
    { for name, p in data.aws_ssm_parameter.read : name => p.arn },
  )
}

output "names" {
  description = "A list of all of the parameter names"
  value       = keys(local.parameter_value_map)
}

output "values" {
  description = "A list of all of the parameter values, aligned with the `names` output"
  value       = values(local.parameter_value_map)
  sensitive   = true
}

output "map" {
  description = "A map of the names and values created"
  value       = local.parameter_value_map
  sensitive   = true
}

output "arn_map" {
  description = "A map of the names and ARNs created"
  value       = local.parameter_arn_map
}
