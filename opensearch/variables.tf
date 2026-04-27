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

variable "opensearch_domain_name" {
  description = "Name of the opensearch domain"
  type        = string
  default     = null

  validation {
    condition     = var.opensearch_domain_name == null || can(regex("^[a-z][a-z0-9\\-]{2,27}$", var.opensearch_domain_name))
    error_message = "opensearch_domain_name must be 3-28 characters, start with a lowercase letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "ip_address_type" {
  description = "The IP address type for the endpoint. Valid values are ipv4 and dualstack"
  type        = string
  default     = null

  validation {
    condition     = var.ip_address_type == null || contains(["ipv4", "dualstack"], var.ip_address_type)
    error_message = "ip_address_type must be either 'ipv4' or 'dualstack'."
  }
}

variable "opensearch_version" {
  default     = "OpenSearch_2.13"
  description = "OpenSearch version"
  type        = string
}

variable "ebs_options" {
  description = "Configuration block for EBS related options, may be required based on chosen [instance size](https://aws.amazon.com/elasticsearch-service/pricing/)"
  type        = any
  default = {
    ebs_enabled = true
    volume_size = 30
    volume_type = "gp3"
  }

  validation {
    condition     = try(var.ebs_options.volume_type, null) == null || contains(["gp2", "gp3", "io1", "io2", "standard"], try(var.ebs_options.volume_type, "gp3"))
    error_message = "ebs_options.volume_type must be one of: 'gp2', 'gp3', 'io1', 'io2', 'standard'."
  }

  validation {
    condition     = try(var.ebs_options.volume_size, null) == null || (try(var.ebs_options.volume_size, 30) >= 10 && try(var.ebs_options.volume_size, 30) <= 16384)
    error_message = "ebs_options.volume_size must be between 10 and 16384 GiB."
  }
}

variable "advanced_options" {
  description = "Key-value string pairs to specify advanced configuration options. Note that the values for these configuration options must be strings (wrapped in quotes) or they may be wrong and cause a perpetual diff, causing Terraform to want to recreate your Elasticsearch domain on every apply"
  type        = map(string)
  default = {
    "rest.action.multi.allow_explicit_index" = "true"
    "indices.fielddata.cache.size"           = "40"
    "indices.query.bool.max_clause_count"    = "1024"
    "override_main_response_version"         = "false"
  }
}

variable "log_publishing_options" {
  description = "Configuration block for publishing slow and application logs to CloudWatch Logs. This block can be declared multiple times, for each log_type, within the same resource"
  type        = any
  default = [
    {
      log_type = "INDEX_SLOW_LOGS"
    },
    {
      log_type = "SEARCH_SLOW_LOGS"
    },
    {
      log_type = "ES_APPLICATION_LOGS"
    }
  ]
}

variable "cognito_options" {
  description = "Configuration block for authenticating Kibana with Cognito"
  type        = any
  default     = {}
}

variable "encrypt_at_rest" {
  description = "Configuration block for encrypting at rest"
  type        = any
  default = {
    enabled = true
  }
}

variable "domain_endpoint_options" {
  description = "Configuration block for domain endpoint HTTP(S) related options"
  type        = any
  default = {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }
}

variable "auto_tune_options" {
  description = "Configuration block for the Auto-Tune options of the domain"
  type        = any
  default = {
    desired_state       = "ENABLED"
    rollback_on_disable = "NO_ROLLBACK"
  }
}

variable "cluster_config" {
  description = "Configuration block for the cluster of the domain"
  type        = any
  default = {
    dedicated_master_enabled = false
    zone_awareness_config = {
      availability_zone_count = 3
    }
  }

  validation {
    condition     = try(var.cluster_config.instance_type, null) == null || can(regex("\\.search$", try(var.cluster_config.instance_type, "")))
    error_message = "cluster_config.instance_type must be a valid OpenSearch instance type ending with '.search' (e.g. 't3.small.search', 'r6g.large.search')."
  }

  validation {
    condition     = try(var.cluster_config.dedicated_master_count, null) == null || (try(var.cluster_config.dedicated_master_count, 0) >= 0 && try(var.cluster_config.dedicated_master_count, 0) <= 5)
    error_message = "cluster_config.dedicated_master_count must be between 0 and 5."
  }
}

variable "advanced_security_options" {
  description = "Configuration block for [fine-grained access control](https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/fgac.html). Note: master_user_password, if provided, will be stored in state as the provider does not support write_only for this field"
  type        = any
  default = {
    enabled                = true
    anonymous_auth_enabled = false
  }
  sensitive = true
}

variable "node_to_node_encryption" {
  description = "Configuration block for node-to-node encryption options"
  type        = any
  default = {
    enabled = true
  }
}

variable "off_peak_window_options" {
  description = "Configuration to add Off Peak update options"
  type        = any
  default = {
    enabled = true
    off_peak_window = {
      hours = 7
    }
  }
}

variable "snapshot_options" {
  description = "Configuration block for automated daily snapshots. Note: deprecated for OpenSearch 5.3 and later which take hourly automated snapshots. Set `automated_snapshot_start_hour` (0-23) to configure"
  type = object({
    automated_snapshot_start_hour = number
  })
  default = null

  validation {
    condition     = var.snapshot_options == null || (var.snapshot_options.automated_snapshot_start_hour >= 0 && var.snapshot_options.automated_snapshot_start_hour <= 23)
    error_message = "snapshot_options.automated_snapshot_start_hour must be between 0 and 23."
  }
}

variable "software_update_options" {
  description = "Software update options for the domain"
  type        = any
  default = {
    auto_software_update_enabled = false
  }
}

variable "vpc_options" {
  description = "Configuration block for VPC related options. Adding or removing this configuration forces a new resource ([documentation](https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html#es-vpc-limitations))"
  type        = any
  default     = {}
}

variable "timeouts" {
  description = "Create and delete timeout configurations for the domain"
  type        = map(string)
  default     = {}
}

################################################################################
# SAML Options
################################################################################

variable "create_saml_options" {
  description = "Determines whether SAML options will be created"
  type        = bool
  default     = false
}

variable "saml_options" {
  description = "SAML authentication options for an AWS OpenSearch Domain"
  type        = any
  default     = {}
}

################################################################################
# Outbound Connections
################################################################################

variable "outbound_connections" {
  description = "Map of AWS OpenSearch outbound connections to create"
  type        = any
  default     = {}
}

################################################################################
# CloudWatch Log Group
################################################################################

variable "create_cloudwatch_log_groups" {
  description = "Determines whether log groups are created"
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain log events"
  type        = number
  default     = 7

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_log_group_retention_in_days)
    error_message = "cloudwatch_log_group_retention_in_days must be one of the allowed CloudWatch Logs retention values: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653."
  }
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "If a KMS Key ARN is set, this key will be used to encrypt the corresponding log group. Please be sure that the KMS Key has an appropriate key policy (https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html)"
  type        = string
  default     = null

  validation {
    condition     = var.cloudwatch_log_group_kms_key_id == null || can(regex("^arn:", var.cloudwatch_log_group_kms_key_id))
    error_message = "cloudwatch_log_group_kms_key_id must be a valid ARN starting with 'arn:'."
  }
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

  validation {
    condition     = var.cloudwatch_log_group_class == null || contains(["STANDARD", "INFREQUENT_ACCESS"], var.cloudwatch_log_group_class)
    error_message = "cloudwatch_log_group_class must be either 'STANDARD' or 'INFREQUENT_ACCESS'."
  }
}

variable "create_cloudwatch_log_resource_policy" {
  description = "Determines whether a resource policy will be created for OpenSearch to log to CloudWatch"
  type        = bool
  default     = true
}

variable "cloudwatch_log_resource_policy_name" {
  description = "Name of the resource policy for OpenSearch to log to CloudWatch"
  type        = string
  default     = null
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

################################################################################
# Package Association(s)
################################################################################

variable "package_associations" {
  description = "Map of package association IDs to associate with the domain"
  type        = map(string)
  default     = {}
}

################################################################################
# VPC Endpoint(s)
################################################################################

variable "vpc_endpoints" {
  description = "Map of VPC endpoints to create for the domain"
  type        = any
  default     = {}
}

################################################################################
# Access Policy
################################################################################

variable "enable_access_policy" {
  description = "Determines whether an access policy will be applied to the domain"
  type        = bool
  default     = true
}

variable "create_access_policy" {
  description = "Determines whether an access policy will be created"
  type        = bool
  default     = true
}

variable "access_policies" {
  description = "IAM policy document specifying the access policies for the domain. Required if `create_access_policy` is `false`"
  type        = string
  default     = null
}

variable "access_policy_statements" {
  description = "A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage"
  type        = any
  default     = {}
}

variable "access_policy_source_policy_documents" {
  description = "List of IAM policy documents that are merged together into the exported document. Statements must have unique `sid`s"
  type        = list(string)
  default     = []
}

variable "access_policy_override_policy_documents" {
  description = "List of IAM policy documents that are merged together into the exported document. In merging, statements with non-blank `sid`s will override statements with the same `sid`"
  type        = list(string)
  default     = []
}

################################################################################
variable "identity_center_options" {
  description = "Configuration block for AWS IAM Identity Center options"
  type        = any
  default     = {}
}

variable "aiml_options" {
  description = "Configuration block for AI/ML options including natural language query generation, S3 vectors engine, and serverless vector acceleration"
  type        = any
  default     = {}
}
