################################################################################
# Accelerator
################################################################################

output "accelerator_arn" {
  description = "The ARN of the Global Accelerator."
  value = try(
    aws_globalaccelerator_accelerator.this.id,
    aws_globalaccelerator_custom_routing_accelerator.this.id,
    ""
  )
}

output "accelerator_id" {
  description = "The ID of the Global Accelerator."
  value = try(
    aws_globalaccelerator_accelerator.this.id,
    aws_globalaccelerator_custom_routing_accelerator.this.id,
    ""
  )
}

output "accelerator_name" {
  description = "The name of the Global Accelerator."
  value = try(
    aws_globalaccelerator_accelerator.this.name,
    aws_globalaccelerator_custom_routing_accelerator.this.name,
    ""
  )
}

output "accelerator_dns_name" {
  description = "The DNS name of the Global Accelerator."
  value = try(
    aws_globalaccelerator_accelerator.this.dns_name,
    aws_globalaccelerator_custom_routing_accelerator.this.dns_name,
    ""
  )
}

output "accelerator_hosted_zone_id" {
  description = "The Route 53 hosted zone ID for the Global Accelerator."
  value = try(
    aws_globalaccelerator_accelerator.this.hosted_zone_id,
    ""
  )
}

output "accelerator_ip_sets" {
  description = "The IP address sets associated with the Global Accelerator."
  value = try(
    aws_globalaccelerator_accelerator.this.ip_sets,
    aws_globalaccelerator_custom_routing_accelerator.this.ip_sets,
    []
  )
}

################################################################################
# Listeners
################################################################################

output "listener_ids" {
  description = "Map of listener IDs."
  value       = { for k, v in aws_globalaccelerator_listener.this : k => try(v.id, "") }
}

################################################################################
# Endpoint Groups
################################################################################

output "endpoint_group_ids" {
  description = "Map of endpoint group IDs."
  value       = { for k, v in aws_globalaccelerator_endpoint_group.this : k => try(v.id, "") }
}

output "endpoint_group_arns" {
  description = "Map of endpoint group ARNs."
  value       = { for k, v in aws_globalaccelerator_endpoint_group.this : k => try(v.arn, "") }
}

################################################################################
# Custom Routing
################################################################################

output "custom_routing_listener_ids" {
  description = "Map of custom routing listener IDs."
  value       = { for k, v in aws_globalaccelerator_custom_routing_listener.this : k => try(v.id, "") }
}

output "custom_routing_endpoint_group_ids" {
  description = "Map of custom routing endpoint group IDs."
  value       = { for k, v in aws_globalaccelerator_custom_routing_endpoint_group.this : k => try(v.id, "") }
}
