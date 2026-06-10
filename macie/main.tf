locals {
  enabled = var.enabled
  name    = var.name
  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  create_organization_admin_account = local.enabled && var.create_organization_admin_account
  create_organization_configuration = local.enabled && var.create_organization_configuration
}

################################################################################
# Macie Account
################################################################################

resource "aws_macie2_account" "this" {
  finding_publishing_frequency = var.finding_publishing_frequency
  status                       = "ENABLED"

  lifecycle {
    enabled = local.enabled
  }
}

################################################################################
# Classification Jobs
################################################################################

resource "aws_macie2_classification_job" "this" {
  for_each = local.enabled ? { for k, v in var.classification_jobs : k => v } : {}

  job_type = each.value.job_type
  name     = each.key

  s3_job_definition {
    dynamic "bucket_definitions" {
      for_each = each.value.bucket_definitions

      content {
        account_id = bucket_definitions.value.account_id
        buckets    = bucket_definitions.value.buckets
      }
    }

    dynamic "scoping" {
      for_each = try(each.value.scoping, null) != null ? [each.value.scoping] : []

      content {
        dynamic "excludes" {
          for_each = try(scoping.value.excludes, null) != null ? [scoping.value.excludes] : []

          content {
            dynamic "and" {
              for_each = try(excludes.value.and, [])

              content {
                dynamic "simple_scope_term" {
                  for_each = try(and.value.simple_scope_term, null) != null ? [and.value.simple_scope_term] : []

                  content {
                    comparator = simple_scope_term.value.comparator
                    key        = simple_scope_term.value.key
                    values     = simple_scope_term.value.values
                  }
                }
              }
            }
          }
        }

        dynamic "includes" {
          for_each = try(scoping.value.includes, null) != null ? [scoping.value.includes] : []

          content {
            dynamic "and" {
              for_each = try(includes.value.and, [])

              content {
                dynamic "simple_scope_term" {
                  for_each = try(and.value.simple_scope_term, null) != null ? [and.value.simple_scope_term] : []

                  content {
                    comparator = simple_scope_term.value.comparator
                    key        = simple_scope_term.value.key
                    values     = simple_scope_term.value.values
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  sampling_percentage = try(each.value.sampling_percentage, 100)
  initial_run         = try(each.value.initial_run, true)
  description         = try(each.value.description, null)

  dynamic "schedule_frequency" {
    for_each = each.value.job_type == "SCHEDULED" && try(each.value.schedule_frequency, null) != null ? [each.value.schedule_frequency] : []

    content {
      monthly_schedule = try(schedule_frequency.value.monthly_schedule, null)
      weekly_schedule  = try(schedule_frequency.value.weekly_schedule, null)
    }
  }

  tags = local.tags

  depends_on = [aws_macie2_account.this]
}

################################################################################
# Custom Data Identifiers
################################################################################

resource "aws_macie2_custom_data_identifier" "this" {
  for_each = local.enabled ? { for k, v in var.custom_data_identifiers : k => v } : {}

  name                   = each.key
  regex                  = try(each.value.regex, null)
  keywords               = try(each.value.keywords, null)
  ignore_words           = try(each.value.ignore_words, null)
  maximum_match_distance = try(each.value.maximum_match_distance, null)
  description            = try(each.value.description, null)

  tags = local.tags

  depends_on = [aws_macie2_account.this]
}

################################################################################
# Member Accounts
################################################################################

resource "aws_macie2_member" "this" {
  for_each = local.enabled ? { for k, v in var.member_accounts : k => v } : {}

  account_id                            = each.value.account_id
  email                                 = each.value.email
  invite                                = try(each.value.invite, true)
  invitation_message                    = try(each.value.invitation_message, "Macie member invitation")
  invitation_disable_email_notification = try(each.value.disable_email_notification, true)
  status                                = try(each.value.status, "ENABLED")

  tags = local.tags

  depends_on = [aws_macie2_account.this]
}

################################################################################
# Classification Export Configuration
################################################################################

resource "aws_macie2_classification_export_configuration" "this" {
  s3_destination {
    bucket_name = var.classification_export_bucket_name
    key_prefix  = try(var.classification_export_key_prefix, null)
    kms_key_arn = var.classification_export_kms_key_arn
  }

  depends_on = [aws_macie2_account.this]

  lifecycle {
    enabled = local.enabled && var.classification_export_bucket_name != null

    precondition {
      condition     = var.classification_export_bucket_name == null || var.classification_export_kms_key_arn != null
      error_message = "classification_export_kms_key_arn must be set when classification_export_bucket_name is set - Macie requires KMS encryption for classification results."
    }
  }
}

################################################################################
# Organization Support
################################################################################

# Designates a member account as the Macie delegated administrator for the
# organization. Must be applied from the organization management account.
resource "aws_macie2_organization_admin_account" "this" {
  admin_account_id = coalesce(var.admin_account_id, "000000000000")

  lifecycle {
    enabled = local.create_organization_admin_account

    precondition {
      condition     = !local.create_organization_admin_account || var.admin_account_id != null
      error_message = "admin_account_id must be set when create_organization_admin_account is true."
    }
  }
}

# Organization-wide auto-enable behaviour. Must be applied from the delegated
# administrator account.
resource "aws_macie2_organization_configuration" "this" {
  auto_enable = var.auto_enable_organization_members

  depends_on = [aws_macie2_account.this]

  lifecycle {
    enabled = local.create_organization_configuration
  }
}
