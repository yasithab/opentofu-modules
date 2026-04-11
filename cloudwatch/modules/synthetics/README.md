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
