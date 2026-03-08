
variable "enabled" {
  description = "Determines whether resources will be created"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  type    = string
  default = null
}

variable "build_runner_build_timeout" {
  description = "Number of minutes, from 5 to 480 (8 hours), for AWS CodeBuild to wait until timing out any related build that does not get marked as completed"
  type        = number
  default     = 60
}

variable "build_runner_queued_timeout" {
  description = "Number of minutes, from 5 to 480 (8 hours), a build is allowed to be queued before it times out"
  type        = number
  default     = 60
}

variable "deployment_runner_build_timeout" {
  description = "Number of minutes, from 5 to 480 (8 hours), for AWS CodeBuild to wait until timing out any related build that does not get marked as completed"
  type        = number
  default     = 60
}

variable "deployment_runner_queued_timeout" {
  description = "Number of minutes, from 5 to 480 (8 hours), a build is allowed to be queued before it times out"
  type        = number
  default     = 480
}

variable "concurrent_build_limit" {
  description = "pecify a maximum number of concurrent builds for the project. The value specified must be greater than 0 and less than the account concurrent running builds limit"
  type        = number
  default     = 30
}

variable "concurrent_deployment_limit" {
  description = "pecify a maximum number of concurrent builds for the project. The value specified must be greater than 0 and less than the account concurrent running builds limit"
  type        = number
  default     = 2
}

variable "create_iam_role" {
  description = "Enable this option if you need to create an IAM role"
  type        = bool
  default     = false
}

variable "iam_role_name" {
  description = "Name of the codebuild IAM role"
  type        = string
  default     = null
}

variable "create_security_group" {
  description = "Enable this option if you need to create the security group"
  type        = bool
  default     = false
}

variable "github_organization_name" {
  description = "The GitHub organization name"
  type        = string
  default     = null
}

variable "repository_name" {
  description = "Name of the Github repository"
  type        = string
  default     = null
}

variable "codebuild_iam_policy" {
  description = "The codebuild IAM policy"
  type        = string
  default     = null
}

variable "build_runner_environment_type" {
  description = "Environment type for AWS Codebuild Project"
  type        = string
  default     = "LINUX_CONTAINER"
}

variable "deployment_runner_environment_type" {
  description = "Environment type for AWS Codebuild Project"
  type        = string
  default     = "LINUX_CONTAINER"
}

variable "build_runner_compute_type" {
  description = "Compute type for AWS Codebuild Project"
  type        = string
  default     = "BUILD_GENERAL1_MEDIUM"
}

variable "deployment_runner_compute_type" {
  description = "Compute type for AWS Codebuild Project"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "build_runner_build_type" {
  description = "The type of build this webhook will trigger. Valid values for this parameter are: BUILD, BUILD_BATCH"
  type        = string
  default     = "BUILD"
}

variable "deployment_runner_build_type" {
  description = "The type of build this webhook will trigger. Valid values for this parameter are: BUILD, BUILD_BATCH"
  type        = string
  default     = "BUILD"
}

variable "codebuild_runner_repository_url" {
  description = "The codebuild runner ecr image url"
  type        = string
  default     = null
}

variable "codebuild_runner_repository_name" {
  description = "The name of the ECR repository where the Docker image is stored"
  type        = string
  default     = "codebuild-runner"
}

variable "codebuild_runner_image_tag" {
  description = "The codebuild runner image tag"
  type        = string
  default     = "latest"
}

variable "env_name" {
  description = "Environment name (e.g., development, staging, production). If not set, falls back to terraform.workspace."
  type        = string
  default     = null
}

variable "codebuild_subnets" {
  description = "The list of IDs of the codebuild subnets"
  type        = list(any)
}

variable "cache_type" {
  description = "The cache type for codebuild project"
  type        = string
  default     = "LOCAL"
}

variable "cache_modes" {
  description = "Cache modes to enable for the codebuild project"
  type        = list(string)
  default     = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
}

variable "build_image_pull_credentials_type" {
  description = "Image pull credentials type for the build codebuild project"
  type        = string
  default     = "SERVICE_ROLE"
}

variable "deployment_image_pull_credentials_type" {
  description = "Image pull credentials type for the deployment codebuild project"
  type        = string
  default     = "SERVICE_ROLE"
}

variable "project_visibility" {
  description = "Specifies the visibility of the project's builds. Possible values are: PUBLIC_READ, PRIVATE."
  type        = string
  default     = "PRIVATE"

  validation {
    condition     = contains(["PUBLIC_READ", "PRIVATE"], var.project_visibility)
    error_message = "project_visibility must be PUBLIC_READ or PRIVATE."
  }
}

variable "badge_enabled" {
  description = "Generates a publicly-accessible URL for the projects build badge."
  type        = bool
  default     = false
}

variable "resource_access_role" {
  description = "The ARN of the IAM role that enables CodeBuild to access the CloudWatch Logs and Amazon S3 artifacts for the project's builds."
  type        = string
  default     = null
}

variable "build_runner_buildspec" {
  description = "The build spec declaration to use for the build runner project's builds."
  type        = string
  default     = null
}

variable "deployment_runner_buildspec" {
  description = "The build spec declaration to use for the deployment runner project's builds."
  type        = string
  default     = null
}

variable "build_runner_fleet_arn" {
  description = "ARN of the CodeBuild reserved capacity fleet for the build runner."
  type        = string
  default     = null
}

variable "deployment_runner_fleet_arn" {
  description = "ARN of the CodeBuild reserved capacity fleet for the deployment runner."
  type        = string
  default     = null
}

variable "secondary_artifacts" {
  description = "List of secondary artifact configurations for the CodeBuild projects."
  type = list(object({
    type                   = string
    artifact_identifier    = string
    location               = optional(string)
    name                   = optional(string)
    namespace_type         = optional(string)
    override_artifact_name = optional(bool)
    packaging              = optional(string)
    path                   = optional(string)
    encryption_disabled    = optional(bool)
    bucket_owner_access    = optional(string)
  }))
  default = []
}

variable "file_system_locations" {
  description = "List of EFS file system locations to mount during builds."
  type = list(object({
    identifier    = optional(string)
    location      = optional(string)
    mount_options = optional(string)
    mount_point   = optional(string)
    type          = optional(string, "EFS")
  }))
  default = []
}

variable "environment_variables" {
  description = "List of environment variables to set for the build runner. Each entry supports: name, value, type (PLAINTEXT, PARAMETER_STORE, SECRETS_MANAGER)."
  type = list(object({
    name  = string
    value = string
    type  = optional(string, "PLAINTEXT")
  }))
  default = []
}

variable "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for CodeBuild logs."
  type        = string
  default     = null
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain CodeBuild CloudWatch logs."
  type        = number
  default     = 30

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_log_group_retention_in_days)
    error_message = "cloudwatch_log_group_retention_in_days must be one of the allowed CloudWatch Logs retention values."
  }
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "KMS Key ARN for encrypting CodeBuild CloudWatch log group."
  type        = string
  default     = null
}

variable "create_cloudwatch_log_group" {
  description = "Whether to create a CloudWatch log group for CodeBuild logs."
  type        = bool
  default     = false
}

variable "cloudwatch_logs_status" {
  description = "Status for CloudWatch logging in CodeBuild. Valid values: ENABLED, DISABLED."
  type        = string
  default     = "ENABLED"

  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.cloudwatch_logs_status)
    error_message = "cloudwatch_logs_status must be ENABLED or DISABLED."
  }
}

variable "s3_logs_status" {
  description = "Status for S3 logging in CodeBuild. Valid values: ENABLED, DISABLED."
  type        = string
  default     = "DISABLED"

  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.s3_logs_status)
    error_message = "s3_logs_status must be ENABLED or DISABLED."
  }
}

variable "s3_logs_location" {
  description = "S3 bucket path where CodeBuild logs will be stored. Required when s3_logs_status is ENABLED."
  type        = string
  default     = null
}

variable "s3_logs_encryption_disabled" {
  description = "Whether to disable encrypting S3 build logs. Defaults to false."
  type        = bool
  default     = false
}

variable "s3_logs_bucket_owner_access" {
  description = "Cross-account bucket owner access for S3 logs. Valid values: NONE, READ_ONLY, FULL."
  type        = string
  default     = "NONE"

  validation {
    condition     = contains(["NONE", "READ_ONLY", "FULL"], var.s3_logs_bucket_owner_access)
    error_message = "s3_logs_bucket_owner_access must be NONE, READ_ONLY, or FULL."
  }
}

variable "encryption_key" {
  description = "AWS KMS customer master key (CMK) ARN to be used for encrypting the CodeBuild project's build output artifacts."
  type        = string
  default     = null
}

variable "source_version" {
  description = "Version of the build input to be built for this project. If not specified, the latest version is used."
  type        = string
  default     = null
}

variable "auto_retry_limit" {
  description = "Maximum number of additional automatic retries after a failed build"
  type        = number
  default     = null
}

variable "docker_server" {
  description = "Configuration for a Docker build environment server"
  type        = any
  default     = null
}

variable "registry_credential" {
  description = "Information about credentials for a private Docker registry to access during the build. Contains credential (ARN or name of AWS Secrets Manager credential) and credential_provider (must be SECRETS_MANAGER)."
  type        = any
  default     = null
}

variable "cache_namespace" {
  description = "Namespace that determines the scope in which a cache is shared across multiple projects. Applies when cache type is S3 or LOCAL."
  type        = string
  default     = null
}

variable "secondary_source_versions" {
  description = "List of secondary source version overrides. Each entry requires source_identifier (matching a secondary_sources identifier) and source_version."
  type = list(object({
    source_identifier = string
    source_version    = string
  }))
  default = []
}

variable "cloudwatch_log_group_deletion_protection_enabled" {
  description = "Whether to enable deletion protection on the CloudWatch log group."
  type        = bool
  default     = false
}

variable "artifacts_type" {
  description = "Build output artifact type. Valid values: CODEPIPELINE, NO_ARTIFACTS, S3."
  type        = string
  default     = "NO_ARTIFACTS"
}

variable "artifacts_location" {
  description = "Location where the artifacts are stored. Required when artifacts_type is S3."
  type        = string
  default     = null
}

variable "artifacts_name" {
  description = "Name of the build artifact. Required for S3 artifacts when namespace_type is BUILD_ID."
  type        = string
  default     = null
}

variable "artifacts_namespace_type" {
  description = "Namespace to use in storing build artifacts. Valid values: NONE, BUILD_ID."
  type        = string
  default     = null
}

variable "artifacts_packaging" {
  description = "Type of build output artifact to create. Valid values: NONE, ZIP."
  type        = string
  default     = null
}

variable "artifacts_path" {
  description = "If type is set to S3, this is the path to the output artifact."
  type        = string
  default     = null
}

variable "artifacts_override_artifact_name" {
  description = "Whether a name specified in the build spec overrides the artifact name."
  type        = bool
  default     = null
}

variable "artifacts_encryption_disabled" {
  description = "Whether to disable encrypting output artifacts. If type is set to NO_ARTIFACTS, this value is ignored."
  type        = bool
  default     = null
}

variable "artifacts_bucket_owner_access" {
  description = "Specifies the bucket owner's access for objects that another account uploads to their Amazon S3 bucket. Valid values: NONE, READ_ONLY, FULL."
  type        = string
  default     = null
}

variable "build_batch_config" {
  description = "Configuration for batch builds. If set, enables batch build support."
  type = object({
    service_role      = string
    combine_artifacts = optional(bool)
    timeout_in_mins   = optional(number)
    restrictions = optional(object({
      maximum_builds_allowed = optional(number)
      compute_types_allowed  = optional(list(string), [])
    }))
  })
  default = null
}

variable "cache_location" {
  description = "Location where the AWS CodeBuild project stores cached resources. Required when cache_type is S3."
  type        = string
  default     = null
}

variable "environment_certificate" {
  description = "ARN of the S3 bucket, path prefix and object key that contains the PEM-encoded certificate for the build environment."
  type        = string
  default     = null
}

variable "source_insecure_ssl" {
  description = "Ignore SSL warnings when connecting to source control."
  type        = bool
  default     = null
}

variable "source_report_build_status" {
  description = "Whether to report the status of a build's start and finish to your source provider. Supported for GitHub, GitHub Enterprise, and Bitbucket."
  type        = bool
  default     = null
}

variable "source_auth" {
  description = "Authorization configuration for the source. Requires type (CODECONNECTIONS, OAUTH) and optional resource (OAuth token ARN or CodeConnections ARN)."
  type = object({
    type     = string
    resource = optional(string)
  })
  default = null
}

variable "source_build_status_config" {
  description = "Configuration for the build status notification for the source. Supports context and target_url."
  type = object({
    context    = optional(string)
    target_url = optional(string)
  })
  default = null
}

variable "build_runner_webhook_manual_creation" {
  description = "If true, the webhook for the build runner is created manually. Returns payload_url and secret for manual setup."
  type        = bool
  default     = null
}

variable "build_runner_webhook_branch_filter" {
  description = "A regular expression used to determine which branches the build runner webhook triggers a build on."
  type        = string
  default     = null
}

variable "deployment_runner_webhook_manual_creation" {
  description = "If true, the webhook for the deployment runner is created manually. Returns payload_url and secret for manual setup."
  type        = bool
  default     = null
}

variable "deployment_runner_webhook_branch_filter" {
  description = "A regular expression used to determine which branches the deployment runner webhook triggers a build on."
  type        = string
  default     = null
}

variable "webhook_scope_configuration" {
  description = "Configuration for a GitHub organization or global webhook. Applies to both build and deployment runner webhooks."
  type = object({
    name   = string
    scope  = string
    domain = optional(string)
  })
  default = null
}

variable "webhook_pull_request_build_policy" {
  description = "Approval requirements for pull request builds. Applies to both build and deployment runner webhooks."
  type = object({
    requires_comment_approval = string
    approver_roles            = optional(list(string))
  })
  default = null
}

variable "secondary_sources" {
  description = "List of secondary source configurations for the CodeBuild projects."
  type = list(object({
    type                = string
    location            = optional(string)
    source_identifier   = string
    git_clone_depth     = optional(number)
    buildspec           = optional(string)
    insecure_ssl        = optional(bool)
    report_build_status = optional(bool)
    git_submodules_config = optional(object({
      fetch_submodules = bool
    }))
    auth = optional(object({
      type     = string
      resource = optional(string)
    }))
    build_status_config = optional(object({
      context    = optional(string)
      target_url = optional(string)
    }))
  }))
  default = []
}
