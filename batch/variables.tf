variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}


variable "name" {
  description = "Name used as a prefix for all Batch resources."
  type        = string

  validation {
    condition     = length(var.name) >= 1
    error_message = "name must not be empty."
  }
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# Compute Environment
################################################################################

variable "compute_environment_type" {
  description = "Type of the compute environment. Valid values: `MANAGED`, `UNMANAGED`."
  type        = string
  default     = "MANAGED"

  validation {
    condition     = contains(["MANAGED", "UNMANAGED"], var.compute_environment_type)
    error_message = "compute_environment_type must be one of: MANAGED, UNMANAGED."
  }
}

variable "compute_environment_state" {
  description = "State of the compute environment. Valid values: `ENABLED`, `DISABLED`."
  type        = string
  default     = "ENABLED"

  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.compute_environment_state)
    error_message = "compute_environment_state must be one of: ENABLED, DISABLED."
  }
}

variable "compute_resources" {
  description = "Compute resources configuration for the compute environment. Required for MANAGED type."
  type = object({
    type                = optional(string, "FARGATE")
    allocation_strategy = optional(string)
    min_vcpus           = optional(number, 0)
    max_vcpus           = optional(number, 16)
    desired_vcpus       = optional(number)
    instance_type       = optional(list(string))
    instance_role       = optional(string)
    image_id            = optional(string)
    ec2_key_pair        = optional(string)
    bid_percentage      = optional(number)
    spot_iam_fleet_role = optional(string)
    subnets             = optional(list(string), [])
    security_group_ids  = optional(list(string), [])
    tags                = optional(map(string))
    ec2_configuration = optional(object({
      image_id_override = optional(string)
      image_type        = optional(string)
    }))
    launch_template = optional(object({
      launch_template_id   = optional(string)
      launch_template_name = optional(string)
      version              = optional(string)
    }))
  })
  default = null
}

variable "eks_configuration" {
  description = "EKS configuration for the compute environment."
  type = object({
    eks_cluster_arn      = string
    kubernetes_namespace = string
  })
  default = null
}

variable "update_policy" {
  description = "Update policy for the compute environment."
  type = object({
    job_execution_timeout_minutes = optional(number, 30)
    terminate_jobs_on_update      = optional(bool, false)
  })
  default = null
}

################################################################################
# Job Queue
################################################################################

variable "job_queues" {
  description = "Map of job queue configurations to create. `scheduling_policy_key` references a key in `scheduling_policies`; `compute_environment_order` defaults to this module's compute environment."
  type = map(object({
    name                  = string
    state                 = optional(string, "ENABLED")
    priority              = optional(number, 1)
    scheduling_policy_arn = optional(string)
    scheduling_policy_key = optional(string)
    compute_environment_order = optional(list(object({
      order               = number
      compute_environment = optional(string)
    })))
    job_state_time_limit_actions = optional(list(object({
      action           = string
      max_time_seconds = number
      reason           = string
      state            = string
    })), [])
  }))
  default = {}
}

################################################################################
# Scheduling Policy
################################################################################

variable "scheduling_policies" {
  description = "Map of scheduling policy configurations with fair share settings."
  type = map(object({
    name = string
    fair_share_policy = optional(object({
      compute_reservation = optional(number, 0)
      share_decay_seconds = optional(number, 0)
      share_distribution = optional(list(object({
        share_identifier = string
        weight_factor    = optional(number, 1)
      })), [])
    }))
  }))
  default = {}
}

################################################################################
# Job Definition
################################################################################

variable "job_definitions" {
  description = "Map of job definition configurations. `container_properties`, `node_properties`, and `ecs_properties` are JSON strings."
  type = map(object({
    name                  = string
    type                  = optional(string, "container")
    platform_capabilities = optional(list(string), ["FARGATE"])
    propagate_tags        = optional(bool, true)
    scheduling_priority   = optional(number)
    parameters            = optional(map(string))
    container_properties  = optional(string)
    node_properties       = optional(string)
    ecs_properties        = optional(string)
    retry_strategy = optional(object({
      attempts = optional(number, 3)
      evaluate_on_exit = optional(list(object({
        action           = string
        on_exit_code     = optional(string)
        on_reason        = optional(string)
        on_status_reason = optional(string)
      })), [])
    }))
    timeout = optional(object({
      attempt_duration_seconds = optional(number)
    }))
  }))
  default = {}
}

################################################################################
# Security Group
################################################################################

variable "create_security_group" {
  description = "Whether to create a security group for the Batch compute environment."
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID for the security group. Required when `create_security_group` is true."
  type        = string
  default     = null
}

variable "security_group_rules" {
  description = "Map of security group rules for the Batch compute environment. Use `type` key with value `ingress` or `egress`."
  type = map(object({
    type                         = optional(string, "ingress")
    ip_protocol                  = optional(string, "tcp")
    from_port                    = optional(number)
    to_port                      = optional(number)
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    description                  = optional(string)
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
    tags                         = optional(map(string), {})
  }))
  default = {
    egress_all = {
      type        = "egress"
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow all outbound traffic"
    }
  }
}

################################################################################
# IAM
################################################################################

variable "create_service_role" {
  description = "Whether to create the Batch service IAM role. When false and the compute environment type is MANAGED, `service_role_arn` must be provided."
  type        = bool
  default     = true

  validation {
    condition     = !var.enabled || var.create_service_role || var.compute_environment_type != "MANAGED" || var.service_role_arn != null
    error_message = "A MANAGED compute environment requires a service role: set create_service_role = true or provide service_role_arn."
  }
}

variable "service_role_arn" {
  description = "ARN of an existing IAM role for the Batch service. Used when `create_service_role` is false."
  type        = string
  default     = null

  validation {
    condition     = var.service_role_arn == null || can(regex("^arn:", var.service_role_arn))
    error_message = "service_role_arn must be a valid ARN starting with 'arn:'."
  }
}

variable "create_execution_role" {
  description = "Whether to create the Batch execution IAM role for Fargate tasks."
  type        = bool
  default     = true
}

variable "execution_role_arn" {
  description = "ARN of an existing IAM execution role for Fargate tasks. Used when `create_execution_role` is false; reflected in the `execution_role_arn` output."
  type        = string
  default     = null

  validation {
    condition     = var.execution_role_arn == null || can(regex("^arn:", var.execution_role_arn))
    error_message = "execution_role_arn must be a valid ARN starting with 'arn:'."
  }
}

variable "create_job_role" {
  description = "Whether to create a default job IAM role."
  type        = bool
  default     = true
}

variable "job_role_arn" {
  description = "ARN of an existing IAM job role. Used when `create_job_role` is false; reflected in the `job_role_arn` output."
  type        = string
  default     = null

  validation {
    condition     = var.job_role_arn == null || can(regex("^arn:", var.job_role_arn))
    error_message = "job_role_arn must be a valid ARN starting with 'arn:'."
  }
}

variable "execution_role_policies" {
  description = "Map of additional IAM policy ARNs to attach to the execution role."
  type        = map(string)
  default     = {}
}

variable "job_role_policies" {
  description = "Map of IAM policy ARNs to attach to the job role."
  type        = map(string)
  default     = {}
}
