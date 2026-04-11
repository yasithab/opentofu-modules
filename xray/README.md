# AWS X-Ray

Provisions AWS X-Ray sampling rules, encryption configuration, trace groups with filter expressions, and resource policies for distributed tracing observability.

## Features

- **Sampling Rules** - Create custom sampling rules with configurable rates, reservoir sizes, and service/path/host filters for fine-grained trace collection control
- **KMS Encryption** - Configure encryption for X-Ray traces at rest using a customer-managed KMS key
- **Groups** - Define trace groups with filter expressions and optional X-Ray Insights for anomaly detection and notifications
- **Resource Policies** - Manage X-Ray resource policies for cross-account trace access and service integrations

## Usage

```hcl
module "xray" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//xray?depth=1&ref=master"

  name = "platform-xray"

  sampling_rules = {
    default_low_rate = {
      priority       = 1000
      reservoir_size = 1
      fixed_rate     = 0.05
      service_name   = "*"
    }
  }

  tags = {
    Environment = "production"
  }
}
```

## Examples

### Basic Sampling Rules

Creates custom sampling rules to control trace volume for different services and endpoints.

```hcl
module "xray_basic" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//xray?depth=1&ref=master"

  enabled = true

  name = "microservices-xray"

  sampling_rules = {
    health_checks = {
      priority       = 1
      reservoir_size = 0
      fixed_rate     = 0
      url_path       = "/health*"
      service_name   = "*"
      http_method    = "GET"
    }
    api_high_priority = {
      priority       = 100
      reservoir_size = 10
      fixed_rate     = 0.10
      service_name   = "api-gateway"
      url_path       = "/api/v1/*"
    }
    default_rule = {
      priority       = 10000
      reservoir_size = 1
      fixed_rate     = 0.05
      service_name   = "*"
    }
  }

  tags = {
    Environment = "production"
    Team        = "observability"
  }
}
```

### With KMS Encryption and Groups

Enables KMS encryption for all traces and creates groups for filtering traces by error conditions and specific services.

```hcl
module "xray_encrypted" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//xray?depth=1&ref=master"

  enabled = true

  name       = "platform-xray"
  kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/mrk-1234abcd-12ab-34cd-56ef-1234567890ab"

  sampling_rules = {
    production_services = {
      priority       = 100
      reservoir_size = 5
      fixed_rate     = 0.10
      service_name   = "*"
    }
  }

  groups = {
    errors = {
      filter_expression = "responsetime > 5 OR error = true"
      insights_configuration = {
        insights_enabled      = true
        notifications_enabled = true
      }
    }
    payment_service = {
      filter_expression = "service(\"payment-service\")"
      insights_configuration = {
        insights_enabled      = true
        notifications_enabled = true
      }
    }
    slow_requests = {
      filter_expression = "responsetime > 3"
    }
  }

  tags = {
    Environment = "production"
    Team        = "observability"
  }
}
```

### With Resource Policies for Cross-Account Access

Configures X-Ray resource policies to allow other AWS accounts or services to send traces to the current account.

```hcl
module "xray_cross_account" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//xray?depth=1&ref=master"

  enabled = true

  name       = "central-xray"
  kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/mrk-1234abcd-12ab-34cd-56ef-1234567890ab"

  sampling_rules = {
    default = {
      priority       = 1000
      reservoir_size = 1
      fixed_rate     = 0.05
      service_name   = "*"
    }
  }

  groups = {
    all_errors = {
      filter_expression = "error = true OR fault = true"
      insights_configuration = {
        insights_enabled      = true
        notifications_enabled = true
      }
    }
  }

  resource_policies = {
    cross_account_access = {
      policy_document = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid       = "AllowWorkloadAccounts"
            Effect    = "Allow"
            Principal = {
              AWS = [
                "arn:aws:iam::111111111111:root",
                "arn:aws:iam::222222222222:root"
              ]
            }
            Action = [
              "xray:PutTraceSegments",
              "xray:PutTelemetryRecords"
            ]
            Resource = "*"
          }
        ]
      })
    }
  }

  tags = {
    Environment = "production"
    Team        = "observability"
    Purpose     = "centralized-tracing"
  }
}
```
