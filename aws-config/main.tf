data "aws_region" "current" {}

locals {
  enabled       = var.enabled
  recorder_name = coalesce(var.recorder_name, var.name, "default")

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  # -- Recording ----------------------------------------------------------------

  # When global_resource_collector_region is set, only that region records global
  # resources (IAM users, roles, policies, etc.), preventing duplicate config items
  # in multi-region deployments.
  include_global_resource_types = (
    var.global_resource_collector_region != null
    ? data.aws_region.current.region == var.global_resource_collector_region
    : lookup(var.recording_group, "include_global_resource_types", false)
  )

  # -- REQUIRED_TAGS rule -------------------------------------------------------

  # Build REQUIRED_TAGS input_parameters JSON from the required_tags convenience
  # variable. The rule supports up to 6 key/value pairs (tag1Key...tag6Key).
  required_tags_keys = sort(keys(var.required_tags))
  required_tags_params = length(var.required_tags) > 0 ? jsonencode(merge(
    { for i, k in local.required_tags_keys : "tag${i + 1}Key" => k },
    {
      for i, k in local.required_tags_keys : "tag${i + 1}Value" => var.required_tags[k]
      if var.required_tags[k] != null && var.required_tags[k] != ""
    }
  )) : null

  # Auto-generate a REQUIRED_TAGS managed rule when required_tags is populated.
  # Callers can override or disable it by including REQUIRED_TAGS = { enabled = false }
  # in their own managed_rules map - merge() lets the caller entry win.
  required_tags_rule = length(var.required_tags) > 0 ? {
    REQUIRED_TAGS = {
      description                 = "Checks that required tags are applied to AWS resources."
      source_identifier           = null
      input_parameters            = local.required_tags_params
      resource_types_scope        = var.required_tags_resource_types
      evaluation_mode             = "DETECTIVE"
      maximum_execution_frequency = null
      tag_key_scope               = null
      tag_value_scope             = null
      tags                        = {}
      enabled                     = true
    }
  } : {}

  # required_tags_rule is listed first so an explicit caller entry wins via merge().
  all_managed_rules = merge(local.required_tags_rule, var.managed_rules)

  # -- Aggregation --------------------------------------------------------------

  create_aggregator_auth = local.enabled && var.create_aggregator_authorization

  # Resolved role ARN for organization_aggregation_source.
  # Preference order: caller-supplied role_arn -> auto-created org aggregator role.
  org_aggregator_role_arn = (
    var.aggregator_organization == null ? null
    : var.aggregator_organization.role_arn != null ? var.aggregator_organization.role_arn
    : local.create_org_aggregator_role ? aws_iam_role.config_org_aggregator[0].arn
    : null
  )
}

# -- Configuration Recorder ---------------------------------------------------

resource "aws_config_configuration_recorder" "this" {
  lifecycle {
    enabled = local.enabled
  }

  name     = local.recorder_name
  role_arn = local.create_iam_role ? aws_iam_role.config[0].arn : var.iam_role_arn

  dynamic "recording_group" {
    for_each = [var.recording_group]
    content {
      all_supported                 = lookup(recording_group.value, "all_supported", true)
      include_global_resource_types = local.include_global_resource_types

      dynamic "exclusion_by_resource_types" {
        for_each = lookup(recording_group.value, "exclusion_by_resource_types", null) != null ? [recording_group.value.exclusion_by_resource_types] : []
        content {
          resource_types = exclusion_by_resource_types.value.resource_types
        }
      }

      dynamic "recording_strategy" {
        for_each = lookup(recording_group.value, "recording_strategy", null) != null ? [recording_group.value.recording_strategy] : []
        content {
          use_only = recording_strategy.value.use_only
        }
      }
    }
  }

  dynamic "recording_mode" {
    for_each = length(keys(var.recording_mode)) > 0 ? [var.recording_mode] : []
    content {
      recording_frequency = lookup(recording_mode.value, "recording_frequency", "CONTINUOUS")

      dynamic "recording_mode_override" {
        for_each = lookup(recording_mode.value, "recording_mode_override", [])
        content {
          description         = lookup(recording_mode_override.value, "description", null)
          recording_frequency = recording_mode_override.value.recording_frequency
          resource_types      = recording_mode_override.value.resource_types
        }
      }
    }
  }
}

# -- Delivery Channel ---------------------------------------------------------

resource "aws_config_delivery_channel" "this" {
  lifecycle {
    enabled = local.enabled && var.delivery_channel_s3_bucket_name != null
  }

  name           = local.recorder_name
  s3_bucket_name = coalesce(var.delivery_channel_s3_bucket_name, "placeholder")
  s3_key_prefix  = var.delivery_channel_s3_key_prefix
  s3_kms_key_arn = var.delivery_channel_s3_kms_key_arn
  sns_topic_arn  = var.delivery_channel_sns_topic_arn

  dynamic "snapshot_delivery_properties" {
    for_each = var.snapshot_delivery_frequency != null ? [var.snapshot_delivery_frequency] : []
    content {
      delivery_frequency = snapshot_delivery_properties.value
    }
  }

  depends_on = [aws_config_configuration_recorder.this]
}

# -- Ordering Gate ------------------------------------------------------------
# AWS requires: recorder must be stopped before delivery channel can be deleted.
# This terraform_data resource sits between the delivery channel and the recorder
# status, forcing strict sequential destruction:
#   recorder_status (stop) → config_ordering → delivery_channel (delete) → recorder
# Without this gate, OpenTofu may parallelise the destructions and the delivery
# channel delete races the stop call, causing a 400 LastDeliveryChannelDeleteFailed.

resource "terraform_data" "config_ordering" {
  lifecycle {
    enabled = local.enabled
  }

  depends_on = [
    aws_config_configuration_recorder.this,
    aws_config_delivery_channel.this,
  ]
}

# -- Recorder Status ----------------------------------------------------------

resource "aws_config_configuration_recorder_status" "this" {
  lifecycle {
    enabled = local.enabled
  }

  name       = aws_config_configuration_recorder.this.name
  is_enabled = true

  depends_on = [terraform_data.config_ordering]
}

# -- Managed Config Rules -----------------------------------------------------

resource "aws_config_config_rule" "managed" {
  # Filter out entries with enabled = false; absent key defaults to true via lookup.
  for_each = local.enabled ? {
    for k, v in local.all_managed_rules : k => v if lookup(v, "enabled", true)
  } : {}

  name        = each.key
  description = each.value.description
  tags        = merge(local.tags, lookup(each.value, "tags", {}))

  input_parameters            = lookup(each.value, "input_parameters", null)
  maximum_execution_frequency = lookup(each.value, "maximum_execution_frequency", null)

  source {
    owner             = "AWS"
    source_identifier = coalesce(lookup(each.value, "source_identifier", null), each.key)

    dynamic "source_detail" {
      for_each = lookup(each.value, "source_details", [])
      content {
        event_source                = lookup(source_detail.value, "event_source", null)
        message_type                = lookup(source_detail.value, "message_type", null)
        maximum_execution_frequency = lookup(source_detail.value, "maximum_execution_frequency", null)
      }
    }
  }

  dynamic "scope" {
    for_each = (
      length(lookup(each.value, "resource_types_scope", [])) > 0 ||
      lookup(each.value, "tag_key_scope", null) != null ||
      lookup(each.value, "compliance_resource_id", null) != null
    ) ? [each.value] : []
    content {
      compliance_resource_types = length(lookup(scope.value, "resource_types_scope", [])) > 0 ? scope.value.resource_types_scope : null
      compliance_resource_id    = lookup(scope.value, "compliance_resource_id", null)
      tag_key                   = lookup(scope.value, "tag_key_scope", null)
      tag_value                 = lookup(scope.value, "tag_value_scope", null)
    }
  }

  dynamic "evaluation_mode" {
    for_each = lookup(each.value, "evaluation_mode", null) != null ? [each.value.evaluation_mode] : []
    content {
      mode = evaluation_mode.value
    }
  }

  depends_on = [aws_config_configuration_recorder_status.this]
}

# -- Custom (Lambda-backed) Config Rules --------------------------------------

resource "aws_config_config_rule" "custom" {
  # custom_rules is a typed map(object) - use direct attribute access throughout.
  for_each = local.enabled ? {
    for k, v in var.custom_rules : k => v if v.enabled
  } : {}

  name        = each.key
  description = each.value.description
  tags        = merge(local.tags, each.value.tags)

  input_parameters            = each.value.input_parameters
  maximum_execution_frequency = each.value.maximum_execution_frequency

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = each.value.source_identifier

    dynamic "source_detail" {
      for_each = each.value.source_details != null ? each.value.source_details : []
      content {
        event_source                = lookup(source_detail.value, "event_source", null)
        message_type                = lookup(source_detail.value, "message_type", null)
        maximum_execution_frequency = lookup(source_detail.value, "maximum_execution_frequency", null)
      }
    }
  }

  dynamic "scope" {
    for_each = (
      length(each.value.resource_types_scope) > 0 ||
      each.value.tag_key_scope != null ||
      each.value.compliance_resource_id != null
    ) ? [each.value] : []
    content {
      compliance_resource_types = length(scope.value.resource_types_scope) > 0 ? scope.value.resource_types_scope : null
      compliance_resource_id    = scope.value.compliance_resource_id
      tag_key                   = scope.value.tag_key_scope
      tag_value                 = scope.value.tag_value_scope
    }
  }

  dynamic "evaluation_mode" {
    for_each = each.value.evaluation_mode != null ? [each.value.evaluation_mode] : []
    content {
      mode = evaluation_mode.value
    }
  }

  depends_on = [aws_config_configuration_recorder_status.this]
}

# -- Custom Policy (Guard-backed) Config Rules --------------------------------

resource "aws_config_config_rule" "custom_policy" {
  # custom_policy_rules uses CUSTOM_POLICY owner with inline Guard policy text.
  for_each = local.enabled ? {
    for k, v in var.custom_policy_rules : k => v if v.enabled
  } : {}

  name        = each.key
  description = each.value.description
  tags        = merge(local.tags, each.value.tags)

  input_parameters            = each.value.input_parameters
  maximum_execution_frequency = each.value.maximum_execution_frequency

  source {
    owner = "CUSTOM_POLICY"

    custom_policy_details {
      policy_runtime            = each.value.policy_runtime
      policy_text               = each.value.policy_text
      enable_debug_log_delivery = each.value.enable_debug_log_delivery
    }

    dynamic "source_detail" {
      for_each = each.value.source_details != null ? each.value.source_details : []
      content {
        event_source                = lookup(source_detail.value, "event_source", null)
        message_type                = lookup(source_detail.value, "message_type", null)
        maximum_execution_frequency = lookup(source_detail.value, "maximum_execution_frequency", null)
      }
    }
  }

  dynamic "scope" {
    for_each = (
      length(each.value.resource_types_scope) > 0 ||
      each.value.tag_key_scope != null ||
      each.value.compliance_resource_id != null
    ) ? [each.value] : []
    content {
      compliance_resource_types = length(scope.value.resource_types_scope) > 0 ? scope.value.resource_types_scope : null
      compliance_resource_id    = scope.value.compliance_resource_id
      tag_key                   = scope.value.tag_key_scope
      tag_value                 = scope.value.tag_value_scope
    }
  }

  dynamic "evaluation_mode" {
    for_each = each.value.evaluation_mode != null ? [each.value.evaluation_mode] : []
    content {
      mode = evaluation_mode.value
    }
  }

  depends_on = [aws_config_configuration_recorder_status.this]
}

# -- Retention Configuration --------------------------------------------------

resource "aws_config_retention_configuration" "this" {
  lifecycle {
    enabled = local.enabled && var.retention_period_in_days != null
  }

  retention_period_in_days = coalesce(var.retention_period_in_days, 2557)
}

# -- Configuration Aggregator -------------------------------------------------

# trivy:ignore:AVD-AWS-0019 - all_regions is caller-controlled via var.aggregator_accounts.all_aws_regions
resource "aws_config_configuration_aggregator" "this" {
  lifecycle {
    enabled = local.enabled && var.create_aggregator
  }

  name = coalesce(var.aggregator_name, "${local.recorder_name}-aggregator")
  tags = local.tags

  dynamic "account_aggregation_source" {
    for_each = var.aggregator_accounts != null ? [var.aggregator_accounts] : []
    content {
      account_ids = account_aggregation_source.value.account_ids
      regions     = account_aggregation_source.value.all_aws_regions ? null : account_aggregation_source.value.aws_regions
      all_regions = account_aggregation_source.value.all_aws_regions
    }
  }

  dynamic "organization_aggregation_source" {
    for_each = var.aggregator_organization != null ? [var.aggregator_organization] : []
    content {
      role_arn    = local.org_aggregator_role_arn
      regions     = organization_aggregation_source.value.all_aws_regions ? null : organization_aggregation_source.value.aws_regions
      all_regions = organization_aggregation_source.value.all_aws_regions
    }
  }
}

# -- Aggregator Authorization (child accounts) --------------------------------
# Deploy in every child/member account to authorise the central aggregator account
# to pull Config data from this account.

resource "aws_config_aggregate_authorization" "this" {
  lifecycle {
    enabled = local.create_aggregator_auth
    precondition {
      condition     = !local.create_aggregator_auth || var.aggregator_account_id != null
      error_message = "aggregator_account_id must be set when create_aggregator_authorization is true."
    }
  }

  account_id            = coalesce(var.aggregator_account_id, "000000000000")
  authorized_aws_region = coalesce(var.aggregator_account_region, data.aws_region.current.region)
  tags                  = local.tags
}
