locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  launch_template_id = var.create_launch_template ? aws_launch_template.this.id : var.launch_template_id

  security_group_ids = compact(concat(
    var.create_security_group ? [aws_security_group.this.id] : [],
    var.security_group_ids,
  ))
}

################################################################################
# Launch Template
################################################################################

resource "aws_launch_template" "this" {
  name        = var.name
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
    for_each = length(var.metadata_options) > 0 ? [var.metadata_options] : []

    content {
      http_endpoint               = try(metadata_options.value.http_endpoint, "enabled")
      http_tokens                 = try(metadata_options.value.http_tokens, "required")
      http_put_response_hop_limit = try(metadata_options.value.http_put_response_hop_limit, 2)
      instance_metadata_tags      = try(metadata_options.value.instance_metadata_tags, null)
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
      associate_public_ip_address = try(network_interfaces.value.associate_public_ip_address, null)
      delete_on_termination       = try(network_interfaces.value.delete_on_termination, true)
      description                 = try(network_interfaces.value.description, null)
      device_index                = try(network_interfaces.value.device_index, network_interfaces.key)
      security_groups             = try(network_interfaces.value.security_groups, local.security_group_ids)
      subnet_id                   = try(network_interfaces.value.subnet_id, null)
    }
  }

  vpc_security_group_ids = length(var.network_interfaces) == 0 ? local.security_group_ids : null

  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings

    content {
      device_name = block_device_mappings.value.device_name

      dynamic "ebs" {
        for_each = try([block_device_mappings.value.ebs], [])

        content {
          volume_size           = try(ebs.value.volume_size, null)
          volume_type           = try(ebs.value.volume_type, "gp3")
          encrypted             = try(ebs.value.encrypted, true)
          kms_key_id            = try(ebs.value.kms_key_id, null)
          iops                  = try(ebs.value.iops, null)
          throughput            = try(ebs.value.throughput, null)
          delete_on_termination = try(ebs.value.delete_on_termination, true)
          snapshot_id           = try(ebs.value.snapshot_id, null)
        }
      }
    }
  }

  dynamic "placement" {
    for_each = length(var.placement) > 0 ? [var.placement] : []

    content {
      availability_zone = try(placement.value.availability_zone, null)
      group_name        = try(placement.value.group_name, null)
      tenancy           = try(placement.value.tenancy, null)
    }
  }

  dynamic "tag_specifications" {
    for_each = var.tag_specifications

    content {
      resource_type = tag_specifications.value.resource_type
      tags          = merge(local.tags, try(tag_specifications.value.tags, {}))
    }
  }

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_launch_template
  }
}

################################################################################
# IAM Instance Profile and Role
################################################################################

data "aws_iam_policy_document" "ec2_assume_role" {
  count = var.enabled && var.create_iam_instance_profile ? 1 : 0

  statement {
    sid     = "EC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
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
    enabled = local.enabled && var.create_iam_instance_profile
  }
}

resource "aws_iam_instance_profile" "this" {
  name = coalesce(var.iam_role_name, "${var.name}-profile")
  role = aws_iam_role.this.name

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_iam_instance_profile
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = { for k, v in var.iam_role_policy_arns : k => v if local.enabled && var.create_iam_instance_profile }

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "this" {
  for_each = { for k, v in var.iam_role_policies : k => v if local.enabled && var.create_iam_instance_profile }

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
    enabled               = local.enabled && var.create_security_group
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = { for k, v in var.security_group_ingress_rules : k => v if local.enabled && var.create_security_group }

  security_group_id = aws_security_group.this.id

  description                  = try(each.value.description, null)
  cidr_ipv4                    = try(each.value.cidr_ipv4, null)
  cidr_ipv6                    = try(each.value.cidr_ipv6, null)
  from_port                    = try(each.value.from_port, null)
  to_port                      = try(each.value.to_port, null)
  ip_protocol                  = try(each.value.ip_protocol, "tcp")
  referenced_security_group_id = try(each.value.referenced_security_group_id, null)
  prefix_list_id               = try(each.value.prefix_list_id, null)

  tags = local.tags
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = { for k, v in var.security_group_egress_rules : k => v if local.enabled && var.create_security_group }

  security_group_id = aws_security_group.this.id

  description                  = try(each.value.description, null)
  cidr_ipv4                    = try(each.value.cidr_ipv4, null)
  cidr_ipv6                    = try(each.value.cidr_ipv6, null)
  from_port                    = try(each.value.from_port, null)
  to_port                      = try(each.value.to_port, null)
  ip_protocol                  = try(each.value.ip_protocol, "-1")
  referenced_security_group_id = try(each.value.referenced_security_group_id, null)
  prefix_list_id               = try(each.value.prefix_list_id, null)

  tags = local.tags
}

################################################################################
# Auto Scaling Group
################################################################################

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
            instance_type     = try(override.value.instance_type, null)
            weighted_capacity = try(override.value.weighted_capacity, null)
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
      pool_state                  = try(warm_pool.value.pool_state, "Stopped")
      min_size                    = try(warm_pool.value.min_size, 0)
      max_group_prepared_capacity = try(warm_pool.value.max_group_prepared_capacity, null)

      dynamic "instance_reuse_policy" {
        for_each = try([warm_pool.value.instance_reuse_policy], [])

        content {
          reuse_on_scale_in = try(instance_reuse_policy.value.reuse_on_scale_in, false)
        }
      }
    }
  }

  dynamic "instance_refresh" {
    for_each = var.instance_refresh != null ? [var.instance_refresh] : []

    content {
      strategy = try(instance_refresh.value.strategy, "Rolling")
      triggers = try(instance_refresh.value.triggers, null)

      dynamic "preferences" {
        for_each = try([instance_refresh.value.preferences], [])

        content {
          min_healthy_percentage       = try(preferences.value.min_healthy_percentage, 90)
          instance_warmup              = try(preferences.value.instance_warmup, null)
          checkpoint_delay             = try(preferences.value.checkpoint_delay, null)
          checkpoint_percentages       = try(preferences.value.checkpoint_percentages, null)
          skip_matching                = try(preferences.value.skip_matching, null)
          auto_rollback                = try(preferences.value.auto_rollback, null)
          scale_in_protected_instances = try(preferences.value.scale_in_protected_instances, null)
          standby_instances            = try(preferences.value.standby_instances, null)
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
    enabled = local.enabled
    ignore_changes = [
      desired_capacity,
    ]
  }
}

################################################################################
# Scaling Policies
################################################################################

resource "aws_autoscaling_policy" "this" {
  for_each = { for k, v in var.scaling_policies : k => v if local.enabled }

  name                   = try(each.value.name, each.key)
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = try(each.value.policy_type, "TargetTrackingScaling")

  # Simple / Step scaling
  adjustment_type          = try(each.value.adjustment_type, null)
  scaling_adjustment       = try(each.value.scaling_adjustment, null)
  cooldown                 = try(each.value.cooldown, null)
  min_adjustment_magnitude = try(each.value.min_adjustment_magnitude, null)
  metric_aggregation_type  = try(each.value.metric_aggregation_type, null)

  # Estimated instance warmup (target tracking / step)
  estimated_instance_warmup = try(each.value.estimated_instance_warmup, null)

  # Target tracking
  dynamic "target_tracking_configuration" {
    for_each = try([each.value.target_tracking_configuration], [])

    content {
      target_value     = target_tracking_configuration.value.target_value
      disable_scale_in = try(target_tracking_configuration.value.disable_scale_in, false)

      dynamic "predefined_metric_specification" {
        for_each = try([target_tracking_configuration.value.predefined_metric_specification], [])

        content {
          predefined_metric_type = predefined_metric_specification.value.predefined_metric_type
          resource_label         = try(predefined_metric_specification.value.resource_label, null)
        }
      }

      dynamic "customized_metric_specification" {
        for_each = try([target_tracking_configuration.value.customized_metric_specification], [])

        content {
          metric_name = try(customized_metric_specification.value.metric_name, null)
          namespace   = try(customized_metric_specification.value.namespace, null)
          statistic   = try(customized_metric_specification.value.statistic, null)
          unit        = try(customized_metric_specification.value.unit, null)

          dynamic "metric_dimension" {
            for_each = try(customized_metric_specification.value.metric_dimensions, [])

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
    for_each = try(each.value.step_adjustments, [])

    content {
      scaling_adjustment          = step_adjustment.value.scaling_adjustment
      metric_interval_lower_bound = try(step_adjustment.value.metric_interval_lower_bound, null)
      metric_interval_upper_bound = try(step_adjustment.value.metric_interval_upper_bound, null)
    }
  }

  # Predictive scaling
  dynamic "predictive_scaling_configuration" {
    for_each = try([each.value.predictive_scaling_configuration], [])

    content {
      mode                         = try(predictive_scaling_configuration.value.mode, "ForecastAndScale")
      scheduling_buffer_time       = try(predictive_scaling_configuration.value.scheduling_buffer_time, null)
      max_capacity_breach_behavior = try(predictive_scaling_configuration.value.max_capacity_breach_behavior, null)
      max_capacity_buffer          = try(predictive_scaling_configuration.value.max_capacity_buffer, null)

      dynamic "metric_specification" {
        for_each = try([predictive_scaling_configuration.value.metric_specification], [])

        content {
          target_value = metric_specification.value.target_value

          dynamic "predefined_scaling_metric_specification" {
            for_each = try([metric_specification.value.predefined_scaling_metric_specification], [])

            content {
              predefined_metric_type = predefined_scaling_metric_specification.value.predefined_metric_type
              resource_label         = try(predefined_scaling_metric_specification.value.resource_label, null)
            }
          }

          dynamic "predefined_load_metric_specification" {
            for_each = try([metric_specification.value.predefined_load_metric_specification], [])

            content {
              predefined_metric_type = predefined_load_metric_specification.value.predefined_metric_type
              resource_label         = try(predefined_load_metric_specification.value.resource_label, null)
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

  scheduled_action_name  = try(each.value.name, each.key)
  autoscaling_group_name = aws_autoscaling_group.this.name
  min_size               = try(each.value.min_size, null)
  max_size               = try(each.value.max_size, null)
  desired_capacity       = try(each.value.desired_capacity, null)
  start_time             = try(each.value.start_time, null)
  end_time               = try(each.value.end_time, null)
  recurrence             = try(each.value.recurrence, null)
  time_zone              = try(each.value.time_zone, null)
}

################################################################################
# Lifecycle Hooks
################################################################################

resource "aws_autoscaling_lifecycle_hook" "this" {
  for_each = { for k, v in var.lifecycle_hooks : k => v if local.enabled }

  name                    = try(each.value.name, each.key)
  autoscaling_group_name  = aws_autoscaling_group.this.name
  lifecycle_transition    = each.value.lifecycle_transition
  default_result          = try(each.value.default_result, "CONTINUE")
  heartbeat_timeout       = try(each.value.heartbeat_timeout, 3600)
  notification_metadata   = try(each.value.notification_metadata, null)
  notification_target_arn = try(each.value.notification_target_arn, null)
  role_arn                = try(each.value.role_arn, null)
}

################################################################################
# Notification Configurations
################################################################################

resource "aws_autoscaling_notification" "this" {
  for_each = { for k, v in var.notification_configurations : k => v if local.enabled }

  group_names   = [aws_autoscaling_group.this.name]
  topic_arn     = each.value.topic_arn
  notifications = each.value.notifications
}

################################################################################
# Traffic Source Attachments
################################################################################

resource "aws_autoscaling_traffic_source_attachment" "this" {
  for_each = { for k, v in var.traffic_source_attachments : k => v if local.enabled }

  autoscaling_group_name = aws_autoscaling_group.this.name

  traffic_source {
    identifier = each.value.traffic_source_identifier
    type       = try(each.value.traffic_source_type, "elbv2")
  }
}
