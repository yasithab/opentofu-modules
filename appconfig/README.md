# AWS AppConfig

OpenTofu module for creating and managing AWS AppConfig applications, environments, configuration profiles, deployment strategies, and extensions.

## Features

- **Application Management** - Create and configure AppConfig applications
- **Multiple Environments** - Support for multiple environments with CloudWatch alarm monitoring for automatic rollback
- **Configuration Profiles** - Freeform and Feature Flag configuration profile types with optional validators
- **Hosted Configuration Versions** - Manage configuration content directly in AppConfig
- **Deployment Strategies** - Custom deployment strategies with configurable duration, growth factor, and bake time
- **Managed Deployments** - Trigger deployments linking environments, profiles, versions, and strategies, with optional KMS encryption at rest via `kms_key_identifier`
- **Extensions** - Create custom extensions with action points and associate them with environments or profiles
- **Typed Inputs** - All collection variables are fully typed objects with optional attributes, so misconfigurations fail at plan time instead of being silently swallowed
- **Security by Default** - Tagging enforced on all resources; `hosted_configuration_versions` is marked sensitive

> [!NOTE]
> Do **not** put secrets in `hosted_configuration_versions[*].content` — the content is persisted in OpenTofu state and AppConfig. Store secrets in SSM SecureString or Secrets Manager and reference them from your configuration instead. The variable is marked `sensitive` as a defence-in-depth measure only.

## Usage

```hcl
module "appconfig" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//appconfig?depth=1&ref=master"

  name = "my-app"

  environments = {
    production = {
      description = "Production environment"
    }
  }

  configuration_profiles = {
    settings = {
      type = "AWS.Freeform"
    }
  }

  tags = {
    Environment = "production"
  }
}
```

## Examples

### Basic Feature Flag

A simple feature flag configuration profile with a hosted configuration version.

```hcl
module "appconfig" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//appconfig?depth=1&ref=master"

  name                    = "my-app"
  application_description = "My application feature flags"

  environments = {
    production = {
      description = "Production environment"
    }
  }

  configuration_profiles = {
    feature_flags = {
      description = "Feature flags for my-app"
      type        = "AWS.AppConfig.FeatureFlags"
    }
  }

  hosted_configuration_versions = {
    feature_flags = {
      content_type = "application/json"
      content = jsonencode({
        version = "1"
        flags = {
          dark_mode = {
            name = "Dark Mode"
            attributes = {
              enabled = { constraints = { type = "boolean" } }
            }
          }
          new_checkout = {
            name = "New Checkout Flow"
            attributes = {
              enabled = { constraints = { type = "boolean" } }
            }
          }
        }
        values = {
          dark_mode    = { enabled = true }
          new_checkout = { enabled = false }
        }
      })
    }
  }

  deployment_strategies = {
    quick = {
      deployment_duration_in_minutes = 0
      growth_factor                  = 100
      growth_type                    = "LINEAR"
      replicate_to                   = "NONE"
      final_bake_time_in_minutes     = 0
    }
  }

  deployments = {
    feature_flags = {
      environment_key            = "production"
      configuration_profile_key  = "feature_flags"
      configuration_version_key  = "feature_flags"
      deployment_strategy_key    = "quick"
    }
  }

  tags = {
    Environment = "production"
    Service     = "my-app"
  }
}
```

### Freeform JSON Config with Deployment

A freeform JSON configuration with a gradual deployment strategy.

```hcl
module "appconfig" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//appconfig?depth=1&ref=master"

  name = "api-service"

  environments = {
    staging = {
      description = "Staging environment"
    }
  }

  configuration_profiles = {
    app_config = {
      description  = "Application configuration"
      type         = "AWS.Freeform"
      location_uri = "hosted"
      validators = [
        {
          type    = "JSON_SCHEMA"
          content = jsonencode({
            "$schema" = "http://json-schema.org/draft-07/schema#"
            type      = "object"
            required  = ["log_level", "max_connections"]
            properties = {
              log_level       = { type = "string", enum = ["DEBUG", "INFO", "WARN", "ERROR"] }
              max_connections = { type = "integer", minimum = 1 }
              cache_ttl       = { type = "integer", minimum = 0 }
            }
          })
        }
      ]
    }
  }

  hosted_configuration_versions = {
    app_config = {
      content_type = "application/json"
      content = jsonencode({
        log_level       = "INFO"
        max_connections = 100
        cache_ttl       = 300
      })
      description = "Initial configuration v1"
    }
  }

  deployment_strategies = {
    gradual = {
      description                    = "Gradual rollout over 10 minutes"
      deployment_duration_in_minutes = 10
      growth_factor                  = 20
      growth_type                    = "LINEAR"
      replicate_to                   = "NONE"
      final_bake_time_in_minutes     = 5
    }
  }

  deployments = {
    app_config = {
      environment_key           = "staging"
      configuration_profile_key = "app_config"
      configuration_version_key = "app_config"
      deployment_strategy_key   = "gradual"
      description               = "Deploy v1 configuration"
    }
  }

  tags = {
    Environment = "staging"
    Service     = "api-service"
  }
}
```

### Multiple Environments with Alarm Monitoring

Multiple environments with CloudWatch alarm monitors for automatic rollback on errors.

```hcl
module "appconfig" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//appconfig?depth=1&ref=master"

  name                    = "payment-service"
  application_description = "Payment service configuration"

  environments = {
    development = {
      description = "Development environment"
    }
    staging = {
      description = "Staging environment"
      monitors = [
        {
          alarm_arn      = "arn:aws:cloudwatch:us-east-1:123456789012:alarm:staging-error-rate"
          alarm_role_arn = "arn:aws:iam::123456789012:role/appconfig-alarm-role"
        }
      ]
    }
    production = {
      description = "Production environment"
      monitors = [
        {
          alarm_arn      = "arn:aws:cloudwatch:us-east-1:123456789012:alarm:prod-error-rate"
          alarm_role_arn = "arn:aws:iam::123456789012:role/appconfig-alarm-role"
        },
        {
          alarm_arn      = "arn:aws:cloudwatch:us-east-1:123456789012:alarm:prod-latency-p99"
          alarm_role_arn = "arn:aws:iam::123456789012:role/appconfig-alarm-role"
        }
      ]
    }
  }

  configuration_profiles = {
    settings = {
      description = "Service settings"
      type        = "AWS.Freeform"
    }
    feature_flags = {
      description = "Feature flags"
      type        = "AWS.AppConfig.FeatureFlags"
    }
  }

  hosted_configuration_versions = {
    settings = {
      content_type = "application/json"
      content = jsonencode({
        payment_timeout_seconds = 30
        retry_attempts          = 3
        enable_fraud_detection  = true
      })
    }
    feature_flags = {
      content_type = "application/json"
      content = jsonencode({
        version = "1"
        flags = {
          apple_pay = {
            name       = "Apple Pay"
            attributes = { enabled = { constraints = { type = "boolean" } } }
          }
        }
        values = {
          apple_pay = { enabled = false }
        }
      })
    }
  }

  deployment_strategies = {
    canary_prod = {
      description                    = "Canary deployment for production"
      deployment_duration_in_minutes = 20
      growth_factor                  = 10
      growth_type                    = "LINEAR"
      replicate_to                   = "NONE"
      final_bake_time_in_minutes     = 10
    }
  }

  tags = {
    Environment = "multi"
    Service     = "payment-service"
  }
}
```

### Custom Deployment Strategy

Different deployment strategies for various risk profiles.

```hcl
module "appconfig" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//appconfig?depth=1&ref=master"

  name = "config-strategies"

  environments = {
    production = {
      description = "Production environment"
    }
  }

  configuration_profiles = {
    settings = {
      type = "AWS.Freeform"
    }
  }

  hosted_configuration_versions = {
    settings = {
      content_type = "application/json"
      content = jsonencode({
        feature_x = true
      })
    }
  }

  deployment_strategies = {
    instant = {
      description                    = "Instant deployment (all at once)"
      deployment_duration_in_minutes = 0
      growth_factor                  = 100
      growth_type                    = "LINEAR"
      replicate_to                   = "NONE"
      final_bake_time_in_minutes     = 0
    }
    canary = {
      description                    = "Canary: 10% every 2 minutes with 5 minute bake"
      deployment_duration_in_minutes = 20
      growth_factor                  = 10
      growth_type                    = "LINEAR"
      replicate_to                   = "NONE"
      final_bake_time_in_minutes     = 5
    }
    exponential = {
      description                    = "Exponential growth deployment"
      deployment_duration_in_minutes = 15
      growth_factor                  = 2
      growth_type                    = "EXPONENTIAL"
      replicate_to                   = "NONE"
      final_bake_time_in_minutes     = 10
    }
    blue_green = {
      description                    = "Blue/green style: instant switch with long bake"
      deployment_duration_in_minutes = 0
      growth_factor                  = 100
      growth_type                    = "LINEAR"
      replicate_to                   = "NONE"
      final_bake_time_in_minutes     = 30
    }
  }

  deployments = {
    settings = {
      environment_key           = "production"
      configuration_profile_key = "settings"
      configuration_version_key = "settings"
      deployment_strategy_key   = "canary"
    }
  }

  tags = {
    Environment = "production"
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
| application\_description | Description of the AppConfig application | `string` | `null` | no |
| configuration\_profiles | Map of configuration profiles to create. Each entry supports `name` (defaults to the map key), `description`, `type` (`AWS.Freeform` or `AWS.AppConfig.FeatureFlags`), `location_uri`, and `validators` (list of objects with `type` and optional `content`). | <pre>map(object({<br/>    name         = optional(string)<br/>    description  = optional(string)<br/>    type         = optional(string, "AWS.Freeform")<br/>    location_uri = optional(string, "hosted")<br/>    validators = optional(list(object({<br/>      type    = string<br/>      content = optional(string)<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| deployment\_strategies | Map of deployment strategies to create. Each entry supports `name` (defaults to the map key), `description`, `deployment_duration_in_minutes`, `growth_factor`, `growth_type`, `replicate_to`, and `final_bake_time_in_minutes`. | <pre>map(object({<br/>    name                           = optional(string)<br/>    description                    = optional(string)<br/>    deployment_duration_in_minutes = number<br/>    growth_factor                  = number<br/>    growth_type                    = optional(string, "LINEAR")<br/>    replicate_to                   = optional(string, "NONE")<br/>    final_bake_time_in_minutes     = optional(number, 0)<br/>  }))</pre> | `{}` | no |
| deployments | Map of deployments to trigger. Each entry requires `environment_key` (key from `environments`), `configuration_profile_key` (key from `configuration_profiles`), `configuration_version_key` (key from `hosted_configuration_versions`), and `deployment_strategy_key` (key from `deployment_strategies`) or `deployment_strategy_id` for a predefined strategy. Optional `kms_key_identifier` (KMS key ID, alias, or ARN) encrypts the configuration data at rest. | <pre>map(object({<br/>    environment_key           = string<br/>    configuration_profile_key = string<br/>    configuration_version_key = string<br/>    deployment_strategy_key   = optional(string)<br/>    deployment_strategy_id    = optional(string)<br/>    description               = optional(string)<br/>    kms_key_identifier        = optional(string)<br/>  }))</pre> | `{}` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| environments | Map of AppConfig environments to create. Each entry supports `name` (defaults to the map key), `description`, and `monitors` (list of objects with `alarm_arn` and optional `alarm_role_arn`). | <pre>map(object({<br/>    name        = optional(string)<br/>    description = optional(string)<br/>    monitors = optional(list(object({<br/>      alarm_arn      = string<br/>      alarm_role_arn = optional(string)<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| extension\_associations | Map of extension associations. Each entry requires `extension_key` (key from `extensions`) and either `resource_type` (`environment` or `configuration_profile`) with `resource_key`, or a literal `resource_arn`. | <pre>map(object({<br/>    extension_key = string<br/>    resource_type = optional(string)<br/>    resource_key  = optional(string)<br/>    resource_arn  = optional(string)<br/>  }))</pre> | `{}` | no |
| extensions | Map of AppConfig extensions. Each entry supports `name` (defaults to the map key), `description`, `action_points` (map keyed by action point name, each a list of actions with `name`, `uri`, and optional `role_arn`), and `parameters` (map keyed by parameter name with optional `required` and `description`). | <pre>map(object({<br/>    name        = optional(string)<br/>    description = optional(string)<br/>    action_points = optional(map(list(object({<br/>      name     = string<br/>      uri      = string<br/>      role_arn = optional(string)<br/>    }))), {})<br/>    parameters = optional(map(object({<br/>      required    = optional(bool, false)<br/>      description = optional(string)<br/>    })), {})<br/>  }))</pre> | `{}` | no |
| hosted\_configuration\_versions | Map of hosted configuration versions. Key must match a key in `configuration_profiles`. Each entry supports `content`, `content_type`, and `description`. Do NOT put secrets in `content` — hosted configuration content is stored in OpenTofu state and in AppConfig; use SSM SecureString / Secrets Manager references instead. | <pre>map(object({<br/>    content      = string<br/>    content_type = optional(string, "application/json")<br/>    description  = optional(string)<br/>  }))</pre> | `{}` | no |
| name | Name of the AppConfig application | `string` | n/a | yes |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| application\_arn | The ARN of the AppConfig application |
| application\_id | The AppConfig application ID |
| application\_name | The name of the AppConfig application |
| configuration\_profile\_arns | Map of configuration profile keys to their ARNs |
| configuration\_profile\_ids | Map of configuration profile keys to their profile IDs |
| deployment\_numbers | Map of deployment keys to their deployment numbers |
| deployment\_states | Map of deployment keys to their states |
| deployment\_strategy\_arns | Map of deployment strategy keys to their ARNs |
| deployment\_strategy\_ids | Map of deployment strategy keys to their IDs |
| environment\_arns | Map of environment keys to their ARNs |
| environment\_ids | Map of environment keys to their IDs |
| environment\_states | Map of environment keys to their states |
| extension\_arns | Map of extension keys to their ARNs |
| extension\_association\_arns | Map of extension association keys to their ARNs |
| extension\_association\_ids | Map of extension association keys to their IDs |
| extension\_ids | Map of extension keys to their IDs |
| extension\_versions | Map of extension keys to their version numbers |
| hosted\_configuration\_version\_arns | Map of hosted configuration version keys to their ARNs |
| hosted\_configuration\_version\_numbers | Map of hosted configuration version keys to their version numbers |
<!-- END_TF_DOCS -->

</details>
