locals {
  enabled  = var.enabled
  env_name = var.env_name

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
    Region    = data.aws_region.current.region
  })

  # Per-runner configuration consumed by aws_codebuild_project.this and
  # aws_codebuild_webhook.this via for_each. The map keys ("build",
  # "deployment") become the resource instance keys and the keys of the map
  # outputs. Every difference between the two runners lives here; everything
  # not in this map is shared between them.
  runners = {
    build = {
      name                        = "${lower(var.repository_name)}-build-${local.env_name}"
      short_name                  = "${lower(var.repository_name)}-build"
      description                 = "CodeBuild Project for ${lower(var.repository_name)} build jobs"
      build_timeout               = var.build_runner_build_timeout
      queued_timeout              = var.build_runner_queued_timeout
      concurrent_build_limit      = var.concurrent_build_limit
      environment_type            = var.build_runner_environment_type
      compute_type                = var.build_runner_compute_type
      image_pull_credentials_type = var.build_image_pull_credentials_type
      fleet_arn                   = var.build_runner_fleet_arn
      buildspec                   = var.build_runner_buildspec
      webhook_build_type          = var.build_runner_build_type
      webhook_manual_creation     = var.build_runner_webhook_manual_creation
      webhook_branch_filter       = var.build_runner_webhook_branch_filter
    }
    deployment = {
      name                        = "${lower(var.repository_name)}-deploy-${local.env_name}"
      short_name                  = "${lower(var.repository_name)}-deploy"
      description                 = "CodeBuild Project for ${lower(var.repository_name)} deployment jobs"
      build_timeout               = var.deployment_runner_build_timeout
      queued_timeout              = var.deployment_runner_queued_timeout
      concurrent_build_limit      = var.concurrent_deployment_limit
      environment_type            = var.deployment_runner_environment_type
      compute_type                = var.deployment_runner_compute_type
      image_pull_credentials_type = var.deployment_image_pull_credentials_type
      fleet_arn                   = var.deployment_runner_fleet_arn
      buildspec                   = var.deployment_runner_buildspec
      webhook_build_type          = var.deployment_runner_build_type
      webhook_manual_creation     = var.deployment_runner_webhook_manual_creation
      webhook_branch_filter       = var.deployment_runner_webhook_branch_filter
    }
  }
}

# Creating Assume role policy for service role
data "aws_iam_policy_document" "assume_role_policy_codebuild_runners" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_role" "role_codebuild_runners" {
  count = local.enabled && !var.create_iam_role ? 1 : 0
  name  = coalesce(var.iam_role_name, "codebuild-${var.repository_name}")
}

# Creating Service Role for CodeBuild
resource "aws_iam_role" "role_codebuild_runners" {
  name               = coalesce(var.iam_role_name, "codebuild-${var.repository_name}")
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_codebuild_runners.json

  lifecycle {
    enabled = local.enabled && var.create_iam_role
  }
}

# Attaching the Policy to the role
resource "aws_iam_role_policy" "policy_codebuild_runners" {
  name   = "codebuild-github-runner-policy"
  role   = aws_iam_role.role_codebuild_runners.name
  policy = var.codebuild_iam_policy

  lifecycle {
    enabled = local.enabled && var.create_iam_role
  }
}


# Creating Codebuild Project
data "aws_ecr_repository" "codebuild_runner" {
  count = local.enabled && var.codebuild_runner_repository_url == null ? 1 : 0
  name  = var.codebuild_runner_repository_name
}

#######################################################################################################################
# Security Group for Codebuild
#######################################################################################################################
# Optional legacy lookup by Name tag, used only when no explicit security_group_ids are passed
data "aws_security_group" "codebuild_runners_sg" {
  count = local.enabled && !var.create_security_group && length(var.security_group_ids) == 0 ? 1 : 0

  filter {
    name   = "tag:Name"
    values = ["codebuild-runners-${local.env_name}-security-group"]
  }
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_security_group" "codebuild_runners" {
  name        = "codebuild-runners-${local.env_name}-security-group"
  description = "Allow internal traffic within the security group and all outbound traffic"
  vpc_id      = var.vpc_id

  tags = merge(local.tags, { Name = "codebuild-runners-${local.env_name}-security-group" })

  lifecycle {
    enabled = local.enabled && var.create_security_group
  }
}

resource "aws_vpc_security_group_ingress_rule" "codebuild_runners" {
  description                  = "self-referencing rule"
  security_group_id            = aws_security_group.codebuild_runners.id
  referenced_security_group_id = aws_security_group.codebuild_runners.id
  ip_protocol                  = "-1"

  lifecycle {
    enabled = local.enabled && var.create_security_group
  }
}

# trivy:ignore:AVD-AWS-0104 - CodeBuild runners require broad egress to pull packages and container images
resource "aws_vpc_security_group_egress_rule" "codebuild_runners" {
  security_group_id = aws_security_group.codebuild_runners.id
  description       = "allow all egress"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  lifecycle {
    enabled = local.enabled && var.create_security_group
  }
}

#######################################################################################################################
# CloudWatch Log Group (shared by both runners; each runner logs to its own stream prefix)
#######################################################################################################################

resource "aws_cloudwatch_log_group" "codebuild_runners" {
  name                        = coalesce(var.cloudwatch_log_group_name, "/aws/codebuild/${lower(var.repository_name)}-${local.env_name}")
  retention_in_days           = var.cloudwatch_log_group_retention_in_days
  kms_key_id                  = var.cloudwatch_log_group_kms_key_id
  skip_destroy                = false
  log_group_class             = "STANDARD"
  deletion_protection_enabled = var.cloudwatch_log_group_deletion_protection_enabled

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_cloudwatch_log_group
  }
}

#######################################################################################################################
# CodeBuild Runner Projects
#
# One project per entry in local.runners ("build" and "deployment"). State
# addresses are aws_codebuild_project.this["build"] and
# aws_codebuild_project.this["deployment"]; per-runner settings (timeouts,
# concurrency, compute/environment type, fleet, image pull credentials,
# buildspec, log stream, webhook settings) come from local.runners, everything
# else is shared module-level configuration.
#######################################################################################################################

resource "aws_codebuild_project" "this" {
  for_each = { for k, v in local.runners : k => v if local.enabled }

  name                   = each.value.name
  description            = each.value.description
  build_timeout          = each.value.build_timeout
  queued_timeout         = each.value.queued_timeout
  concurrent_build_limit = each.value.concurrent_build_limit
  auto_retry_limit       = var.auto_retry_limit
  service_role           = try(data.aws_iam_role.role_codebuild_runners[0].arn, aws_iam_role.role_codebuild_runners.arn)
  project_visibility     = var.project_visibility
  badge_enabled          = var.badge_enabled
  resource_access_role   = var.resource_access_role
  encryption_key         = var.encryption_key
  source_version         = var.source_version

  artifacts {
    type                   = var.artifacts_type
    location               = var.artifacts_location
    name                   = var.artifacts_name
    namespace_type         = var.artifacts_namespace_type
    packaging              = var.artifacts_packaging
    path                   = var.artifacts_path
    override_artifact_name = var.artifacts_override_artifact_name
    encryption_disabled    = var.artifacts_encryption_disabled
    bucket_owner_access    = var.artifacts_bucket_owner_access
  }

  dynamic "secondary_artifacts" {
    for_each = var.secondary_artifacts
    content {
      type                   = secondary_artifacts.value.type
      artifact_identifier    = secondary_artifacts.value.artifact_identifier
      location               = try(secondary_artifacts.value.location, null)
      name                   = try(secondary_artifacts.value.name, null)
      namespace_type         = try(secondary_artifacts.value.namespace_type, null)
      override_artifact_name = try(secondary_artifacts.value.override_artifact_name, null)
      packaging              = try(secondary_artifacts.value.packaging, null)
      path                   = try(secondary_artifacts.value.path, null)
      encryption_disabled    = try(secondary_artifacts.value.encryption_disabled, null)
      bucket_owner_access    = try(secondary_artifacts.value.bucket_owner_access, null)
    }
  }

  dynamic "build_batch_config" {
    for_each = var.build_batch_config != null ? [var.build_batch_config] : []
    content {
      service_role      = build_batch_config.value.service_role
      combine_artifacts = try(build_batch_config.value.combine_artifacts, null)
      timeout_in_mins   = try(build_batch_config.value.timeout_in_mins, null)

      dynamic "restrictions" {
        for_each = try(build_batch_config.value.restrictions, null) != null ? [build_batch_config.value.restrictions] : []
        content {
          maximum_builds_allowed = try(restrictions.value.maximum_builds_allowed, null)
          compute_types_allowed  = try(restrictions.value.compute_types_allowed, [])
        }
      }
    }
  }

  cache {
    type            = var.cache_type
    location        = var.cache_location
    modes           = var.cache_type == "LOCAL" ? var.cache_modes : null
    cache_namespace = var.cache_namespace
  }

  environment {
    image                       = "${var.codebuild_runner_repository_url != null ? var.codebuild_runner_repository_url : try(data.aws_ecr_repository.codebuild_runner[0].repository_url, "")}:${var.codebuild_runner_image_tag}"
    type                        = each.value.environment_type
    compute_type                = each.value.compute_type
    privileged_mode             = var.privileged_mode
    image_pull_credentials_type = each.value.image_pull_credentials_type
    certificate                 = var.environment_certificate

    dynamic "fleet" {
      for_each = each.value.fleet_arn != null ? [1] : []
      content {
        fleet_arn = each.value.fleet_arn
      }
    }

    dynamic "docker_server" {
      for_each = var.docker_server != null ? [var.docker_server] : []

      content {
        compute_type       = docker_server.value.compute_type
        security_group_ids = docker_server.value.security_group_ids
      }
    }

    dynamic "registry_credential" {
      for_each = var.registry_credential != null ? [var.registry_credential] : []
      content {
        credential          = registry_credential.value.credential
        credential_provider = registry_credential.value.credential_provider
      }
    }

    dynamic "environment_variable" {
      for_each = var.environment_variables
      content {
        name  = environment_variable.value.name
        value = environment_variable.value.value
        type  = environment_variable.value.type
      }
    }
  }

  source {
    type                = "GITHUB"
    location            = "https://github.com/${var.github_organization_name}/${var.repository_name}.git"
    git_clone_depth     = 1
    buildspec           = each.value.buildspec
    insecure_ssl        = var.source_insecure_ssl
    report_build_status = var.source_report_build_status

    git_submodules_config {
      fetch_submodules = true
    }

    dynamic "auth" {
      for_each = var.source_auth != null ? [var.source_auth] : []
      content {
        type     = auth.value.type
        resource = try(auth.value.resource, null)
      }
    }

    dynamic "build_status_config" {
      for_each = var.source_build_status_config != null ? [var.source_build_status_config] : []
      content {
        context    = try(build_status_config.value.context, null)
        target_url = try(build_status_config.value.target_url, null)
      }
    }
  }

  dynamic "secondary_sources" {
    for_each = var.secondary_sources
    content {
      type                = secondary_sources.value.type
      source_identifier   = secondary_sources.value.source_identifier
      location            = try(secondary_sources.value.location, null)
      git_clone_depth     = try(secondary_sources.value.git_clone_depth, null)
      buildspec           = try(secondary_sources.value.buildspec, null)
      insecure_ssl        = try(secondary_sources.value.insecure_ssl, null)
      report_build_status = try(secondary_sources.value.report_build_status, null)

      dynamic "git_submodules_config" {
        for_each = try(secondary_sources.value.git_submodules_config, null) != null ? [secondary_sources.value.git_submodules_config] : []
        content {
          fetch_submodules = git_submodules_config.value.fetch_submodules
        }
      }

      dynamic "auth" {
        for_each = try(secondary_sources.value.auth, null) != null ? [secondary_sources.value.auth] : []
        content {
          type     = auth.value.type
          resource = try(auth.value.resource, null)
        }
      }

      dynamic "build_status_config" {
        for_each = try(secondary_sources.value.build_status_config, null) != null ? [secondary_sources.value.build_status_config] : []
        content {
          context    = try(build_status_config.value.context, null)
          target_url = try(build_status_config.value.target_url, null)
        }
      }
    }
  }

  dynamic "secondary_source_version" {
    for_each = var.secondary_source_versions
    content {
      source_identifier = secondary_source_version.value.source_identifier
      source_version    = secondary_source_version.value.source_version
    }
  }

  dynamic "file_system_locations" {
    for_each = var.file_system_locations
    content {
      identifier    = try(file_system_locations.value.identifier, null)
      location      = try(file_system_locations.value.location, null)
      mount_options = try(file_system_locations.value.mount_options, null)
      mount_point   = try(file_system_locations.value.mount_point, null)
      type          = try(file_system_locations.value.type, "EFS")
    }
  }

  vpc_config {
    vpc_id             = var.vpc_id
    subnets            = var.codebuild_subnets
    security_group_ids = var.create_security_group ? [aws_security_group.codebuild_runners.id] : (length(var.security_group_ids) > 0 ? var.security_group_ids : [data.aws_security_group.codebuild_runners_sg[0].id])
  }

  logs_config {
    cloudwatch_logs {
      group_name  = var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.codebuild_runners.name : var.cloudwatch_log_group_name
      stream_name = each.value.short_name
      status      = var.cloudwatch_logs_status
    }

    s3_logs {
      status              = var.s3_logs_status
      location            = var.s3_logs_location
      encryption_disabled = var.s3_logs_encryption_disabled
      bucket_owner_access = var.s3_logs_bucket_owner_access
    }
  }

  tags = merge(local.tags, { Name = each.value.short_name })
}

# Configuring the webhook for each runner project
resource "aws_codebuild_webhook" "this" {
  for_each = { for k, v in local.runners : k => v if local.enabled }

  project_name    = aws_codebuild_project.this[each.key].name
  build_type      = each.value.webhook_build_type
  manual_creation = each.value.webhook_manual_creation
  branch_filter   = each.value.webhook_branch_filter

  filter_group {
    filter {
      type                    = "EVENT"
      pattern                 = "WORKFLOW_JOB_QUEUED"
      exclude_matched_pattern = false
    }
  }

  dynamic "scope_configuration" {
    for_each = var.webhook_scope_configuration != null ? [var.webhook_scope_configuration] : []
    content {
      name   = scope_configuration.value.name
      scope  = scope_configuration.value.scope
      domain = try(scope_configuration.value.domain, null)
    }
  }

  dynamic "pull_request_build_policy" {
    for_each = var.webhook_pull_request_build_policy != null ? [var.webhook_pull_request_build_policy] : []
    content {
      requires_comment_approval = pull_request_build_policy.value.requires_comment_approval
      approver_roles            = try(pull_request_build_policy.value.approver_roles, null)
    }
  }
}

data "aws_region" "current" {}
