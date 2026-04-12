locals {
  create    = var.enabled
  workspace = var.env_name != null ? var.env_name : terraform.workspace

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
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
  count = var.create_iam_role ? 0 : 1
  name  = try(var.iam_role_name, "codebuild-${var.repository_name}")
}

# Creating Service Role for CodeBuild
resource "aws_iam_role" "role_codebuild_runners" {
  name               = try(var.iam_role_name, "codebuild-${var.repository_name}")
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_codebuild_runners.json

  lifecycle {
    enabled = local.create && var.create_iam_role
  }
}

# Attaching the Policy to the role
resource "aws_iam_role_policy" "policy_codebuild_runners" {
  name   = "codebuild-github-runner-policy"
  role   = aws_iam_role.role_codebuild_runners.name
  policy = var.codebuild_iam_policy

  lifecycle {
    enabled = local.create && var.create_iam_role
  }
}


data "aws_vpc" "vpc" {
  count = local.create && var.vpc_id != null ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

# Creating Codebuild Project
data "aws_ecr_repository" "codebuild_runner" {
  count = local.create ? 1 : 0
  name  = var.codebuild_runner_repository_name
}

#######################################################################################################################
# Security Group for Codebuild
#######################################################################################################################
data "aws_security_group" "codebuild_runners_sg" {
  count = var.create_security_group ? 0 : 1

  filter {
    name   = "tag:Name"
    values = ["codebuild-runners-${local.workspace}-security-group"]
  }
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_security_group" "codebuild_runners" {
  name        = "codebuild-runners-${local.workspace}-security-group"
  description = "Allow internal traffic within the security group and all outbound traffic"
  vpc_id      = try(data.aws_vpc.vpc[0].id, var.vpc_id)

  tags = merge(local.tags, { Name = "codebuild-runners-${local.workspace}-security-group" })

  lifecycle {
    enabled = local.create && var.create_security_group
  }
}

resource "aws_vpc_security_group_ingress_rule" "codebuild_runners" {
  description                  = "self-referencing rule"
  security_group_id            = aws_security_group.codebuild_runners.id
  referenced_security_group_id = aws_security_group.codebuild_runners.id
  ip_protocol                  = "-1"

  lifecycle {
    enabled = local.create && var.create_security_group
  }
}

# trivy:ignore:AVD-AWS-0104 - CodeBuild runners require broad egress to pull packages and container images
resource "aws_vpc_security_group_egress_rule" "codebuild_runners" {
  security_group_id = aws_security_group.codebuild_runners.id
  description       = "allow all egress"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  lifecycle {
    enabled = local.create && var.create_security_group
  }
}

#######################################################################################################################
# Runners for Builds
#######################################################################################################################

resource "aws_cloudwatch_log_group" "codebuild_runners" {
  name                        = coalesce(var.cloudwatch_log_group_name, "/aws/codebuild/${lower(var.repository_name)}-${local.workspace}")
  retention_in_days           = var.cloudwatch_log_group_retention_in_days
  kms_key_id                  = var.cloudwatch_log_group_kms_key_id
  skip_destroy                = false
  log_group_class             = "STANDARD"
  deletion_protection_enabled = var.cloudwatch_log_group_deletion_protection_enabled

  tags = local.tags

  lifecycle {
    enabled = local.create && var.create_cloudwatch_log_group
  }
}

resource "aws_codebuild_project" "codebuild_build_runner" {
  name                   = "${lower(var.repository_name)}-build-${local.workspace}"
  description            = "CodeBuild Project for ${lower(var.repository_name)} build jobs"
  build_timeout          = var.build_runner_build_timeout
  queued_timeout         = var.build_runner_queued_timeout
  concurrent_build_limit = var.concurrent_build_limit
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
    type                        = var.build_runner_environment_type
    compute_type                = var.build_runner_compute_type
    privileged_mode             = true
    image_pull_credentials_type = var.build_image_pull_credentials_type
    certificate                 = var.environment_certificate

    dynamic "fleet" {
      for_each = var.build_runner_fleet_arn != null ? [1] : []
      content {
        fleet_arn = var.build_runner_fleet_arn
      }
    }

    dynamic "docker_server" {
      for_each = var.docker_server != null ? [var.docker_server] : []

      content {
        compute_type       = docker_server.value.compute_type
        security_group_ids = try(docker_server.value.security_group_ids, null)
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
    buildspec           = var.build_runner_buildspec
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
    security_group_ids = var.create_security_group ? [aws_security_group.codebuild_runners.id] : [data.aws_security_group.codebuild_runners_sg[0].id]
  }

  logs_config {
    cloudwatch_logs {
      group_name  = var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.codebuild_runners.name : var.cloudwatch_log_group_name
      stream_name = "${lower(var.repository_name)}-build"
      status      = var.cloudwatch_logs_status
    }

    s3_logs {
      status              = var.s3_logs_status
      location            = var.s3_logs_location
      encryption_disabled = var.s3_logs_encryption_disabled
      bucket_owner_access = var.s3_logs_bucket_owner_access
    }
  }

  tags = merge(local.tags, { Name = "${lower(var.repository_name)}-build" })

  lifecycle {
    enabled = local.create
  }
}

# Configuring the webhook for the project
resource "aws_codebuild_webhook" "codebuild_build_runner" {
  project_name    = aws_codebuild_project.codebuild_build_runner.name
  build_type      = var.build_runner_build_type
  manual_creation = var.build_runner_webhook_manual_creation
  branch_filter   = var.build_runner_webhook_branch_filter

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

  lifecycle {
    enabled = local.create
  }
}

#######################################################################################################################
# Runners for Deployments
#######################################################################################################################

resource "aws_codebuild_project" "codebuild_deployment_runner" {
  name                   = "${lower(var.repository_name)}-deploy-${local.workspace}"
  description            = "CodeBuild Project for ${lower(var.repository_name)} deployment jobs"
  build_timeout          = var.deployment_runner_build_timeout
  queued_timeout         = var.deployment_runner_queued_timeout
  concurrent_build_limit = var.concurrent_deployment_limit
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
    type                        = var.deployment_runner_environment_type
    compute_type                = var.deployment_runner_compute_type
    privileged_mode             = true
    image_pull_credentials_type = var.deployment_image_pull_credentials_type
    certificate                 = var.environment_certificate

    dynamic "fleet" {
      for_each = var.deployment_runner_fleet_arn != null ? [1] : []
      content {
        fleet_arn = var.deployment_runner_fleet_arn
      }
    }

    dynamic "docker_server" {
      for_each = var.docker_server != null ? [var.docker_server] : []

      content {
        compute_type       = docker_server.value.compute_type
        security_group_ids = try(docker_server.value.security_group_ids, null)
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
    buildspec           = var.deployment_runner_buildspec
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
    security_group_ids = var.create_security_group ? [aws_security_group.codebuild_runners.id] : [data.aws_security_group.codebuild_runners_sg[0].id]
  }

  logs_config {
    cloudwatch_logs {
      group_name  = var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.codebuild_runners.name : var.cloudwatch_log_group_name
      stream_name = "${lower(var.repository_name)}-deploy"
      status      = var.cloudwatch_logs_status
    }

    s3_logs {
      status              = var.s3_logs_status
      location            = var.s3_logs_location
      encryption_disabled = var.s3_logs_encryption_disabled
      bucket_owner_access = var.s3_logs_bucket_owner_access
    }
  }

  tags = merge(local.tags, { Name = "${lower(var.repository_name)}-deploy" })

  lifecycle {
    enabled = local.create
  }
}

# Configuring the webhook for the project
resource "aws_codebuild_webhook" "codebuild_deployment_runner" {
  project_name    = aws_codebuild_project.codebuild_deployment_runner.name
  build_type      = var.deployment_runner_build_type
  manual_creation = var.deployment_runner_webhook_manual_creation
  branch_filter   = var.deployment_runner_webhook_branch_filter

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

  lifecycle {
    enabled = local.create
  }
}

#######################################################################################################################
