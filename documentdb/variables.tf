variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

variable "region" {
  description = "AWS region override. If null, the provider default region is used."
  type        = string
  default     = null
}

variable "name" {
  description = "Name of the DocumentDB cluster and used as a default for related resources."
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# Cluster
################################################################################

variable "engine_version" {
  description = "The DocumentDB engine version (e.g. 5.0.0)."
  type        = string
  default     = "5.0.0"
}

variable "master_username" {
  description = "Master username for the DocumentDB cluster."
  type        = string
  default     = "docdbadmin"
}

variable "master_password_wo" {
  description = "Write-only master password for the DocumentDB cluster. Never stored in state."
  type        = string
  default     = null
  ephemeral   = true
}

variable "master_password_wo_version" {
  description = "Version counter for the master password. Increment to trigger a password rotation."
  type        = number
  default     = 1
}

variable "storage_encrypted" {
  description = "Whether to encrypt cluster storage at rest. Enabled by default for production security."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "ARN of the KMS key to use for storage encryption. If null, the default aws/rds key is used."
  type        = string
  default     = null
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups."
  type        = number
  default     = 7
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

variable "storage_type" {
  description = "The storage type to associate with the cluster. Valid values: standard, iopt1."
  type        = string
  default     = null
}

variable "allow_major_version_upgrade" {
  description = "Whether to allow major engine version upgrades when changing engine versions."
  type        = bool
  default     = false
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch. Valid values: audit, profiler."
  type        = list(string)
  default     = ["audit", "profiler"]
}

variable "vpc_security_group_ids" {
  description = "List of additional VPC security group IDs to associate with the cluster."
  type        = list(string)
  default     = []
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
  description = "Default instance class for cluster instances (e.g. db.r6g.large)."
  type        = string
  default     = "db.r6g.large"
}

variable "auto_minor_version_upgrade" {
  description = "Whether minor engine upgrades are applied automatically during the maintenance window."
  type        = bool
  default     = true
}

variable "ca_cert_identifier" {
  description = "The CA certificate identifier for the DB instances."
  type        = string
  default     = null
}

variable "enable_performance_insights" {
  description = "Whether to enable Performance Insights for cluster instances."
  type        = bool
  default     = false
}

variable "performance_insights_kms_key_id" {
  description = "ARN of the KMS key to encrypt Performance Insights data."
  type        = string
  default     = null
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
  description = "The family of the cluster parameter group (e.g. docdb5.0)."
  type        = string
  default     = "docdb5.0"
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
      name  = "tls"
      value = "enabled"
    },
    {
      name  = "audit_logs"
      value = "enabled"
    },
  ]
}

################################################################################
# Security Group
################################################################################

variable "create_security_group" {
  description = "Whether to create a security group for the DocumentDB cluster."
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "ID of the VPC where the security group will be created."
  type        = string
  default     = null
}

variable "security_group_rules" {
  description = "Map of security group rules for the DocumentDB cluster."
  type        = any
  default     = {}
}
