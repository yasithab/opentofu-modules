################################################################################
# Workspace
################################################################################

output "workspace_arn" {
  description = "Amazon Resource Name (ARN) of the Grafana workspace."
  value       = try(aws_grafana_workspace.this.arn, "")
}

output "workspace_id" {
  description = "Identifier of the Grafana workspace."
  value       = try(aws_grafana_workspace.this.id, "")
}

output "workspace_name" {
  description = "Name of the Grafana workspace."
  value       = try(aws_grafana_workspace.this.name, "")
}

output "workspace_endpoint" {
  description = "Endpoint URL of the Grafana workspace."
  value       = try(aws_grafana_workspace.this.endpoint, "")
}

output "workspace_grafana_version" {
  description = "Grafana version deployed in the workspace."
  value       = try(aws_grafana_workspace.this.grafana_version, "")
}

################################################################################
# IAM Role
################################################################################

output "iam_role_arn" {
  description = "ARN of the IAM role used by the Grafana workspace."
  value       = try(aws_iam_role.this.arn, "")
}

output "iam_role_name" {
  description = "Name of the IAM role used by the Grafana workspace."
  value       = try(aws_iam_role.this.name, "")
}

################################################################################
# API Keys
################################################################################

output "api_keys" {
  description = "Map of API key names to their attributes."
  value = {
    for k, v in aws_grafana_workspace_api_key.this : k => {
      id  = v.id
      key = v.key
    }
  }
  sensitive = true
}

################################################################################
# License
################################################################################

output "license_type" {
  description = "License type associated with the workspace."
  value       = try(aws_grafana_license_association.this.license_type, "")
}

################################################################################
