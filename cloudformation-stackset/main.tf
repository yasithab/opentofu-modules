locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

################################################################################
# CloudFormation StackSet
################################################################################

resource "aws_cloudformation_stack_set" "this" {
  name             = var.name
  description      = var.description
  permission_model = var.permission_model

  # Template source (mutually exclusive)
  template_body = var.template_body
  template_url  = var.template_url

  parameters = var.parameters

  capabilities = var.capabilities

  # Service-managed permissions (AWS Organizations)
  dynamic "auto_deployment" {
    for_each = var.permission_model == "SERVICE_MANAGED" ? [1] : []
    content {
      enabled                          = var.auto_deployment_enabled
      retain_stacks_on_account_removal = var.retain_stacks_on_account_removal
    }
  }

  # Self-managed permissions
  administration_role_arn = var.permission_model == "SELF_MANAGED" ? var.administration_role_arn : null
  execution_role_name     = var.permission_model == "SELF_MANAGED" ? var.execution_role_name : null

  # Optional managed execution
  dynamic "managed_execution" {
    for_each = var.managed_execution_enabled ? [1] : []
    content {
      active = true
    }
  }

  # Optional operation preferences at the StackSet level
  dynamic "operation_preferences" {
    for_each = var.stackset_operation_preferences != null ? [var.stackset_operation_preferences] : []
    content {
      failure_tolerance_count      = try(operation_preferences.value.failure_tolerance_count, null)
      failure_tolerance_percentage = try(operation_preferences.value.failure_tolerance_percentage, null)
      max_concurrent_count         = try(operation_preferences.value.max_concurrent_count, null)
      max_concurrent_percentage    = try(operation_preferences.value.max_concurrent_percentage, null)
      region_concurrency_type      = try(operation_preferences.value.region_concurrency_type, null)
      region_order                 = length(try(operation_preferences.value.region_order, [])) > 0 ? operation_preferences.value.region_order : null
    }
  }

  call_as = var.call_as

  tags = local.tags

  timeouts {
    update = var.stackset_update_timeout
  }

  lifecycle {
    enabled        = local.enabled
    ignore_changes = [administration_role_arn]
  }
}

################################################################################
# StackSet Instance (Deployments)
################################################################################

resource "aws_cloudformation_stack_set_instance" "this" {
  for_each = { for idx, deployment in var.deployments : idx => deployment if local.enabled }

  stack_set_name            = aws_cloudformation_stack_set.this.name
  stack_set_instance_region = each.value.region

  # For SERVICE_MANAGED permission model
  dynamic "deployment_targets" {
    for_each = var.permission_model == "SERVICE_MANAGED" ? [1] : []
    content {
      organizational_unit_ids = each.value.organizational_unit_ids
      account_filter_type     = length(each.value.accounts) > 0 ? each.value.account_filter_type : null
      accounts                = length(each.value.accounts) > 0 ? each.value.accounts : null
      accounts_url            = try(each.value.accounts_url, null)
    }
  }

  # For SELF_MANAGED permission model
  account_id = var.permission_model == "SELF_MANAGED" ? each.value.account_id : null

  # Per-instance parameter overrides (override StackSet-level parameters for this instance)
  parameter_overrides = try(each.value.parameter_overrides, null)

  # Operation preferences
  dynamic "operation_preferences" {
    for_each = var.operation_preferences != null ? [var.operation_preferences] : []
    content {
      failure_tolerance_count      = operation_preferences.value.failure_tolerance_count
      failure_tolerance_percentage = operation_preferences.value.failure_tolerance_percentage
      max_concurrent_count         = operation_preferences.value.max_concurrent_count
      max_concurrent_percentage    = operation_preferences.value.max_concurrent_percentage
      concurrency_mode             = try(operation_preferences.value.concurrency_mode, null)
      region_concurrency_type      = operation_preferences.value.region_concurrency_type
      region_order                 = length(try(operation_preferences.value.region_order, [])) > 0 ? operation_preferences.value.region_order : null
    }
  }

  retain_stack = try(each.value.retain_stack, false)

  call_as = var.call_as

  timeouts {
    create = var.instance_timeouts.create
    update = var.instance_timeouts.update
    delete = var.instance_timeouts.delete
  }
}

################################################################################
