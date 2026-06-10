
variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
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
  type = object({
    http_endpoint               = optional(string, "enabled")
    http_tokens                 = optional(string, "required")
    http_put_response_hop_limit = optional(number, 2)
    instance_metadata_tags      = optional(string)
  })
  default = {}
}

variable "network_interfaces" {
  description = "List of network interface configurations for the launch template. `device_index` defaults to the list index; `security_groups` defaults to the module-managed security group IDs."
  type = list(object({
    associate_public_ip_address = optional(bool)
    delete_on_termination       = optional(bool, true)
    description                 = optional(string)
    device_index                = optional(number)
    security_groups             = optional(list(string))
    subnet_id                   = optional(string)
  }))
  default = []
}

variable "block_device_mappings" {
  description = "List of block device mappings for the launch template. EBS volumes are gp3 and encrypted by default."
  type = list(object({
    device_name = string
    ebs = optional(object({
      volume_size           = optional(number)
      volume_type           = optional(string, "gp3")
      encrypted             = optional(bool, true)
      kms_key_id            = optional(string)
      iops                  = optional(number)
      throughput            = optional(number)
      delete_on_termination = optional(bool, true)
      snapshot_id           = optional(string)
    }))
  }))
  default = []
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
  type = object({
    availability_zone = optional(string)
    group_name        = optional(string)
    tenancy           = optional(string)
  })
  default = null
}

variable "tag_specifications" {
  description = "Additional tag specifications for resources created by the launch template (e.g., `instance`, `volume`)"
  type = list(object({
    resource_type = string
    tags          = optional(map(string), {})
  }))
  default = []
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
  type = map(object({
    description                  = optional(string)
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    from_port                    = optional(number)
    to_port                      = optional(number)
    ip_protocol                  = optional(string, "tcp")
    referenced_security_group_id = optional(string)
    prefix_list_id               = optional(string)
  }))
  default = {}
}

variable "security_group_egress_rules" {
  description = "Map of egress rules for the security group"
  type = map(object({
    description                  = optional(string)
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    from_port                    = optional(number)
    to_port                      = optional(number)
    ip_protocol                  = optional(string, "-1")
    referenced_security_group_id = optional(string)
    prefix_list_id               = optional(string)
  }))
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

  validation {
    condition     = var.max_size >= var.min_size
    error_message = "max_size must be >= min_size."
  }
}

variable "desired_capacity" {
  description = "Desired number of instances in the ASG. NOTE: when `ignore_desired_capacity_changes` is true (the default), out-of-band changes to desired capacity (e.g., by scaling policies or scheduled actions) are ignored (`lifecycle.ignore_changes`); OpenTofu will not revert them on subsequent applies. See the README's 'Desired capacity drift' section."
  type        = number
  default     = null

  validation {
    condition     = var.desired_capacity == null || var.desired_capacity >= 0
    error_message = "desired_capacity must be >= 0."
  }
}

variable "ignore_desired_capacity_changes" {
  description = "Whether to ignore out-of-band changes to `desired_capacity` (default true). When true the ASG is created as `aws_autoscaling_group.this` with `lifecycle.ignore_changes = [desired_capacity]`, so scaling policies/scheduled actions/manual edits are never reverted. When false the ASG is created as `aws_autoscaling_group.tracked` and OpenTofu manages `desired_capacity` like any other attribute. Toggling this after creation moves the group to a different resource address - see the README's 'Desired capacity drift' section for the required `tofu state mv`."
  type        = bool
  default     = true
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
  type = list(object({
    instance_type     = optional(string)
    weighted_capacity = optional(string)
  }))
  default = []
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
  type = map(object({
    name                      = optional(string)
    policy_type               = optional(string, "TargetTrackingScaling")
    adjustment_type           = optional(string)
    scaling_adjustment        = optional(number)
    cooldown                  = optional(number)
    min_adjustment_magnitude  = optional(number)
    metric_aggregation_type   = optional(string)
    estimated_instance_warmup = optional(number)
    target_tracking_configuration = optional(object({
      target_value     = number
      disable_scale_in = optional(bool, false)
      predefined_metric_specification = optional(object({
        predefined_metric_type = string
        resource_label         = optional(string)
      }))
      customized_metric_specification = optional(object({
        metric_name = optional(string)
        namespace   = optional(string)
        statistic   = optional(string)
        unit        = optional(string)
        metric_dimensions = optional(list(object({
          name  = string
          value = string
        })), [])
      }))
    }))
    step_adjustments = optional(list(object({
      scaling_adjustment          = number
      metric_interval_lower_bound = optional(number)
      metric_interval_upper_bound = optional(number)
    })), [])
    predictive_scaling_configuration = optional(object({
      mode                         = optional(string, "ForecastAndScale")
      scheduling_buffer_time       = optional(number)
      max_capacity_breach_behavior = optional(string)
      max_capacity_buffer          = optional(number)
      metric_specification = optional(object({
        target_value = number
        predefined_scaling_metric_specification = optional(object({
          predefined_metric_type = string
          resource_label         = optional(string)
        }))
        predefined_load_metric_specification = optional(object({
          predefined_metric_type = string
          resource_label         = optional(string)
        }))
      }))
    }))
  }))
  default = {}
}

################################################################################
# Scheduled Actions
################################################################################

variable "scheduled_actions" {
  description = "Map of scheduled actions. Each entry supports `min_size`, `max_size`, `desired_capacity`, `start_time`, `end_time`, `recurrence`, and `time_zone`."
  type = map(object({
    name             = optional(string)
    min_size         = optional(number)
    max_size         = optional(number)
    desired_capacity = optional(number)
    start_time       = optional(string)
    end_time         = optional(string)
    recurrence       = optional(string)
    time_zone        = optional(string)
  }))
  default = {}
}

################################################################################
# Warm Pool
################################################################################

variable "warm_pool" {
  description = "Warm pool configuration. Set to `{}` to enable with defaults. Supports `pool_state`, `min_size`, `max_group_prepared_capacity`, and `instance_reuse_policy`."
  type = object({
    pool_state                  = optional(string, "Stopped")
    min_size                    = optional(number, 0)
    max_group_prepared_capacity = optional(number)
    instance_reuse_policy = optional(object({
      reuse_on_scale_in = optional(bool, false)
    }))
  })
  default = null
}

################################################################################
# Instance Refresh
################################################################################

variable "instance_refresh" {
  description = "Instance refresh configuration. Set to `{}` to enable with defaults. Supports `strategy`, `preferences`, and `triggers`."
  type = object({
    strategy = optional(string, "Rolling")
    triggers = optional(list(string))
    preferences = optional(object({
      min_healthy_percentage       = optional(number, 90)
      instance_warmup              = optional(number)
      checkpoint_delay             = optional(number)
      checkpoint_percentages       = optional(list(number))
      skip_matching                = optional(bool)
      auto_rollback                = optional(bool)
      scale_in_protected_instances = optional(string)
      standby_instances            = optional(string)
    }))
  })
  default = null
}

################################################################################
# Lifecycle Hooks
################################################################################

variable "lifecycle_hooks" {
  description = "Map of lifecycle hooks. Each entry supports `lifecycle_transition`, `default_result`, `heartbeat_timeout`, `notification_metadata`, `notification_target_arn`, and `role_arn`."
  type = map(object({
    name                    = optional(string)
    lifecycle_transition    = string
    default_result          = optional(string, "CONTINUE")
    heartbeat_timeout       = optional(number, 3600)
    notification_metadata   = optional(string)
    notification_target_arn = optional(string)
    role_arn                = optional(string)
  }))
  default = {}
}

################################################################################
# Notification Configuration
################################################################################

variable "notification_configurations" {
  description = "Map of notification configurations. Each entry requires `topic_arn` and `notifications` (list of event types)."
  type = map(object({
    topic_arn     = string
    notifications = list(string)
  }))
  default = {}
}

################################################################################
# Traffic Source Attachments
################################################################################

variable "traffic_source_attachments" {
  description = "Map of traffic source attachments (ALB/NLB target group ARNs). Each entry requires `traffic_source_identifier` and optionally `traffic_source_type`."
  type = map(object({
    traffic_source_identifier = string
    traffic_source_type       = optional(string, "elbv2")
  }))
  default = {}
}

variable "target_group_arns" {
  description = "List of target group ARNs to attach to the ASG (convenience alias for ALB/NLB)"
  type        = list(string)
  default     = []
}
