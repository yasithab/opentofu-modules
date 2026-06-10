variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name for the bastion instance and related resources"
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of tags to apply to all resources."
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

  validation {
    condition     = var.ebs_root_volume_size >= 1
    error_message = "ebs_root_volume_size must be at least 1 GB."
  }
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
      for name, user in var.tunnel_users : can(regex("^(ssh-(ed25519|rsa)|ecdsa-sha2-nistp(256|384|521)|sk-(ssh-ed25519|ecdsa-sha2-nistp256)@openssh\\.com) ", user.ssh_public_key))
    ])
    error_message = "ssh_public_key must start with a valid key type: ssh-ed25519, ssh-rsa, ecdsa-sha2-nistp{256,384,521}, sk-ssh-ed25519@openssh.com, or sk-ecdsa-sha2-nistp256@openssh.com."
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

  validation {
    condition     = var.maintenance_window_cutoff >= 0 && var.maintenance_window_cutoff < var.maintenance_window_duration
    error_message = "maintenance_window_cutoff must be less than maintenance_window_duration."
  }
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
    condition     = var.ssh_host_key_ssm_prefix == null || (can(regex("^/[a-zA-Z0-9/_-]+$", var.ssh_host_key_ssm_prefix)) && !can(regex("\\.\\.", var.ssh_host_key_ssm_prefix)))
    error_message = "ssh_host_key_ssm_prefix must start with / and contain only alphanumeric characters, forward slashes, underscores, and hyphens. Path traversal (..) is not allowed."
  }
}

variable "ssh_host_keys_wo_version" {
  description = "Version counter for the write-only SSH host keys SSM parameter value. The host keys are written via the `value_wo` write-only attribute and never stored in state; increment this number to force the parameter value to be rewritten (e.g. after rotating the TLS keys)."
  type        = number
  default     = 1
}

variable "kms_key_arn" {
  description = "ARN of the customer-managed KMS key used to encrypt the SSH host key SSM parameter. When set, the bastion's kms:Decrypt permission is scoped to this key instead of all keys in the account (the kms:ViaService=ssm condition applies either way)."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:", var.kms_key_arn))
    error_message = "kms_key_arn must be a valid ARN starting with 'arn:'."
  }
}

################################################################################
# SSM Session Logging
################################################################################

variable "session_log_retention_days" {
  description = "Number of days to retain SSM session logs in CloudWatch"
  type        = number
  default     = 7

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.session_log_retention_days)
    error_message = "session_log_retention_days must be a valid CloudWatch retention value: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, or 3653."
  }
}

variable "session_log_kms_key_id" {
  description = "KMS key ARN for encrypting SSM session logs in CloudWatch. Uses default CloudWatch encryption when null."
  type        = string
  default     = null
}

variable "session_idle_timeout_minutes" {
  description = "Idle timeout in minutes for SSM sessions"
  type        = number
  default     = 20

  validation {
    condition     = var.session_idle_timeout_minutes >= 1 && var.session_idle_timeout_minutes <= 60
    error_message = "session_idle_timeout_minutes must be between 1 and 60."
  }
}

################################################################################
# EIP
################################################################################

variable "eip_tags" {
  description = "Additional tags for the Elastic IP"
  type        = map(string)
  default     = {}
}
