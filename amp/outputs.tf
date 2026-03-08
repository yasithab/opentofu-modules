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
