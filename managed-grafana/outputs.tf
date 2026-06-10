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
# Service Accounts
################################################################################

output "service_accounts" {
  description = "Map of service account names to their attributes."
  value = {
    for k, v in aws_grafana_workspace_service_account.this : k => {
      id                 = v.id
      service_account_id = v.service_account_id
      grafana_role       = v.grafana_role
    }
  }
}

output "service_account_tokens" {
  description = "Map of service account token keys (service_account/token) to their attributes, including the secret token key."
  value = {
    for k, v in aws_grafana_workspace_service_account_token.this : k => {
      id         = v.id
      key        = v.key
      created_at = v.created_at
      expires_at = v.expires_at
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
