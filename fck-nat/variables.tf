variable "enabled" {
  description = "Controls if fck-nat resources should be created."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name for all fck-nat resources."
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# Networking
################################################################################

variable "vpc_id" {
  description = "VPC ID to deploy fck-nat into."
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID for the fck-nat instance."
  type        = string
}

variable "additional_security_group_ids" {
  description = "Additional security group IDs to attach to the fck-nat ENIs."
  type        = list(string)
  default     = []
}

################################################################################
# Instance
################################################################################

variable "instance_type" {
  description = "EC2 instance type for fck-nat. Graviton (t4g, c6gn, c7gn) recommended."
  type        = string
  default     = "t4g.nano"
}

variable "ami_id" {
  description = "Custom AMI ID. When null the latest fck-nat AL2023 AMI is auto-detected."
  type        = string
  default     = null
}

variable "ebs_root_volume_size" {
  description = "Root EBS volume size in GB."
  type        = number
  default     = 8
}

variable "encryption" {
  description = "Whether to encrypt the root EBS volume."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for EBS volume encryption. Uses the default EBS key when null."
  type        = string
  default     = null
}

variable "credit_specification" {
  description = "CPU credit option for burstable (T-type) instances: 'standard' or 'unlimited'. Null uses the instance default."
  type        = string
  default     = null
}

################################################################################
# High Availability
################################################################################

variable "ha_mode" {
  description = "Use an Auto Scaling Group for automatic instance recovery."
  type        = bool
  default     = true
}

variable "use_spot_instances" {
  description = "Use spot instances for additional cost savings."
  type        = bool
  default     = false
}

################################################################################
# Performance Tuning
################################################################################

variable "conntrack_max" {
  description = "Maximum number of concurrent tracked connections. Higher values use more memory. 0 uses the OS default."
  type        = number
  default     = 0
}

variable "local_port_range" {
  description = "Ephemeral port range as 'min max' (e.g., '1024 65535'). Wider range reduces port exhaustion under high connection rates. Empty string uses the OS default."
  type        = string
  default     = ""

  validation {
    condition     = var.local_port_range == "" || can(regex("^\\d+ \\d+$", var.local_port_range))
    error_message = "local_port_range must be two space-separated integers (e.g., '1024 65535') or an empty string."
  }
}

################################################################################
# EIP
################################################################################

variable "eip_allocation_ids" {
  description = "Elastic IP allocation IDs to associate with fck-nat (max 1). Provides a static outbound IP."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.eip_allocation_ids) <= 1
    error_message = "At most one EIP allocation ID can be provided."
  }
}

################################################################################
# Route Tables
################################################################################

variable "update_route_tables" {
  description = "Whether to create 0.0.0.0/0 routes pointing to the fck-nat ENI in the given route tables."
  type        = bool
  default     = false
}

variable "route_tables_ids" {
  description = "Map of logical name to route table ID. A 0.0.0.0/0 route is created in each."
  type        = map(string)
  default     = {}
}

################################################################################
# SSM
################################################################################

variable "attach_ssm_session_policy" {
  description = "Attach SSM Session Manager permissions to the IAM role (allows interactive shell access)."
  type        = bool
  default     = false
}

variable "attach_ssm_patch_policy" {
  description = "Attach SSM Patch Manager permissions to the IAM role (allows automated patching, no interactive access)."
  type        = bool
  default     = true
}

################################################################################
# Extensibility
################################################################################

variable "cloud_init_parts" {
  description = "Additional cloud-init parts to append after the fck-nat configuration script."
  type = list(object({
    content      = string
    content_type = string
  }))
  default = []
}
