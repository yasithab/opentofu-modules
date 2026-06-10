data "aws_partition" "current" {}

locals {
  enabled = var.enabled

  create_launch_template      = local.enabled && var.create_launch_template
  create_security_group       = local.enabled && var.create_security_group
  create_iam_instance_profile = local.enabled && var.create_iam_instance_profile

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  launch_template_id = var.create_launch_template ? aws_launch_template.this.id : var.launch_template_id

  # Name of whichever ASG variant is active (see the two aws_autoscaling_group
  # resources below). try() falls through to the enabled copy.
  autoscaling_group_name = try(aws_autoscaling_group.this.name, aws_autoscaling_group.tracked.name, "")

  security_group_ids = compact(concat(
    var.create_security_group ? [aws_security_group.this.id] : [],
    var.security_group_ids,
  ))
}

################################################################################
# Launch Template
################################################################################

resource "aws_launch_template" "this" {
  name_prefix = "${var.name}-"
  description = var.launch_template_description
  image_id    = var.image_id

  instance_type = var.use_mixed_instances_policy ? null : var.instance_type
  key_name      = var.key_name
  ebs_optimized = var.ebs_optimized
  user_data     = var.user_data

  dynamic "monitoring" {
    for_each = var.enable_monitoring ? [1] : []

    content {
      enabled = true
    }
  }

  dynamic "metadata_options" {
    for_each = var.metadata_options != null ? [var.metadata_options] : []

    content {
      http_endpoint               = metadata_options.value.http_endpoint
      http_tokens                 = metadata_options.value.http_tokens
      http_put_response_hop_limit = metadata_options.value.http_put_response_hop_limit
      instance_metadata_tags      = metadata_options.value.instance_metadata_tags
    }
  }

  dynamic "iam_instance_profile" {
    for_each = var.create_iam_instance_profile ? [1] : var.iam_instance_profile_arn != null ? [1] : []

    content {
      arn = var.create_iam_instance_profile ? aws_iam_instance_profile.this.arn : var.iam_instance_profile_arn
    }
  }

  dynamic "network_interfaces" {
    for_each = var.network_interfaces

    content {
      associate_public_ip_address = network_interfaces.value.associate_public_ip_address
      delete_on_termination       = network_interfaces.value.delete_on_termination
      description                 = network_interfaces.value.description
      device_index                = coalesce(network_interfaces.value.device_index, network_interfaces.key)
      security_groups             = network_interfaces.value.security_groups != null ? network_interfaces.value.security_groups : local.security_group_ids
      subnet_id                   = network_interfaces.value.subnet_id
    }
  }

  vpc_security_group_ids = length(var.network_interfaces) == 0 ? local.security_group_ids : null

  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings

    content {
      device_name = block_device_mappings.value.device_name

      dynamic "ebs" {
        for_each = block_device_mappings.value.ebs != null ? [block_device_mappings.value.ebs] : []

        content {
          volume_size           = ebs.value.volume_size
          volume_type           = ebs.value.volume_type
          encrypted             = ebs.value.encrypted
          kms_key_id            = ebs.value.kms_key_id
          iops                  = ebs.value.iops
          throughput            = ebs.value.throughput
          delete_on_termination = ebs.value.delete_on_termination
          snapshot_id           = ebs.value.snapshot_id
        }
      }
    }
  }

  dynamic "placement" {
    for_each = var.placement != null ? [var.placement] : []

    content {
      availability_zone = placement.value.availability_zone
      group_name        = placement.value.group_name
      tenancy           = placement.value.tenancy
    }
  }

  dynamic "tag_specifications" {
    for_each = var.tag_specifications

    content {
      resource_type = tag_specifications.value.resource_type
      tags          = merge(local.tags, tag_specifications.value.tags)
    }
  }

  tags = local.tags

  lifecycle {
    enabled               = local.create_launch_template
    create_before_destroy = true
  }
}

################################################################################
# IAM Instance Profile and Role
################################################################################

data "aws_iam_policy_document" "ec2_assume_role" {
  count = local.create_iam_instance_profile ? 1 : 0

  statement {
    sid     = "EC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.${data.aws_partition.current.dns_suffix}"]
    }
  }
}

resource "aws_iam_role" "this" {
  name                  = coalesce(var.iam_role_name, "${var.name}-role")
  description           = var.iam_role_description
  path                  = var.iam_role_path
  permissions_boundary  = var.iam_role_permissions_boundary
  force_detach_policies = true
  assume_role_policy    = data.aws_iam_policy_document.ec2_assume_role[0].json

  tags = local.tags

  lifecycle {
    enabled = local.create_iam_instance_profile
  }
}

resource "aws_iam_instance_profile" "this" {
  name = coalesce(var.iam_role_name, "${var.name}-profile")
  role = aws_iam_role.this.name

  tags = local.tags

  lifecycle {
    enabled = local.create_iam_instance_profile
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = { for k, v in var.iam_role_policy_arns : k => v if local.create_iam_instance_profile }

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "this" {
  for_each = { for k, v in var.iam_role_policies : k => v if local.create_iam_instance_profile }

  name   = each.key
  role   = aws_iam_role.this.id
  policy = each.value
}

################################################################################
# Security Group
################################################################################

resource "aws_security_group" "this" {
  name        = coalesce(var.security_group_name, var.name)
  description = var.security_group_description
  vpc_id      = var.vpc_id

  tags = merge(local.tags, {
    Name = coalesce(var.security_group_name, var.name)
  })

  lifecycle {
    enabled               = local.create_security_group
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = { for k, v in var.security_group_ingress_rules : k => v if local.create_security_group }

  security_group_id = aws_security_group.this.id

  description                  = each.value.description
  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  ip_protocol                  = each.value.ip_protocol
  referenced_security_group_id = each.value.referenced_security_group_id
  prefix_list_id               = each.value.prefix_list_id

  tags = local.tags
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = { for k, v in var.security_group_egress_rules : k => v if local.create_security_group }

  security_group_id = aws_security_group.this.id

  description                  = each.value.description
  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  ip_protocol                  = each.value.ip_protocol
  referenced_security_group_id = each.value.referenced_security_group_id
  prefix_list_id               = each.value.prefix_list_id

  tags = local.tags
}

################################################################################
# Auto Scaling Group
################################################################################

# Two copies of the ASG exist below, differentiated only by `lifecycle { ignore_changes }`:
#
#   - aws_autoscaling_group.this    - ignores out-of-band `desired_capacity` drift
#                                     (default, `ignore_desired_capacity_changes = true`)
#   - aws_autoscaling_group.tracked - `desired_capacity` fully managed by OpenTofu
#                                     (`ignore_desired_capacity_changes = false`)
#
# Exactly one is enabled via mutually exclusive `lifecycle { enabled }` conditions.
# This is the correct workaround for OpenTofu's limitation that `ignore_changes`
# cannot be dynamic - same pattern as the dynamodb module's 3-copy table
# (documented as intentional in CLAUDE.md). Do not consolidate. Keep both
# resource bodies identical except for the lifecycle block.
resource "aws_autoscaling_group" "this" {
  name                      = var.name
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.vpc_zone_identifier
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  default_cooldown          = var.default_cooldown
  default_instance_warmup   = var.default_instance_warmup
  protect_from_scale_in     = var.protect_from_scale_in
  termination_policies      = var.termination_policies
  suspended_processes       = var.suspended_processes
  max_instance_lifetime     = var.max_instance_lifetime
  enabled_metrics           = var.enabled_metrics
  metrics_granularity       = var.metrics_granularity
  service_linked_role_arn   = var.service_linked_role_arn
  capacity_rebalance        = var.capacity_rebalance
  force_delete              = var.force_delete
  wait_for_capacity_timeout = var.wait_for_capacity_timeout
  target_group_arns         = var.target_group_arns

  dynamic "launch_template" {
    for_each = var.use_mixed_instances_policy ? [] : [1]

    content {
      id      = local.launch_template_id
      version = var.launch_template_version
    }
  }

  dynamic "mixed_instances_policy" {
    for_each = var.use_mixed_instances_policy ? [1] : []

    content {
      launch_template {
        launch_template_specification {
          launch_template_id = local.launch_template_id
          version            = var.launch_template_version
        }

        dynamic "override" {
          for_each = var.mixed_instances_override

          content {
            instance_type     = override.value.instance_type
            weighted_capacity = override.value.weighted_capacity
          }
        }
      }

      instances_distribution {
        on_demand_base_capacity                  = var.on_demand_base_capacity
        on_demand_percentage_above_base_capacity = var.on_demand_percentage_above_base_capacity
        spot_allocation_strategy                 = var.spot_allocation_strategy
        spot_instance_pools                      = var.spot_instance_pools
        spot_max_price                           = var.spot_max_price
      }
    }
  }

  dynamic "warm_pool" {
    for_each = var.warm_pool != null ? [var.warm_pool] : []

    content {
      pool_state                  = warm_pool.value.pool_state
      min_size                    = warm_pool.value.min_size
      max_group_prepared_capacity = warm_pool.value.max_group_prepared_capacity

      dynamic "instance_reuse_policy" {
        for_each = warm_pool.value.instance_reuse_policy != null ? [warm_pool.value.instance_reuse_policy] : []

        content {
          reuse_on_scale_in = instance_reuse_policy.value.reuse_on_scale_in
        }
      }
    }
  }

  dynamic "instance_refresh" {
    for_each = var.instance_refresh != null ? [var.instance_refresh] : []

    content {
      strategy = instance_refresh.value.strategy
      triggers = instance_refresh.value.triggers

      dynamic "preferences" {
        for_each = instance_refresh.value.preferences != null ? [instance_refresh.value.preferences] : []

        content {
          min_healthy_percentage       = preferences.value.min_healthy_percentage
          instance_warmup              = preferences.value.instance_warmup
          checkpoint_delay             = preferences.value.checkpoint_delay
          checkpoint_percentages       = preferences.value.checkpoint_percentages
          skip_matching                = preferences.value.skip_matching
          auto_rollback                = preferences.value.auto_rollback
          scale_in_protected_instances = preferences.value.scale_in_protected_instances
          standby_instances            = preferences.value.standby_instances
        }
      }
    }
  }

  dynamic "tag" {
    for_each = local.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    enabled = local.enabled && var.ignore_desired_capacity_changes
    ignore_changes = [
      desired_capacity,
    ]
  }
}

# Variant of aws_autoscaling_group.this with no ignore_changes: `desired_capacity`
# is fully managed by OpenTofu. Enabled when `ignore_desired_capacity_changes = false`.
# See the comment above aws_autoscaling_group.this for the two-resource pattern.
resource "aws_autoscaling_group" "tracked" {
  name                      = var.name
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.vpc_zone_identifier
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  default_cooldown          = var.default_cooldown
  default_instance_warmup   = var.default_instance_warmup
  protect_from_scale_in     = var.protect_from_scale_in
  termination_policies      = var.termination_policies
  suspended_processes       = var.suspended_processes
  max_instance_lifetime     = var.max_instance_lifetime
  enabled_metrics           = var.enabled_metrics
  metrics_granularity       = var.metrics_granularity
  service_linked_role_arn   = var.service_linked_role_arn
  capacity_rebalance        = var.capacity_rebalance
  force_delete              = var.force_delete
  wait_for_capacity_timeout = var.wait_for_capacity_timeout
  target_group_arns         = var.target_group_arns

  dynamic "launch_template" {
    for_each = var.use_mixed_instances_policy ? [] : [1]

    content {
      id      = local.launch_template_id
      version = var.launch_template_version
    }
  }

  dynamic "mixed_instances_policy" {
    for_each = var.use_mixed_instances_policy ? [1] : []

    content {
      launch_template {
        launch_template_specification {
          launch_template_id = local.launch_template_id
          version            = var.launch_template_version
        }

        dynamic "override" {
          for_each = var.mixed_instances_override

          content {
            instance_type     = override.value.instance_type
            weighted_capacity = override.value.weighted_capacity
          }
        }
      }

      instances_distribution {
        on_demand_base_capacity                  = var.on_demand_base_capacity
        on_demand_percentage_above_base_capacity = var.on_demand_percentage_above_base_capacity
        spot_allocation_strategy                 = var.spot_allocation_strategy
        spot_instance_pools                      = var.spot_instance_pools
        spot_max_price                           = var.spot_max_price
      }
    }
  }

  dynamic "warm_pool" {
    for_each = var.warm_pool != null ? [var.warm_pool] : []

    content {
      pool_state                  = warm_pool.value.pool_state
      min_size                    = warm_pool.value.min_size
      max_group_prepared_capacity = warm_pool.value.max_group_prepared_capacity

      dynamic "instance_reuse_policy" {
        for_each = warm_pool.value.instance_reuse_policy != null ? [warm_pool.value.instance_reuse_policy] : []

        content {
          reuse_on_scale_in = instance_reuse_policy.value.reuse_on_scale_in
        }
      }
    }
  }

  dynamic "instance_refresh" {
    for_each = var.instance_refresh != null ? [var.instance_refresh] : []

    content {
      strategy = instance_refresh.value.strategy
      triggers = instance_refresh.value.triggers

      dynamic "preferences" {
        for_each = instance_refresh.value.preferences != null ? [instance_refresh.value.preferences] : []

        content {
          min_healthy_percentage       = preferences.value.min_healthy_percentage
          instance_warmup              = preferences.value.instance_warmup
          checkpoint_delay             = preferences.value.checkpoint_delay
          checkpoint_percentages       = preferences.value.checkpoint_percentages
          skip_matching                = preferences.value.skip_matching
          auto_rollback                = preferences.value.auto_rollback
          scale_in_protected_instances = preferences.value.scale_in_protected_instances
          standby_instances            = preferences.value.standby_instances
        }
      }
    }
  }

  dynamic "tag" {
    for_each = local.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    enabled = local.enabled && !var.ignore_desired_capacity_changes
  }
}

################################################################################
# Scaling Policies
################################################################################

resource "aws_autoscaling_policy" "this" {
  for_each = { for k, v in var.scaling_policies : k => v if local.enabled }

  name                   = coalesce(each.value.name, each.key)
  autoscaling_group_name = local.autoscaling_group_name
  policy_type            = each.value.policy_type

  # Simple / Step scaling
  adjustment_type          = each.value.adjustment_type
  scaling_adjustment       = each.value.scaling_adjustment
  cooldown                 = each.value.cooldown
  min_adjustment_magnitude = each.value.min_adjustment_magnitude
  metric_aggregation_type  = each.value.metric_aggregation_type

  # Estimated instance warmup (target tracking / step)
  estimated_instance_warmup = each.value.estimated_instance_warmup

  # Target tracking
  dynamic "target_tracking_configuration" {
    for_each = each.value.target_tracking_configuration != null ? [each.value.target_tracking_configuration] : []

    content {
      target_value     = target_tracking_configuration.value.target_value
      disable_scale_in = target_tracking_configuration.value.disable_scale_in

      dynamic "predefined_metric_specification" {
        for_each = target_tracking_configuration.value.predefined_metric_specification != null ? [target_tracking_configuration.value.predefined_metric_specification] : []

        content {
          predefined_metric_type = predefined_metric_specification.value.predefined_metric_type
          resource_label         = predefined_metric_specification.value.resource_label
        }
      }

      dynamic "customized_metric_specification" {
        for_each = target_tracking_configuration.value.customized_metric_specification != null ? [target_tracking_configuration.value.customized_metric_specification] : []

        content {
          metric_name = customized_metric_specification.value.metric_name
          namespace   = customized_metric_specification.value.namespace
          statistic   = customized_metric_specification.value.statistic
          unit        = customized_metric_specification.value.unit

          dynamic "metric_dimension" {
            for_each = customized_metric_specification.value.metric_dimensions

            content {
              name  = metric_dimension.value.name
              value = metric_dimension.value.value
            }
          }
        }
      }
    }
  }

  # Step adjustments
  dynamic "step_adjustment" {
    for_each = each.value.step_adjustments

    content {
      scaling_adjustment          = step_adjustment.value.scaling_adjustment
      metric_interval_lower_bound = step_adjustment.value.metric_interval_lower_bound
      metric_interval_upper_bound = step_adjustment.value.metric_interval_upper_bound
    }
  }

  # Predictive scaling
  dynamic "predictive_scaling_configuration" {
    for_each = each.value.predictive_scaling_configuration != null ? [each.value.predictive_scaling_configuration] : []

    content {
      mode                         = predictive_scaling_configuration.value.mode
      scheduling_buffer_time       = predictive_scaling_configuration.value.scheduling_buffer_time
      max_capacity_breach_behavior = predictive_scaling_configuration.value.max_capacity_breach_behavior
      max_capacity_buffer          = predictive_scaling_configuration.value.max_capacity_buffer

      dynamic "metric_specification" {
        for_each = predictive_scaling_configuration.value.metric_specification != null ? [predictive_scaling_configuration.value.metric_specification] : []

        content {
          target_value = metric_specification.value.target_value

          dynamic "predefined_scaling_metric_specification" {
            for_each = metric_specification.value.predefined_scaling_metric_specification != null ? [metric_specification.value.predefined_scaling_metric_specification] : []

            content {
              predefined_metric_type = predefined_scaling_metric_specification.value.predefined_metric_type
              resource_label         = predefined_scaling_metric_specification.value.resource_label
            }
          }

          dynamic "predefined_load_metric_specification" {
            for_each = metric_specification.value.predefined_load_metric_specification != null ? [metric_specification.value.predefined_load_metric_specification] : []

            content {
              predefined_metric_type = predefined_load_metric_specification.value.predefined_metric_type
              resource_label         = predefined_load_metric_specification.value.resource_label
            }
          }
        }
      }
    }
  }
}

################################################################################
# Scheduled Actions
################################################################################

resource "aws_autoscaling_schedule" "this" {
  for_each = { for k, v in var.scheduled_actions : k => v if local.enabled }

  scheduled_action_name  = coalesce(each.value.name, each.key)
  autoscaling_group_name = local.autoscaling_group_name
  min_size               = each.value.min_size
  max_size               = each.value.max_size
  desired_capacity       = each.value.desired_capacity
  start_time             = each.value.start_time
  end_time               = each.value.end_time
  recurrence             = each.value.recurrence
  time_zone              = each.value.time_zone
}

################################################################################
# Lifecycle Hooks
################################################################################

resource "aws_autoscaling_lifecycle_hook" "this" {
  for_each = { for k, v in var.lifecycle_hooks : k => v if local.enabled }

  name                    = coalesce(each.value.name, each.key)
  autoscaling_group_name  = local.autoscaling_group_name
  lifecycle_transition    = each.value.lifecycle_transition
  default_result          = each.value.default_result
  heartbeat_timeout       = each.value.heartbeat_timeout
  notification_metadata   = each.value.notification_metadata
  notification_target_arn = each.value.notification_target_arn
  role_arn                = each.value.role_arn
}

################################################################################
# Notification Configurations
################################################################################

resource "aws_autoscaling_notification" "this" {
  for_each = { for k, v in var.notification_configurations : k => v if local.enabled }

  group_names   = [local.autoscaling_group_name]
  topic_arn     = each.value.topic_arn
  notifications = each.value.notifications
}

################################################################################
# Traffic Source Attachments
################################################################################

resource "aws_autoscaling_traffic_source_attachment" "this" {
  for_each = { for k, v in var.traffic_source_attachments : k => v if local.enabled }

  autoscaling_group_name = local.autoscaling_group_name

  traffic_source {
    identifier = each.value.traffic_source_identifier
    type       = each.value.traffic_source_type
  }
}
