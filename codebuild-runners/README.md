<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.34 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.34 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_codebuild_subnets"></a> [codebuild\_subnets](#input\_codebuild\_subnets) | The list of IDs of the codebuild subnets | `list(any)` | n/a | yes |
| <a name="input_artifacts_bucket_owner_access"></a> [artifacts\_bucket\_owner\_access](#input\_artifacts\_bucket\_owner\_access) | Specifies the bucket owner's access for objects that another account uploads to their Amazon S3 bucket. Valid values: NONE, READ\_ONLY, FULL. | `string` | `null` | no |
| <a name="input_artifacts_encryption_disabled"></a> [artifacts\_encryption\_disabled](#input\_artifacts\_encryption\_disabled) | Whether to disable encrypting output artifacts. If type is set to NO\_ARTIFACTS, this value is ignored. | `bool` | `null` | no |
| <a name="input_artifacts_location"></a> [artifacts\_location](#input\_artifacts\_location) | Location where the artifacts are stored. Required when artifacts\_type is S3. | `string` | `null` | no |
| <a name="input_artifacts_name"></a> [artifacts\_name](#input\_artifacts\_name) | Name of the build artifact. Required for S3 artifacts when namespace\_type is BUILD\_ID. | `string` | `null` | no |
| <a name="input_artifacts_namespace_type"></a> [artifacts\_namespace\_type](#input\_artifacts\_namespace\_type) | Namespace to use in storing build artifacts. Valid values: NONE, BUILD\_ID. | `string` | `null` | no |
| <a name="input_artifacts_override_artifact_name"></a> [artifacts\_override\_artifact\_name](#input\_artifacts\_override\_artifact\_name) | Whether a name specified in the build spec overrides the artifact name. | `bool` | `null` | no |
| <a name="input_artifacts_packaging"></a> [artifacts\_packaging](#input\_artifacts\_packaging) | Type of build output artifact to create. Valid values: NONE, ZIP. | `string` | `null` | no |
| <a name="input_artifacts_path"></a> [artifacts\_path](#input\_artifacts\_path) | If type is set to S3, this is the path to the output artifact. | `string` | `null` | no |
| <a name="input_artifacts_type"></a> [artifacts\_type](#input\_artifacts\_type) | Build output artifact type. Valid values: CODEPIPELINE, NO\_ARTIFACTS, S3. | `string` | `"NO_ARTIFACTS"` | no |
| <a name="input_auto_retry_limit"></a> [auto\_retry\_limit](#input\_auto\_retry\_limit) | Maximum number of additional automatic retries after a failed build | `number` | `null` | no |
| <a name="input_badge_enabled"></a> [badge\_enabled](#input\_badge\_enabled) | Generates a publicly-accessible URL for the projects build badge. | `bool` | `false` | no |
| <a name="input_build_batch_config"></a> [build\_batch\_config](#input\_build\_batch\_config) | Configuration for batch builds. If set, enables batch build support. | <pre>object({<br/>    service_role      = string<br/>    combine_artifacts = optional(bool)<br/>    timeout_in_mins   = optional(number)<br/>    restrictions = optional(object({<br/>      maximum_builds_allowed = optional(number)<br/>      compute_types_allowed  = optional(list(string), [])<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_build_image_pull_credentials_type"></a> [build\_image\_pull\_credentials\_type](#input\_build\_image\_pull\_credentials\_type) | Image pull credentials type for the build codebuild project | `string` | `"SERVICE_ROLE"` | no |
| <a name="input_build_runner_build_timeout"></a> [build\_runner\_build\_timeout](#input\_build\_runner\_build\_timeout) | Number of minutes, from 5 to 480 (8 hours), for AWS CodeBuild to wait until timing out any related build that does not get marked as completed | `number` | `60` | no |
| <a name="input_build_runner_build_type"></a> [build\_runner\_build\_type](#input\_build\_runner\_build\_type) | The type of build this webhook will trigger. Valid values for this parameter are: BUILD, BUILD\_BATCH | `string` | `"BUILD"` | no |
| <a name="input_build_runner_buildspec"></a> [build\_runner\_buildspec](#input\_build\_runner\_buildspec) | The build spec declaration to use for the build runner project's builds. | `string` | `null` | no |
| <a name="input_build_runner_compute_type"></a> [build\_runner\_compute\_type](#input\_build\_runner\_compute\_type) | Compute type for AWS Codebuild Project | `string` | `"BUILD_GENERAL1_MEDIUM"` | no |
| <a name="input_build_runner_environment_type"></a> [build\_runner\_environment\_type](#input\_build\_runner\_environment\_type) | Environment type for AWS Codebuild Project | `string` | `"LINUX_CONTAINER"` | no |
| <a name="input_build_runner_fleet_arn"></a> [build\_runner\_fleet\_arn](#input\_build\_runner\_fleet\_arn) | ARN of the CodeBuild reserved capacity fleet for the build runner. | `string` | `null` | no |
| <a name="input_build_runner_queued_timeout"></a> [build\_runner\_queued\_timeout](#input\_build\_runner\_queued\_timeout) | Number of minutes, from 5 to 480 (8 hours), a build is allowed to be queued before it times out | `number` | `60` | no |
| <a name="input_build_runner_webhook_branch_filter"></a> [build\_runner\_webhook\_branch\_filter](#input\_build\_runner\_webhook\_branch\_filter) | A regular expression used to determine which branches the build runner webhook triggers a build on. | `string` | `null` | no |
| <a name="input_build_runner_webhook_manual_creation"></a> [build\_runner\_webhook\_manual\_creation](#input\_build\_runner\_webhook\_manual\_creation) | If true, the webhook for the build runner is created manually. Returns payload\_url and secret for manual setup. | `bool` | `null` | no |
| <a name="input_cache_location"></a> [cache\_location](#input\_cache\_location) | Location where the AWS CodeBuild project stores cached resources. Required when cache\_type is S3. | `string` | `null` | no |
| <a name="input_cache_modes"></a> [cache\_modes](#input\_cache\_modes) | Cache modes to enable for the codebuild project | `list(string)` | <pre>[<br/>  "LOCAL_DOCKER_LAYER_CACHE",<br/>  "LOCAL_SOURCE_CACHE"<br/>]</pre> | no |
| <a name="input_cache_namespace"></a> [cache\_namespace](#input\_cache\_namespace) | Namespace that determines the scope in which a cache is shared across multiple projects. Applies when cache type is S3 or LOCAL. | `string` | `null` | no |
| <a name="input_cache_type"></a> [cache\_type](#input\_cache\_type) | The cache type for codebuild project | `string` | `"LOCAL"` | no |
| <a name="input_cloudwatch_log_group_deletion_protection_enabled"></a> [cloudwatch\_log\_group\_deletion\_protection\_enabled](#input\_cloudwatch\_log\_group\_deletion\_protection\_enabled) | Whether to enable deletion protection on the CloudWatch log group. | `bool` | `false` | no |
| <a name="input_cloudwatch_log_group_kms_key_id"></a> [cloudwatch\_log\_group\_kms\_key\_id](#input\_cloudwatch\_log\_group\_kms\_key\_id) | KMS Key ARN for encrypting CodeBuild CloudWatch log group. | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#input\_cloudwatch\_log\_group\_name) | Name of the CloudWatch log group for CodeBuild logs. | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_retention_in_days"></a> [cloudwatch\_log\_group\_retention\_in\_days](#input\_cloudwatch\_log\_group\_retention\_in\_days) | Number of days to retain CodeBuild CloudWatch logs. | `number` | `30` | no |
| <a name="input_cloudwatch_logs_status"></a> [cloudwatch\_logs\_status](#input\_cloudwatch\_logs\_status) | Status for CloudWatch logging in CodeBuild. Valid values: ENABLED, DISABLED. | `string` | `"ENABLED"` | no |
| <a name="input_codebuild_iam_policy"></a> [codebuild\_iam\_policy](#input\_codebuild\_iam\_policy) | The codebuild IAM policy | `string` | `null` | no |
| <a name="input_codebuild_runner_image_tag"></a> [codebuild\_runner\_image\_tag](#input\_codebuild\_runner\_image\_tag) | The codebuild runner image tag | `string` | `"latest"` | no |
| <a name="input_codebuild_runner_repository_name"></a> [codebuild\_runner\_repository\_name](#input\_codebuild\_runner\_repository\_name) | The name of the ECR repository where the Docker image is stored | `string` | `"codebuild-runner"` | no |
| <a name="input_codebuild_runner_repository_url"></a> [codebuild\_runner\_repository\_url](#input\_codebuild\_runner\_repository\_url) | The codebuild runner ecr image url | `string` | `null` | no |
| <a name="input_concurrent_build_limit"></a> [concurrent\_build\_limit](#input\_concurrent\_build\_limit) | pecify a maximum number of concurrent builds for the project. The value specified must be greater than 0 and less than the account concurrent running builds limit | `number` | `30` | no |
| <a name="input_concurrent_deployment_limit"></a> [concurrent\_deployment\_limit](#input\_concurrent\_deployment\_limit) | pecify a maximum number of concurrent builds for the project. The value specified must be greater than 0 and less than the account concurrent running builds limit | `number` | `2` | no |
| <a name="input_create_cloudwatch_log_group"></a> [create\_cloudwatch\_log\_group](#input\_create\_cloudwatch\_log\_group) | Whether to create a CloudWatch log group for CodeBuild logs. | `bool` | `false` | no |
| <a name="input_create_iam_role"></a> [create\_iam\_role](#input\_create\_iam\_role) | Enable this option if you need to create an IAM role | `bool` | `false` | no |
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | Enable this option if you need to create the security group | `bool` | `false` | no |
| <a name="input_deployment_image_pull_credentials_type"></a> [deployment\_image\_pull\_credentials\_type](#input\_deployment\_image\_pull\_credentials\_type) | Image pull credentials type for the deployment codebuild project | `string` | `"SERVICE_ROLE"` | no |
| <a name="input_deployment_runner_build_timeout"></a> [deployment\_runner\_build\_timeout](#input\_deployment\_runner\_build\_timeout) | Number of minutes, from 5 to 480 (8 hours), for AWS CodeBuild to wait until timing out any related build that does not get marked as completed | `number` | `60` | no |
| <a name="input_deployment_runner_build_type"></a> [deployment\_runner\_build\_type](#input\_deployment\_runner\_build\_type) | The type of build this webhook will trigger. Valid values for this parameter are: BUILD, BUILD\_BATCH | `string` | `"BUILD"` | no |
| <a name="input_deployment_runner_buildspec"></a> [deployment\_runner\_buildspec](#input\_deployment\_runner\_buildspec) | The build spec declaration to use for the deployment runner project's builds. | `string` | `null` | no |
| <a name="input_deployment_runner_compute_type"></a> [deployment\_runner\_compute\_type](#input\_deployment\_runner\_compute\_type) | Compute type for AWS Codebuild Project | `string` | `"BUILD_GENERAL1_SMALL"` | no |
| <a name="input_deployment_runner_environment_type"></a> [deployment\_runner\_environment\_type](#input\_deployment\_runner\_environment\_type) | Environment type for AWS Codebuild Project | `string` | `"LINUX_CONTAINER"` | no |
| <a name="input_deployment_runner_fleet_arn"></a> [deployment\_runner\_fleet\_arn](#input\_deployment\_runner\_fleet\_arn) | ARN of the CodeBuild reserved capacity fleet for the deployment runner. | `string` | `null` | no |
| <a name="input_deployment_runner_queued_timeout"></a> [deployment\_runner\_queued\_timeout](#input\_deployment\_runner\_queued\_timeout) | Number of minutes, from 5 to 480 (8 hours), a build is allowed to be queued before it times out | `number` | `480` | no |
| <a name="input_deployment_runner_webhook_branch_filter"></a> [deployment\_runner\_webhook\_branch\_filter](#input\_deployment\_runner\_webhook\_branch\_filter) | A regular expression used to determine which branches the deployment runner webhook triggers a build on. | `string` | `null` | no |
| <a name="input_deployment_runner_webhook_manual_creation"></a> [deployment\_runner\_webhook\_manual\_creation](#input\_deployment\_runner\_webhook\_manual\_creation) | If true, the webhook for the deployment runner is created manually. Returns payload\_url and secret for manual setup. | `bool` | `null` | no |
| <a name="input_docker_server"></a> [docker\_server](#input\_docker\_server) | Configuration for a Docker build environment server | `any` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Determines whether resources will be created | `bool` | `true` | no |
| <a name="input_encryption_key"></a> [encryption\_key](#input\_encryption\_key) | AWS KMS customer master key (CMK) ARN to be used for encrypting the CodeBuild project's build output artifacts. | `string` | `null` | no |
| <a name="input_env_name"></a> [env\_name](#input\_env\_name) | Environment name (e.g., development, staging, production). If not set, falls back to terraform.workspace. | `string` | `null` | no |
| <a name="input_environment_certificate"></a> [environment\_certificate](#input\_environment\_certificate) | ARN of the S3 bucket, path prefix and object key that contains the PEM-encoded certificate for the build environment. | `string` | `null` | no |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | List of environment variables to set for the build runner. Each entry supports: name, value, type (PLAINTEXT, PARAMETER\_STORE, SECRETS\_MANAGER). | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>    type  = optional(string, "PLAINTEXT")<br/>  }))</pre> | `[]` | no |
| <a name="input_file_system_locations"></a> [file\_system\_locations](#input\_file\_system\_locations) | List of EFS file system locations to mount during builds. | <pre>list(object({<br/>    identifier    = optional(string)<br/>    location      = optional(string)<br/>    mount_options = optional(string)<br/>    mount_point   = optional(string)<br/>    type          = optional(string, "EFS")<br/>  }))</pre> | `[]` | no |
| <a name="input_github_organization_name"></a> [github\_organization\_name](#input\_github\_organization\_name) | The GitHub organization name | `string` | `null` | no |
| <a name="input_iam_role_name"></a> [iam\_role\_name](#input\_iam\_role\_name) | Name of the codebuild IAM role | `string` | `null` | no |
| <a name="input_project_visibility"></a> [project\_visibility](#input\_project\_visibility) | Specifies the visibility of the project's builds. Possible values are: PUBLIC\_READ, PRIVATE. | `string` | `"PRIVATE"` | no |
| <a name="input_registry_credential"></a> [registry\_credential](#input\_registry\_credential) | Information about credentials for a private Docker registry to access during the build. Contains credential (ARN or name of AWS Secrets Manager credential) and credential\_provider (must be SECRETS\_MANAGER). | `any` | `null` | no |
| <a name="input_repository_name"></a> [repository\_name](#input\_repository\_name) | Name of the Github repository | `string` | `null` | no |
| <a name="input_resource_access_role"></a> [resource\_access\_role](#input\_resource\_access\_role) | The ARN of the IAM role that enables CodeBuild to access the CloudWatch Logs and Amazon S3 artifacts for the project's builds. | `string` | `null` | no |
| <a name="input_s3_logs_bucket_owner_access"></a> [s3\_logs\_bucket\_owner\_access](#input\_s3\_logs\_bucket\_owner\_access) | Cross-account bucket owner access for S3 logs. Valid values: NONE, READ\_ONLY, FULL. | `string` | `"NONE"` | no |
| <a name="input_s3_logs_encryption_disabled"></a> [s3\_logs\_encryption\_disabled](#input\_s3\_logs\_encryption\_disabled) | Whether to disable encrypting S3 build logs. Defaults to false. | `bool` | `false` | no |
| <a name="input_s3_logs_location"></a> [s3\_logs\_location](#input\_s3\_logs\_location) | S3 bucket path where CodeBuild logs will be stored. Required when s3\_logs\_status is ENABLED. | `string` | `null` | no |
| <a name="input_s3_logs_status"></a> [s3\_logs\_status](#input\_s3\_logs\_status) | Status for S3 logging in CodeBuild. Valid values: ENABLED, DISABLED. | `string` | `"DISABLED"` | no |
| <a name="input_secondary_artifacts"></a> [secondary\_artifacts](#input\_secondary\_artifacts) | List of secondary artifact configurations for the CodeBuild projects. | <pre>list(object({<br/>    type                   = string<br/>    artifact_identifier    = string<br/>    location               = optional(string)<br/>    name                   = optional(string)<br/>    namespace_type         = optional(string)<br/>    override_artifact_name = optional(bool)<br/>    packaging              = optional(string)<br/>    path                   = optional(string)<br/>    encryption_disabled    = optional(bool)<br/>    bucket_owner_access    = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_secondary_source_versions"></a> [secondary\_source\_versions](#input\_secondary\_source\_versions) | List of secondary source version overrides. Each entry requires source\_identifier (matching a secondary\_sources identifier) and source\_version. | <pre>list(object({<br/>    source_identifier = string<br/>    source_version    = string<br/>  }))</pre> | `[]` | no |
| <a name="input_secondary_sources"></a> [secondary\_sources](#input\_secondary\_sources) | List of secondary source configurations for the CodeBuild projects. | <pre>list(object({<br/>    type                = string<br/>    location            = optional(string)<br/>    source_identifier   = string<br/>    git_clone_depth     = optional(number)<br/>    buildspec           = optional(string)<br/>    insecure_ssl        = optional(bool)<br/>    report_build_status = optional(bool)<br/>    git_submodules_config = optional(object({<br/>      fetch_submodules = bool<br/>    }))<br/>    auth = optional(object({<br/>      type     = string<br/>      resource = optional(string)<br/>    }))<br/>    build_status_config = optional(object({<br/>      context    = optional(string)<br/>      target_url = optional(string)<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_source_auth"></a> [source\_auth](#input\_source\_auth) | Authorization configuration for the source. Requires type (CODECONNECTIONS, OAUTH) and optional resource (OAuth token ARN or CodeConnections ARN). | <pre>object({<br/>    type     = string<br/>    resource = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_source_build_status_config"></a> [source\_build\_status\_config](#input\_source\_build\_status\_config) | Configuration for the build status notification for the source. Supports context and target\_url. | <pre>object({<br/>    context    = optional(string)<br/>    target_url = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_source_insecure_ssl"></a> [source\_insecure\_ssl](#input\_source\_insecure\_ssl) | Ignore SSL warnings when connecting to source control. | `bool` | `null` | no |
| <a name="input_source_report_build_status"></a> [source\_report\_build\_status](#input\_source\_report\_build\_status) | Whether to report the status of a build's start and finish to your source provider. Supported for GitHub, GitHub Enterprise, and Bitbucket. | `bool` | `null` | no |
| <a name="input_source_version"></a> [source\_version](#input\_source\_version) | Version of the build input to be built for this project. If not specified, the latest version is used. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `string` | `null` | no |
| <a name="input_webhook_pull_request_build_policy"></a> [webhook\_pull\_request\_build\_policy](#input\_webhook\_pull\_request\_build\_policy) | Approval requirements for pull request builds. Applies to both build and deployment runner webhooks. | <pre>object({<br/>    requires_comment_approval = string<br/>    approver_roles            = optional(list(string))<br/>  })</pre> | `null` | no |
| <a name="input_webhook_scope_configuration"></a> [webhook\_scope\_configuration](#input\_webhook\_scope\_configuration) | Configuration for a GitHub organization or global webhook. Applies to both build and deployment runner webhooks. | <pre>object({<br/>    name   = string<br/>    scope  = string<br/>    domain = optional(string)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_build_runner_project_arn"></a> [build\_runner\_project\_arn](#output\_build\_runner\_project\_arn) | ARN of the CodeBuild build runner project |
| <a name="output_build_runner_project_name"></a> [build\_runner\_project\_name](#output\_build\_runner\_project\_name) | Name of the CodeBuild build runner project |
| <a name="output_build_runner_webhook_url"></a> [build\_runner\_webhook\_url](#output\_build\_runner\_webhook\_url) | URL of the webhook to trigger builds for the build runner |
| <a name="output_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#output\_cloudwatch\_log\_group\_arn) | ARN of the CloudWatch log group for CodeBuild logs |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | Name of the CloudWatch log group for CodeBuild logs |
| <a name="output_deployment_runner_project_arn"></a> [deployment\_runner\_project\_arn](#output\_deployment\_runner\_project\_arn) | ARN of the CodeBuild deployment runner project |
| <a name="output_deployment_runner_project_name"></a> [deployment\_runner\_project\_name](#output\_deployment\_runner\_project\_name) | Name of the CodeBuild deployment runner project |
| <a name="output_deployment_runner_webhook_url"></a> [deployment\_runner\_webhook\_url](#output\_deployment\_runner\_webhook\_url) | URL of the webhook to trigger builds for the deployment runner |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | ARN of the CodeBuild IAM role (if created by this module) |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | Name of the CodeBuild IAM role (if created by this module) |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the CodeBuild security group (if created by this module) |
<!-- END_TF_DOCS -->
