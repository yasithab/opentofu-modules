variable "enabled" {
  description = "Whether to create the AWS Batch resources."
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
  type        = any
  default     = null
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
  type        = any
  default     = null
}

################################################################################
# Job Queue
################################################################################

variable "job_queues" {
  description = "Map of job queue configurations to create."
  type        = any
  default     = {}
}

################################################################################
# Scheduling Policy
################################################################################

variable "scheduling_policies" {
  description = "Map of scheduling policy configurations with fair share settings."
  type        = any
  default     = {}
}

################################################################################
# Job Definition
################################################################################

variable "job_definitions" {
  description = "Map of job definition configurations."
  type        = any
  default     = {}
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
  description = "Whether to create the Batch service IAM role."
  type        = bool
  default     = true
}

variable "create_execution_role" {
  description = "Whether to create the Batch execution IAM role for Fargate tasks."
  type        = bool
  default     = true
}

variable "create_job_role" {
  description = "Whether to create a default job IAM role."
  type        = bool
  default     = true
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
