locals {
  enabled = var.enabled
  name    = var.name

  create_workspace                = local.enabled && var.create_workspace
  create_alert_manager_definition = local.enabled && var.create_alert_manager_definition
  create_cloudwatch_log_group     = local.enabled && var.create_cloudwatch_log_group && var.enable_cloudwatch_logging

  workspace_id   = local.create_workspace ? aws_prometheus_workspace.this.id : var.workspace_id
  log_group_name = coalesce(var.cloudwatch_log_group_name, local.name != null ? "amp-${local.name}" : null, "amp-workspace")

  # ARN of the log group used for workspace logging - either created by this
  # module or passed in via cloudwatch_log_group_arn.
  log_group_arn = var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.this.arn : var.cloudwatch_log_group_arn

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
    Region    = data.aws_region.current.region
  })
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

################################################################################
# Workspace
################################################################################

resource "aws_prometheus_workspace" "this" {
  alias       = local.name
  kms_key_arn = var.kms_key_arn
  region      = var.region

  dynamic "logging_configuration" {
    for_each = var.enable_cloudwatch_logging && (var.create_cloudwatch_log_group || var.cloudwatch_log_group_arn != null) ? [1] : []

    content {
      log_group_arn = "${local.log_group_arn}:*"
    }
  }

  tags = local.tags

  lifecycle {
    enabled = local.create_workspace
  }
}

################################################################################
# Alert Manager Definition
################################################################################

resource "aws_prometheus_alert_manager_definition" "this" {
  workspace_id = local.workspace_id
  definition   = var.alert_manager_definition
  region       = var.region

  lifecycle {
    enabled = local.create_alert_manager_definition
  }
}

################################################################################
# Rule Group Namespace
################################################################################

resource "aws_prometheus_rule_group_namespace" "this" {
  for_each = local.enabled ? var.rule_group_namespaces : {}

  name         = each.value.name
  workspace_id = local.workspace_id
  data         = each.value.data
  region       = var.region

  tags = local.tags
}

################################################################################
# CloudWatch Log Group
################################################################################

resource "aws_cloudwatch_log_group" "this" {
  name              = var.cloudwatch_log_group_use_name_prefix ? null : local.log_group_name
  name_prefix       = var.cloudwatch_log_group_use_name_prefix ? "${local.log_group_name}-" : null
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id
  skip_destroy      = var.cloudwatch_log_group_skip_destroy
  log_group_class   = var.cloudwatch_log_group_class

  tags = local.tags

  lifecycle {
    enabled = local.create_cloudwatch_log_group
  }
}

################################################################################
# Prometheus Scraper
################################################################################

resource "aws_prometheus_scraper" "this" {
  for_each = local.enabled ? var.scrapers : {}

  alias                = each.value.alias
  scrape_configuration = each.value.scrape_configuration
  region               = var.region

  source {
    eks {
      cluster_arn        = each.value.eks_cluster_arn
      security_group_ids = each.value.security_group_ids
      subnet_ids         = each.value.subnet_ids
    }
  }

  destination {
    amp {
      workspace_arn = local.create_workspace ? aws_prometheus_workspace.this.arn : (
        each.value.workspace_arn != null ? each.value.workspace_arn :
        "arn:${data.aws_partition.current.partition}:aps:${coalesce(var.region, data.aws_region.current.region)}:${data.aws_caller_identity.current.account_id}:workspace/${var.workspace_id}"
      )
    }
  }

  dynamic "role_configuration" {
    for_each = each.value.role_configuration != null ? [each.value.role_configuration] : []

    content {
      source_role_arn = role_configuration.value.source_role_arn
      target_role_arn = role_configuration.value.target_role_arn
    }
  }

  tags = local.tags

  timeouts {
    create = each.value.timeouts != null ? each.value.timeouts.create : null
    update = each.value.timeouts != null ? each.value.timeouts.update : null
    delete = each.value.timeouts != null ? each.value.timeouts.delete : null
  }
}

################################################################################
