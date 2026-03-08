output "security_group_arn" {
  description = "The ARN of the security group"
  value       = try(aws_security_group.this.arn, aws_security_group.this_name_prefix.arn, "")
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = try(aws_security_group.this.id, aws_security_group.this_name_prefix.id, "")
}

output "security_group_vpc_id" {
  description = "The VPC ID"
  value       = try(aws_security_group.this.vpc_id, aws_security_group.this_name_prefix.vpc_id, "")
}

output "security_group_owner_id" {
  description = "The owner ID"
  value       = try(aws_security_group.this.owner_id, aws_security_group.this_name_prefix.owner_id, "")
}

output "security_group_name" {
  description = "The name of the security group"
  value       = try(aws_security_group.this.name, aws_security_group.this_name_prefix.name, "")
}

output "security_group_description" {
  description = "The description of the security group"
  value       = try(aws_security_group.this.description, aws_security_group.this_name_prefix.description, "")
}
