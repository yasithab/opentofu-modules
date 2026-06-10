data "aws_partition" "current" {}

locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  partition  = data.aws_partition.current.partition
  dns_suffix = data.aws_partition.current.dns_suffix

  # Effective service role ARN: created by this module or passed in by the caller
  service_role_arn = var.create_service_role ? aws_iam_role.service.arn : var.service_role_arn
}

################################################################################
# Compute Environment
################################################################################

resource "aws_batch_compute_environment" "this" {
  name         = var.name
  type         = var.compute_environment_type
  state        = var.compute_environment_state
  service_role = var.compute_environment_type == "MANAGED" ? local.service_role_arn : null

  dynamic "update_policy" {
    for_each = var.update_policy != null ? [var.update_policy] : []

    content {
      job_execution_timeout_minutes = update_policy.value.job_execution_timeout_minutes
      terminate_jobs_on_update      = update_policy.value.terminate_jobs_on_update
    }
  }

  dynamic "compute_resources" {
    for_each = var.compute_resources != null ? [var.compute_resources] : []

    content {
      type                = compute_resources.value.type
      allocation_strategy = compute_resources.value.allocation_strategy
      min_vcpus           = compute_resources.value.min_vcpus
      max_vcpus           = compute_resources.value.max_vcpus
      desired_vcpus       = compute_resources.value.desired_vcpus

      instance_type       = compute_resources.value.instance_type
      instance_role       = compute_resources.value.instance_role
      image_id            = compute_resources.value.image_id
      ec2_key_pair        = compute_resources.value.ec2_key_pair
      bid_percentage      = compute_resources.value.bid_percentage
      spot_iam_fleet_role = compute_resources.value.spot_iam_fleet_role

      subnets = compute_resources.value.subnets
      security_group_ids = compact(concat(
        compute_resources.value.security_group_ids,
        var.create_security_group ? [aws_security_group.this.id] : []
      ))

      tags = compute_resources.value.tags

      dynamic "ec2_configuration" {
        for_each = compute_resources.value.ec2_configuration != null ? [compute_resources.value.ec2_configuration] : []

        content {
          image_id_override = ec2_configuration.value.image_id_override
          image_type        = ec2_configuration.value.image_type
        }
      }

      dynamic "launch_template" {
        for_each = compute_resources.value.launch_template != null ? [compute_resources.value.launch_template] : []

        content {
          launch_template_id   = launch_template.value.launch_template_id
          launch_template_name = launch_template.value.launch_template_name
          version              = launch_template.value.version
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
  state    = each.value.state
  priority = each.value.priority

  scheduling_policy_arn = each.value.scheduling_policy_arn != null ? each.value.scheduling_policy_arn : (
    each.value.scheduling_policy_key != null ? aws_batch_scheduling_policy.this[each.value.scheduling_policy_key].arn : null
  )

  dynamic "compute_environment_order" {
    for_each = each.value.compute_environment_order != null ? each.value.compute_environment_order : [
      { order = 1, compute_environment = aws_batch_compute_environment.this.arn }
    ]

    content {
      order               = compute_environment_order.value.order
      compute_environment = coalesce(compute_environment_order.value.compute_environment, aws_batch_compute_environment.this.arn)
    }
  }

  dynamic "job_state_time_limit_action" {
    for_each = each.value.job_state_time_limit_actions

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
    for_each = each.value.fair_share_policy != null ? [each.value.fair_share_policy] : []

    content {
      compute_reservation = fair_share_policy.value.compute_reservation
      share_decay_seconds = fair_share_policy.value.share_decay_seconds

      dynamic "share_distribution" {
        for_each = fair_share_policy.value.share_distribution

        content {
          share_identifier = share_distribution.value.share_identifier
          weight_factor    = share_distribution.value.weight_factor
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
  type                  = each.value.type
  platform_capabilities = each.value.platform_capabilities
  propagate_tags        = each.value.propagate_tags

  scheduling_priority = each.value.scheduling_priority
  parameters          = each.value.parameters

  container_properties = each.value.container_properties
  node_properties      = each.value.node_properties
  ecs_properties       = each.value.ecs_properties

  dynamic "retry_strategy" {
    for_each = each.value.retry_strategy != null ? [each.value.retry_strategy] : []

    content {
      attempts = retry_strategy.value.attempts

      dynamic "evaluate_on_exit" {
        for_each = retry_strategy.value.evaluate_on_exit

        content {
          action           = evaluate_on_exit.value.action
          on_exit_code     = evaluate_on_exit.value.on_exit_code
          on_reason        = evaluate_on_exit.value.on_reason
          on_status_reason = evaluate_on_exit.value.on_status_reason
        }
      }
    }
  }

  dynamic "timeout" {
    for_each = each.value.timeout != null ? [each.value.timeout] : []

    content {
      attempt_duration_seconds = timeout.value.attempt_duration_seconds
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

# trivy:ignore:AVD-AWS-0104 - Egress rules are caller-controlled via var.security_group_rules
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
          Service = "batch.${local.dns_suffix}"
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
          Service = "ecs-tasks.${local.dns_suffix}"
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
          Service = "ecs-tasks.${local.dns_suffix}"
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
