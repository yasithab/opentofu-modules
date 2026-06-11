# CloudWatch Synthetics

Provisions CloudWatch Synthetics canaries with S3 artifact storage, IAM execution roles, alarm integration, VPC support, and canary group organization.

## Features

- **Canary Management** - Create multiple canaries with configurable runtime versions, handlers, schedules, and retention policies
- **S3 Artifact Bucket** - Automatically create a hardened S3 bucket with encryption, versioning, public access blocking, and lifecycle expiration for canary artifacts
- **IAM Role** - Least-privilege execution role with scoped permissions for S3, CloudWatch Logs, CloudWatch Metrics, and X-Ray tracing
- **VPC Support** - Run canaries inside a VPC for monitoring internal endpoints, with automatic ENI management permissions
- **Alarm Integration** - Automatic CloudWatch alarm creation per canary with configurable thresholds and notification actions
- **Visual Monitoring** - Support for screenshot comparison and active X-Ray tracing through run configuration
- **Canary Groups** - Organize canaries into logical groups for easier management and reporting
- **Artifact Encryption** - KMS encryption support for both the shared artifact bucket and per-canary artifact configuration

> **Behavior changes:**
> - When `artifact_s3_bucket_name` is not set, the default artifact bucket name is now `synthetics-artifacts-{name}-{account_id}-{region}` (account ID and region suffix added for global S3 name uniqueness).
> - `artifact_s3_bucket_name` is required when `create_artifact_bucket = false`, and each canary must set `execution_role_arn` when `create_iam_role = false` (validated at plan time).
> - Group association state keys changed from `{group}-{canary}` to `{group}/{canary}`; existing associations will be re-created in place on the next apply (no canary downtime, associations are recreated).

## Usage

```hcl
module "synthetics" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/synthetics?depth=1&ref=master"

  name = "api-monitoring"

  canaries = {
    api_health = {
      name                = "api-health-check"
      handler             = "apiCanaryBlueprint.handler"
      runtime_version     = "syn-nodejs-puppeteer-9.1"
      schedule_expression = "rate(5 minutes)"
      zip_file            = "canary-scripts/api-health.zip"
    }
  }

  tags = {
    Environment = "production"
  }
}
```

## Examples

### Basic Heartbeat Canary

Creates a single heartbeat canary that checks an endpoint every 5 minutes with a CloudWatch alarm.

```hcl
module "synthetics_basic" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/synthetics?depth=1&ref=master"

  enabled = true

  name = "website-monitoring"

  canaries = {
    homepage = {
      name                = "homepage-heartbeat"
      handler             = "heartbeatCanary.handler"
      runtime_version     = "syn-nodejs-puppeteer-9.1"
      schedule_expression = "rate(5 minutes)"
      zip_file            = "canary-scripts/homepage.zip"

      run_config = {
        timeout_in_seconds = 60
        active_tracing     = true
      }
    }
  }

  default_alarm_actions = ["arn:aws:sns:us-east-1:123456789012:synthetics-alerts"]

  tags = {
    Environment = "production"
    Team        = "sre"
  }
}
```

### VPC Canaries for Internal Endpoints

Deploys canaries inside a VPC to monitor internal APIs not reachable from the public internet.

```hcl
module "synthetics_vpc" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/synthetics?depth=1&ref=master"

  enabled = true

  name             = "internal-monitoring"
  enable_vpc_policy = true

  canaries = {
    internal_api = {
      name                = "internal-api-check"
      handler             = "apiCanaryBlueprint.handler"
      runtime_version     = "syn-nodejs-puppeteer-9.1"
      schedule_expression = "rate(5 minutes)"
      zip_file            = "canary-scripts/internal-api.zip"

      vpc_config = {
        security_group_ids = ["sg-0a1b2c3d4e5f67890"]
        subnet_ids         = ["subnet-0abc123def456gh01", "subnet-0abc123def456gh02"]
      }

      run_config = {
        timeout_in_seconds = 120
        environment_variables = {
          TARGET_URL = "https://internal-api.example.local/health"
        }
      }
    }
    internal_db = {
      name                = "internal-db-check"
      handler             = "apiCanaryBlueprint.handler"
      runtime_version     = "syn-nodejs-puppeteer-9.1"
      schedule_expression = "rate(10 minutes)"
      zip_file            = "canary-scripts/db-check.zip"

      vpc_config = {
        security_group_ids = ["sg-0a1b2c3d4e5f67890"]
        subnet_ids         = ["subnet-0abc123def456gh01", "subnet-0abc123def456gh02"]
      }
    }
  }

  canary_groups = {
    internal = {
      canary_keys = ["internal_api", "internal_db"]
    }
  }

  artifact_s3_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mrk-1234abcd-12ab-34cd-56ef-1234567890ab"

  default_alarm_actions = ["arn:aws:sns:us-east-1:123456789012:internal-alerts"]
  default_ok_actions    = ["arn:aws:sns:us-east-1:123456789012:internal-alerts"]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

### Multiple Canaries with Existing Bucket

Uses an existing S3 bucket for artifacts and creates multiple canaries across different runtimes.

```hcl
module "synthetics_multi" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudwatch/modules/synthetics?depth=1&ref=master"

  enabled = true

  name                   = "multi-service-monitoring"
  create_artifact_bucket = false
  artifact_s3_bucket_name = "existing-synthetics-artifacts-bucket"

  canaries = {
    api_v1 = {
      name                = "api-v1-health"
      handler             = "apiCanaryBlueprint.handler"
      runtime_version     = "syn-nodejs-puppeteer-9.1"
      schedule_expression = "rate(5 minutes)"
      zip_file            = "canary-scripts/api-v1.zip"
    }
    api_v2 = {
      name                = "api-v2-health"
      handler             = "apiCanaryBlueprint.handler"
      runtime_version     = "syn-nodejs-puppeteer-9.1"
      schedule_expression = "rate(5 minutes)"
      zip_file            = "canary-scripts/api-v2.zip"
    }
    visual_check = {
      name                = "dashboard-visual"
      handler             = "visualMonitoring.handler"
      runtime_version     = "syn-nodejs-puppeteer-9.1"
      schedule_expression = "rate(15 minutes)"
      zip_file            = "canary-scripts/visual.zip"

      success_retention_period = 7
      failure_retention_period = 14
    }
  }

  canary_groups = {
    api_canaries = {
      canary_keys = ["api_v1", "api_v2"]
    }
    visual_canaries = {
      canary_keys = ["visual_check"]
    }
  }

  default_alarm_actions = ["arn:aws:sns:us-east-1:123456789012:synthetics-alerts"]

  tags = {
    Environment = "production"
    Team        = "sre"
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
| artifact\_s3\_bucket\_force\_destroy | Allow destruction of the S3 bucket even if it contains objects. | `bool` | `false` | no |
| artifact\_s3\_bucket\_name | Name of the S3 bucket for canary artifacts. Used as bucket name when creating, or as existing bucket reference. Required when create\_artifact\_bucket is false. | `string` | `null` | no |
| artifact\_s3\_bucket\_use\_name\_prefix | Determines whether to use the S3 bucket name as a prefix. | `bool` | `false` | no |
| artifact\_s3\_expiration\_days | Number of days after which canary artifacts in S3 are automatically deleted. Set to 0 to disable. | `number` | `90` | no |
| artifact\_s3\_kms\_key\_arn | ARN of a KMS key to use for encrypting canary artifacts in S3. Defaults to AES256 if not set. | `string` | `null` | no |
| canaries | Map of canary configurations. Each key is a unique identifier for the canary. | <pre>map(object({<br/>    name                         = string<br/>    handler                      = string<br/>    runtime_version              = string<br/>    schedule_expression          = string<br/>    schedule_duration_in_seconds = optional(number)<br/>    zip_file                     = optional(string)<br/>    s3_bucket                    = optional(string)<br/>    s3_key                       = optional(string)<br/>    s3_version                   = optional(string)<br/>    start_canary                 = optional(bool, true)<br/>    delete_lambda                = optional(bool, true)<br/>    execution_role_arn           = optional(string)<br/>    artifact_s3_location         = optional(string)<br/>    success_retention_period     = optional(number)<br/>    failure_retention_period     = optional(number)<br/>    run_config = optional(object({<br/>      timeout_in_seconds    = optional(number, 60)<br/>      memory_in_mb          = optional(number)<br/>      active_tracing        = optional(bool, false)<br/>      environment_variables = optional(map(string))<br/>    }))<br/>    vpc_config = optional(object({<br/>      security_group_ids = list(string)<br/>      subnet_ids         = list(string)<br/>    }))<br/>    artifact_config = optional(object({<br/>      encryption_mode = optional(string, "SSE_S3")<br/>      kms_key_arn     = optional(string)<br/>    }))<br/>    create_alarm              = optional(bool)<br/>    alarm_name                = optional(string)<br/>    alarm_description         = optional(string)<br/>    alarm_comparison_operator = optional(string)<br/>    alarm_evaluation_periods  = optional(number)<br/>    alarm_period              = optional(number)<br/>    alarm_threshold           = optional(number)<br/>    alarm_treat_missing_data  = optional(string)<br/>    alarm_actions             = optional(list(string))<br/>    ok_actions                = optional(list(string))<br/>    insufficient_data_actions = optional(list(string))<br/>  }))</pre> | `{}` | no |
| canary\_groups | Map of canary group configurations. Each key is the group name, with canary\_keys listing which canaries belong to it. | <pre>map(object({<br/>    canary_keys = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| create\_artifact\_bucket | Determines whether an S3 bucket is created for canary artifacts. | `bool` | `true` | no |
| create\_canary\_alarms | Default value for whether to create CloudWatch alarms for canaries. Can be overridden per canary. | `bool` | `true` | no |
| create\_iam\_role | Determines whether an IAM execution role is created for the canaries. | `bool` | `true` | no |
| default\_alarm\_actions | Default list of ARNs to notify when a canary alarm transitions to ALARM state. | `list(string)` | `[]` | no |
| default\_failure\_retention\_period | Default number of days to retain failed canary run data. | `number` | `31` | no |
| default\_ok\_actions | Default list of ARNs to notify when a canary alarm transitions to OK state. | `list(string)` | `[]` | no |
| default\_success\_retention\_period | Default number of days to retain successful canary run data. | `number` | `31` | no |
| enable\_vpc\_policy | Determines whether VPC networking permissions are added to the IAM role. Enable when any canary uses vpc\_config. | `bool` | `false` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| iam\_role\_name | Name of the IAM role. Defaults to synthetics-{name}. | `string` | `null` | no |
| iam\_role\_path | Path for the IAM role. | `string` | `"/"` | no |
| iam\_role\_policy\_arns | Map of additional IAM policy ARNs to attach to the canary execution role. | `map(string)` | `{}` | no |
| iam\_role\_use\_name\_prefix | Determines whether to use the IAM role name as a prefix. | `bool` | `false` | no |
| name | Name prefix used for naming resources (IAM role, S3 bucket, etc.). | `string` | n/a | yes |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| alarm\_arns | Map of canary keys to their CloudWatch alarm ARNs. |
| artifact\_bucket\_arn | ARN of the S3 bucket used for canary artifacts. |
| artifact\_bucket\_id | ID (name) of the S3 bucket used for canary artifacts. |
| canary\_arns | Map of canary keys to their ARNs. |
| canary\_engine\_arns | Map of canary keys to the ARN of the Lambda function that runs the canary. |
| canary\_group\_arns | Map of canary group names to their ARNs. |
| canary\_group\_ids | Map of canary group names to their IDs. |
| canary\_ids | Map of canary keys to their IDs. |
| canary\_names | Map of canary keys to their names. |
| canary\_source\_location\_arns | Map of canary keys to the ARN of the Lambda layer containing the canary script source. |
| iam\_role\_arn | ARN of the IAM execution role used by the canaries. |
| iam\_role\_name | Name of the IAM execution role used by the canaries. |
<!-- END_TF_DOCS -->

</details>
