variable "enabled" {
  description = "Controls if resources should be created."
  type        = bool
  default     = true
}


variable "create_namespace" {
  description = "Whether to create an HTTP namespace"
  type        = bool
  default     = false
}

variable "create_private_dns_namespace" {
  description = "Whether to create a private DNS namespace"
  type        = bool
  default     = false
}

variable "create_public_dns_namespace" {
  description = "Whether to create a public DNS namespace"
  type        = bool
  default     = false
}

variable "create_ecs_service_discovery_role" {
  description = "Whether to create IAM role for ECS service discovery"
  type        = bool
  default     = false
}

variable "namespace_name" {
  description = "Name of the CloudMap namespace"
  type        = string
  default     = null
}

variable "namespace_description" {
  description = "Description of the CloudMap namespace"
  type        = string
  default     = null
}

variable "existing_namespace_id" {
  description = "ID of an existing namespace to use"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "VPC ID for private DNS namespace"
  type        = string
  default     = null
}

variable "services" {
  description = "Map of CloudMap services to create"
  type = map(object({
    name            = string
    description     = optional(string)
    type            = optional(string)
    force_destroy   = optional(bool, true)
    dns_ttl         = optional(number, 10)
    dns_record_type = optional(string, "A")
    routing_policy  = optional(string, "MULTIVALUE")
    health_check_config = optional(object({
      resource_path     = string
      type              = string
      failure_threshold = optional(number, 3)
    }))
    health_check_custom_config            = optional(bool, false)
    custom_health_check_failure_threshold = optional(number, 1)
    tags                                  = optional(map(string), {})
  }))
  default = {}
}

variable "dns_ttl" {
  description = "TTL for DNS records"
  type        = number
  default     = 10
}

variable "dns_record_type" {
  description = "Type of DNS record"
  type        = string
  default     = "A"
  validation {
    condition     = contains(["A", "AAAA", "CNAME", "SRV"], var.dns_record_type)
    error_message = "DNS record type must be one of: A, AAAA, CNAME, SRV."
  }
}

variable "routing_policy" {
  description = "Routing policy for the service"
  type        = string
  default     = "MULTIVALUE"
  validation {
    condition     = contains(["MULTIVALUE", "WEIGHTED"], var.routing_policy)
    error_message = "Routing policy must be one of: MULTIVALUE, WEIGHTED."
  }
}

variable "enable_health_checks" {
  description = "Enable health checks for the service. Set to false when using private IPs or unsupported instance types."
  type        = bool
  default     = true
}


variable "enable_dns_config" {
  description = "Enable DNS configuration for the service. Set to false for HTTP namespaces or when using existing HTTP namespaces."
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

# Lambda Function URL Support Variables
variable "enable_lambda_registration" {
  description = "Enable registration of Lambda Function URL in CloudMap service discovery"
  type        = bool
  default     = false
}

variable "lambda_instance_id" {
  description = "Unique identifier for the Lambda instance in CloudMap"
  type        = string
  default     = "lambda-function"
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.lambda_instance_id))
    error_message = "Lambda instance ID must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "lambda_url" {
  description = "Lambda Function URL or API Gateway endpoint to register in CloudMap"
  type        = string
  default     = null
  validation {
    condition     = var.lambda_url == null || can(regex("^https?://", var.lambda_url))
    error_message = "Lambda URL must be a valid HTTP or HTTPS URL."
  }
}

variable "lambda_service_name" {
  description = "Name of the CloudMap service for Lambda registration. If not specified, uses the first service name from var.services"
  type        = string
  default     = null
}

variable "lambda_attributes" {
  description = "Additional attributes for the Lambda instance in CloudMap"
  type        = map(string)
  default     = {}
}

variable "lambda_ip_address" {
  description = "IP address to use for Lambda A record in CloudMap. If not provided, uses a placeholder IP."
  type        = string
  default     = null
  validation {
    condition     = var.lambda_ip_address == null || can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$", var.lambda_ip_address))
    error_message = "Lambda IP address must be a valid IPv4 address."
  }
}
