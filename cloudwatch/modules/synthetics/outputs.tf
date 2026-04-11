################################################################################
# Canaries
################################################################################

output "canary_arns" {
  description = "Map of canary keys to their ARNs."
  value = {
    for k, v in aws_synthetics_canary.this : k => v.arn
  }
}

output "canary_ids" {
  description = "Map of canary keys to their IDs."
  value = {
    for k, v in aws_synthetics_canary.this : k => v.id
  }
}

output "canary_names" {
  description = "Map of canary keys to their names."
  value = {
    for k, v in aws_synthetics_canary.this : k => v.name
  }
}

output "canary_source_location_arns" {
  description = "Map of canary keys to the ARN of the Lambda layer containing the canary script source."
  value = {
    for k, v in aws_synthetics_canary.this : k => try(v.source_location_arn, "")
  }
}

output "canary_engine_arns" {
  description = "Map of canary keys to the ARN of the Lambda function that runs the canary."
  value = {
    for k, v in aws_synthetics_canary.this : k => try(v.engine_arn, "")
  }
}

################################################################################
# Canary Groups
################################################################################

output "canary_group_ids" {
  description = "Map of canary group names to their IDs."
  value = {
    for k, v in aws_synthetics_group.this : k => v.id
  }
}

output "canary_group_arns" {
  description = "Map of canary group names to their ARNs."
  value = {
    for k, v in aws_synthetics_group.this : k => v.arn
  }
}

################################################################################
# S3 Artifact Bucket
################################################################################

output "artifact_bucket_arn" {
  description = "ARN of the S3 bucket used for canary artifacts."
  value       = try(aws_s3_bucket.artifacts.arn, "")
}

output "artifact_bucket_id" {
  description = "ID (name) of the S3 bucket used for canary artifacts."
  value       = try(aws_s3_bucket.artifacts.id, "")
}

################################################################################
# IAM Role
################################################################################

output "iam_role_arn" {
  description = "ARN of the IAM execution role used by the canaries."
  value       = try(aws_iam_role.this.arn, "")
}

output "iam_role_name" {
  description = "Name of the IAM execution role used by the canaries."
  value       = try(aws_iam_role.this.name, "")
}

################################################################################
# CloudWatch Alarms
################################################################################

output "alarm_arns" {
  description = "Map of canary keys to their CloudWatch alarm ARNs."
  value = {
    for k, v in aws_cloudwatch_metric_alarm.canary : k => v.arn
  }
}

################################################################################
