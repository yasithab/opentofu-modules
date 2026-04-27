variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}


variable "name" {
  description = "Name of the Neptune cluster and used as a default for related resources."
  type        = string

  validation {
    condition     = length(var.name) > 0
    error_message = "The name must not be empty."
  }
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# Cluster
################################################################################

variable "engine" {
  description = "The name of the database engine. Valid values: neptune."
  type        = string
  default     = "neptune"

  validation {
    condition     = contains(["neptune"], var.engine)
    error_message = "The engine must be 'neptune'."
  }
}

variable "engine_version" {
  description = "The Neptune engine version (e.g. 1.3.2.1)."
  type        = string
  default     = null
}

variable "vpc_security_group_ids" {
  description = "List of additional VPC security group IDs to associate with the cluster."
  type        = list(string)
  default     = []
}

variable "create_security_group" {
  description = "Whether to create a security group for the Neptune cluster."
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "ID of the VPC where the security group will be created."
  type        = string
  default     = null
}

variable "security_group_rules" {
  description = "Map of security group rules for the Neptune cluster."
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
  default = {}
}

variable "storage_encrypted" {
  description = "Whether to encrypt cluster storage at rest. Enabled by default for production security."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "ARN of the KMS key to use for storage encryption. If null, the default key is used."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:", var.kms_key_arn))
    error_message = "The kms_key_arn must be a valid ARN starting with 'arn:'."
  }
}

variable "iam_database_authentication_enabled" {
  description = "Whether to enable IAM database authentication for the Neptune cluster."
  type        = bool
  default     = true
}

variable "iam_roles" {
  description = "List of IAM role ARNs to associate with the Neptune cluster."
  type        = list(string)
  default     = []
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "The backup_retention_period must be between 1 and 35 days."
  }
}

variable "preferred_backup_window" {
  description = "Daily time range during which automated backups are created (UTC)."
  type        = string
  default     = "02:00-03:00"
}

variable "preferred_maintenance_window" {
  description = "Weekly time range during which system maintenance can occur (UTC)."
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot when the cluster is deleted."
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "Name of the final cluster snapshot created when the cluster is deleted."
  type        = string
  default     = null
}

variable "snapshot_identifier" {
  description = "Snapshot identifier to restore from when creating the cluster."
  type        = string
  default     = null
}

variable "apply_immediately" {
  description = "Whether to apply cluster modifications immediately or during the next maintenance window."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Whether deletion protection is enabled on the cluster. Enabled by default."
  type        = bool
  default     = true
}

variable "enable_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch. Valid values: audit, slowquery."
  type        = list(string)
  default     = ["audit"]
}

variable "storage_type" {
  description = "The storage type for the cluster. Valid values: standard, iopt1."
  type        = string
  default     = null

  validation {
    condition     = var.storage_type == null || contains(["standard", "iopt1"], var.storage_type)
    error_message = "The storage_type must be 'standard' or 'iopt1'."
  }
}

variable "allow_major_version_upgrade" {
  description = "Whether to allow major engine version upgrades."
  type        = bool
  default     = false
}

variable "copy_tags_to_snapshot" {
  description = "Whether to copy all tags to snapshots."
  type        = bool
  default     = true
}

variable "serverless_v2_scaling_configuration" {
  description = "Map with min_capacity and max_capacity for Neptune Serverless v2. Set to empty map to disable."
  type        = map(number)
  default     = {}
}

################################################################################
# Cluster Instances
################################################################################

variable "instances" {
  description = "Map of cluster instance configurations. Each entry creates an instance with optional overrides."
  type        = any
  default     = {}
}

variable "instance_class" {
  description = "Default instance class for cluster instances (e.g. db.r6g.large, db.serverless for Serverless v2)."
  type        = string
  default     = "db.r6g.large"
}

variable "auto_minor_version_upgrade" {
  description = "Whether minor engine upgrades are applied automatically during the maintenance window."
  type        = bool
  default     = true
}

################################################################################
# Subnet Group
################################################################################

variable "create_subnet_group" {
  description = "Whether to create a new subnet group for the cluster."
  type        = bool
  default     = true
}

variable "subnet_group_name" {
  description = "Name of the subnet group. If null, uses var.name."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "List of VPC subnet IDs for the subnet group."
  type        = list(string)
  default     = []
}

################################################################################
# Cluster Parameter Group
################################################################################

variable "create_cluster_parameter_group" {
  description = "Whether to create a cluster parameter group."
  type        = bool
  default     = true
}

variable "cluster_parameter_group_name" {
  description = "Name of the cluster parameter group. If null, uses var.name-cluster."
  type        = string
  default     = null
}

variable "cluster_parameter_group_family" {
  description = "The family of the cluster parameter group (e.g. neptune1.3)."
  type        = string
  default     = "neptune1.3"
}

variable "cluster_parameters" {
  description = "List of cluster parameter maps to apply."
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string)
  }))
  default = [
    {
      name  = "neptune_enable_audit_log"
      value = "1"
    },
  ]
}

################################################################################
# Instance Parameter Group
################################################################################

variable "create_instance_parameter_group" {
  description = "Whether to create an instance-level parameter group."
  type        = bool
  default     = true
}

variable "instance_parameter_group_name" {
  description = "Name of the instance parameter group. If null, uses var.name-instance."
  type        = string
  default     = null
}

variable "instance_parameter_group_family" {
  description = "The family of the instance parameter group (e.g. neptune1.3)."
  type        = string
  default     = "neptune1.3"
}

variable "instance_parameters" {
  description = "List of instance parameter maps to apply."
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string)
  }))
  default = []
}

################################################################################
# CloudWatch Log Group
################################################################################

variable "create_cloudwatch_log_group" {
  description = "Determines whether a CloudWatch log group is created for each `enable_cloudwatch_logs_exports`"
  type        = bool
  default     = false
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "The number of days to retain CloudWatch logs for the Neptune cluster"
  type        = number
  default     = 7

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_log_group_retention_in_days)
    error_message = "cloudwatch_log_group_retention_in_days must be one of the allowed CloudWatch Logs retention values."
  }
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "The ARN of the KMS Key to use when encrypting log data"
  type        = string
  default     = null
}

variable "cloudwatch_log_group_skip_destroy" {
  description = "Set to true if you do not wish the log group to be deleted at destroy time"
  type        = bool
  default     = null
}

variable "cloudwatch_log_group_class" {
  description = "Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT_ACCESS"
  type        = string
  default     = null
}

variable "cloudwatch_log_group_tags" {
  description = "Additional tags for the CloudWatch log group(s)"
  type        = map(string)
  default     = {}
}
