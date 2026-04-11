# Amazon Managed Grafana

Provisions an Amazon Managed Grafana workspace with configurable authentication, data sources, notification destinations, IAM roles, VPC configuration, and API key management.

## Features

- **Workspace Management** - Create a fully configured Grafana workspace with version pinning, data source integration, and notification destinations
- **Authentication** - Support for AWS SSO and SAML identity providers with configurable role mappings
- **Data Sources** - Automatic IAM policy provisioning for CloudWatch, Prometheus, X-Ray, Timestream, and other AWS data sources
- **VPC Configuration** - Private workspace access through VPC endpoints and network access controls
- **IAM Role** - Least-privilege IAM role with per-data-source policies, automatically scoped to selected data sources
- **API Key Management** - Create and manage workspace API keys with configurable roles and TTL
- **License Management** - Support for Enterprise and free-tier license types
- **SNS Notifications** - Scoped SNS publish permissions for alert notification channels

## Usage

```hcl
module "managed_grafana" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//managed-grafana?depth=1&ref=master"

  name         = "platform-grafana"
  data_sources = ["CLOUDWATCH", "PROMETHEUS", "XRAY"]

  tags = {
    Environment = "production"
  }
}
```

## Examples

### Basic Usage with AWS SSO

Creates a Grafana workspace with AWS SSO authentication, CloudWatch and Prometheus data sources, and a managed IAM role.

```hcl
module "grafana" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//managed-grafana?depth=1&ref=master"

  enabled = true

  name                     = "observability-grafana"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  data_sources             = ["CLOUDWATCH", "PROMETHEUS"]
  notification_destinations = ["SNS"]

  sns_topic_arns = [
    "arn:aws:sns:us-east-1:123456789012:grafana-alerts"
  ]

  tags = {
    Environment = "production"
    Team        = "observability"
  }
}
```

### With SAML Authentication and VPC Configuration

Deploys a private Grafana workspace accessible only through a VPC, with SAML-based authentication from an external identity provider.

```hcl
module "grafana_private" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//managed-grafana?depth=1&ref=master"

  enabled = true

  name                     = "private-grafana"
  authentication_providers = ["SAML"]
  permission_type          = "CUSTOMER_MANAGED"
  data_sources             = ["CLOUDWATCH", "PROMETHEUS", "XRAY"]
  license_type             = "ENTERPRISE"

  enable_saml_configuration = true
  saml_idp_metadata_url     = "https://idp.example.com/metadata"
  saml_editor_role_values   = ["grafana-editors"]
  saml_admin_role_values    = ["grafana-admins"]

  vpc_configuration = {
    security_group_ids = ["sg-0a1b2c3d4e5f67890"]
    subnet_ids         = ["subnet-0abc123def456gh01", "subnet-0abc123def456gh02"]
  }

  network_access_control = {
    prefix_list_ids = ["pl-0abc123def456gh01"]
    vpce_ids        = ["vpce-0abc123def456gh01"]
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

### Enterprise with API Keys and Custom Plugins

Creates an Enterprise-licensed workspace with API keys for automation and custom workspace configuration including plugins.

```hcl
module "grafana_enterprise" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//managed-grafana?depth=1&ref=master"

  enabled = true

  name                     = "enterprise-grafana"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  data_sources             = ["CLOUDWATCH", "PROMETHEUS", "XRAY", "TIMESTREAM"]
  license_type             = "ENTERPRISE"
  grafana_version          = "10.4"

  workspace_configuration = {
    plugins = {
      pluginAdminEnabled = true
    }
    unifiedAlerting = {
      enabled = true
    }
  }

  api_keys = {
    ci_viewer = {
      key_role        = "VIEWER"
      seconds_to_live = 2592000
    }
    automation_editor = {
      key_role        = "EDITOR"
      seconds_to_live = 2592000
    }
  }

  sns_topic_arns = [
    "arn:aws:sns:us-east-1:123456789012:grafana-critical",
    "arn:aws:sns:us-east-1:123456789012:grafana-warnings"
  ]

  tags = {
    Environment = "production"
    Team        = "observability"
    CostCenter  = "platform-eng"
  }
}
```
