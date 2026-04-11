locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

################################################################################
# Application
################################################################################

resource "aws_appconfig_application" "this" {
  name        = var.name
  description = var.application_description

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}

################################################################################
# Environments
################################################################################

resource "aws_appconfig_environment" "this" {
  for_each = { for k, v in var.environments : k => v if local.enabled }

  name           = try(each.value.name, each.key)
  description    = try(each.value.description, null)
  application_id = aws_appconfig_application.this.id

  dynamic "monitor" {
    for_each = try(each.value.monitors, [])

    content {
      alarm_arn      = monitor.value.alarm_arn
      alarm_role_arn = try(monitor.value.alarm_role_arn, null)
    }
  }

  tags = local.tags
}

################################################################################
# Configuration Profiles
################################################################################

resource "aws_appconfig_configuration_profile" "this" {
  for_each = { for k, v in var.configuration_profiles : k => v if local.enabled }

  application_id = aws_appconfig_application.this.id
  name           = try(each.value.name, each.key)
  description    = try(each.value.description, null)
  type           = try(each.value.type, "AWS.Freeform")
  location_uri   = try(each.value.location_uri, "hosted")

  dynamic "validator" {
    for_each = try(each.value.validators, [])

    content {
      type    = validator.value.type
      content = try(validator.value.content, null)
    }
  }

  tags = local.tags
}

################################################################################
# Hosted Configuration Versions
################################################################################

resource "aws_appconfig_hosted_configuration_version" "this" {
  for_each = { for k, v in var.hosted_configuration_versions : k => v if local.enabled }

  application_id           = aws_appconfig_application.this.id
  configuration_profile_id = aws_appconfig_configuration_profile.this[each.key].configuration_profile_id
  content                  = each.value.content
  content_type             = try(each.value.content_type, "application/json")
  description              = try(each.value.description, null)
}

################################################################################
# Deployment Strategies
################################################################################

resource "aws_appconfig_deployment_strategy" "this" {
  for_each = { for k, v in var.deployment_strategies : k => v if local.enabled }

  name                           = try(each.value.name, each.key)
  description                    = try(each.value.description, null)
  deployment_duration_in_minutes = each.value.deployment_duration_in_minutes
  growth_factor                  = each.value.growth_factor
  growth_type                    = try(each.value.growth_type, "LINEAR")
  replicate_to                   = try(each.value.replicate_to, "NONE")
  final_bake_time_in_minutes     = try(each.value.final_bake_time_in_minutes, 0)

  tags = local.tags
}

################################################################################
# Deployments
################################################################################

resource "aws_appconfig_deployment" "this" {
  for_each = { for k, v in var.deployments : k => v if local.enabled }

  application_id           = aws_appconfig_application.this.id
  environment_id           = aws_appconfig_environment.this[each.value.environment_key].environment_id
  configuration_profile_id = aws_appconfig_configuration_profile.this[each.value.configuration_profile_key].configuration_profile_id
  configuration_version    = aws_appconfig_hosted_configuration_version.this[each.value.configuration_version_key].version_number
  deployment_strategy_id   = try(each.value.deployment_strategy_id, aws_appconfig_deployment_strategy.this[each.value.deployment_strategy_key].id)
  description              = try(each.value.description, null)

  tags = local.tags
}

################################################################################
# Extensions
################################################################################

resource "aws_appconfig_extension" "this" {
  for_each = { for k, v in var.extensions : k => v if local.enabled }

  name        = try(each.value.name, each.key)
  description = try(each.value.description, null)

  dynamic "action_point" {
    for_each = try(each.value.action_points, {})

    content {
      point = action_point.key

      dynamic "action" {
        for_each = action_point.value

        content {
          name     = action.value.name
          role_arn = try(action.value.role_arn, null)
          uri      = action.value.uri
        }
      }
    }
  }

  dynamic "parameter" {
    for_each = try(each.value.parameters, {})

    content {
      name        = parameter.key
      required    = try(parameter.value.required, false)
      description = try(parameter.value.description, null)
    }
  }

  tags = local.tags
}

resource "aws_appconfig_extension_association" "this" {
  for_each = { for k, v in var.extension_associations : k => v if local.enabled }

  extension_arn = aws_appconfig_extension.this[each.value.extension_key].arn
  resource_arn = try(
    each.value.resource_type == "environment" ? aws_appconfig_environment.this[each.value.resource_key].arn : null,
    each.value.resource_type == "configuration_profile" ? aws_appconfig_configuration_profile.this[each.value.resource_key].arn : null,
    each.value.resource_arn,
  )
}
