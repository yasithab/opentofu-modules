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
# RDS Proxy
################################################################################

variable "auth" {
  description = "Configuration block(s) with authorization mechanisms to connect to the associated instances or clusters"
  type        = any
  default     = {}
}

variable "debug_logging" {
  description = "Whether the proxy includes detailed information about SQL statements in its logs"
  type        = bool
  default     = false
}

variable "default_auth_scheme" {
  description = "The default authentication scheme for new connections. Valid values are NONE and IAM_AUTH. Defaults to NONE"
  type        = string
  default     = null
}

variable "endpoint_network_type" {
  description = "The type of network protocol for client connections to the proxy. Valid values are IPV4, IPV6, or DUAL. Defaults to IPV4"
  type        = string
  default     = null
}

variable "engine_family" {
  description = "The kind of database engine that the proxy will connect to. Valid values are `MYSQL`, `POSTGRESQL`, or `SQLSERVER`"
  type        = string
  default     = null
}

variable "target_connection_network_type" {
  description = "The type of network protocol used for connections to the proxy target. Valid values are IPV4 or IPV6"
  type        = string
  default     = null
}

variable "idle_client_timeout" {
  description = "The number of seconds that a connection to the proxy can be inactive before the proxy disconnects it"
  type        = number
  default     = 1800
}

variable "require_tls" {
  description = "A Boolean parameter that specifies whether Transport Layer Security (TLS) encryption is required for connections to the proxy"
  type        = bool
  default     = true
}

variable "role_arn" {
  description = "The Amazon Resource Name (ARN) of the IAM role that the proxy uses to access secrets in AWS Secrets Manager"
  type        = string
  default     = null
}

variable "vpc_security_group_ids" {
  description = "One or more VPC security group IDs to associate with the new proxy"
  type        = list(string)
  default     = []
}

variable "vpc_subnet_ids" {
  description = "One or more VPC subnet IDs to associate with the new proxy"
  type        = list(string)
  default     = []
}

variable "proxy_tags" {
  description = "A map of tags to apply to the RDS Proxy"
  type        = map(string)
  default     = {}
}

variable "proxy_timeouts" {
  description = "Create, update, and delete timeout configurations for the RDS Proxy"
  type        = map(string)
  default     = {}
}

# Proxy Default Target Group
variable "connection_borrow_timeout" {
  description = "The number of seconds for a proxy to wait for a connection to become available in the connection pool"
  type        = number
  default     = null
}

variable "init_query" {
  description = "One or more SQL statements for the proxy to run when opening each new database connection"
  type        = string
  default     = null
}

variable "max_connections_percent" {
  description = "The maximum size of the connection pool for each target in a target group"
  type        = number
  default     = 90
}

variable "max_idle_connections_percent" {
  description = "Controls how actively the proxy closes idle database connections in the connection pool"
  type        = number
  default     = 50
}

variable "session_pinning_filters" {
  description = "Each item in the list represents a class of SQL operations that normally cause all later statements in a session using a proxy to be pinned to the same underlying database connection"
  type        = list(string)
  default     = []
}

# Proxy Target
variable "target_db_instance" {
  description = "Determines whether DB instance is targeted by proxy"
  type        = bool
  default     = false
}

variable "db_instance_identifier" {
  description = "DB instance identifier"
  type        = string
  default     = null
}

variable "target_db_cluster" {
  description = "Determines whether DB cluster is targeted by proxy"
  type        = bool
  default     = false
}

variable "db_cluster_identifier" {
  description = "DB cluster identifier"
  type        = string
  default     = null
}

# Proxy endpoints
variable "endpoints" {
  description = "Map of DB proxy endpoints to create and their attributes (see `aws_db_proxy_endpoint`)"
  type        = any
  default     = {}
}

################################################################################
# CloudWatch Logs
################################################################################

variable "manage_log_group" {
  description = "Determines whether Terraform will create/manage the CloudWatch log group or not. Note - this will fail if set to true after the log group has been created as the resource will already exist"
  type        = bool
  default     = true
}

variable "log_group_retention_in_days" {
  description = "Specifies the number of days you want to retain log events in the log group"
  type        = number
  default     = 30

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_group_retention_in_days)
    error_message = "log_group_retention_in_days must be one of the allowed CloudWatch Logs retention values: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653."
  }
}

variable "log_group_kms_key_id" {
  description = "The ARN of the KMS Key to use when encrypting log data"
  type        = string
  default     = null
}

variable "log_group_skip_destroy" {
  description = "Set to true if you do not wish the log group (and any logs it may contain) to be deleted at destroy time, and instead just remove the log group from the Terraform state"
  type        = bool
  default     = null
}

variable "log_group_class" {
  description = "Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT_ACCESS"
  type        = string
  default     = null
}

variable "log_group_tags" {
  description = "A map of tags to apply to the CloudWatch log group"
  type        = map(string)
  default     = {}
}

################################################################################
# IAM Role
################################################################################

variable "create_iam_role" {
  description = "Determines whether an IAM role is created"
  type        = bool
  default     = true
}

variable "iam_role_name" {
  description = "The name of the role. If omitted, Terraform will assign a random, unique name"
  type        = string
  default     = null
}

variable "use_role_name_prefix" {
  description = "Whether to use unique name beginning with the specified `iam_role_name`"
  type        = bool
  default     = false
}

variable "iam_role_description" {
  description = "The description of the role"
  type        = string
  default     = null
}

variable "iam_role_path" {
  description = "The path to the role"
  type        = string
  default     = null
}

variable "iam_role_force_detach_policies" {
  description = "Specifies to force detaching any policies the role has before destroying it"
  type        = bool
  default     = true
}

variable "iam_role_max_session_duration" {
  description = "The maximum session duration (in seconds) that you want to set for the specified role"
  type        = number
  default     = 43200 # 12 hours
}

variable "iam_role_permissions_boundary" {
  description = "The ARN of the policy that is used to set the permissions boundary for the role"
  type        = string
  default     = null
}

variable "iam_role_tags" {
  description = "A map of tags to apply to the IAM role"
  type        = map(string)
  default     = {}
}

# IAM Policy
variable "create_iam_policy" {
  description = "Determines whether an IAM policy is created"
  type        = bool
  default     = true
}

variable "iam_policy_name" {
  description = "The name of the role policy. If omitted, Terraform will assign a random, unique name"
  type        = string
  default     = null
}

variable "use_policy_name_prefix" {
  description = "Whether to use unique name beginning with the specified `iam_policy_name`"
  type        = bool
  default     = false
}

variable "kms_key_arns" {
  description = "List of KMS Key ARNs to allow access to decrypt SecretsManager secrets"
  type        = list(string)
  default     = []
}
