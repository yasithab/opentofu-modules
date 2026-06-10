output "id" {
  description = "The URL for the created Amazon SQS queue"
  value       = try(aws_sqs_queue.default.id, "")
}

output "arn" {
  description = "The ARN of the SQS queue"
  value       = try(aws_sqs_queue.default.arn, "")
}

output "dlq_id" {
  description = "The URL for the created dead letter queue"
  value       = try(aws_sqs_queue.deadletter.id, "")
}

output "dlq_arn" {
  description = "The ARN of the dead letter queue"
  value       = try(aws_sqs_queue.deadletter.arn, "")
}

output "name" {
  description = "The name of the SQS queue"
  value       = try(aws_sqs_queue.default.name, "")
}

output "url" {
  description = "The URL of the SQS queue"
  value       = try(aws_sqs_queue.default.url, "")
}

output "dlq_name" {
  description = "The name of the dead letter queue"
  value       = try(aws_sqs_queue.deadletter.name, "")
}

output "dlq_url" {
  description = "The URL of the dead letter queue"
  value       = try(aws_sqs_queue.deadletter.url, "")
}
