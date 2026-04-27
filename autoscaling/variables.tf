
variable "enabled" {
  description = "Determines whether resources will be created (affects all resources)"
  type        = bool
  default     = true
}


variable "name" {
  description = "Name used for the Auto Scaling Group, launch template, and related resources"
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# Launch Template
################################################################################

variable "create_launch_template" {
  description = "Whether to create a launch template"
  type        = bool
  default     = true
}

variable "launch_template_id" {
  description = "ID of an existing launch template to use. Required if `create_launch_template` is false."
  type        = string
  default     = null
}

variable "launch_template_version" {
  description = "Launch template version. Can be version number, `$Latest`, or `$Default`."
  type        = string
  default     = null
}

variable "launch_template_description" {
  description = "Description for the launch template"
  type        = string
  default     = null
}

variable "image_id" {
  description = "AMI ID to use for the launch template"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "Instance type to use for the launch template"
  type        = string
  default     = null
}

variable "key_name" {
  description = "Key pair name to associate with instances"
  type        = string
  default     = null
}

variable "user_data" {
  description = "Base64-encoded user data to provide when launching instances"
  type        = string
  default     = null
}

variable "ebs_optimized" {
  description = "Whether the instance is EBS-optimized"
  type        = bool
  default     = null
}

variable "enable_monitoring" {
  description = "Whether to enable detailed monitoring for instances"
  type        = bool
  default     = true
}

variable "metadata_options" {
  description = "Metadata options for the launch template. Defaults enforce IMDSv2."
  type        = any
  default = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }
}

variable "network_interfaces" {
  description = "List of network interface configurations for the launch template"
  type        = any
  default     = []
}

variable "block_device_mappings" {
  description = "List of block device mappings for the launch template"
  type        = any
  default     = []
}

variable "iam_instance_profile_arn" {
  description = "ARN of an existing IAM instance profile. Mutually exclusive with `create_iam_instance_profile`."
  type        = string
  default     = null

  validation {
    condition     = var.iam_instance_profile_arn == null || can(regex("^arn:", var.iam_instance_profile_arn))
    error_message = "iam_instance_profile_arn must be a valid ARN starting with 'arn:'."
  }
}

variable "placement" {
  description = "Placement configuration for the launch template"
  type        = any
  default     = {}
}

variable "tag_specifications" {
  description = "Additional tag specifications for resources created by the launch template (e.g., `instance`, `volume`)"
  type        = any
  default     = []
}

################################################################################
# IAM Instance Profile and Role
################################################################################

variable "create_iam_instance_profile" {
  description = "Whether to create an IAM instance profile and role"
  type        = bool
  default     = false
}

variable "iam_role_name" {
  description = "Name of the IAM role. Defaults to `<name>-role`."
  type        = string
  default     = null
}

variable "iam_role_description" {
  description = "Description for the IAM role"
  type        = string
  default     = null
}

variable "iam_role_path" {
  description = "Path for the IAM role"
  type        = string
  default     = null
}

variable "iam_role_permissions_boundary" {
  description = "ARN of the permissions boundary policy for the IAM role"
  type        = string
  default     = null

  validation {
    condition     = var.iam_role_permissions_boundary == null || can(regex("^arn:", var.iam_role_permissions_boundary))
    error_message = "iam_role_permissions_boundary must be a valid ARN starting with 'arn:'."
  }
}

variable "iam_role_policy_arns" {
  description = "Map of IAM policy ARNs to attach to the role"
  type        = map(string)
  default     = {}
}

variable "iam_role_policies" {
  description = "Map of inline IAM policies. Key is the policy name, value is the JSON policy document."
  type        = map(string)
  default     = {}
}

################################################################################
# Security Group
################################################################################

variable "create_security_group" {
  description = "Whether to create a security group for the instances"
  type        = bool
  default     = false
}

variable "security_group_name" {
  description = "Name of the security group. Defaults to the ASG name."
  type        = string
  default     = null
}

variable "security_group_description" {
  description = "Description of the security group"
  type        = string
  default     = "Security group for Auto Scaling Group instances"
}

variable "vpc_id" {
  description = "VPC ID for the security group. Required if `create_security_group` is true."
  type        = string
  default     = null
}

variable "security_group_ingress_rules" {
  description = "Map of ingress rules for the security group"
  type        = any
  default     = {}
}

variable "security_group_egress_rules" {
  description = "Map of egress rules for the security group"
  type        = any
  default = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow all outbound traffic"
    }
  }
}

variable "security_group_ids" {
  description = "List of additional security group IDs to associate with instances"
  type        = list(string)
  default     = []
}

################################################################################
# Auto Scaling Group
################################################################################

variable "min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 0

  validation {
    condition     = var.min_size >= 0
    error_message = "min_size must be >= 0."
  }
}

variable "max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 1

  validation {
    condition     = var.max_size >= 0
    error_message = "max_size must be >= 0."
  }
}

variable "desired_capacity" {
  description = "Desired number of instances in the ASG"
  type        = number
  default     = null

  validation {
    condition     = var.desired_capacity == null || var.desired_capacity >= 0
    error_message = "desired_capacity must be >= 0."
  }
}

variable "vpc_zone_identifier" {
  description = "List of subnet IDs for the ASG to launch instances in"
  type        = list(string)
  default     = []
}

variable "health_check_type" {
  description = "Type of health check. Valid values: `EC2`, `ELB`."
  type        = string
  default     = "EC2"

  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "health_check_type must be one of: EC2, ELB."
  }
}

variable "health_check_grace_period" {
  description = "Time in seconds after instance launch before health checking starts"
  type        = number
  default     = 300

  validation {
    condition     = var.health_check_grace_period >= 0
    error_message = "health_check_grace_period must be >= 0."
  }
}

variable "default_cooldown" {
  description = "Default cooldown period in seconds between scaling activities"
  type        = number
  default     = null
}

variable "default_instance_warmup" {
  description = "Default instance warmup time in seconds"
  type        = number
  default     = null
}

variable "protect_from_scale_in" {
  description = "Whether instances are protected from scale-in"
  type        = bool
  default     = false
}

variable "termination_policies" {
  description = "List of policies to decide how instances are terminated"
  type        = list(string)
  default     = []
}

variable "suspended_processes" {
  description = "List of processes to suspend for the ASG"
  type        = list(string)
  default     = []
}

variable "max_instance_lifetime" {
  description = "Maximum amount of time in seconds an instance can be in service"
  type        = number
  default     = null
}

variable "enabled_metrics" {
  description = "List of ASG metrics to enable. Defaults to all metrics."
  type        = list(string)
  default = [
    "GroupDesiredCapacity",
    "GroupInServiceCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingCapacity",
    "GroupPendingInstances",
    "GroupStandbyCapacity",
    "GroupStandbyInstances",
    "GroupTerminatingCapacity",
    "GroupTerminatingInstances",
    "GroupTotalCapacity",
    "GroupTotalInstances",
  ]
}

variable "metrics_granularity" {
  description = "Granularity for ASG metrics"
  type        = string
  default     = "1Minute"
}

variable "service_linked_role_arn" {
  description = "ARN of the service-linked role for the ASG"
  type        = string
  default     = null

  validation {
    condition     = var.service_linked_role_arn == null || can(regex("^arn:", var.service_linked_role_arn))
    error_message = "service_linked_role_arn must be a valid ARN starting with 'arn:'."
  }
}

variable "capacity_rebalance" {
  description = "Whether capacity rebalancing is enabled"
  type        = bool
  default     = false
}

variable "force_delete" {
  description = "Whether to force delete the ASG without waiting for instances to terminate"
  type        = bool
  default     = false
}

variable "wait_for_capacity_timeout" {
  description = "Maximum duration to wait for ASG instances to be healthy"
  type        = string
  default     = "10m"
}

################################################################################
# Mixed Instances Policy
################################################################################

variable "use_mixed_instances_policy" {
  description = "Whether to use a mixed instances policy"
  type        = bool
  default     = false
}

variable "mixed_instances_override" {
  description = "List of instance type overrides for mixed instances policy"
  type        = any
  default     = []
}

variable "on_demand_base_capacity" {
  description = "Absolute minimum number of on-demand instances"
  type        = number
  default     = 0
}

variable "on_demand_percentage_above_base_capacity" {
  description = "Percentage of on-demand instances beyond the base capacity"
  type        = number
  default     = 100

  validation {
    condition     = var.on_demand_percentage_above_base_capacity >= 0 && var.on_demand_percentage_above_base_capacity <= 100
    error_message = "on_demand_percentage_above_base_capacity must be between 0 and 100."
  }
}

variable "spot_allocation_strategy" {
  description = "Strategy for allocating Spot instances. Valid values: `lowest-price`, `capacity-optimized`, `capacity-optimized-prioritized`, `price-capacity-optimized`."
  type        = string
  default     = "price-capacity-optimized"

  validation {
    condition     = contains(["lowest-price", "capacity-optimized", "capacity-optimized-prioritized", "price-capacity-optimized"], var.spot_allocation_strategy)
    error_message = "spot_allocation_strategy must be one of: lowest-price, capacity-optimized, capacity-optimized-prioritized, price-capacity-optimized."
  }
}

variable "spot_instance_pools" {
  description = "Number of Spot pools per availability zone. Only relevant with `lowest-price` strategy."
  type        = number
  default     = null
}

variable "spot_max_price" {
  description = "Maximum price per unit hour to pay for Spot instances"
  type        = string
  default     = null
}

################################################################################
# Scaling Policies
################################################################################

variable "scaling_policies" {
  description = "Map of scaling policies to create. Supports target_tracking, step, simple, and predictive types."
  type        = any
  default     = {}
}

################################################################################
# Scheduled Actions
################################################################################

variable "scheduled_actions" {
  description = "Map of scheduled actions. Each entry supports `min_size`, `max_size`, `desired_capacity`, `start_time`, `end_time`, `recurrence`, and `time_zone`."
  type        = any
  default     = {}
}

################################################################################
# Warm Pool
################################################################################

variable "warm_pool" {
  description = "Warm pool configuration. Set to `{}` to enable with defaults. Supports `pool_state`, `min_size`, `max_group_prepared_capacity`, and `instance_reuse_policy`."
  type        = any
  default     = null
}

################################################################################
# Instance Refresh
################################################################################

variable "instance_refresh" {
  description = "Instance refresh configuration. Set to `{}` to enable with defaults. Supports `strategy`, `preferences`, and `triggers`."
  type        = any
  default     = null
}

################################################################################
# Lifecycle Hooks
################################################################################

variable "lifecycle_hooks" {
  description = "Map of lifecycle hooks. Each entry supports `lifecycle_transition`, `default_result`, `heartbeat_timeout`, `notification_metadata`, `notification_target_arn`, and `role_arn`."
  type        = any
  default     = {}
}

################################################################################
# Notification Configuration
################################################################################

variable "notification_configurations" {
  description = "Map of notification configurations. Each entry requires `topic_arn` and `notifications` (list of event types)."
  type        = any
  default     = {}
}

################################################################################
# Traffic Source Attachments
################################################################################

variable "traffic_source_attachments" {
  description = "Map of traffic source attachments (ALB/NLB target group ARNs). Each entry requires `traffic_source_identifier` and optionally `traffic_source_type`."
  type        = any
  default     = {}
}

variable "target_group_arns" {
  description = "List of target group ARNs to attach to the ASG (convenience alias for ALB/NLB)"
  type        = list(string)
  default     = []
}
