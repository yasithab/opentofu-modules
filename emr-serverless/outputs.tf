output "application_arn" {
  description = "ARN of the EMR Serverless application"
  value       = try(aws_emrserverless_application.this.arn, "")
}

output "application_id" {
  description = "ID of the EMR Serverless application"
  value       = try(aws_emrserverless_application.this.id, "")
}

output "application_name" {
  description = "Name of the EMR Serverless application"
  value       = try(aws_emrserverless_application.this.name, "")
}

output "application_type" {
  description = "Type of the EMR Serverless application (Spark or Hive)"
  value       = try(aws_emrserverless_application.this.type, "")
}

output "execution_role_arn" {
  description = "ARN of the IAM execution role"
  value       = try(aws_iam_role.execution.arn, "")
}

output "execution_role_name" {
  description = "Name of the IAM execution role"
  value       = try(aws_iam_role.execution.name, "")
}
