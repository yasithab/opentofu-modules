variable "enabled" {
  description = "Set to false to disable all resources in this module."
  type        = bool
  default     = true
}

variable "name" {
  description = "Naming base used for the configuration recorder and delivery channel when recorder_name is not set."
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of tags to apply to all taggable resources."
  type        = map(string)
  default     = {}
}

# -- Recorder -----------------------------------------------------------------

variable "recorder_name" {
  description = "Override the configuration recorder (and delivery channel) name. Falls back to var.name then 'default'."
  type        = string
  default     = null
}

variable "global_resource_collector_region" {
  description = <<-EOT
    AWS region that is responsible for recording global resources (IAM users, roles,
    policies, etc.). When set, include_global_resource_types is automatically enabled
    only in this region, preventing duplicate config items in multi-region deployments.
    When null, the value from recording_group.include_global_resource_types is used.
  EOT
  type        = string
  default     = null
}

variable "recording_group" {
  description = <<-EOT
    Configuration recorder recording group settings.
    Supports all_supported, include_global_resource_types (overridden by
    global_resource_collector_region when set), exclusion_by_resource_types,
    and recording_strategy sub-objects.
  EOT
  type        = any
  default     = {}
}

variable "recording_mode" {
  description = <<-EOT
    Recording mode configuration. Set recording_frequency to CONTINUOUS or DAILY.
    Optionally supply recording_mode_override list for per-resource-type overrides.
  EOT
  type        = any
  default     = {}
}

# -- Delivery Channel ---------------------------------------------------------

variable "delivery_channel_s3_bucket_name" {
  description = "Name of the S3 bucket for AWS Config history and snapshots. The module does not create this bucket."
  type        = string
  default     = null
}

variable "delivery_channel_s3_key_prefix" {
  description = "S3 key prefix for AWS Config delivery."
  type        = string
  default     = null
}

variable "delivery_channel_s3_kms_key_arn" {
  description = "KMS key ARN used to encrypt Config history objects in S3."
  type        = string
  default     = null
}

variable "delivery_channel_sns_topic_arn" {
  description = "SNS topic ARN for AWS Config change notifications."
  type        = string
  default     = null
}

variable "snapshot_delivery_frequency" {
  description = "How often AWS Config delivers configuration snapshots. Valid values: One_Hour | Three_Hours | Six_Hours | Twelve_Hours | TwentyFour_Hours."
  type        = string
  default     = "TwentyFour_Hours"

  validation {
    condition = var.snapshot_delivery_frequency == null || contains(
      ["One_Hour", "Three_Hours", "Six_Hours", "Twelve_Hours", "TwentyFour_Hours"],
      var.snapshot_delivery_frequency
    )
    error_message = "snapshot_delivery_frequency must be one of: One_Hour, Three_Hours, Six_Hours, Twelve_Hours, TwentyFour_Hours."
  }
}

# -- Retention ----------------------------------------------------------------

variable "retention_period_in_days" {
  description = "Number of days AWS Config retains configuration history. Must be between 30 and 2557. Set to null to skip creating a retention configuration."
  type        = number
  default     = 2557

  validation {
    condition     = var.retention_period_in_days == null || (var.retention_period_in_days >= 30 && var.retention_period_in_days <= 2557)
    error_message = "retention_period_in_days must be between 30 and 2557."
  }
}

# -- IAM ----------------------------------------------------------------------

variable "create_iam_role" {
  description = "Whether to create an IAM role for the AWS Config service. Set to false and supply iam_role_arn to use an existing role."
  type        = bool
  default     = true
}

variable "iam_role_arn" {
  description = "ARN of an existing IAM role to use for the configuration recorder. Required when create_iam_role is false."
  type        = string
  default     = null
}

variable "iam_role_name" {
  description = "Override the IAM role name. Defaults to recorder_name + '-config-role'."
  type        = string
  default     = null
}

# -- Tag Enforcement ----------------------------------------------------------

variable "required_tags" {
  description = <<-EOT
    Map of tags that must be present on AWS resources. Key = tag name; value = required
    tag value (set to "" or null to accept any value). When non-empty, a REQUIRED_TAGS
    managed Config rule is automatically created.
    Override or disable the auto-rule by adding REQUIRED_TAGS = { enabled = false } to
    the managed_rules variable.
  EOT
  type        = map(string)
  default     = {}
}

variable "required_tags_resource_types" {
  description = "Limit the REQUIRED_TAGS rule to these resource types (e.g. [\"AWS::EC2::Instance\"]). Empty list = all supported types."
  type        = list(string)
  default     = []
}

# -- Config Rules -------------------------------------------------------------

variable "managed_rules" {
  description = <<-EOT
    Map of AWS managed Config rules to create. The map key is used as the rule name
    and as the source_identifier unless source_identifier is explicitly overridden.
    Set enabled = false on any entry to skip that rule without removing it from the map.
    source_details supports a list of objects with optional event_source, message_type,
    and maximum_execution_frequency for advanced trigger configuration.
  EOT
  type = map(object({
    description                 = optional(string)
    source_identifier           = optional(string)
    input_parameters            = optional(string)
    maximum_execution_frequency = optional(string)
    resource_types_scope        = optional(list(string), [])
    compliance_resource_id      = optional(string)
    tag_key_scope               = optional(string)
    tag_value_scope             = optional(string)
    evaluation_mode             = optional(string)
    source_details = optional(list(object({
      event_source                = optional(string)
      message_type                = optional(string)
      maximum_execution_frequency = optional(string)
    })), [])
    tags    = optional(map(string), {})
    enabled = optional(bool, true)
  }))
  default = {}
}

variable "custom_rules" {
  description = <<-EOT
    Map of custom (Lambda-backed) Config rules to create. The map key is used as the
    rule name. source_identifier must be set to the Lambda function ARN.
    Set enabled = false on any entry to skip that rule without removing it from the map.
    source_details supports a list of objects with optional event_source, message_type,
    and maximum_execution_frequency for advanced trigger configuration.
  EOT
  type = map(object({
    description                 = optional(string)
    source_identifier           = string
    input_parameters            = optional(string)
    maximum_execution_frequency = optional(string)
    resource_types_scope        = optional(list(string), [])
    compliance_resource_id      = optional(string)
    tag_key_scope               = optional(string)
    tag_value_scope             = optional(string)
    evaluation_mode             = optional(string)
    source_details = optional(list(object({
      event_source                = optional(string)
      message_type                = optional(string)
      maximum_execution_frequency = optional(string)
    })), [])
    tags    = optional(map(string), {})
    enabled = optional(bool, true)
  }))
  default = {}
}

variable "custom_policy_rules" {
  description = <<-EOT
    Map of custom policy (AWS Guard-backed) Config rules to create. The map key is used
    as the rule name. policy_text must contain the AWS CloudFormation Guard policy and
    policy_runtime must be set (currently only "guard-2.x.x" is supported).
    Set enabled = false on any entry to skip that rule without removing it from the map.
  EOT
  type = map(object({
    description                 = optional(string)
    policy_runtime              = string
    policy_text                 = string
    enable_debug_log_delivery   = optional(bool, false)
    input_parameters            = optional(string)
    maximum_execution_frequency = optional(string)
    resource_types_scope        = optional(list(string), [])
    compliance_resource_id      = optional(string)
    tag_key_scope               = optional(string)
    tag_value_scope             = optional(string)
    evaluation_mode             = optional(string)
    source_details = optional(list(object({
      event_source                = optional(string)
      message_type                = optional(string)
      maximum_execution_frequency = optional(string)
    })), [])
    tags    = optional(map(string), {})
    enabled = optional(bool, true)
  }))
  default = {}
}

# -- Aggregator ---------------------------------------------------------------

variable "create_aggregator" {
  description = "Whether to create a configuration aggregator (central/security account)."
  type        = bool
  default     = false
}

variable "aggregator_name" {
  description = "Name for the configuration aggregator. Defaults to recorder_name + '-aggregator'."
  type        = string
  default     = null
}

variable "aggregator_accounts" {
  description = <<-EOT
    Account-level aggregation source. Set account_ids and aws_regions (or all_aws_regions = true).
  EOT
  type = object({
    account_ids     = list(string)
    aws_regions     = optional(list(string))
    all_aws_regions = optional(bool, false)
  })
  default = null
}

variable "aggregator_organization" {
  description = <<-EOT
    Organization-level aggregation source. Set aws_regions (or all_aws_regions = true) and
    optionally role_arn to override the default service-linked role.
  EOT
  type = object({
    aws_regions     = optional(list(string))
    all_aws_regions = optional(bool, false)
    role_arn        = optional(string)
  })
  default = null
}

# -- Aggregator Authorization (child accounts) --------------------------------

variable "create_aggregator_authorization" {
  description = <<-EOT
    Set to true in child/member accounts to authorize a central aggregator account
    to collect Config data from this account. Supply aggregator_account_id and
    aggregator_account_region alongside this flag.
  EOT
  type        = bool
  default     = false
}

variable "aggregator_account_id" {
  description = "AWS account ID of the central Config aggregator. Required when create_aggregator_authorization = true."
  type        = string
  default     = null
}

variable "aggregator_account_region" {
  description = "AWS region where the central Config aggregator resides. Defaults to the current region when not set."
  type        = string
  default     = null
}
