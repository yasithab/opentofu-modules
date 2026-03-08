output "namespace_id" {
  description = "ID of the created namespace"
  value       = local.namespace_id
}

output "namespace_arn" {
  description = "ARN of the created namespace"
  value = var.create_private_dns_namespace ? aws_service_discovery_private_dns_namespace.this.arn : (
    var.create_public_dns_namespace ? aws_service_discovery_public_dns_namespace.this.arn : (
      var.create_namespace ? aws_service_discovery_http_namespace.this.arn : null
    )
  )
}

output "namespace_name" {
  description = "Name of the created namespace"
  value = var.create_private_dns_namespace ? aws_service_discovery_private_dns_namespace.this.name : (
    var.create_public_dns_namespace ? aws_service_discovery_public_dns_namespace.this.name : (
      var.create_namespace ? aws_service_discovery_http_namespace.this.name : null
    )
  )
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
  value       = var.create_ecs_service_discovery_role && length(var.services) > 0 ? aws_iam_role.ecs_service_discovery.arn : null
}

output "ecs_service_discovery_role_name" {
  description = "Name of the ECS service discovery IAM role"
  value       = var.create_ecs_service_discovery_role && length(var.services) > 0 ? aws_iam_role.ecs_service_discovery.name : null
}

output "lambda_instance_id" {
  description = "ID of the registered Lambda instance in CloudMap"
  value       = var.enable_lambda_registration && var.lambda_url != null && var.lambda_service_name != null ? aws_service_discovery_instance.lambda[var.lambda_service_name].instance_id : null
}

output "lambda_service_id" {
  description = "ID of the CloudMap service where Lambda is registered"
  value       = var.enable_lambda_registration && var.lambda_url != null && var.lambda_service_name != null ? aws_service_discovery_instance.lambda[var.lambda_service_name].service_id : null
}

output "lambda_discovery_url" {
  description = "CloudMap discovery URL for the Lambda function"
  value = var.enable_lambda_registration && var.lambda_url != null && length(var.services) > 0 ? (
    var.create_private_dns_namespace ? "${var.lambda_instance_id}.${aws_service_discovery_service.services[local.lambda_service_key].name}.${var.namespace_name}" : (
      var.create_public_dns_namespace ? "${var.lambda_instance_id}.${aws_service_discovery_service.services[local.lambda_service_key].name}.${var.namespace_name}" : null
    )
  ) : null
}
