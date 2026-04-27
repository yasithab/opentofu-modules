data "aws_partition" "current" {}

locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  partition = data.aws_partition.current.partition
}

################################################################################
# Compute Environment
################################################################################

resource "aws_batch_compute_environment" "this" {
  name         = var.name
  type         = var.compute_environment_type
  state        = var.compute_environment_state
  service_role = var.compute_environment_type == "MANAGED" ? aws_iam_role.service.arn : null

  dynamic "update_policy" {
    for_each = var.update_policy != null ? [var.update_policy] : []

    content {
      job_execution_timeout_minutes = try(update_policy.value.job_execution_timeout_minutes, 30)
      terminate_jobs_on_update      = try(update_policy.value.terminate_jobs_on_update, false)
    }
  }

  dynamic "compute_resources" {
    for_each = var.compute_resources != null ? [var.compute_resources] : []

    content {
      type                = try(compute_resources.value.type, "FARGATE")
      allocation_strategy = try(compute_resources.value.allocation_strategy, null)
      min_vcpus           = try(compute_resources.value.min_vcpus, 0)
      max_vcpus           = try(compute_resources.value.max_vcpus, 16)
      desired_vcpus       = try(compute_resources.value.desired_vcpus, null)

      instance_type       = try(compute_resources.value.instance_type, null)
      instance_role       = try(compute_resources.value.instance_role, null)
      image_id            = try(compute_resources.value.image_id, null)
      ec2_key_pair        = try(compute_resources.value.ec2_key_pair, null)
      bid_percentage      = try(compute_resources.value.bid_percentage, null)
      spot_iam_fleet_role = try(compute_resources.value.spot_iam_fleet_role, null)

      subnets = try(compute_resources.value.subnets, [])
      security_group_ids = compact(concat(
        try(compute_resources.value.security_group_ids, []),
        var.create_security_group ? [aws_security_group.this.id] : []
      ))

      tags = try(compute_resources.value.tags, null)

      dynamic "ec2_configuration" {
        for_each = try(compute_resources.value.ec2_configuration, null) != null ? [compute_resources.value.ec2_configuration] : []

        content {
          image_id_override = try(ec2_configuration.value.image_id_override, null)
          image_type        = try(ec2_configuration.value.image_type, null)
        }
      }

      dynamic "launch_template" {
        for_each = try(compute_resources.value.launch_template, null) != null ? [compute_resources.value.launch_template] : []

        content {
          launch_template_id   = try(launch_template.value.launch_template_id, null)
          launch_template_name = try(launch_template.value.launch_template_name, null)
          version              = try(launch_template.value.version, null)
        }
      }
    }
  }

  dynamic "eks_configuration" {
    for_each = var.eks_configuration != null ? [var.eks_configuration] : []

    content {
      eks_cluster_arn      = eks_configuration.value.eks_cluster_arn
      kubernetes_namespace = eks_configuration.value.kubernetes_namespace
    }
  }

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }

  depends_on = [
    aws_iam_role_policy_attachment.service,
  ]
}

################################################################################
# Job Queue
################################################################################

resource "aws_batch_job_queue" "this" {
  for_each = { for k, v in var.job_queues : k => v if local.enabled }

  name     = each.value.name
  state    = try(each.value.state, "ENABLED")
  priority = try(each.value.priority, 1)

  scheduling_policy_arn = try(each.value.scheduling_policy_arn, try(
    aws_batch_scheduling_policy.this[each.value.scheduling_policy_key].arn,
    null
  ))

  dynamic "compute_environment_order" {
    for_each = try(each.value.compute_environment_order, [
      { order = 1, compute_environment = aws_batch_compute_environment.this.arn }
    ])

    content {
      order = compute_environment_order.value.order
      compute_environment = try(
        compute_environment_order.value.compute_environment,
        aws_batch_compute_environment.this.arn
      )
    }
  }

  dynamic "job_state_time_limit_action" {
    for_each = try(each.value.job_state_time_limit_actions, [])

    content {
      action           = job_state_time_limit_action.value.action
      max_time_seconds = job_state_time_limit_action.value.max_time_seconds
      reason           = job_state_time_limit_action.value.reason
      state            = job_state_time_limit_action.value.state
    }
  }

  tags = local.tags
}

################################################################################
# Scheduling Policy
################################################################################

resource "aws_batch_scheduling_policy" "this" {
  for_each = { for k, v in var.scheduling_policies : k => v if local.enabled }

  name = each.value.name

  dynamic "fair_share_policy" {
    for_each = try(each.value.fair_share_policy, null) != null ? [each.value.fair_share_policy] : []

    content {
      compute_reservation = try(fair_share_policy.value.compute_reservation, 0)
      share_decay_seconds = try(fair_share_policy.value.share_decay_seconds, 0)

      dynamic "share_distribution" {
        for_each = try(fair_share_policy.value.share_distribution, [])

        content {
          share_identifier = share_distribution.value.share_identifier
          weight_factor    = try(share_distribution.value.weight_factor, 1)
        }
      }
    }
  }

  tags = local.tags
}

################################################################################
# Job Definition
################################################################################

resource "aws_batch_job_definition" "this" {
  for_each = { for k, v in var.job_definitions : k => v if local.enabled }

  name                  = each.value.name
  type                  = try(each.value.type, "container")
  platform_capabilities = try(each.value.platform_capabilities, ["FARGATE"])
  propagate_tags        = try(each.value.propagate_tags, true)

  scheduling_priority = try(each.value.scheduling_priority, null)
  parameters          = try(each.value.parameters, null)

  container_properties = try(each.value.container_properties, null)
  node_properties      = try(each.value.node_properties, null)
  ecs_properties       = try(each.value.ecs_properties, null)

  dynamic "retry_strategy" {
    for_each = try(each.value.retry_strategy, null) != null ? [each.value.retry_strategy] : []

    content {
      attempts = try(retry_strategy.value.attempts, 3)

      dynamic "evaluate_on_exit" {
        for_each = try(retry_strategy.value.evaluate_on_exit, [])

        content {
          action           = evaluate_on_exit.value.action
          on_exit_code     = try(evaluate_on_exit.value.on_exit_code, null)
          on_reason        = try(evaluate_on_exit.value.on_reason, null)
          on_status_reason = try(evaluate_on_exit.value.on_status_reason, null)
        }
      }
    }
  }

  dynamic "timeout" {
    for_each = try(each.value.timeout, null) != null ? [each.value.timeout] : []

    content {
      attempt_duration_seconds = try(timeout.value.attempt_duration_seconds, null)
    }
  }

  tags = local.tags
}

################################################################################
# Security Group
################################################################################

resource "aws_security_group" "this" {
  name        = "${var.name}-batch"
  description = "Security group for AWS Batch compute environment - ${var.name}"
  vpc_id      = var.vpc_id

  tags = merge(local.tags, {
    Name = "${var.name}-batch"
  })

  lifecycle {
    enabled               = local.enabled && var.create_security_group
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = { for k, v in var.security_group_rules : k => v if local.enabled && var.create_security_group && try(v.type, "egress") == "egress" }

  security_group_id = aws_security_group.this.id

  cidr_ipv4                    = try(each.value.cidr_ipv4, null)
  cidr_ipv6                    = try(each.value.cidr_ipv6, null)
  description                  = try(each.value.description, null)
  from_port                    = try(each.value.from_port, null)
  to_port                      = try(each.value.to_port, null)
  ip_protocol                  = try(each.value.ip_protocol, "-1")
  prefix_list_id               = try(each.value.prefix_list_id, null)
  referenced_security_group_id = try(each.value.referenced_security_group_id, null)

  tags = merge(local.tags, try(each.value.tags, {}))
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = { for k, v in var.security_group_rules : k => v if local.enabled && var.create_security_group && try(v.type, "ingress") == "ingress" }

  security_group_id = aws_security_group.this.id

  cidr_ipv4                    = try(each.value.cidr_ipv4, null)
  cidr_ipv6                    = try(each.value.cidr_ipv6, null)
  description                  = try(each.value.description, null)
  from_port                    = try(each.value.from_port, null)
  to_port                      = try(each.value.to_port, null)
  ip_protocol                  = try(each.value.ip_protocol, "-1")
  prefix_list_id               = try(each.value.prefix_list_id, null)
  referenced_security_group_id = try(each.value.referenced_security_group_id, null)

  tags = merge(local.tags, try(each.value.tags, {}))
}

################################################################################
# IAM - Batch Service Role
################################################################################

resource "aws_iam_role" "service" {
  name = "${var.name}-batch-service"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "batch.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_service_role
  }
}

resource "aws_iam_role_policy_attachment" "service" {
  role       = aws_iam_role.service.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSBatchServiceRole"

  lifecycle {
    enabled = local.enabled && var.create_service_role
  }
}

################################################################################
# IAM - Execution Role (for Fargate)
################################################################################

resource "aws_iam_role" "execution" {
  name = "${var.name}-batch-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_execution_role
  }
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

  lifecycle {
    enabled = local.enabled && var.create_execution_role
  }
}

resource "aws_iam_role_policy_attachment" "execution_additional" {
  for_each = { for k, v in var.execution_role_policies : k => v if local.enabled && var.create_execution_role }

  role       = aws_iam_role.execution.name
  policy_arn = each.value
}

################################################################################
# IAM - Job Role
################################################################################

resource "aws_iam_role" "job" {
  name = "${var.name}-batch-job"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_job_role
  }
}

resource "aws_iam_role_policy_attachment" "job" {
  for_each = { for k, v in var.job_role_policies : k => v if local.enabled && var.create_job_role }

  role       = aws_iam_role.job.name
  policy_arn = each.value
}
