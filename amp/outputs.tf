################################################################################
# Workspace
################################################################################

output "workspace_arn" {
  description = "Amazon Resource Name (ARN) of the workspace"
  value       = try(aws_prometheus_workspace.this.arn, "")
}

output "workspace_id" {
  description = "Identifier of the workspace"
  value       = try(aws_prometheus_workspace.this.id, "")
}

output "workspace_prometheus_endpoint" {
  description = "Prometheus endpoint available for this workspace"
  value       = try(aws_prometheus_workspace.this.prometheus_endpoint, "")
}

################################################################################
# CloudWatch Log Group
################################################################################

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group created for workspace logging"
  value       = try(aws_cloudwatch_log_group.this.name, "")
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group created for workspace logging"
  value       = try(aws_cloudwatch_log_group.this.arn, "")
}

################################################################################
# Rule Group Namespaces
################################################################################

output "rule_group_namespaces" {
  description = "Map of rule group namespace keys to their attributes"
  value = {
    for k, v in aws_prometheus_rule_group_namespace.this : k => {
      id   = v.id
      arn  = v.arn
      name = v.name
    }
  }
}

################################################################################
# Scrapers
################################################################################

output "scraper_arns" {
  description = "Map of scraper names to ARNs"
  value = {
    for k, v in aws_prometheus_scraper.this : k => v.arn
  }
}

output "scraper_ids" {
  description = "Map of scraper names to IDs"
  value = {
    for k, v in aws_prometheus_scraper.this : k => v.id
  }
}

################################################################################
