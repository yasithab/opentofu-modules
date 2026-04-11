data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  is_vpc_endpoint = var.endpoint_type == "VPC"
}

################################################################################
# Transfer Server
################################################################################

resource "aws_transfer_server" "this" {
  identity_provider_type           = var.identity_provider_type
  protocols                        = var.protocols
  endpoint_type                    = var.endpoint_type
  domain                           = var.domain
  security_policy_name             = var.security_policy_name
  certificate                      = var.certificate_arn
  host_key                         = var.host_key
  force_destroy                    = var.force_destroy
  function                         = var.identity_provider_type == "AWS_LAMBDA" ? var.identity_provider_function_arn : null
  url                              = var.identity_provider_type == "API_GATEWAY" ? var.identity_provider_url : null
  invocation_role                  = var.identity_provider_type == "API_GATEWAY" ? var.identity_provider_invocation_role_arn : null
  directory_id                     = var.identity_provider_type == "AWS_DIRECTORY_SERVICE" ? var.directory_id : null
  logging_role                     = var.create_logging_role ? aws_iam_role.logging.arn : var.logging_role_arn
  structured_log_destinations      = var.structured_log_destinations
  pre_authentication_login_banner  = var.pre_authentication_login_banner
  post_authentication_login_banner = var.post_authentication_display_banner

  dynamic "endpoint_details" {
    for_each = local.is_vpc_endpoint ? [1] : []

    content {
      vpc_id                 = var.vpc_id
      subnet_ids             = var.subnet_ids
      security_group_ids     = var.security_group_ids
      address_allocation_ids = var.address_allocation_ids
    }
  }

  dynamic "protocol_details" {
    for_each = var.protocol_details != null ? [var.protocol_details] : []

    content {
      passive_ip                  = try(protocol_details.value.passive_ip, null)
      set_stat_option             = try(protocol_details.value.set_stat_option, null)
      tls_session_resumption_mode = try(protocol_details.value.tls_session_resumption_mode, null)
      as2_transports              = try(protocol_details.value.as2_transports, null)
    }
  }

  dynamic "s3_storage_options" {
    for_each = var.s3_storage_options != null ? [var.s3_storage_options] : []

    content {
      directory_listing_optimization = try(s3_storage_options.value.directory_listing_optimization, null)
    }
  }

  dynamic "workflow_details" {
    for_each = var.workflow_on_upload != null || var.workflow_on_partial_upload != null ? [1] : []

    content {
      dynamic "on_upload" {
        for_each = var.workflow_on_upload != null ? [var.workflow_on_upload] : []

        content {
          execution_role = on_upload.value.execution_role
          workflow_id    = on_upload.value.workflow_id
        }
      }

      dynamic "on_partial_upload" {
        for_each = var.workflow_on_partial_upload != null ? [var.workflow_on_partial_upload] : []

        content {
          execution_role = on_partial_upload.value.execution_role
          workflow_id    = on_partial_upload.value.workflow_id
        }
      }
    }
  }

  tags = merge(local.tags, {
    Name = var.name
  })

  lifecycle {
    enabled = local.enabled
  }
}

################################################################################
# Users
################################################################################

resource "aws_transfer_user" "this" {
  for_each = { for k, v in var.users : k => v if local.enabled }

  server_id = aws_transfer_server.this.id
  user_name = each.value.user_name
  role      = each.value.role

  home_directory      = try(each.value.home_directory, null)
  home_directory_type = try(each.value.home_directory_type, null)
  policy              = try(each.value.policy, null)

  dynamic "home_directory_mappings" {
    for_each = try(each.value.home_directory_mappings, [])

    content {
      entry  = home_directory_mappings.value.entry
      target = home_directory_mappings.value.target
    }
  }

  dynamic "posix_profile" {
    for_each = try(each.value.posix_profile, null) != null ? [each.value.posix_profile] : []

    content {
      gid            = posix_profile.value.gid
      uid            = posix_profile.value.uid
      secondary_gids = try(posix_profile.value.secondary_gids, null)
    }
  }

  tags = local.tags
}

################################################################################
# SSH Keys
################################################################################

resource "aws_transfer_ssh_key" "this" {
  for_each = { for k, v in var.users : k => v if local.enabled && try(v.ssh_public_key, null) != null }

  server_id = aws_transfer_server.this.id
  user_name = aws_transfer_user.this[each.key].user_name
  body      = each.value.ssh_public_key
}

################################################################################
# Workflow
################################################################################

resource "aws_transfer_workflow" "this" {
  for_each = { for k, v in var.workflows : k => v if local.enabled }

  description = try(each.value.description, null)

  dynamic "steps" {
    for_each = each.value.steps

    content {
      type = steps.value.type

      dynamic "copy_step_details" {
        for_each = steps.value.type == "COPY" ? [try(steps.value.copy_step_details, {})] : []

        content {
          name                 = try(copy_step_details.value.name, null)
          source_file_location = try(copy_step_details.value.source_file_location, null)

          dynamic "destination_file_location" {
            for_each = try(copy_step_details.value.destination_file_location, null) != null ? [copy_step_details.value.destination_file_location] : []

            content {
              dynamic "s3_file_location" {
                for_each = try(destination_file_location.value.s3_file_location, null) != null ? [destination_file_location.value.s3_file_location] : []

                content {
                  bucket = try(s3_file_location.value.bucket, null)
                  key    = try(s3_file_location.value.key, null)
                }
              }

              dynamic "efs_file_location" {
                for_each = try(destination_file_location.value.efs_file_location, null) != null ? [destination_file_location.value.efs_file_location] : []

                content {
                  file_system_id = try(efs_file_location.value.file_system_id, null)
                  path           = try(efs_file_location.value.path, null)
                }
              }
            }
          }
        }
      }

      dynamic "custom_step_details" {
        for_each = steps.value.type == "CUSTOM" ? [try(steps.value.custom_step_details, {})] : []

        content {
          name                 = try(custom_step_details.value.name, null)
          source_file_location = try(custom_step_details.value.source_file_location, null)
          target               = try(custom_step_details.value.target, null)
          timeout_seconds      = try(custom_step_details.value.timeout_seconds, null)
        }
      }

      dynamic "delete_step_details" {
        for_each = steps.value.type == "DELETE" ? [try(steps.value.delete_step_details, {})] : []

        content {
          name                 = try(delete_step_details.value.name, null)
          source_file_location = try(delete_step_details.value.source_file_location, null)
        }
      }

      dynamic "tag_step_details" {
        for_each = steps.value.type == "TAG" ? [try(steps.value.tag_step_details, {})] : []

        content {
          name                 = try(tag_step_details.value.name, null)
          source_file_location = try(tag_step_details.value.source_file_location, null)

          dynamic "tags" {
            for_each = try(tag_step_details.value.tags, [])

            content {
              key   = tags.value.key
              value = tags.value.value
            }
          }
        }
      }
    }
  }

  dynamic "on_exception_steps" {
    for_each = try(each.value.on_exception_steps, [])

    content {
      type = on_exception_steps.value.type

      dynamic "delete_step_details" {
        for_each = on_exception_steps.value.type == "DELETE" ? [try(on_exception_steps.value.delete_step_details, {})] : []

        content {
          name                 = try(delete_step_details.value.name, null)
          source_file_location = try(delete_step_details.value.source_file_location, null)
        }
      }
    }
  }

  tags = local.tags
}

################################################################################
# Route53 Custom Hostname
################################################################################

resource "aws_route53_record" "this" {
  for_each = { for k, v in var.route53_records : k => v if local.enabled }

  zone_id = each.value.zone_id
  name    = each.value.name
  type    = "CNAME"
  ttl     = try(each.value.ttl, 300)
  records = [aws_transfer_server.this.endpoint]
}

################################################################################
# IAM - Logging Role
################################################################################

resource "aws_iam_role" "logging" {
  name = "${var.name}-transfer-logging"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "transfer.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_logging_role
  }
}

resource "aws_iam_role_policy" "logging" {
  name = "${var.name}-transfer-logging"
  role = aws_iam_role.logging.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
        ]
        Resource = "arn:${local.partition}:logs:*:${local.account_id}:log-group:/aws/transfer/*"
      }
    ]
  })

  lifecycle {
    enabled = local.enabled && var.create_logging_role
  }
}
