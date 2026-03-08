################################################################################
# Cluster
################################################################################

locals {
  execute_command_configuration = {
    logging = "OVERRIDE"
    log_configuration = {
      cloud_watch_log_group_name = try(aws_cloudwatch_log_group.this.name, null)
    }
  }

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  dynamic "configuration" {
    for_each = length(var.cluster_configuration) > 0 || var.create_cloudwatch_log_group ? [var.cluster_configuration] : []

    content {
      dynamic "execute_command_configuration" {
        for_each = var.create_cloudwatch_log_group ? [merge(local.execute_command_configuration, try(configuration.value.execute_command_configuration, {}))] : try([configuration.value.execute_command_configuration], [])

        content {
          kms_key_id = try(execute_command_configuration.value.kms_key_id, null)
          logging    = try(execute_command_configuration.value.logging, "DEFAULT")

          dynamic "log_configuration" {
            for_each = try([execute_command_configuration.value.log_configuration], [])

            content {
              cloud_watch_encryption_enabled = try(log_configuration.value.cloud_watch_encryption_enabled, null)
              cloud_watch_log_group_name     = try(log_configuration.value.cloud_watch_log_group_name, null)
              s3_bucket_name                 = try(log_configuration.value.s3_bucket_name, null)
              s3_bucket_encryption_enabled   = try(log_configuration.value.s3_bucket_encryption_enabled, null)
              s3_key_prefix                  = try(log_configuration.value.s3_key_prefix, null)
            }
          }
        }
      }

      dynamic "managed_storage_configuration" {
        for_each = try([configuration.value.managed_storage_configuration], [])

        content {
          fargate_ephemeral_storage_kms_key_id = try(managed_storage_configuration.value.fargate_ephemeral_storage_kms_key_id, null)
          kms_key_id                           = try(managed_storage_configuration.value.kms_key_id, null)
        }
      }
    }
  }

  dynamic "service_connect_defaults" {
    for_each = length(var.cluster_service_connect_defaults) > 0 ? [var.cluster_service_connect_defaults] : []

    content {
      namespace = service_connect_defaults.value.namespace
    }
  }

  dynamic "setting" {
    for_each = flatten([var.cluster_settings])

    content {
      name  = setting.value.name
      value = setting.value.value
    }
  }

  tags = local.tags

  lifecycle {
    enabled = var.enabled
  }
}

################################################################################
# CloudWatch Log Group
################################################################################
resource "aws_cloudwatch_log_group" "this" {
  name              = try(coalesce(var.cloudwatch_log_group_name, "/aws/ecs/${var.cluster_name}"), "")
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id
  log_group_class   = var.cloudwatch_log_group_class
  skip_destroy      = var.cloudwatch_log_group_skip_destroy

  deletion_protection_enabled = var.cloudwatch_log_group_deletion_protection_enabled

  tags = merge(local.tags, var.cloudwatch_log_group_tags)

  lifecycle {
    enabled = var.enabled && var.create_cloudwatch_log_group
  }
}

################################################################################
# Cluster Capacity Providers
################################################################################

locals {
  default_capacity_providers = merge(
    { for k, v in var.fargate_capacity_providers : k => v if var.default_capacity_provider_use_fargate },
    { for k, v in var.autoscaling_capacity_providers : k => v if !var.default_capacity_provider_use_fargate }
  )
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name
  capacity_providers = distinct(concat(
    [for k, v in var.fargate_capacity_providers : try(v.name, k)],
    [for k, v in var.autoscaling_capacity_providers : try(v.name, k)]
  ))

  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-capacity-providers.html#capacity-providers-considerations
  dynamic "default_capacity_provider_strategy" {
    for_each = local.default_capacity_providers
    iterator = strategy

    content {
      capacity_provider = try(strategy.value.name, strategy.key)
      base              = try(strategy.value.default_capacity_provider_strategy.base, null)
      weight            = try(strategy.value.default_capacity_provider_strategy.weight, null)
    }
  }

  depends_on = [
    aws_ecs_capacity_provider.this
  ]

  lifecycle {
    enabled = var.enabled && length(merge(var.fargate_capacity_providers, var.autoscaling_capacity_providers)) > 0
  }
}

################################################################################
# Capacity Provider - Autoscaling Group(s)
################################################################################

resource "aws_ecs_capacity_provider" "this" {
  for_each = { for k, v in var.autoscaling_capacity_providers : k => v if var.enabled }

  name = try(each.value.name, each.key)

  auto_scaling_group_provider {
    auto_scaling_group_arn = each.value.auto_scaling_group_arn
    # When you use managed termination protection, you must also use managed scaling otherwise managed termination protection won't work
    managed_termination_protection = length(try([each.value.managed_scaling], [])) == 0 ? "DISABLED" : try(each.value.managed_termination_protection, null)
    managed_draining               = try(each.value.managed_draining, null)

    dynamic "managed_scaling" {
      for_each = try([each.value.managed_scaling], [])

      content {
        instance_warmup_period    = try(managed_scaling.value.instance_warmup_period, null)
        maximum_scaling_step_size = try(managed_scaling.value.maximum_scaling_step_size, null)
        minimum_scaling_step_size = try(managed_scaling.value.minimum_scaling_step_size, null)
        status                    = try(managed_scaling.value.status, null)
        target_capacity           = try(managed_scaling.value.target_capacity, null)
      }
    }
  }

  cluster = try(each.value.cluster, null)

  dynamic "managed_instances_provider" {
    for_each = try([each.value.managed_instances_provider], [])

    content {
      infrastructure_role_arn = managed_instances_provider.value.infrastructure_role_arn
      propagate_tags          = try(managed_instances_provider.value.propagate_tags, null)

      dynamic "infrastructure_optimization" {
        for_each = try([managed_instances_provider.value.infrastructure_optimization], [])

        content {
          scale_in_after = try(infrastructure_optimization.value.scale_in_after, null)
        }
      }

      dynamic "instance_launch_template" {
        for_each = try([managed_instances_provider.value.instance_launch_template], [])

        content {
          capacity_option_type     = try(instance_launch_template.value.capacity_option_type, null)
          ec2_instance_profile_arn = instance_launch_template.value.ec2_instance_profile_arn
          monitoring               = try(instance_launch_template.value.monitoring, null)

          dynamic "instance_requirements" {
            for_each = try([instance_launch_template.value.instance_requirements], [])

            content {
              accelerator_manufacturers                               = try(instance_requirements.value.accelerator_manufacturers, null)
              accelerator_names                                       = try(instance_requirements.value.accelerator_names, null)
              accelerator_types                                       = try(instance_requirements.value.accelerator_types, null)
              allowed_instance_types                                  = try(instance_requirements.value.allowed_instance_types, null)
              bare_metal                                              = try(instance_requirements.value.bare_metal, null)
              burstable_performance                                   = try(instance_requirements.value.burstable_performance, null)
              cpu_manufacturers                                       = try(instance_requirements.value.cpu_manufacturers, null)
              excluded_instance_types                                 = try(instance_requirements.value.excluded_instance_types, null)
              instance_generations                                    = try(instance_requirements.value.instance_generations, null)
              local_storage                                           = try(instance_requirements.value.local_storage, null)
              local_storage_types                                     = try(instance_requirements.value.local_storage_types, null)
              max_spot_price_as_percentage_of_optimal_on_demand_price = try(instance_requirements.value.max_spot_price_as_percentage_of_optimal_on_demand_price, null)
              on_demand_max_price_percentage_over_lowest_price        = try(instance_requirements.value.on_demand_max_price_percentage_over_lowest_price, null)
              require_hibernate_support                               = try(instance_requirements.value.require_hibernate_support, null)
              spot_max_price_percentage_over_lowest_price             = try(instance_requirements.value.spot_max_price_percentage_over_lowest_price, null)

              dynamic "accelerator_count" {
                for_each = try([instance_requirements.value.accelerator_count], [])
                content {
                  max = try(accelerator_count.value.max, null)
                  min = try(accelerator_count.value.min, null)
                }
              }

              dynamic "accelerator_total_memory_mib" {
                for_each = try([instance_requirements.value.accelerator_total_memory_mib], [])
                content {
                  max = try(accelerator_total_memory_mib.value.max, null)
                  min = try(accelerator_total_memory_mib.value.min, null)
                }
              }

              dynamic "baseline_ebs_bandwidth_mbps" {
                for_each = try([instance_requirements.value.baseline_ebs_bandwidth_mbps], [])
                content {
                  max = try(baseline_ebs_bandwidth_mbps.value.max, null)
                  min = try(baseline_ebs_bandwidth_mbps.value.min, null)
                }
              }

              dynamic "memory_gib_per_vcpu" {
                for_each = try([instance_requirements.value.memory_gib_per_vcpu], [])
                content {
                  max = try(memory_gib_per_vcpu.value.max, null)
                  min = try(memory_gib_per_vcpu.value.min, null)
                }
              }

              dynamic "memory_mib" {
                for_each = try([instance_requirements.value.memory_mib], [])
                content {
                  max = try(memory_mib.value.max, null)
                  min = memory_mib.value.min
                }
              }

              dynamic "network_bandwidth_gbps" {
                for_each = try([instance_requirements.value.network_bandwidth_gbps], [])
                content {
                  max = try(network_bandwidth_gbps.value.max, null)
                  min = try(network_bandwidth_gbps.value.min, null)
                }
              }

              dynamic "network_interface_count" {
                for_each = try([instance_requirements.value.network_interface_count], [])
                content {
                  max = try(network_interface_count.value.max, null)
                  min = try(network_interface_count.value.min, null)
                }
              }

              dynamic "total_local_storage_gb" {
                for_each = try([instance_requirements.value.total_local_storage_gb], [])
                content {
                  max = try(total_local_storage_gb.value.max, null)
                  min = try(total_local_storage_gb.value.min, null)
                }
              }

              dynamic "vcpu_count" {
                for_each = try([instance_requirements.value.vcpu_count], [])
                content {
                  max = try(vcpu_count.value.max, null)
                  min = vcpu_count.value.min
                }
              }
            }
          }

          dynamic "network_configuration" {
            for_each = try([instance_launch_template.value.network_configuration], [])

            content {
              security_groups = try(network_configuration.value.security_groups, null)
              subnets         = network_configuration.value.subnets
            }
          }

          dynamic "storage_configuration" {
            for_each = try([instance_launch_template.value.storage_configuration], [])

            content {
              storage_size_gib = storage_configuration.value.storage_size_gib
            }
          }
        }
      }
    }
  }

  tags = merge(local.tags, try(each.value.tags, {}))
}

################################################################################
# Task Execution - IAM Role
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
################################################################################

locals {
  task_exec_iam_role_name = try(coalesce(var.task_exec_iam_role_name, var.cluster_name), "")

  create_task_exec_iam_role = var.enabled && var.create_task_exec_iam_role
  create_task_exec_policy   = local.create_task_exec_iam_role && var.create_task_exec_policy
}

data "aws_iam_policy_document" "task_exec_assume" {
  count = local.create_task_exec_iam_role ? 1 : 0

  statement {
    sid     = "ECSTaskExecutionAssumeRole"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_exec" {
  name        = var.task_exec_iam_role_use_name_prefix ? null : local.task_exec_iam_role_name
  name_prefix = var.task_exec_iam_role_use_name_prefix ? "${local.task_exec_iam_role_name}-" : null
  path        = var.task_exec_iam_role_path
  description = coalesce(var.task_exec_iam_role_description, "Task execution role for ${var.cluster_name}")

  assume_role_policy    = data.aws_iam_policy_document.task_exec_assume[0].json
  permissions_boundary  = var.task_exec_iam_role_permissions_boundary
  force_detach_policies = true

  tags = merge(local.tags, var.task_exec_iam_role_tags)

  lifecycle {
    enabled = local.create_task_exec_iam_role
  }
}

resource "aws_iam_role_policy_attachment" "task_exec_additional" {
  for_each = { for k, v in var.task_exec_iam_role_policies : k => v if local.create_task_exec_iam_role }

  role       = aws_iam_role.task_exec.name
  policy_arn = each.value
}

data "aws_iam_policy_document" "task_exec" {
  count = local.create_task_exec_policy ? 1 : 0

  # Pulled from AmazonECSTaskExecutionRolePolicy
  statement {
    sid = "Logs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }

  # Pulled from AmazonECSTaskExecutionRolePolicy
  statement {
    sid = "ECR"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = length(var.task_exec_ssm_param_arns) > 0 ? [1] : []

    content {
      sid       = "GetSSMParams"
      actions   = ["ssm:GetParameters"]
      resources = var.task_exec_ssm_param_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.task_exec_secret_arns) > 0 ? [1] : []

    content {
      sid       = "GetSecrets"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = var.task_exec_secret_arns
    }
  }

  dynamic "statement" {
    for_each = var.task_exec_iam_statements

    content {
      sid           = try(statement.value.sid, null)
      actions       = try(statement.value.actions, null)
      not_actions   = try(statement.value.not_actions, null)
      effect        = try(statement.value.effect, null)
      resources     = try(statement.value.resources, null)
      not_resources = try(statement.value.not_resources, null)

      dynamic "principals" {
        for_each = try(statement.value.principals, [])

        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "not_principals" {
        for_each = try(statement.value.not_principals, [])

        content {
          type        = not_principals.value.type
          identifiers = not_principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = try(statement.value.conditions, [])

        content {
          test     = condition.value.test
          values   = condition.value.values
          variable = condition.value.variable
        }
      }
    }
  }
}

resource "aws_iam_policy" "task_exec" {
  name        = var.task_exec_iam_role_use_name_prefix ? null : local.task_exec_iam_role_name
  name_prefix = var.task_exec_iam_role_use_name_prefix ? "${local.task_exec_iam_role_name}-" : null
  description = coalesce(var.task_exec_iam_role_description, "Task execution role IAM policy")
  policy      = data.aws_iam_policy_document.task_exec[0].json

  tags = merge(local.tags, var.task_exec_iam_role_tags)

  lifecycle {
    enabled = local.create_task_exec_policy
  }
}

resource "aws_iam_role_policy_attachment" "task_exec" {
  role       = aws_iam_role.task_exec.name
  policy_arn = aws_iam_policy.task_exec.arn

  lifecycle {
    enabled = local.create_task_exec_policy
  }
}

################################################################################
# Node - IAM Role + Instance Profile
# Required for EC2 launch type - allows ECS agent to register instances
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/instance_IAM_role.html
################################################################################

locals {
  node_iam_role_name = try(coalesce(var.node_iam_role_name, "${var.cluster_name}-node"), "")
  create_node_role   = var.enabled && var.create_node_iam_role
}

data "aws_iam_policy_document" "node_assume" {
  count = local.create_node_role ? 1 : 0

  statement {
    sid     = "EC2AssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name        = var.node_iam_role_use_name_prefix ? null : local.node_iam_role_name
  name_prefix = var.node_iam_role_use_name_prefix ? "${local.node_iam_role_name}-" : null
  path        = var.node_iam_role_path
  description = coalesce(var.node_iam_role_description, "ECS node role for ${var.cluster_name}")

  assume_role_policy    = data.aws_iam_policy_document.node_assume[0].json
  permissions_boundary  = var.node_iam_role_permissions_boundary
  force_detach_policies = true

  tags = merge(local.tags, var.node_iam_role_tags)

  lifecycle {
    enabled = local.create_node_role
  }
}

# Core ECS agent + ECR + CloudWatch permissions
resource "aws_iam_role_policy_attachment" "node_ecs" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"

  lifecycle {
    enabled = local.create_node_role
  }
}

# Optional: SSM Session Manager access on EC2 nodes
resource "aws_iam_role_policy_attachment" "node_ssm" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

  lifecycle {
    enabled = local.create_node_role && var.node_iam_role_attach_ssm_policy
  }
}

resource "aws_iam_role_policy_attachment" "node_additional" {
  for_each = { for k, v in var.node_iam_role_policies : k => v if local.create_node_role }

  role       = aws_iam_role.node.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "node" {
  name        = var.node_iam_role_use_name_prefix ? null : local.node_iam_role_name
  name_prefix = var.node_iam_role_use_name_prefix ? "${local.node_iam_role_name}-" : null
  path        = var.node_iam_role_path
  role        = aws_iam_role.node.name

  tags = merge(local.tags, var.node_iam_role_tags)

  lifecycle {
    enabled = local.create_node_role
  }
}

################################################################################
# Security Group
# Optional cluster-level security group for EC2 instances
################################################################################

locals {
  create_security_group = var.enabled && var.create_security_group
  security_group_name   = try(coalesce(var.security_group_name, var.cluster_name), "")
}

resource "aws_security_group" "this" {
  name        = var.security_group_use_name_prefix ? null : local.security_group_name
  name_prefix = var.security_group_use_name_prefix ? "${local.security_group_name}-" : null
  description = var.security_group_description
  vpc_id      = var.vpc_id

  tags = merge(local.tags, var.security_group_tags, {
    Name = local.security_group_name
  })

  lifecycle {
    enabled               = local.create_security_group
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = { for k, v in var.security_group_rules : k => v if local.create_security_group && try(v.type, "ingress") == "ingress" }

  security_group_id = aws_security_group.this.id
  ip_protocol       = try(each.value.ip_protocol, "tcp")

  cidr_ipv4                    = lookup(each.value, "cidr_ipv4", null)
  cidr_ipv6                    = lookup(each.value, "cidr_ipv6", null)
  description                  = try(each.value.description, null)
  from_port                    = try(each.value.from_port, null)
  prefix_list_id               = lookup(each.value, "prefix_list_id", null)
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)
  to_port                      = try(each.value.to_port, null)

  tags = merge(local.tags, var.security_group_tags)
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = { for k, v in var.security_group_rules : k => v if local.create_security_group && try(v.type, "ingress") == "egress" }

  security_group_id = aws_security_group.this.id
  ip_protocol       = try(each.value.ip_protocol, "-1")

  cidr_ipv4                    = lookup(each.value, "cidr_ipv4", null)
  cidr_ipv6                    = lookup(each.value, "cidr_ipv6", null)
  description                  = try(each.value.description, null)
  from_port                    = try(each.value.from_port, null)
  prefix_list_id               = lookup(each.value, "prefix_list_id", null)
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)
  to_port                      = try(each.value.to_port, null)

  tags = merge(local.tags, var.security_group_tags)
}
