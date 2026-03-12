variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name to use for resource naming and tagging."
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# DB Subnet Group
################################################################################

variable "create_db_subnet_group" {
  description = "Determines whether to create the database subnet group or use existing"
  type        = bool
  default     = false
}

variable "db_subnet_group_name" {
  description = "The name of the subnet group name (existing or created)"
  type        = string
  default     = null
}

variable "subnets" {
  description = "List of subnet IDs used by database subnet group created"
  type        = list(string)
  default     = []
}

################################################################################
# DB Instance
################################################################################

variable "use_identifier_prefix" {
  description = "Whether to use `name` as a prefix for the DB instance identifier"
  type        = bool
  default     = false
}

variable "allocated_storage" {
  description = "The allocated storage in gibibytes (GiB)"
  type        = number
  default     = null
}

variable "max_allocated_storage" {
  description = "The upper limit to which Amazon RDS can automatically scale the storage of the DB instance. Set to 0 to disable storage autoscaling"
  type        = number
  default     = 0
}

variable "allow_major_version_upgrade" {
  description = "Enable to allow major engine version upgrades when changing engine versions. Defaults to `false`"
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window. Default is `false`"
  type        = bool
  default     = null
}

variable "auto_minor_version_upgrade" {
  description = "Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window. Default `true`"
  type        = bool
  default     = null
}

variable "availability_zone" {
  description = "The AZ for the RDS instance. If not set and multi_az is false, a random AZ in the region will be selected"
  type        = string
  default     = null
}

variable "backup_retention_period" {
  description = "The days to retain backups for. Must be between 0 and 35"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "The daily time range during which automated backups are created if automated backups are enabled using the backup_retention_period parameter. Time in UTC"
  type        = string
  default     = "02:00-03:00"
}

variable "ca_cert_identifier" {
  description = "The identifier of the CA certificate for the DB instance"
  type        = string
  default     = null
}

variable "character_set_name" {
  description = "The character set name to use for DB encoding in Oracle and Microsoft SQL instances (collation). This can't be changed. See Oracle Character Sets Supported in Amazon RDS or Server-Level Collation for Microsoft SQL Server for more information"
  type        = string
  default     = null
}

variable "copy_tags_to_snapshot" {
  description = "Copy all instance tags to snapshots"
  type        = bool
  default     = null
}

variable "custom_iam_instance_profile" {
  description = "The instance profile associated with the underlying Amazon EC2 instance of an RDS Custom DB instance"
  type        = string
  default     = null
}

variable "database_name" {
  description = "The name of the database to create when the DB instance is created"
  type        = string
  default     = null
}

variable "db_parameter_group_name" {
  description = "Name of the DB parameter group to associate (existing, if not creating one)"
  type        = string
  default     = null
}

variable "delete_automated_backups" {
  description = "Specifies whether to remove automated backups immediately after the DB instance is deleted"
  type        = bool
  default     = null
}

variable "deletion_protection" {
  description = "If the DB instance should have deletion protection enabled. The database can't be deleted when this value is set to `true`. The default is `true`"
  type        = bool
  default     = true
}

variable "domain" {
  description = "The ID of the Directory Service Active Directory domain to create the instance in"
  type        = string
  default     = null
}

variable "domain_iam_role_name" {
  description = "(Required if domain is provided) The name of the IAM role to be used when making API calls to the Directory Service"
  type        = string
  default     = null
}

variable "enabled_cloudwatch_logs_exports" {
  description = "Set of log types to export to cloudwatch. Valid values depend on engine: MySQL/MariaDB: audit, error, general, slowquery. PostgreSQL: postgresql, upgrade. Oracle: alert, audit, listener, trace, oemagent. MSSQL: agent, error"
  type        = list(string)
  default     = []
}

variable "engine" {
  description = "The database engine to use. Valid values: mysql, postgres, mariadb, oracle-ee, oracle-se2, sqlserver-ee, sqlserver-se, sqlserver-ex, sqlserver-web"
  type        = string
  default     = null
}

variable "engine_version" {
  description = "The engine version to use. If auto_minor_version_upgrade is enabled, you can provide a prefix of the version such as 8.0 (for 8.0.36)"
  type        = string
  default     = null
}

variable "engine_lifecycle_support" {
  description = "The life cycle type for this DB instance. Valid values: open-source-rds-extended-support, open-source-rds-extended-support-disabled"
  type        = string
  default     = null
}

variable "final_snapshot_identifier" {
  description = "The name of your final DB snapshot when this DB instance is deleted. Must be provided if skip_final_snapshot is set to false"
  type        = string
  default     = null
}

variable "iam_database_authentication_enabled" {
  description = "Specifies whether mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled"
  type        = bool
  default     = null
}

variable "instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = null
}

variable "iops" {
  description = "The amount of provisioned IOPS. Setting this implies a storage_type of io1 or io2"
  type        = number
  default     = null
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key. When specifying kms_key_id, storage_encrypted needs to be set to true"
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_id == null || can(regex("^arn:aws[a-z-]*:kms:", var.kms_key_id))
    error_message = "kms_key_id must be a valid KMS ARN or null."
  }
}

variable "license_model" {
  description = "License model information for this DB instance. Optional, but required for some DB engines (e.g. Oracle)"
  type        = string
  default     = null
}

variable "maintenance_window" {
  description = "The window to perform maintenance in. Syntax: ddd:hh24:mi-ddd:hh24:mi"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "manage_master_user_password" {
  description = "Set to true to allow RDS to manage the master user password in Secrets Manager. Cannot be set if master_password_wo is provided"
  type        = bool
  default     = true
}

variable "master_user_secret_kms_key_id" {
  description = "The Amazon Web Services KMS key identifier is the key ARN, key ID, alias ARN, or alias name for the KMS key"
  type        = string
  default     = null
}

variable "master_password_wo" {
  description = "Write-only password for the master DB user. Never stored in Terraform state. Required unless manage_master_user_password is set to true or unless snapshot_identifier is provided"
  type        = string
  default     = null
  ephemeral   = true
}

variable "master_password_wo_version" {
  description = "Version counter for the master DB password. Increment to trigger a password rotation without storing the new value in state"
  type        = number
  default     = 1
}

variable "master_username" {
  description = "Username for the master DB user. Required unless snapshot_identifier or replicate_source_db is provided"
  type        = string
  default     = null
}

variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. Set to 0 to disable. Valid values: 0, 1, 5, 10, 15, 30, 60"
  type        = number
  default     = 0
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
  default     = false
}

variable "network_type" {
  description = "The type of network stack to use (IPV4 or DUAL)"
  type        = string
  default     = null
}

variable "option_group_name" {
  description = "Name of the option group to associate (existing, if not creating one)"
  type        = string
  default     = null
}

variable "performance_insights_enabled" {
  description = "Specifies whether Performance Insights is enabled or not"
  type        = bool
  default     = null
}

variable "performance_insights_kms_key_id" {
  description = "The ARN for the KMS key to encrypt Performance Insights data"
  type        = string
  default     = null
}

variable "performance_insights_retention_period" {
  description = "Amount of time in days to retain Performance Insights data. Either 7 (7 days) or 731 (2 years)"
  type        = number
  default     = null
}

variable "port" {
  description = "The port on which the DB accepts connections"
  type        = number
  default     = null

  validation {
    condition     = var.port == null || (var.port >= 0 && var.port <= 65535)
    error_message = "Port must be between 0 and 65535."
  }
}

variable "publicly_accessible" {
  description = "Determines whether instances are publicly accessible. Default false"
  type        = bool
  default     = null
}

variable "replicate_source_db" {
  description = "Specifies that this resource is a Read Replica, and to use the value as the source database identifier. This correlates to the identifier of another Amazon RDS Database to replicate (if replicating within a single region) or ARN of the Amazon RDS Database to replicate (if replicating cross-region)"
  type        = string
  default     = null
}

variable "restore_to_point_in_time" {
  description = "Configuration block for restoring a DB instance to an arbitrary point in time. Requires the source_db_instance_identifier or source_dbi_resource_id argument"
  type        = map(string)
  default     = {}
}

variable "skip_final_snapshot" {
  description = "Determines whether a final snapshot is created before the DB instance is deleted. If true is specified, no snapshot is created"
  type        = bool
  default     = false
}

variable "snapshot_identifier" {
  description = "Specifies whether or not to create this database from a snapshot"
  type        = string
  default     = null
}

variable "storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted. The default is true"
  type        = bool
  default     = true
}

variable "storage_type" {
  description = "The storage type for the DB instance. Valid values: gp2, gp3, io1, io2, standard (magnetic)"
  type        = string
  default     = "gp3"
}

variable "storage_throughput" {
  description = "The storage throughput value for the DB instance. Applicable only for gp3 storage type. Cannot be specified if the storage_type is not gp3"
  type        = number
  default     = null
}

variable "timezone" {
  description = "Time zone of the DB instance. Only supported for Microsoft SQL Server"
  type        = string
  default     = null
}

variable "dedicated_log_volume" {
  description = "Use a dedicated log volume (DLV) for the DB instance. Requires Provisioned IOPS storage types"
  type        = bool
  default     = null
}

variable "database_insights_mode" {
  description = "The mode of Database Insights to enable for the DB instance. Valid values: standard, advanced"
  type        = string
  default     = null
}

variable "replica_mode" {
  description = "Specifies whether the replica is in either mounted or open-read-only mode. Only supported for Oracle DB instances"
  type        = string
  default     = null
}

variable "blue_green_update" {
  description = "Enables low-downtime updates using RDS Blue/Green Deployments. See blue_green_update configuration below"
  type        = map(string)
  default     = {}
}

variable "s3_import" {
  description = "Configuration map used to restore from a Percona Xtrabackup in S3 (only MySQL is supported)"
  type        = map(string)
  default     = {}
}

variable "instance_tags" {
  description = "A map of tags to add to only the DB instance"
  type        = map(string)
  default     = {}
}

variable "vpc_security_group_ids" {
  description = "List of VPC security groups to associate to the instance in addition to the security group created"
  type        = list(string)
  default     = []
}

variable "instance_timeouts" {
  description = "Create, update, and delete timeout configurations for the DB instance"
  type        = map(string)
  default     = {}
}

################################################################################
# Read Replica(s)
################################################################################

variable "read_replicas" {
  description = "Map of read replicas and any specific/overriding attributes to be created. Each key becomes part of the identifier"
  type        = any
  default     = {}
}

################################################################################
# DB Option Group
################################################################################

variable "create_db_option_group" {
  description = "Determines whether to create a DB option group"
  type        = bool
  default     = false
}

variable "db_option_group_name" {
  description = "The name of the option group. If omitted, defaults to var.name"
  type        = string
  default     = null
}

variable "db_option_group_use_name_prefix" {
  description = "Determines whether the option group name is used as a prefix"
  type        = bool
  default     = true
}

variable "db_option_group_description" {
  description = "The description of the option group"
  type        = string
  default     = null
}

variable "db_option_group_engine_name" {
  description = "Specifies the name of the engine that this option group should be associated with"
  type        = string
  default     = null
}

variable "db_option_group_major_engine_version" {
  description = "Specifies the major version of the engine that this option group should be associated with"
  type        = string
  default     = null
}

variable "db_option_group_options" {
  description = "A list of options to apply to the option group"
  type        = any
  default     = []
}

################################################################################
# DB Parameter Group
################################################################################

variable "create_db_parameter_group" {
  description = "Determines whether a DB parameter group should be created or use existing"
  type        = bool
  default     = false
}

variable "db_parameter_group_use_name_prefix" {
  description = "Determines whether the DB parameter group name is used as a prefix"
  type        = bool
  default     = true
}

variable "db_parameter_group_description" {
  description = "The description of the DB parameter group"
  type        = string
  default     = null
}

variable "db_parameter_group_family" {
  description = "The family of the DB parameter group"
  type        = string
  default     = null
}

variable "db_parameter_group_parameters" {
  description = "A list of DB parameters to apply. Note that parameters may differ from a family to an other"
  type        = list(map(string))
  default     = []
}

################################################################################
# Enhanced Monitoring
################################################################################

variable "create_monitoring_role" {
  description = "Determines whether to create the IAM role for RDS enhanced monitoring"
  type        = bool
  default     = true
}

variable "monitoring_role_arn" {
  description = "IAM role used by RDS to send enhanced monitoring metrics to CloudWatch"
  type        = string
  default     = null
}

variable "iam_role_name" {
  description = "Friendly name of the monitoring role"
  type        = string
  default     = null
}

variable "iam_role_use_name_prefix" {
  description = "Determines whether to use iam_role_name as is or create a unique name beginning with the iam_role_name as the prefix"
  type        = bool
  default     = false
}

variable "iam_role_description" {
  description = "Description of the monitoring role"
  type        = string
  default     = null
}

variable "iam_role_path" {
  description = "Path for the monitoring role"
  type        = string
  default     = null
}

variable "iam_role_managed_policy_arns" {
  description = "Set of exclusive IAM managed policy ARNs to attach to the monitoring role"
  type        = list(string)
  default     = null
}

variable "iam_role_permissions_boundary" {
  description = "The ARN of the policy that is used to set the permissions boundary for the monitoring role"
  type        = string
  default     = null
}

variable "iam_role_force_detach_policies" {
  description = "Whether to force detaching any policies the monitoring role has before destroying it"
  type        = bool
  default     = null
}

variable "iam_role_max_session_duration" {
  description = "Maximum session duration (in seconds) that you want to set for the monitoring role"
  type        = number
  default     = null
}

################################################################################
# Security Group
################################################################################

variable "create_security_group" {
  description = "Determines whether to create security group for RDS instance"
  type        = bool
  default     = true
}

variable "security_group_name" {
  description = "The security group name. Default value is (var.name)"
  type        = string
  default     = null
}

variable "security_group_use_name_prefix" {
  description = "Determines whether the security group name (var.name) is used as a prefix"
  type        = bool
  default     = true
}

variable "security_group_description" {
  description = "The description of the security group. If value is set to empty string it will contain instance name in the description"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "ID of the VPC where to create security group"
  type        = string
  default     = null
}

variable "security_group_rules" {
  description = "Map of security group rules to add to the security group created"
  type        = any
  default     = {}
}

variable "security_group_tags" {
  description = "Additional tags for the security group"
  type        = map(string)
  default     = {}
}

################################################################################
# CloudWatch Log Group
################################################################################

variable "create_cloudwatch_log_group" {
  description = "Determines whether a CloudWatch log group is created for each enabled_cloudwatch_logs_exports"
  type        = bool
  default     = false
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "The number of days to retain CloudWatch logs for the DB instance"
  type        = number
  default     = 7

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_log_group_retention_in_days)
    error_message = "cloudwatch_log_group_retention_in_days must be one of the allowed CloudWatch Logs retention values: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653."
  }
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "The ARN of the KMS Key to use when encrypting log data"
  type        = string
  default     = null
}

variable "cloudwatch_log_group_skip_destroy" {
  description = "Set to true if you do not wish the log group (and any logs it may contain) to be deleted at destroy time, and instead just remove the log group from the Terraform state"
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

################################################################################
# Managed Secret Rotation
################################################################################

variable "manage_master_user_password_rotation" {
  description = "Whether to manage the master user password rotation. Setting this value to false after previously having been set to true will disable automatic rotation."
  type        = bool
  default     = false
}

variable "master_user_password_rotate_immediately" {
  description = "Specifies whether to rotate the secret immediately or wait until the next scheduled rotation window."
  type        = bool
  default     = null
}

variable "master_user_password_rotation_automatically_after_days" {
  description = "Specifies the number of days between automatic scheduled rotations of the secret"
  type        = number
  default     = null
}

variable "master_user_password_rotation_duration" {
  description = "The length of the rotation window in hours. For example, 3h for a three hour window."
  type        = string
  default     = null
}

variable "master_user_password_rotation_schedule_expression" {
  description = "A cron() or rate() expression that defines the schedule for rotating your secret"
  type        = string
  default     = null
}
