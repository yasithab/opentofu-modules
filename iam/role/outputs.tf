output "name" {
  value       = try(aws_iam_role.default.name, "")
  description = "The name of the IAM role created"
}

output "id" {
  value       = try(aws_iam_role.default.unique_id, "")
  description = "The stable and unique string identifying the role"
}

output "arn" {
  value       = try(aws_iam_role.default.arn, "")
  description = "The Amazon Resource Name (ARN) specifying the role"
}

output "policy" {
  value       = join("", data.aws_iam_policy_document.default[*].json)
  description = "Role policy document in json format. Outputs always, independent of `enabled` variable"
}

output "instance_profile" {
  description = "Name of the ec2 profile (if enabled)"
  value       = try(aws_iam_instance_profile.default.name, "")
}

output "create_date" {
  description = "The creation date of the IAM role"
  value       = try(aws_iam_role.default.create_date, "")
}

output "instance_profile_arn" {
  description = "ARN of the EC2 instance profile (if enabled)"
  value       = try(aws_iam_instance_profile.default.arn, "")
}

output "instance_profile_unique_id" {
  description = "Unique ID of the EC2 instance profile (if enabled)"
  value       = try(aws_iam_instance_profile.default.unique_id, "")
}
