variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}


################################################################################
# Broker
################################################################################

variable "broker_name" {
  type        = string
  description = "The name of the broker"
}

variable "engine_type" {
  type        = string
  description = "The type of broker engine. Valid values: `ActiveMQ`, `RabbitMQ`"
  default     = null

  validation {
    condition     = var.engine_type == null || contains(["ActiveMQ", "RabbitMQ"], var.engine_type)
    error_message = "engine_type must be one of: ActiveMQ, RabbitMQ."
  }
}

variable "engine_version" {
  type        = string
  description = "The version of the broker engine"
  default     = null
}

variable "host_instance_type" {
  type        = string
  description = "The broker's instance type"
  default     = "mq.t3.micro"
}

variable "deployment_mode" {
  type        = string
  description = "The deployment mode of the broker. Valid values: `SINGLE_INSTANCE`, `ACTIVE_STANDBY_MULTI_AZ`, `CLUSTER_MULTI_AZ`"
  default     = "SINGLE_INSTANCE"

  validation {
    condition     = contains(["SINGLE_INSTANCE", "ACTIVE_STANDBY_MULTI_AZ", "CLUSTER_MULTI_AZ"], var.deployment_mode)
    error_message = "deployment_mode must be one of: SINGLE_INSTANCE, ACTIVE_STANDBY_MULTI_AZ, CLUSTER_MULTI_AZ."
  }
}

variable "subnet_ids" {
  type        = list(string)
  description = "The list of subnet IDs in which to launch the broker"
}

variable "apply_immediately" {
  type        = bool
  description = "Specifies whether any broker modifications are applied immediately, or during the next maintenance window"
  default     = false
}

variable "auto_minor_version_upgrade" {
  type        = bool
  description = "Enables automatic upgrades to new minor versions for brokers"
  default     = false
}

variable "publicly_accessible" {
  type        = bool
  description = "Whether to enable connections from applications outside of the VPC that hosts the broker's subnets"
  default     = false
}

variable "storage_type" {
  type        = string
  description = "The storage type of the broker. Valid values: `efs`, `ebs`"
  default     = "ebs"
}

variable "authentication_strategy" {
  type        = string
  description = "Authentication strategy for broker. Valid values: `simple`, `ldap`. `ldap` is not supported for engine_type RabbitMQ"
  default     = null
}

variable "data_replication_mode" {
  type        = string
  description = "Defines whether this broker is a part of a data replication pair. Valid values: `NONE`, `CRDR`"
  default     = null

  validation {
    condition     = var.data_replication_mode == null || contains(["NONE", "CRDR"], var.data_replication_mode)
    error_message = "data_replication_mode must be one of: NONE, CRDR."
  }
}

variable "data_replication_primary_broker_arn" {
  type        = string
  description = "The Amazon Resource Name (ARN) of the primary broker that is used to replicate data from in a data replication pair. Must be set when `data_replication_mode` is `CRDR`"
  default     = null
}

variable "encryption_options" {
  type = object({
    kms_key_id        = optional(string)
    use_aws_owned_key = optional(bool, true)
  })
  description = "Encryption options for the broker"
  default     = null
}

variable "ldap_server_metadata" {
  type = object({
    hosts                    = optional(list(string))
    role_base                = optional(string)
    role_name                = optional(string)
    role_search_matching     = optional(string)
    role_search_subtree      = optional(bool)
    service_account_password = optional(string)
    service_account_username = optional(string)
    user_base                = optional(string)
    user_role_name           = optional(string)
    user_search_matching     = optional(string)
    user_search_subtree      = optional(bool)
  })
  description = "LDAP server metadata for authentication (ActiveMQ only)"
  default     = null
  sensitive   = true
}

variable "logs" {
  type = object({
    audit   = optional(bool, false)
    general = optional(bool, false)
  })
  description = "Logging configuration"
  default     = null
}

variable "maintenance_window_start_time" {
  type = object({
    day_of_week = string
    time_of_day = string
    time_zone   = string
  })
  description = "Maintenance window start time configuration"
  default     = null
}

variable "users" {
  type = list(object({
    username         = string
    password         = string
    console_access   = optional(bool, false)
    groups           = optional(list(string))
    replication_user = optional(bool, false)
  }))
  description = "List of broker users"
  sensitive   = true
}

variable "configuration" {
  type = object({
    id       = string
    revision = number
  })
  description = "The broker configuration. Applies to engine_type of ActiveMQ and RabbitMQ only"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to the broker"
  default     = {}
}

################################################################################
# Security Groups
################################################################################

variable "create_security_group" {
  type        = bool
  description = "Whether to create a security group for the MQ broker"
  default     = false
}

variable "security_groups" {
  type        = list(string)
  description = "List of existing security group IDs to use (ignored if create_security_group is true)"
  default     = []
}

variable "security_group_name" {
  type        = string
  description = "Name for the created security group (auto-generated if not provided)"
  default     = null
}

variable "security_group_name_prefix" {
  type        = string
  description = "Name prefix for the created security group (auto-generated if not provided)"
  default     = null
}

variable "security_group_description" {
  type        = string
  description = "Description for the created security group"
  default     = "Security group for AWS MQ broker"
}

variable "security_group_tags" {
  type        = map(string)
  description = "Additional tags for the security group"
  default     = {}
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC where to create security group"
  default     = null
}

variable "ingress_rules" {
  type = list(object({
    description      = optional(string)
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = optional(list(string))
    ipv6_cidr_blocks = optional(list(string))
    prefix_list_ids  = optional(list(string))
    security_groups  = optional(list(string))
    self             = optional(bool)
  }))
  description = "List of ingress rules to add to the security group"
  default     = null
}

variable "egress_rules" {
  type = list(object({
    description      = optional(string)
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = optional(list(string))
    ipv6_cidr_blocks = optional(list(string))
    prefix_list_ids  = optional(list(string))
    security_groups  = optional(list(string))
    self             = optional(bool)
  }))
  description = "List of egress rules to add to the security group"
  default = [
    {
      description = "All outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

################################################################################
