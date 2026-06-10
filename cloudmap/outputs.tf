output "namespace_id" {
  description = "ID of the namespace in use (created or existing)"
  value       = local.namespace_id
}

output "namespace_arn" {
  description = "ARN of the created namespace"
  value = try(coalesce(
    try(aws_service_discovery_private_dns_namespace.this.arn, null),
    try(aws_service_discovery_public_dns_namespace.this.arn, null),
    try(aws_service_discovery_http_namespace.this.arn, null),
  ), null)
}

output "namespace_name" {
  description = "Name of the created namespace"
  value = try(coalesce(
    try(aws_service_discovery_private_dns_namespace.this.name, null),
    try(aws_service_discovery_public_dns_namespace.this.name, null),
    try(aws_service_discovery_http_namespace.this.name, null),
  ), null)
}

output "services" {
  description = "Map of created services with their details"
  value = {
    for k, v in aws_service_discovery_service.services : k => {
      id   = v.id
      arn  = v.arn
      name = v.name
    }
  }
}

output "service_arns" {
  description = "Map of service names to their ARNs for ECS integration"
  value = {
    for k, v in aws_service_discovery_service.services : k => v.arn
  }
}

output "ecs_service_discovery_role_arn" {
  description = "ARN of the ECS service discovery IAM role"
  value       = try(aws_iam_role.ecs_service_discovery.arn, null)
}

output "ecs_service_discovery_role_name" {
  description = "Name of the ECS service discovery IAM role"
  value       = try(aws_iam_role.ecs_service_discovery.name, null)
}

output "lambda_instance_id" {
  description = "ID of the registered Lambda instance in CloudMap"
  value       = try(aws_service_discovery_instance.lambda[local.lambda_service_key].instance_id, null)
}

output "lambda_service_id" {
  description = "ID of the CloudMap service where Lambda is registered"
  value       = try(aws_service_discovery_instance.lambda[local.lambda_service_key].service_id, null)
}

output "lambda_discovery_url" {
  description = "CloudMap discovery URL for the Lambda function"
  value = local.create_lambda_instance && local.dns_namespace ? try(
    "${var.lambda_instance_id}.${aws_service_discovery_service.services[local.lambda_service_key].name}.${local.name}",
    null
  ) : null
}
