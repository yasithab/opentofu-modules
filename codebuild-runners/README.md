# AWS CodeBuild Runners

Provisions AWS CodeBuild projects configured as GitHub Actions self-hosted runners, with separate build and deployment runner projects, webhook integration, VPC networking, and optional IAM role and security group creation.

## Features

- **Dual Runner Projects** - Creates separate CodeBuild projects for build and deployment workflows, each with independent compute types, timeouts, and concurrency limits
- **GitHub Webhook Integration** - Configures webhooks that trigger on `WORKFLOW_JOB_QUEUED` events, with support for organization-scoped webhooks and pull request approval policies
- **VPC Networking** - Runs builds inside a VPC with configurable subnets and security groups, enabling access to private resources such as databases and internal APIs
- **IAM Role Management** - Optionally creates a dedicated CodeBuild service role with a custom IAM policy, or references an existing role
- **Security Group Creation** - Optionally provisions a security group with self-referencing ingress and full egress for package and image pulls
- **CloudWatch Logging** - Optionally creates a CloudWatch Log Group with configurable retention, KMS encryption, and deletion protection for build logs
- **S3 Logging** - Supports sending build logs to S3 for long-term retention alongside CloudWatch
- **Custom Docker Images** - Pulls runner images from ECR with configurable repository URL and image tag
- **Build Caching** - Supports LOCAL and S3 cache types with Docker layer and source caching enabled by default
- **Artifact Support** - Configurable build artifact output to S3 or CodePipeline, including secondary artifacts
- **Fleet and Batch Builds** - Supports reserved capacity fleets and batch build configurations for high-throughput workloads

## Usage

### Behaviour notes

- The build and deployment runners are a single `for_each` resource pair
  (`aws_codebuild_project.this` / `aws_codebuild_webhook.this`) iterating over an internal
  `runners` map with keys `"build"` and `"deployment"`. Per-runner variables use the
  `build_runner_*` / `deployment_runner_*` prefixes. The shared CloudWatch log group is a
  single resource; each runner logs to its own stream prefix.
- The `project_arns`, `project_names`, and `webhook_urls` outputs are maps keyed by runner
  (e.g. `module.codebuild_runners.project_arns["deployment"]`).
- When `create_security_group = false`, pass existing security groups explicitly via
  `security_group_ids`. If it is empty, the module falls back to a lookup by the
  `Name=codebuild-runners-<env_name>-security-group` tag and fails fast if no matching
  group exists.
- `privileged_mode` defaults to `true`; set it to `false` for runners that do not build
  Docker images.

```hcl
module "codebuild_runners" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//codebuild-runners?depth=1&ref=master"

  repository_name          = "my-service"
  github_organization_name = "MyOrganization"
  env_name                 = "production"

  vpc_id            = "vpc-0abc1234def567890"
  codebuild_subnets = ["subnet-0aaa111122223333", "subnet-0bbb444455556666"]

  codebuild_runner_repository_name = "codebuild-runner"
  codebuild_runner_image_tag       = "3.0.0"

  create_iam_role       = false
  iam_role_name         = "codebuild-my-service"
  create_security_group = false

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Examples

## Basic Usage - GitHub Actions Self-Hosted Runners

Provisions CodeBuild projects for build and deployment GitHub Actions runners linked to a single repository, using an existing IAM role and security group.

```hcl
module "codebuild_runners" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//codebuild-runners?depth=1&ref=master"

  repository_name          = "my-service"
  github_organization_name = "my-org"
  env_name                 = "production"
  vpc_id                   = "vpc-0abc1234def567890"
  codebuild_subnets = [
    "subnet-0aaa111122223333",
    "subnet-0bbb444455556666",
  ]

  codebuild_runner_repository_name = "codebuild-runner"
  codebuild_runner_image_tag       = "3.0.0"

  create_iam_role      = false
  iam_role_name        = "codebuild-my-service"
  create_security_group = false

  concurrent_build_limit      = 10
  concurrent_deployment_limit = 2

  build_runner_compute_type      = "BUILD_GENERAL1_MEDIUM"
  deployment_runner_compute_type = "BUILD_GENERAL1_SMALL"

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## With New IAM Role and Security Group

Creates dedicated IAM role, security group, and CloudWatch log group for full isolation per repository.

```hcl
module "codebuild_runners_full" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//codebuild-runners?depth=1&ref=master"

  repository_name  = "checkout-service"
  env_name         = "staging"
  vpc_id           = "vpc-0abc1234def567890"
  codebuild_subnets = [
    "subnet-0aaa111122223333",
    "subnet-0bbb444455556666",
  ]

  codebuild_runner_repository_name = "codebuild-runner"
  codebuild_runner_image_tag       = "3.0.0"

  create_iam_role      = true
  iam_role_name        = "codebuild-checkout-service-staging"
  codebuild_iam_policy = data.aws_iam_policy_document.codebuild_policy.json

  create_security_group = true

  create_cloudwatch_log_group             = true
  cloudwatch_log_group_retention_in_days  = 30
  cloudwatch_log_group_kms_key_id         = "arn:aws:kms:us-east-1:123456789012:key/mrk-1234abcd5678efgh"

  concurrent_build_limit      = 5
  concurrent_deployment_limit = 2

  build_runner_build_timeout      = 60
  deployment_runner_build_timeout = 120

  environment_variables = [
    {
      name  = "AWS_REGION"
      value = "us-east-1"
      type  = "PLAINTEXT"
    },
    {
      name  = "DEPLOY_BUCKET"
      value = "/codebuild/checkout-service/deploy-bucket"
      type  = "PARAMETER_STORE"
    },
  ]

  tags = {
    Environment = "staging"
    Team        = "checkout"
  }
}
```

## With Encryption and S3 Logging

Encrypts CodeBuild artifacts with a customer-managed KMS key and sends build logs to S3 for long-term retention.

```hcl
module "codebuild_runners_encrypted" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//codebuild-runners?depth=1&ref=master"

  repository_name  = "payments-service"
  env_name         = "production"
  vpc_id           = "vpc-0abc1234def567890"
  codebuild_subnets = [
    "subnet-0aaa111122223333",
    "subnet-0bbb444455556666",
  ]

  codebuild_runner_repository_name = "codebuild-runner"
  codebuild_runner_image_tag       = "3.0.0"

  create_iam_role      = false
  iam_role_name        = "codebuild-payments-service"
  create_security_group = false

  encryption_key = "arn:aws:kms:us-east-1:123456789012:key/mrk-1234abcd5678efgh"

  create_cloudwatch_log_group            = true
  cloudwatch_log_group_retention_in_days = 90
  cloudwatch_log_group_kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/mrk-1234abcd5678efgh"

  s3_logs_status              = "ENABLED"
  s3_logs_location            = "my-codebuild-logs-bucket/payments-service"
  s3_logs_encryption_disabled = false

  concurrent_build_limit      = 10
  concurrent_deployment_limit = 2

  build_runner_compute_type      = "BUILD_GENERAL1_LARGE"
  deployment_runner_compute_type = "BUILD_GENERAL1_MEDIUM"

  auto_retry_limit = 1

  tags = {
    Environment = "production"
    Team        = "payments"
  }
}
```

## Organization-Scoped Webhook

Configures a GitHub organization-level webhook so all repositories in the organization trigger the runners automatically, with a pull request approval policy.

```hcl
module "codebuild_runners_org_webhook" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//codebuild-runners?depth=1&ref=master"

  repository_name          = "org-runners"
  github_organization_name = "MyOrganization"
  env_name                 = "production"
  vpc_id                   = "vpc-0abc1234def567890"
  codebuild_subnets = [
    "subnet-0aaa111122223333",
    "subnet-0bbb444455556666",
  ]

  codebuild_runner_repository_name = "codebuild-runner"
  codebuild_runner_image_tag       = "3.0.0"

  create_iam_role       = false
  iam_role_name         = "codebuild-org-runners"
  create_security_group = false

  webhook_scope_configuration = {
    name  = "MyOrganization"
    scope = "GITHUB_ORGANIZATION"
  }

  webhook_pull_request_build_policy = {
    requires_comment_approval = "COLLABORATORS_ONLY"
    approver_roles            = ["WRITER", "ADMIN"]
  }

  concurrent_build_limit      = 30
  concurrent_deployment_limit = 5

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Reference

<details>
<summary>Requirements, providers, inputs and outputs (generated by terraform-docs)</summary>

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11.0 |
| aws | >= 6.49, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.49, < 7.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| artifacts\_bucket\_owner\_access | Specifies the bucket owner's access for objects that another account uploads to their Amazon S3 bucket. Valid values: NONE, READ\_ONLY, FULL. | `string` | `null` | no |
| artifacts\_encryption\_disabled | Whether to disable encrypting output artifacts. If type is set to NO\_ARTIFACTS, this value is ignored. | `bool` | `null` | no |
| artifacts\_location | Location where the artifacts are stored. Required when artifacts\_type is S3. | `string` | `null` | no |
| artifacts\_name | Name of the build artifact. Required for S3 artifacts when namespace\_type is BUILD\_ID. | `string` | `null` | no |
| artifacts\_namespace\_type | Namespace to use in storing build artifacts. Valid values: NONE, BUILD\_ID. | `string` | `null` | no |
| artifacts\_override\_artifact\_name | Whether a name specified in the build spec overrides the artifact name. | `bool` | `null` | no |
| artifacts\_packaging | Type of build output artifact to create. Valid values: NONE, ZIP. | `string` | `null` | no |
| artifacts\_path | If type is set to S3, this is the path to the output artifact. | `string` | `null` | no |
| artifacts\_type | Build output artifact type. Valid values: CODEPIPELINE, NO\_ARTIFACTS, S3. | `string` | `"NO_ARTIFACTS"` | no |
| auto\_retry\_limit | Maximum number of additional automatic retries after a failed build | `number` | `null` | no |
| badge\_enabled | Generates a publicly-accessible URL for the projects build badge. | `bool` | `false` | no |
| build\_batch\_config | Configuration for batch builds. If set, enables batch build support. | <pre>object({<br/>    service_role      = string<br/>    combine_artifacts = optional(bool)<br/>    timeout_in_mins   = optional(number)<br/>    restrictions = optional(object({<br/>      maximum_builds_allowed = optional(number)<br/>      compute_types_allowed  = optional(list(string), [])<br/>    }))<br/>  })</pre> | `null` | no |
| build\_image\_pull\_credentials\_type | Image pull credentials type for the build codebuild project | `string` | `"SERVICE_ROLE"` | no |
| build\_runner\_build\_timeout | Number of minutes, from 5 to 480 (8 hours), for AWS CodeBuild to wait until timing out any related build that does not get marked as completed | `number` | `60` | no |
| build\_runner\_build\_type | The type of build this webhook will trigger. Valid values for this parameter are: BUILD, BUILD\_BATCH | `string` | `"BUILD"` | no |
| build\_runner\_buildspec | The build spec declaration to use for the build runner project's builds. | `string` | `null` | no |
| build\_runner\_compute\_type | Compute type for AWS Codebuild Project | `string` | `"BUILD_GENERAL1_MEDIUM"` | no |
| build\_runner\_environment\_type | Environment type for AWS Codebuild Project | `string` | `"LINUX_CONTAINER"` | no |
| build\_runner\_fleet\_arn | ARN of the CodeBuild reserved capacity fleet for the build runner. | `string` | `null` | no |
| build\_runner\_queued\_timeout | Number of minutes, from 5 to 480 (8 hours), a build is allowed to be queued before it times out | `number` | `60` | no |
| build\_runner\_webhook\_branch\_filter | A regular expression used to determine which branches the build runner webhook triggers a build on. | `string` | `null` | no |
| build\_runner\_webhook\_manual\_creation | If true, the webhook for the build runner is created manually. Returns payload\_url and secret for manual setup. | `bool` | `null` | no |
| cache\_location | Location where the AWS CodeBuild project stores cached resources. Required when cache\_type is S3. | `string` | `null` | no |
| cache\_modes | Cache modes to enable for the codebuild project | `list(string)` | <pre>[<br/>  "LOCAL_DOCKER_LAYER_CACHE",<br/>  "LOCAL_SOURCE_CACHE"<br/>]</pre> | no |
| cache\_namespace | Namespace that determines the scope in which a cache is shared across multiple projects. Applies when cache type is S3 or LOCAL. | `string` | `null` | no |
| cache\_type | The cache type for codebuild project | `string` | `"LOCAL"` | no |
| cloudwatch\_log\_group\_deletion\_protection\_enabled | Whether to enable deletion protection on the CloudWatch log group. | `bool` | `false` | no |
| cloudwatch\_log\_group\_kms\_key\_id | KMS Key ARN for encrypting CodeBuild CloudWatch log group. | `string` | `null` | no |
| cloudwatch\_log\_group\_name | Name of the CloudWatch log group for CodeBuild logs. | `string` | `null` | no |
| cloudwatch\_log\_group\_retention\_in\_days | Number of days to retain CodeBuild CloudWatch logs. | `number` | `30` | no |
| cloudwatch\_logs\_status | Status for CloudWatch logging in CodeBuild. Valid values: ENABLED, DISABLED. | `string` | `"ENABLED"` | no |
| codebuild\_iam\_policy | The codebuild IAM policy | `string` | `null` | no |
| codebuild\_runner\_image\_tag | The codebuild runner image tag | `string` | `"latest"` | no |
| codebuild\_runner\_repository\_name | The name of the ECR repository where the Docker image is stored | `string` | `"codebuild-runner"` | no |
| codebuild\_runner\_repository\_url | The codebuild runner ecr image url | `string` | `null` | no |
| codebuild\_subnets | The list of IDs of the subnets the CodeBuild runners run in. | `list(string)` | n/a | yes |
| concurrent\_build\_limit | pecify a maximum number of concurrent builds for the project. The value specified must be greater than 0 and less than the account concurrent running builds limit | `number` | `30` | no |
| concurrent\_deployment\_limit | pecify a maximum number of concurrent builds for the project. The value specified must be greater than 0 and less than the account concurrent running builds limit | `number` | `2` | no |
| create\_cloudwatch\_log\_group | Whether to create a CloudWatch log group for CodeBuild logs. BREAKING: defaults to true (was false) so log retention is enforced instead of CodeBuild creating a never-expiring group implicitly. | `bool` | `true` | no |
| create\_iam\_role | Enable this option if you need to create an IAM role | `bool` | `false` | no |
| create\_security\_group | Enable this option if you need to create the security group | `bool` | `false` | no |
| deployment\_image\_pull\_credentials\_type | Image pull credentials type for the deployment codebuild project | `string` | `"SERVICE_ROLE"` | no |
| deployment\_runner\_build\_timeout | Number of minutes, from 5 to 480 (8 hours), for AWS CodeBuild to wait until timing out any related build that does not get marked as completed | `number` | `60` | no |
| deployment\_runner\_build\_type | The type of build this webhook will trigger. Valid values for this parameter are: BUILD, BUILD\_BATCH | `string` | `"BUILD"` | no |
| deployment\_runner\_buildspec | The build spec declaration to use for the deployment runner project's builds. | `string` | `null` | no |
| deployment\_runner\_compute\_type | Compute type for AWS Codebuild Project | `string` | `"BUILD_GENERAL1_SMALL"` | no |
| deployment\_runner\_environment\_type | Environment type for AWS Codebuild Project | `string` | `"LINUX_CONTAINER"` | no |
| deployment\_runner\_fleet\_arn | ARN of the CodeBuild reserved capacity fleet for the deployment runner. | `string` | `null` | no |
| deployment\_runner\_queued\_timeout | Number of minutes, from 5 to 480 (8 hours), a build is allowed to be queued before it times out | `number` | `480` | no |
| deployment\_runner\_webhook\_branch\_filter | A regular expression used to determine which branches the deployment runner webhook triggers a build on. | `string` | `null` | no |
| deployment\_runner\_webhook\_manual\_creation | If true, the webhook for the deployment runner is created manually. Returns payload\_url and secret for manual setup. | `bool` | `null` | no |
| docker\_server | Configuration for a Docker build environment server | <pre>object({<br/>    compute_type       = string<br/>    security_group_ids = optional(list(string))<br/>  })</pre> | `null` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| encryption\_key | AWS KMS customer master key (CMK) ARN to be used for encrypting the CodeBuild project's build output artifacts. | `string` | `null` | no |
| env\_name | Environment name (e.g., development, staging, production). Used in resource names. BREAKING: this is now required; the previous fallback to terraform.workspace was removed. | `string` | n/a | yes |
| environment\_certificate | ARN of the S3 bucket, path prefix and object key that contains the PEM-encoded certificate for the build environment. | `string` | `null` | no |
| environment\_variables | List of environment variables to set for the build runner. Each entry supports: name, value, type (PLAINTEXT, PARAMETER\_STORE, SECRETS\_MANAGER). | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>    type  = optional(string, "PLAINTEXT")<br/>  }))</pre> | `[]` | no |
| file\_system\_locations | List of EFS file system locations to mount during builds. | <pre>list(object({<br/>    identifier    = optional(string)<br/>    location      = optional(string)<br/>    mount_options = optional(string)<br/>    mount_point   = optional(string)<br/>    type          = optional(string, "EFS")<br/>  }))</pre> | `[]` | no |
| github\_organization\_name | The GitHub organization name | `string` | n/a | yes |
| iam\_role\_name | Name of the codebuild IAM role | `string` | `null` | no |
| privileged\_mode | Whether to run the CodeBuild build container in privileged mode (required for Docker-in-Docker builds). Set to false when builds do not need to build container images. | `bool` | `true` | no |
| project\_visibility | Specifies the visibility of the project's builds. Possible values are: PUBLIC\_READ, PRIVATE. | `string` | `"PRIVATE"` | no |
| registry\_credential | Information about credentials for a private Docker registry to access during the build. Contains credential (ARN or name of AWS Secrets Manager credential) and credential\_provider (must be SECRETS\_MANAGER). | <pre>object({<br/>    credential          = string<br/>    credential_provider = string<br/>  })</pre> | `null` | no |
| repository\_name | Name of the Github repository | `string` | n/a | yes |
| resource\_access\_role | The ARN of the IAM role that enables CodeBuild to access the CloudWatch Logs and Amazon S3 artifacts for the project's builds. | `string` | `null` | no |
| s3\_logs\_bucket\_owner\_access | Cross-account bucket owner access for S3 logs. Valid values: NONE, READ\_ONLY, FULL. | `string` | `"NONE"` | no |
| s3\_logs\_encryption\_disabled | Whether to disable encrypting S3 build logs. Defaults to false. | `bool` | `false` | no |
| s3\_logs\_location | S3 bucket path where CodeBuild logs will be stored. Required when s3\_logs\_status is ENABLED. | `string` | `null` | no |
| s3\_logs\_status | Status for S3 logging in CodeBuild. Valid values: ENABLED, DISABLED. | `string` | `"DISABLED"` | no |
| secondary\_artifacts | List of secondary artifact configurations for the CodeBuild projects. | <pre>list(object({<br/>    type                   = string<br/>    artifact_identifier    = string<br/>    location               = optional(string)<br/>    name                   = optional(string)<br/>    namespace_type         = optional(string)<br/>    override_artifact_name = optional(bool)<br/>    packaging              = optional(string)<br/>    path                   = optional(string)<br/>    encryption_disabled    = optional(bool)<br/>    bucket_owner_access    = optional(string)<br/>  }))</pre> | `[]` | no |
| secondary\_source\_versions | List of secondary source version overrides. Each entry requires source\_identifier (matching a secondary\_sources identifier) and source\_version. | <pre>list(object({<br/>    source_identifier = string<br/>    source_version    = string<br/>  }))</pre> | `[]` | no |
| secondary\_sources | List of secondary source configurations for the CodeBuild projects. | <pre>list(object({<br/>    type                = string<br/>    location            = optional(string)<br/>    source_identifier   = string<br/>    git_clone_depth     = optional(number)<br/>    buildspec           = optional(string)<br/>    insecure_ssl        = optional(bool)<br/>    report_build_status = optional(bool)<br/>    git_submodules_config = optional(object({<br/>      fetch_submodules = bool<br/>    }))<br/>    auth = optional(object({<br/>      type     = string<br/>      resource = optional(string)<br/>    }))<br/>    build_status_config = optional(object({<br/>      context    = optional(string)<br/>      target_url = optional(string)<br/>    }))<br/>  }))</pre> | `[]` | no |
| security\_group\_ids | List of existing security group IDs to attach to the CodeBuild projects when create\_security\_group is false. When empty, the module falls back to looking up a security group tagged Name=codebuild-runners-<env\_name>-security-group in the VPC (legacy behaviour). | `list(string)` | `[]` | no |
| source\_auth | Authorization configuration for the source. Requires type (CODECONNECTIONS, OAUTH) and optional resource (OAuth token ARN or CodeConnections ARN). | <pre>object({<br/>    type     = string<br/>    resource = optional(string)<br/>  })</pre> | `null` | no |
| source\_build\_status\_config | Configuration for the build status notification for the source. Supports context and target\_url. | <pre>object({<br/>    context    = optional(string)<br/>    target_url = optional(string)<br/>  })</pre> | `null` | no |
| source\_insecure\_ssl | Ignore SSL warnings when connecting to source control. | `bool` | `null` | no |
| source\_report\_build\_status | Whether to report the status of a build's start and finish to your source provider. Supported for GitHub, GitHub Enterprise, and Bitbucket. | `bool` | `null` | no |
| source\_version | Version of the build input to be built for this project. If not specified, the latest version is used. | `string` | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| vpc\_id | ID of the VPC the CodeBuild runners run in. | `string` | n/a | yes |
| webhook\_pull\_request\_build\_policy | Approval requirements for pull request builds. Applies to both build and deployment runner webhooks. | <pre>object({<br/>    requires_comment_approval = string<br/>    approver_roles            = optional(list(string))<br/>  })</pre> | `null` | no |
| webhook\_scope\_configuration | Configuration for a GitHub organization or global webhook. Applies to both build and deployment runner webhooks. | <pre>object({<br/>    name   = string<br/>    scope  = string<br/>    domain = optional(string)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| cloudwatch\_log\_group\_arn | ARN of the CloudWatch log group for CodeBuild logs |
| cloudwatch\_log\_group\_name | Name of the CloudWatch log group for CodeBuild logs |
| iam\_role\_arn | ARN of the CodeBuild IAM role (if created by this module) |
| iam\_role\_name | Name of the CodeBuild IAM role (if created by this module) |
| project\_arns | Map of runner key to CodeBuild project ARN |
| project\_names | Map of runner key to CodeBuild project name |
| security\_group\_id | ID of the CodeBuild security group (if created by this module) |
| webhook\_urls | Map of runner key to the URL of the webhook that triggers its builds |
<!-- END_TF_DOCS -->

</details>
