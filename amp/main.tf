locals {
  enabled        = var.enabled
  workspace_id   = local.enabled && var.create_workspace ? aws_prometheus_workspace.this.id : var.workspace_id
  log_group_name = try(coalesce(var.cloudwatch_log_group_name, "amp-${var.workspace_alias}"), "")

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

################################################################################
# Workspace
################################################################################

resource "aws_prometheus_workspace" "this" {
  alias       = var.workspace_alias
  kms_key_arn = var.kms_key_arn
  region      = var.region

  dynamic "logging_configuration" {
    for_each = var.create_cloudwatch_log_group && var.enable_cloudwatch_logging ? [1] : []

    content {
      log_group_arn = "${aws_cloudwatch_log_group.this.arn}:*"
    }
  }

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_workspace
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
    enabled = local.enabled
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
    enabled = var.create_cloudwatch_log_group && var.enable_cloudwatch_logging
  }
}

################################################################################
# Prometheus Scraper
################################################################################

resource "aws_prometheus_scraper" "this" {
  for_each = local.enabled ? var.scrapers : {}

  alias                = try(each.value.alias, null)
  scrape_configuration = each.value.scrape_configuration
  region               = var.region

  source {
    eks {
      cluster_arn        = each.value.eks_cluster_arn
      security_group_ids = try(each.value.security_group_ids, [])
      subnet_ids         = each.value.subnet_ids
    }
  }

  destination {
    amp {
      workspace_arn = local.workspace_id != null ? "arn:aws:aps:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:workspace/${local.workspace_id}" : each.value.workspace_arn
    }
  }

  dynamic "role_configuration" {
    for_each = try(each.value.role_configuration, null) != null ? [each.value.role_configuration] : []

    content {
      source_role_arn = try(role_configuration.value.source_role_arn, null)
      target_role_arn = try(role_configuration.value.target_role_arn, null)
    }
  }

  tags = local.tags

  timeouts {
    create = try(each.value.timeouts.create, null)
    update = try(each.value.timeouts.update, null)
    delete = try(each.value.timeouts.delete, null)
  }
}

################################################################################
