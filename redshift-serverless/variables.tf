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

variable "create_random_password" {
  type        = bool
  default     = true
  description = "Determines whether to create random password for cluster `master_password`"
}

variable "random_password_length" {
  type        = number
  default     = 16
  description = "Length of random password to create. Defaults to `16`"
}

variable "engine_mode" {
  type        = string
  default     = "serverless"
  description = "The RedShift cluster engine mode. Valid values: `serverless`"
}

variable "port" {
  description = "RedShift cluster port, default is `5439`"
  type        = number
  default     = 5439

  validation {
    condition     = var.port >= 1 && var.port <= 65535
    error_message = "Port must be between 1 and 65535."
  }
}

variable "admin_username" {
  type        = string
  default     = null
  description = "The username of the administrator for the first database created in the namespace"
}

variable "admin_password" {
  type        = string
  default     = null
  description = "The password of the administrator for the first database created in the namespace"
  sensitive   = true
}

variable "iam_role_enabled" {
  type        = bool
  default     = true
  description = "If `true`, iam role resource is enabled"
}

variable "iam_role_name" {
  type        = string
  default     = null
  description = "The name of the iam role"
}

variable "assume_role_policy" {
  sensitive   = true
  type        = any
  default     = null
  description = "Policy that grants an entity permission to assume the role"
}

variable "policy_enabled" {
  type        = bool
  default     = true
  description = "Whether to Attach Iam policy with role"
}

variable "policy_arn" {
  type        = string
  default     = null
  sensitive   = true
  description = "The ARN of the policy you want to apply"
}

variable "managed_policy_arns" {
  type    = set(string)
  default = []
}

variable "policy_name" {
  type        = string
  default     = null
  description = "The name of the iam policy name"
}

variable "policy" {
  type        = any
  default     = null
  description = "If `true`, iam policy is enabled"
}

variable "kms_enabled" {
  type        = bool
  default     = false
  description = "If `true`, kms key is enabled"
}

variable "kms_alias" {
  type        = string
  default     = "alias/redshift-serverless"
  description = "The display name of the alias. The name must start with the word 'alias' followed by a forward slash (alias/)"
}

variable "kms_key_arn" {
  description = "The ARN for the KMS encryption key. When specifying `kms_key_arn`, `encrypted` needs to be set to `true`"
  type        = string
  default     = null
}

variable "namespace_name" {
  type        = string
  default     = null
  description = "The name of the namespace"
}

variable "manage_admin_password" {
  description = "Whether to use AWS SecretsManager to manage the cluster admin credentials. Conflicts with `admin_password`. One of `admin_password` or `manage_admin_password` is required unless `snapshot_identifier` is provided"
  type        = bool
  default     = true
}

variable "admin_password_secret_kms_key_id" {
  description = "ID of the KMS key used to encrypt the namespace admin credentials secret when `manage_admin_password` is true"
  type        = string
  default     = null
}

variable "db_name" {
  type        = string
  default     = null
  description = "The name of the first database created in the namespace"
}

variable "log_exports" {
  type        = list(string)
  default     = []
  description = "The types of logs the namespace can export. Available export types are userlog, connectionlog, and useractivitylog."
}

variable "workgroup_name" {
  type        = string
  default     = null
  description = "The name of the workgroup"
}

variable "workgroup_base_capacity" {
  type        = number
  default     = 16
  description = "The base data warehouse capacity of the workgroup in Redshift Processing Units (RPUs)."
}

variable "workgroup_max_capacity" {
  type        = number
  default     = 64
  description = "The maximum data-warehouse capacity Amazon Redshift Serverless uses to serve queries, specified in Redshift Processing Units (RPUs)"
}

variable "workgroup_enhanced_vpc_routing" {
  type        = bool
  default     = null
  description = "If `true`, enhanced VPC routing is enabled"
}

variable "publicly_accessible" {
  type        = bool
  default     = false
  description = "If true, the cluster can be accessed from a public network"
}

variable "subnet_ids" {
  type        = list(string)
  default     = null
  description = "An array of VPC subnet IDs to use in the subnet group"
}

variable "workgroup_config_parameter" {
  type        = list(any)
  default     = []
  description = "An array of parameters to set for more control over a serverless database."
}

variable "workgroup_price_performance_target" {
  description = "The price performance target configuration for the workgroup. Set `enabled = true` and provide a `level` (1-100) to enable price performance targeting"
  type = object({
    enabled = optional(bool, false)
    level   = optional(number, null)
  })
  default = null
}

variable "workgroup_track_name" {
  description = "The release track for the workgroup. Valid values are `current` or `trailing`"
  type        = string
  default     = null
}

variable "use_admin_password_wo" {
  description = "Whether to use the write-only admin_user_password_wo attribute instead of admin_user_password. When true, the password is never stored in state"
  type        = bool
  default     = false
}

variable "admin_user_password_wo_version" {
  description = "Version counter for admin_user_password_wo. Increment to trigger a password rotation when use_admin_password_wo is true"
  type        = number
  default     = 1
}

variable "workgroup_port" {
  description = "The custom port to use when connecting to a workgroup. Valid port ranges are 5431-5455 and 8191-8215. The default is 5439"
  type        = number
  default     = null

  validation {
    condition     = var.workgroup_port == null || (var.workgroup_port >= 5431 && var.workgroup_port <= 5455) || (var.workgroup_port >= 8191 && var.workgroup_port <= 8215)
    error_message = "workgroup_port must be in range 5431-5455 or 8191-8215."
  }
}

variable "usage_limit_enabled" {
  type        = bool
  default     = false
  description = "If `true`, it creates a new amazon redshift serverless usage limit."
}

variable "usage_type" {
  type        = string
  default     = "serverless-compute"
  description = "The type of Amazon Redshift Serverless usage to create a usage limit for. Valid values are serverless-compute or cross-region-datasharing."
}

variable "usage_amount" {
  type        = number
  default     = 60
  description = "The limit amount. If time-based, this amount is in Redshift Processing Units (RPU) consumed per hour. If data-based, this amount is in terabytes (TB) of data transferred between Regions in cross-account sharing. The value must be a positive number."
}

variable "usage_breach_action" {
  type        = string
  default     = "log"
  description = "The action that Amazon Redshift Serverless takes when the limit is reached. Valid values are log, emit-metric, and deactivate. The default is log."
}

variable "usage_period" {
  type        = string
  default     = "monthly"
  description = "The time period that the amount applies to. A weekly period begins on Sunday. Valid values are daily, weekly, and monthly. The default is monthly."
}

variable "endpoint_enabled" {
  type        = bool
  default     = true
  description = "If `true`, VPC endpoint is enabled"
}

variable "endpoint_name" {
  type        = string
  default     = null
  description = "The Redshift-managed VPC endpoint name"
}

variable "endpoint_owner_account" {
  description = "The AWS account ID of the owner of the workgroup. This is only required if the workgroup is in another AWS account"
  type        = string
  default     = null
}

variable "endpoint_security_group_ids" {
  description = "The security group IDs to use for the endpoint access (managed VPC endpoint)"
  type        = list(string)
  default     = []
}

variable "snapshot_enabled" {
  type        = bool
  default     = false
  description = "If `true`, snapshot is enabled"
}

variable "snapshot_name" {
  type        = string
  default     = null
  description = "The name of the snapshot."
}

variable "snapshot_retention_period" {
  type        = string
  default     = "-1"
  description = "How long to retain the created snapshot. Default value is -1."
}

variable "snapshot_policy_enabled" {
  type        = bool
  default     = false
  description = "If `true`, snapshot policy is enabled"
}

variable "snapshot_policy" {
  type        = any
  default     = null
  description = "If `true`, serverless snapshot policy is enabled"
}

variable "custom_domain_enabled" {
  type        = bool
  default     = false
  description = "If `true`, custom domain is enabled"
}

variable "custom_domain_name" {
  type        = string
  default     = null
  description = "Custom domain to associate with the workgroup"
}

variable "custom_domain_certificate_arn" {
  type        = string
  default     = null
  description = "ARN of the certificate for the custom domain association"
}

################################################################################
# Security Group
################################################################################

variable "create_security_group" {
  description = "Determines if a security group is created"
  type        = bool
  default     = true
}

variable "security_group_name" {
  description = "Name to use on security group created"
  type        = string
  default     = null
}

variable "security_group_use_name_prefix" {
  description = "Determines whether the security group name (`security_group_name`) is used as a prefix"
  type        = bool
  default     = true
}

variable "security_group_description" {
  description = "Description of the security group created"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "Identifier of the VPC where the security group will be created"
  type        = string
  default     = null
}

variable "security_group_rules" {
  description = "Security group ingress and egress rules to add to the security group created"
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

variable "security_group_tags" {
  description = "A map of additional tags to add to the security group created"
  type        = map(string)
  default     = {}
}