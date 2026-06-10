locals {
  enabled = var.enabled
  name    = var.name

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
    Region    = data.aws_region.current.region
  })
}

################################################################################
# Application
################################################################################

resource "aws_appconfig_application" "this" {
  name        = local.name
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

  name           = coalesce(each.value.name, each.key)
  description    = each.value.description
  application_id = aws_appconfig_application.this.id

  dynamic "monitor" {
    for_each = each.value.monitors

    content {
      alarm_arn      = monitor.value.alarm_arn
      alarm_role_arn = monitor.value.alarm_role_arn
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
  name           = coalesce(each.value.name, each.key)
  description    = each.value.description
  type           = each.value.type
  location_uri   = each.value.location_uri

  dynamic "validator" {
    for_each = each.value.validators

    content {
      type    = validator.value.type
      content = validator.value.content
    }
  }

  tags = local.tags
}

################################################################################
# Hosted Configuration Versions
################################################################################

# The variable is sensitive, so for_each iterates over the (non-secret) keys
# only; entry values are looked up per key and stay sensitive.
resource "aws_appconfig_hosted_configuration_version" "this" {
  for_each = toset([for k in nonsensitive(keys(var.hosted_configuration_versions)) : k if local.enabled])

  application_id           = aws_appconfig_application.this.id
  configuration_profile_id = aws_appconfig_configuration_profile.this[each.key].configuration_profile_id
  content                  = var.hosted_configuration_versions[each.key].content
  content_type             = var.hosted_configuration_versions[each.key].content_type
  description              = var.hosted_configuration_versions[each.key].description
}

################################################################################
# Deployment Strategies
################################################################################

resource "aws_appconfig_deployment_strategy" "this" {
  for_each = { for k, v in var.deployment_strategies : k => v if local.enabled }

  name                           = coalesce(each.value.name, each.key)
  description                    = each.value.description
  deployment_duration_in_minutes = each.value.deployment_duration_in_minutes
  growth_factor                  = each.value.growth_factor
  growth_type                    = each.value.growth_type
  replicate_to                   = each.value.replicate_to
  final_bake_time_in_minutes     = each.value.final_bake_time_in_minutes

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
  deployment_strategy_id   = each.value.deployment_strategy_id != null ? each.value.deployment_strategy_id : aws_appconfig_deployment_strategy.this[each.value.deployment_strategy_key].id
  description              = each.value.description
  kms_key_identifier       = each.value.kms_key_identifier

  tags = local.tags
}

################################################################################
# Extensions
################################################################################

resource "aws_appconfig_extension" "this" {
  for_each = { for k, v in var.extensions : k => v if local.enabled }

  name        = coalesce(each.value.name, each.key)
  description = each.value.description

  dynamic "action_point" {
    for_each = each.value.action_points

    content {
      point = action_point.key

      dynamic "action" {
        for_each = action_point.value

        content {
          name     = action.value.name
          role_arn = action.value.role_arn
          uri      = action.value.uri
        }
      }
    }
  }

  dynamic "parameter" {
    for_each = each.value.parameters

    content {
      name        = parameter.key
      required    = parameter.value.required
      description = parameter.value.description
    }
  }

  tags = local.tags
}

resource "aws_appconfig_extension_association" "this" {
  for_each = { for k, v in var.extension_associations : k => v if local.enabled }

  extension_arn = aws_appconfig_extension.this[each.value.extension_key].arn
  resource_arn = (
    each.value.resource_type == "environment" ? aws_appconfig_environment.this[each.value.resource_key].arn :
    each.value.resource_type == "configuration_profile" ? aws_appconfig_configuration_profile.this[each.value.resource_key].arn :
    each.value.resource_arn
  )
}

data "aws_region" "current" {}
