# AWS AppConfig

OpenTofu module for creating and managing AWS AppConfig applications, environments, configuration profiles, deployment strategies, and extensions.

## Features

- **Application Management** - Create and configure AppConfig applications
- **Multiple Environments** - Support for multiple environments with CloudWatch alarm monitoring for automatic rollback
- **Configuration Profiles** - Freeform and Feature Flag configuration profile types with optional validators
- **Hosted Configuration Versions** - Manage configuration content directly in AppConfig
- **Deployment Strategies** - Custom deployment strategies with configurable duration, growth factor, and bake time
- **Managed Deployments** - Trigger deployments linking environments, profiles, versions, and strategies
- **Extensions** - Create custom extensions with action points and associate them with environments or profiles
- **Security by Default** - Tagging enforced on all resources

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
