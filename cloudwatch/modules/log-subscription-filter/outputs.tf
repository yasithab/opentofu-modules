################################################################################
# Log Subscription Filter
################################################################################

output "subscription_filter_name" {
  description = "The name of the CloudWatch Log Subscription Filter."
  value       = try(aws_cloudwatch_log_subscription_filter.this.name, null)
}

output "subscription_filter_log_group_name" {
  description = "The name of the log group associated with the subscription filter."
  value       = try(aws_cloudwatch_log_subscription_filter.this.log_group_name, null)
}

output "subscription_filter_destination_arn" {
  description = "The ARN of the destination for the subscription filter."
  value       = try(aws_cloudwatch_log_subscription_filter.this.destination_arn, null)
}
