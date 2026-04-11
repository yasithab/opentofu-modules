output "dashboard_arn" {
  description = "ARN of the CloudWatch dashboard."
  value       = try(aws_cloudwatch_dashboard.this.dashboard_arn, "")
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard."
  value       = try(aws_cloudwatch_dashboard.this.dashboard_name, "")
}
