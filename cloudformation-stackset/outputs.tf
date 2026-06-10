################################################################################
# StackSet Outputs
################################################################################

output "stackset_id" {
  description = "ID of the StackSet"
  value       = try(aws_cloudformation_stack_set.this.id, "")
}

output "stackset_name" {
  description = "Name of the StackSet"
  value       = try(aws_cloudformation_stack_set.this.name, "")
}

output "stackset_arn" {
  description = "ARN of the StackSet"
  value       = try(aws_cloudformation_stack_set.this.arn, "")
}

output "stack_set_id" {
  description = "Unique identifier of the StackSet"
  value       = try(aws_cloudformation_stack_set.this.stack_set_id, "")
}

################################################################################
# Instance Outputs
################################################################################

output "instance_ids" {
  description = "Map of deployment key to stack instance IDs"
  value = {
    for key, instance in aws_cloudformation_stack_set_instance.this : key => instance.id
  }
}

output "instance_stack_ids" {
  description = "Map of deployment key to CloudFormation stack IDs in target accounts"
  value = {
    for key, instance in aws_cloudformation_stack_set_instance.this : key => instance.stack_id
  }
}

################################################################################
