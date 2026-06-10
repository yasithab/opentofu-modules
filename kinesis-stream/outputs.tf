output "name" {
  description = "Name of the Kinesis stream."
  value       = try(aws_kinesis_stream.default.name, "")
}

output "shard_count" {
  description = "Number of shards provisioned."
  value       = try(aws_kinesis_stream.default.shard_count, null)
}

output "stream_arn" {
  description = "ARN of the Kinesis stream."
  value       = try(aws_kinesis_stream.default.arn, "")
}

output "consumers" {
  description = "List of consumers registered with Kinesis stream."
  value       = aws_kinesis_stream_consumer.default
}

output "resource_policy_id" {
  description = "ID of the Kinesis resource policy (the stream ARN it is attached to)."
  value       = try(aws_kinesis_resource_policy.default.id, "")
}
