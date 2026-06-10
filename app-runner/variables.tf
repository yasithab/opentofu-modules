variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}


variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# Service
################################################################################

variable "create_service" {
  description = "Determines whether the service will be created"
  type        = bool
  default     = true
}

variable "name" {
  description = "The name of the service"
  type        = string
  default     = null
}

variable "auto_scaling_configuration_arn" {
  description = "ARN of an App Runner automatic scaling configuration resource that you want to associate with your service. If not provided, App Runner associates the latest revision of a default auto scaling configuration"
  type        = string
  default     = null
}

variable "encryption_configuration" {
  description = "The encryption configuration for the service"
  type = object({
    kms_key = string
  })
  default = null
}

variable "health_check_configuration" {
  description = "The health check configuration for the service"
  type = object({
    healthy_threshold   = optional(number)
    interval            = optional(number)
    path                = optional(string)
    protocol            = optional(string)
    timeout             = optional(number)
    unhealthy_threshold = optional(number)
  })
  default = null
}

variable "instance_configuration" {
  description = "The instance configuration for the service"
  type = object({
    cpu               = optional(string)
    memory            = optional(string)
    instance_role_arn = optional(string)
  })
  default = null
}

variable "network_configuration" {
  description = "The network configuration for the service"
  type = object({
    ip_address_type = optional(string)
    ingress_configuration = optional(object({
      is_publicly_accessible = optional(bool)
    }))
    egress_configuration = optional(object({
      egress_type       = optional(string, "VPC")
      vpc_connector_arn = optional(string)
    }))
  })
  default = null
}

variable "source_configuration" {
  description = "The source configuration for the service"
  type = object({
    auto_deployments_enabled = optional(bool, false)
    authentication_configuration = optional(object({
      access_role_arn = optional(string)
      connection_arn  = optional(string)
    }))
    code_repository = optional(object({
      repository_url   = string
      source_directory = optional(string)
      source_code_version = object({
        type  = optional(string, "BRANCH")
        value = string
      })
      code_configuration = optional(object({
        configuration_source = string
        code_configuration_values = optional(object({
          build_command                 = optional(string)
          port                          = optional(string)
          runtime                       = string
          runtime_environment_variables = optional(map(string), {})
          runtime_environment_secrets   = optional(map(string), {})
          start_command                 = optional(string)
        }))
      }))
    }))
    image_repository = optional(object({
      image_identifier      = string
      image_repository_type = string
      image_configuration = optional(object({
        port                          = optional(string)
        runtime_environment_variables = optional(map(string), {})
        runtime_environment_secrets   = optional(map(string), {})
        start_command                 = optional(string)
      }))
    }))
  })
  default = null
}

################################################################################
# IAM Role - Access
################################################################################

variable "create_access_iam_role" {
  description = "Determines whether an IAM role is created or to use an existing IAM role"
  type        = bool
  default     = false
}

variable "access_iam_role_name" {
  description = "Name to use on IAM role created"
  type        = string
  default     = null
}

variable "access_iam_role_use_name_prefix" {
  description = "Determines whether the IAM role name (`iam_role_name`) is used as a prefix"
  type        = bool
  default     = true
}

variable "access_iam_role_path" {
  description = "IAM role path"
  type        = string
  default     = null
}

variable "access_iam_role_description" {
  description = "Description of the role"
  type        = string
  default     = null
}

variable "access_iam_role_permissions_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the IAM role"
  type        = string
  default     = null
}

variable "access_iam_role_max_session_duration" {
  description = "Maximum session duration (in seconds) for the access IAM role. Valid values are between 3600 and 43200."
  type        = number
  default     = null
}

variable "access_iam_role_managed_policy_arns" {
  description = "Set of IAM managed policy ARNs to attach to the access IAM role."
  type        = set(string)
  default     = null
}

variable "access_iam_role_inline_policies" {
  description = "Map of inline IAM policies to attach to the access IAM role. Keys are policy names; values are JSON policy documents."
  type        = map(string)
  default     = {}
}

variable "private_ecr_arn" {
  description = "The ARN of the private ECR repository that contains the service image to launch"
  type        = string
  default     = null
}

variable "access_iam_role_policies" {
  description = "IAM policies to attach to the IAM role"
  type        = map(string)
  default     = {}
}

################################################################################
# IAM Role - Instance
################################################################################

variable "create_instance_iam_role" {
  description = "Determines whether an IAM role is created or to use an existing IAM role"
  type        = bool
  default     = true
}

variable "instance_iam_role_name" {
  description = "Name to use on IAM role created"
  type        = string
  default     = null
}

variable "instance_iam_role_use_name_prefix" {
  description = "Determines whether the IAM role name (`iam_role_name`) is used as a prefix"
  type        = bool
  default     = true
}

variable "instance_iam_role_path" {
  description = "IAM role path"
  type        = string
  default     = null
}

variable "instance_iam_role_description" {
  description = "Description of the role"
  type        = string
  default     = null
}

variable "instance_iam_role_permissions_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the IAM role"
  type        = string
  default     = null
}

variable "instance_iam_role_max_session_duration" {
  description = "Maximum session duration (in seconds) for the instance IAM role. Valid values are between 3600 and 43200."
  type        = number
  default     = null
}

variable "instance_iam_role_managed_policy_arns" {
  description = "Set of IAM managed policy ARNs to attach to the instance IAM role."
  type        = set(string)
  default     = null
}

variable "instance_iam_role_inline_policies" {
  description = "Map of inline IAM policies to attach to the instance IAM role. Keys are policy names; values are JSON policy documents."
  type        = map(string)
  default     = {}
}

variable "instance_iam_role_policies" {
  description = "IAM policies to attach to the IAM role"
  type        = map(string)
  default     = {}
}

################################################################################
# IAM Role Policy - Instance
################################################################################

variable "instance_policy_statements" {
  description = "A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage"
  type = map(object({
    sid           = optional(string)
    actions       = optional(list(string))
    not_actions   = optional(list(string))
    effect        = optional(string)
    resources     = optional(list(string))
    not_resources = optional(list(string))
    principals = optional(list(object({
      type        = string
      identifiers = list(string)
    })), [])
    not_principals = optional(list(object({
      type        = string
      identifiers = list(string)
    })), [])
    conditions = optional(list(object({
      test     = string
      values   = list(string)
      variable = string
    })), [])
  }))
  default = {}
}

################################################################################
# IAM Policy - Shared
################################################################################

variable "iam_policy_delay_after_creation_ms" {
  description = "Milliseconds to wait after IAM policy creation before use. Helps avoid eventual-consistency race conditions. Applies to both access and instance IAM policies."
  type        = number
  default     = null
}

################################################################################
# VPC Ingress Configuration
################################################################################

variable "create_ingress_vpc_connection" {
  description = "Determines whether a VPC ingress configuration will be created"
  type        = bool
  default     = false
}

variable "ingress_vpc_id" {
  description = "The ID of the VPC that is used for the VPC ingress configuration"
  type        = string
  default     = null
}

variable "ingress_vpc_endpoint_id" {
  description = "The ID of the VPC endpoint that is used for the VPC ingress configuration"
  type        = string
  default     = null
}

################################################################################
# Custom Domain Association
################################################################################

variable "create_custom_domain_association" {
  description = "Determines whether a Custom Domain Association will be created"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "The custom domain endpoint to association. Specify a base domain e.g., `example.com` or a subdomain e.g., `subdomain.example.com`"
  type        = string
  default     = null
}

variable "enable_www_subdomain" {
  description = "Whether to associate the subdomain with the App Runner service in addition to the base domain. Defaults to `true`"
  type        = bool
  default     = null
}

variable "hosted_zone_id" {
  description = "The ID of the Route53 hosted zone that contains the domain for the `domain_name`"
  type        = string
  default     = null
}

################################################################################
# VPC Connector
################################################################################

variable "create_vpc_connector" {
  description = "Determines whether a VPC Connector will be created"
  type        = bool
  default     = false
}

variable "vpc_connector_name" {
  description = "The name of the VPC Connector"
  type        = string
  default     = null
}

variable "vpc_connector_subnets" {
  description = "The subnets to use for the VPC Connector"
  type        = list(string)
  default     = []
}

variable "vpc_connector_security_groups" {
  description = "The security groups to use for the VPC Connector"
  type        = list(string)
  default     = []
}

################################################################################
# Connection(s)
################################################################################

variable "connections" {
  description = "Map of connection definitions to create"
  type = map(object({
    name          = optional(string)
    provider_type = optional(string, "GITHUB")
    tags          = optional(map(string), {})
  }))
  default = {}
}

################################################################################
# Autoscaling Configuration(s)
################################################################################

variable "auto_scaling_configurations" {
  description = "Map of auto-scaling configuration definitions to create"
  type = map(object({
    name            = optional(string)
    max_concurrency = optional(number)
    max_size        = optional(number)
    min_size        = optional(number)
    tags            = optional(map(string), {})
  }))
  default = {}
}

################################################################################
# Observability Configuration
################################################################################

variable "enable_observability_configuration" {
  description = "Determines whether an X-Ray Observability Configuration will be created and assigned to the service"
  type        = bool
  default     = true
}

variable "observability_trace_vendor" {
  description = "The implementation provider chosen for tracing App Runner services. Valid values: AWSXRAY. Defaults to AWSXRAY when enable_observability_configuration is true."
  type        = string
  default     = "AWSXRAY"

  validation {
    condition     = var.observability_trace_vendor == null || var.observability_trace_vendor == "AWSXRAY"
    error_message = "Valid values for observability_trace_vendor are: AWSXRAY."
  }
}
