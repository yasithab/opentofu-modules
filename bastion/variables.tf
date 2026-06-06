variable "enabled" {
  description = "Whether to create the bastion resources"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name for the bastion instance and related resources"
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "ha_mode" {
  description = "Use an Auto Scaling Group for automatic instance recovery and weekly AMI replacement."
  type        = bool
  default     = true
}

################################################################################
# Instance
################################################################################

variable "instance_type" {
  description = "EC2 instance type for the bastion host"
  type        = string
  default     = "t4g.nano"
}

variable "cpu_architecture" {
  description = "CPU architecture: x86_64 or arm64. Must match the instance type (e.g. t3 = x86_64, t4g = arm64)."
  type        = string
  default     = "arm64"

  validation {
    condition     = contains(["x86_64", "arm64"], var.cpu_architecture)
    error_message = "cpu_architecture must be x86_64 or arm64."
  }
}

variable "subnet_id" {
  description = "VPC subnet ID to launch the bastion in"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the security group."
  type        = string
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs to associate with the bastion"
  type        = list(string)
  default     = []
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed to SSH to the bastion. Only used when public = true and the module creates its own security group (vpc_security_group_ids is empty)."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.allowed_ssh_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "allowed_ssh_cidrs entries must be valid CIDR blocks (e.g. 203.0.113.0/24)."
  }
}

variable "key_name" {
  description = "Key pair name for SSH access. Optional when using SSM Session Manager only."
  type        = string
  default     = null
}

variable "public" {
  description = "Whether the bastion is public. When true, an Elastic IP is created. In ha_mode, EIP is self-associated on boot via user data."
  type        = bool
  default     = false
}

variable "ebs_root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 8
}

variable "ebs_encrypted" {
  description = "Whether to encrypt the root EBS volume"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for EBS volume encryption. Uses default EBS key when null."
  type        = string
  default     = null
}

variable "monitoring" {
  description = "Enable detailed monitoring on launched instances"
  type        = bool
  default     = false
}

variable "user_data_parts" {
  description = "Additional cloud-init parts appended after the bastion bootstrap script"
  type = list(object({
    content      = string
    content_type = string
  }))
  default = []
}

################################################################################
# Tunnel Users
################################################################################

variable "tunnel_users" {
  description = "Map of restricted SSH tunnel users. Only used when public = true. Each user can only create SSH tunnels to allowed_tunnels destinations. Empty allowed_tunnels permits tunneling to any destination."
  type = map(object({
    ssh_public_key  = string
    allowed_tunnels = optional(list(string), [])
  }))
  default = {}

  validation {
    condition     = length(var.tunnel_users) == 0 || var.public
    error_message = "tunnel_users can only be set when public = true. Private bastions use SSM Session Manager."
  }

  validation {
    condition = alltrue([
      for name, user in var.tunnel_users : can(regex("^[a-z_][a-z0-9_-]{0,31}$", name))
    ])
    error_message = "tunnel_users keys must be valid Linux usernames: lowercase alphanumeric, underscore, or hyphen; must start with a letter or underscore; max 32 characters."
  }

  validation {
    condition = alltrue([
      for name, user in var.tunnel_users : !can(regex("'", user.ssh_public_key))
    ])
    error_message = "ssh_public_key must not contain single quotes."
  }

  validation {
    condition = alltrue([
      for name, user in var.tunnel_users : alltrue([
        for t in user.allowed_tunnels : can(regex("^[a-zA-Z0-9._-]+:[0-9]+$", t))
      ])
    ])
    error_message = "allowed_tunnels entries must be in host:port format (e.g. db.internal:5432). No spaces or special characters."
  }
}

################################################################################
# IAM
################################################################################

variable "additional_iam_policies" {
  description = "Map of additional IAM policy ARNs to attach to the bastion role"
  type        = map(string)
  default     = {}
}

variable "iam_role_permissions_boundary" {
  description = "ARN of the permissions boundary policy for the IAM role"
  type        = string
  default     = null
}

################################################################################
# SSM Patch Manager (instance mode only)
################################################################################

variable "patch_schedule" {
  description = "Cron expression for the SSM maintenance window schedule (UTC). Only used when ha_mode = false."
  type        = string
  default     = "cron(0 0 ? * SAT *)"
}

variable "patch_operation" {
  description = "Patch operation to perform: Scan or Install. Only used when ha_mode = false."
  type        = string
  default     = "Install"

  validation {
    condition     = contains(["Scan", "Install"], var.patch_operation)
    error_message = "patch_operation must be Scan or Install."
  }
}

variable "maintenance_window_duration" {
  description = "Duration of the maintenance window in hours. Only used when ha_mode = false."
  type        = number
  default     = 2
}

variable "maintenance_window_cutoff" {
  description = "Hours before the end of the maintenance window that new tasks stop being scheduled. Only used when ha_mode = false."
  type        = number
  default     = 1
}

variable "patch_baseline_approval_days" {
  description = "Number of days after a patch is released before it is auto-approved. Only used when ha_mode = false."
  type        = number
  default     = 7
}

variable "reboot_option" {
  description = "Reboot behavior after patching: RebootIfNeeded or NoReboot. Only used when ha_mode = false."
  type        = string
  default     = "RebootIfNeeded"

  validation {
    condition     = contains(["RebootIfNeeded", "NoReboot"], var.reboot_option)
    error_message = "reboot_option must be RebootIfNeeded or NoReboot."
  }
}

################################################################################
# Replacement Schedule (ha_mode only)
################################################################################

variable "replacement_scale_down_schedule" {
  description = "Cron expression (UTC) for weekly scale-down. Default: Saturday 00:00 UTC (4 AM GST). Only used when ha_mode = true."
  type        = string
  default     = "0 0 * * 6"
}

variable "replacement_scale_up_schedule" {
  description = "Cron expression (UTC) for weekly scale-up after replacement. Default: Saturday 00:05 UTC (4:05 AM GST). Only used when ha_mode = true."
  type        = string
  default     = "5 0 * * 6"
}

################################################################################
# SSH Host Key Persistence (ha_mode + public only)
################################################################################

variable "persist_ssh_host_keys" {
  description = "Persist SSH host keys in SSM Parameter Store so they survive instance replacement. Only used when ha_mode = true and public = true."
  type        = bool
  default     = true
}

variable "ssh_host_key_ssm_prefix" {
  description = "SSM Parameter Store prefix for SSH host keys. Keys stored as SecureString under this path. Only used when ha_mode = true and public = true."
  type        = string
  default     = null

  validation {
    condition     = var.ssh_host_key_ssm_prefix == null || can(regex("^/[a-zA-Z0-9/_-]+$", var.ssh_host_key_ssm_prefix))
    error_message = "ssh_host_key_ssm_prefix must start with / and contain only alphanumeric characters, forward slashes, underscores, and hyphens."
  }
}

################################################################################
# SSM Session Logging
################################################################################

variable "session_log_retention_days" {
  description = "Number of days to retain SSM session logs in CloudWatch"
  type        = number
  default     = 7
}

variable "session_idle_timeout_minutes" {
  description = "Idle timeout in minutes for SSM sessions"
  type        = number
  default     = 20
}

################################################################################
# EIP
################################################################################

variable "eip_tags" {
  description = "Additional tags for the Elastic IP"
  type        = map(string)
  default     = {}
}
