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
  description = "Name of the MemoryDB cluster and used as a default for related resources."
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

variable "description" {
  description = "Description of the MemoryDB cluster."
  type        = string
  default     = null
}

variable "node_type" {
  description = "The compute and memory capacity of the nodes in the cluster (e.g. db.r7g.large)."
  type        = string
  default     = "db.r7g.large"
}

variable "num_shards" {
  description = "The number of shards in the cluster."
  type        = number
  default     = 1
}

variable "num_replicas_per_shard" {
  description = "The number of replicas per shard."
  type        = number
  default     = 1
}

variable "port" {
  description = "The port on which the cluster accepts connections."
  type        = number
  default     = 6379
}

variable "engine" {
  description = "The name of the engine to be used for the cluster. Valid values are redis and valkey."
  type        = string
  default     = "redis"
}

variable "engine_version" {
  description = "The version number of the Redis engine to be used for the cluster."
  type        = string
  default     = null
}

variable "security_group_ids" {
  description = "List of security group IDs to associate with the cluster."
  type        = list(string)
  default     = []
}

variable "maintenance_window" {
  description = "The weekly time range during which system maintenance can occur (e.g. sun:05:00-sun:06:00)."
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "snapshot_window" {
  description = "The daily time range during which MemoryDB begins taking daily snapshots (e.g. 02:00-03:00)."
  type        = string
  default     = "02:00-03:00"
}

variable "snapshot_retention_limit" {
  description = "The number of days for which MemoryDB retains automatic snapshots. Setting to 0 disables backups."
  type        = number
  default     = 7
}

variable "snapshot_name" {
  description = "The name of a snapshot from which to restore data into the cluster."
  type        = string
  default     = null
}

variable "snapshot_arns" {
  description = "List of ARN(s) of the snapshots to restore from."
  type        = list(string)
  default     = null
}

variable "final_snapshot_name" {
  description = "Name of the final cluster snapshot to be created when the cluster is deleted."
  type        = string
  default     = null
}

variable "sns_topic_arn" {
  description = "ARN of an SNS topic to send MemoryDB notifications to."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt data at rest in the cluster."
  type        = string
  default     = null
}

variable "tls_enabled" {
  description = "Whether to enable in-transit encryption (TLS). Enabled by default for production security."
  type        = bool
  default     = true
}

variable "data_tiering" {
  description = "Enable data tiering. Only available for clusters using r6gd node types."
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Whether the cluster will automatically receive minor engine version upgrades after launch."
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
# Parameter Group
################################################################################

variable "create_parameter_group" {
  description = "Whether to create a new parameter group for the cluster."
  type        = bool
  default     = true
}

variable "parameter_group_name" {
  description = "Name of the parameter group. If null, uses var.name."
  type        = string
  default     = null
}

variable "parameter_group_family" {
  description = "The engine version that the parameter group can be used with (e.g. memorydb_redis7)."
  type        = string
  default     = "memorydb_redis7"
}

variable "parameters" {
  description = "List of parameter maps to apply to the parameter group."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

################################################################################
# ACL
################################################################################

variable "create_acl" {
  description = "Whether to create a MemoryDB ACL."
  type        = bool
  default     = true
}

variable "acl_name" {
  description = "Name of the ACL. If null, uses var.name."
  type        = string
  default     = null
}

variable "users" {
  description = "Map of MemoryDB user configurations to create. Each user must have user_name, access_string, and authentication_mode."
  type        = any
  default     = {}
}
