# Amazon Managed Grafana

Provisions an Amazon Managed Grafana workspace with configurable authentication, data sources, notification destinations, IAM roles, VPC configuration, and service account management.

## Features

- **Workspace Management** - Create a fully configured Grafana workspace with version pinning, data source integration, and notification destinations
- **Authentication** - Support for AWS SSO and SAML identity providers with configurable role mappings
- **Data Sources** - Automatic IAM policy provisioning for CloudWatch, Prometheus, X-Ray, Timestream, and other AWS data sources
- **VPC Configuration** - Private workspace access through VPC endpoints and network access controls
- **IAM Role** - Least-privilege IAM role with per-data-source policies, automatically scoped to selected data sources
- **Service Accounts** - Create and manage workspace service accounts and tokens (the supported replacement for API keys)
- **License Management** - Opt-in license association via `create_license_association` supporting ENTERPRISE and ENTERPRISE_FREE_TRIAL license types
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

  create_license_association = true
  license_type               = "ENTERPRISE"

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

### Enterprise with Service Accounts and Custom Plugins

Creates an Enterprise-licensed workspace with service accounts (and tokens) for automation and custom workspace configuration including plugins.

```hcl
module "grafana_enterprise" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//managed-grafana?depth=1&ref=master"

  enabled = true

  name                     = "enterprise-grafana"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  data_sources             = ["CLOUDWATCH", "PROMETHEUS", "XRAY", "TIMESTREAM"]
  grafana_version          = "10.4"

  create_license_association = true
  license_type               = "ENTERPRISE"

  workspace_configuration = {
    plugins = {
      pluginAdminEnabled = true
    }
    unifiedAlerting = {
      enabled = true
    }
  }

  service_accounts = {
    ci-viewer = {
      grafana_role = "VIEWER"
      tokens = {
        ci = {
          seconds_to_live = 2592000
        }
      }
    }
    automation-editor = {
      grafana_role = "EDITOR"
      tokens = {
        automation = {
          seconds_to_live = 2592000
        }
      }
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

### Service accounts

Workspace API keys are deprecated by AWS and do not work on Grafana 9+ workspaces; define automation credentials as service accounts instead:

```hcl
service_accounts = {
  ci-viewer = {
    grafana_role = "VIEWER"
    tokens = {
      ci = {
        seconds_to_live = 2592000
      }
    }
  }
}
```

Token secrets are exposed via the sensitive `service_account_tokens` output.

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
| account\_access\_type | Type of account access for the workspace. Valid values are CURRENT\_ACCOUNT and ORGANIZATION. | `string` | `"CURRENT_ACCOUNT"` | no |
| authentication\_providers | List of authentication providers for the workspace. Valid values are AWS\_SSO and SAML. | `list(string)` | <pre>[<br/>  "AWS_SSO"<br/>]</pre> | no |
| create\_iam\_role | Determines whether an IAM role is created for the Grafana workspace. | `bool` | `true` | no |
| create\_license\_association | Determines whether a license association is created for the workspace. Requires `license_type` to be set. | `bool` | `false` | no |
| data\_sources | List of data sources for the workspace. Valid values include AMAZON\_OPENSEARCH\_SERVICE, ATHENA, CLOUDWATCH, PROMETHEUS, REDSHIFT, SITEWISE, TIMESTREAM, TWINMAKER, XRAY. | `list(string)` | <pre>[<br/>  "CLOUDWATCH",<br/>  "PROMETHEUS",<br/>  "XRAY"<br/>]</pre> | no |
| enable\_saml\_configuration | Determines whether SAML configuration is created for the workspace. Requires SAML in `authentication_providers` and exactly one of `saml_idp_metadata_url` or `saml_idp_metadata_xml`. | `bool` | `false` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| grafana\_version | Version of Grafana to deploy. Defaults to the latest version available. | `string` | `null` | no |
| iam\_role\_arn | ARN of an existing IAM role to use when create\_iam\_role is false. | `string` | `null` | no |
| iam\_role\_inline\_policies | Map of inline policy names to policy JSON documents to attach to the IAM role. | `map(string)` | `{}` | no |
| iam\_role\_name | Name of the IAM role. Defaults to grafana-{name}. | `string` | `null` | no |
| iam\_role\_path | Path for the IAM role. | `string` | `"/"` | no |
| iam\_role\_policy\_arns | Map of IAM policy ARNs to attach to the IAM role. | `map(string)` | `{}` | no |
| iam\_role\_use\_name\_prefix | Determines whether to use the IAM role name as a prefix. | `bool` | `false` | no |
| license\_type | License type for the workspace. Valid values are ENTERPRISE and ENTERPRISE\_FREE\_TRIAL. Only used when `create_license_association` is `true`. | `string` | `"ENTERPRISE_FREE_TRIAL"` | no |
| name | Name of the Amazon Managed Grafana workspace. | `string` | n/a | yes |
| network\_access\_control | Network access control configuration. Provide prefix\_list\_ids and vpce\_ids. | <pre>object({<br/>    prefix_list_ids = list(string)<br/>    vpce_ids        = list(string)<br/>  })</pre> | `null` | no |
| notification\_destinations | List of notification destinations. Valid values are SNS. | `list(string)` | <pre>[<br/>  "SNS"<br/>]</pre> | no |
| organization\_role\_name | Role name used to access resources through AWS Organizations. | `string` | `null` | no |
| organizational\_units | List of AWS Organizations organizational unit IDs. | `list(string)` | `[]` | no |
| permission\_type | Permission type for the workspace. Valid values are SERVICE\_MANAGED and CUSTOMER\_MANAGED. | `string` | `"SERVICE_MANAGED"` | no |
| saml\_admin\_role\_values | List of SAML attribute values to match for the admin role. | `list(string)` | `[]` | no |
| saml\_editor\_role\_values | List of SAML attribute values to match for the editor role. | `list(string)` | `[]` | no |
| saml\_idp\_metadata\_url | URL for the SAML identity provider metadata. | `string` | `null` | no |
| saml\_idp\_metadata\_xml | XML metadata for the SAML identity provider. Used when a URL is not available. | `string` | `null` | no |
| saml\_login\_assertion | SAML login assertion attribute mapping configuration. | <pre>object({<br/>    email  = optional(string)<br/>    groups = optional(string)<br/>    login  = optional(string)<br/>    name   = optional(string)<br/>    org    = optional(string)<br/>    role   = optional(string)<br/>  })</pre> | `null` | no |
| service\_accounts | Map of Grafana workspace service account configurations. Each key is the service account name, with a grafana\_role (ADMIN, EDITOR, or VIEWER) and an optional map of tokens (token name => { seconds\_to\_live }). | <pre>map(object({<br/>    grafana_role = string<br/>    tokens = optional(map(object({<br/>      seconds_to_live = number<br/>    })), {})<br/>  }))</pre> | `{}` | no |
| sns\_topic\_arns | List of SNS topic ARNs that Grafana is allowed to publish notifications to. | `list(string)` | `[]` | no |
| stack\_set\_name | Name of the AWS CloudFormation stack set used to generate IAM roles for the workspace. | `string` | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| vpc\_configuration | VPC configuration for the workspace for private access. Provide security\_group\_ids and subnet\_ids. | <pre>object({<br/>    security_group_ids = list(string)<br/>    subnet_ids         = list(string)<br/>  })</pre> | `null` | no |
| workspace\_configuration | Configuration for the workspace as a map (will be JSON-encoded). Supports plugins, unifiedAlerting, etc. | `any` | `null` | no |
| workspace\_description | Description of the Grafana workspace. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| iam\_role\_arn | ARN of the IAM role used by the Grafana workspace. |
| iam\_role\_name | Name of the IAM role used by the Grafana workspace. |
| license\_type | License type associated with the workspace. |
| service\_account\_tokens | Map of service account token keys (service\_account/token) to their attributes, including the secret token key. |
| service\_accounts | Map of service account names to their attributes. |
| workspace\_arn | Amazon Resource Name (ARN) of the Grafana workspace. |
| workspace\_endpoint | Endpoint URL of the Grafana workspace. |
| workspace\_grafana\_version | Grafana version deployed in the workspace. |
| workspace\_id | Identifier of the Grafana workspace. |
| workspace\_name | Name of the Grafana workspace. |
<!-- END_TF_DOCS -->

</details>
