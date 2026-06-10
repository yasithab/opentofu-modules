# Amazon GuardDuty

OpenTofu module for provisioning and managing Amazon GuardDuty threat detection with comprehensive protection features, finding exports, and multi-account support.

## Features

- **Comprehensive Threat Detection** - GuardDuty detector with configurable finding publishing frequency (fifteen minutes, one hour, or six hours)
- **S3 Protection** - Monitors S3 data events to detect suspicious activities such as anomalous data access patterns
- **EKS Protection** - Analyzes EKS audit logs to detect potentially suspicious activities in Kubernetes clusters
- **Malware Protection** - Scans EBS volumes attached to EC2 instances when GuardDuty detects indicators of malware
- **RDS Protection** - Monitors RDS login activity to identify potentially compromised database instances
- **Lambda Protection** - Monitors Lambda function network activity to detect suspicious outbound communications
- **Runtime Monitoring** - OS-level threat detection for EKS, ECS Fargate, and EC2 with automatic agent management
- **Finding Export** - Publishes findings to an S3 bucket with KMS encryption for long-term retention and analysis
- **IPSet and ThreatIntelSet** - Custom trusted IP lists and threat intelligence feeds for enhanced detection accuracy
- **Finding Filters** - Auto-archive or suppress findings based on custom criteria to reduce alert noise
- **Multi-Account Support** - Invite and manage member accounts for centralized threat detection across an organization
- **Organization Support** - Designate a delegated GuardDuty administrator and auto-enable GuardDuty (and individual features) for AWS Organizations member accounts

## Usage

```hcl
module "guardduty" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//guardduty?depth=1&ref=master"

  name = "guardduty-prod"

  finding_publishing_frequency = "FIFTEEN_MINUTES"

  enable_s3_protection      = true
  enable_eks_protection     = true
  enable_malware_protection = true
  enable_rds_protection     = true
  enable_lambda_protection  = true
  enable_runtime_monitoring = true

  tags = {
    Environment = "production"
  }
}
```

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
| admin\_account\_id | AWS account ID to designate as the GuardDuty delegated administrator. Required when create\_organization\_admin\_account is true | `string` | `null` | no |
| auto\_enable\_organization\_members | How GuardDuty is auto-enabled for organization member accounts. Valid values: ALL, NEW, NONE | `string` | `"NEW"` | no |
| create\_organization\_admin\_account | Whether to designate a delegated GuardDuty administrator account for the organization. Apply from the organization management account | `bool` | `false` | no |
| create\_organization\_configuration | Whether to manage the organization-wide GuardDuty configuration. Apply from the delegated administrator account | `bool` | `false` | no |
| enable\_ec2\_agent\_management | Enable automatic management of the GuardDuty security agent for EC2 instances | `bool` | `true` | no |
| enable\_ecs\_fargate\_agent\_management | Enable automatic management of the GuardDuty security agent for ECS Fargate tasks | `bool` | `true` | no |
| enable\_eks\_addon\_management | Enable automatic management of the GuardDuty security agent add-on for EKS clusters | `bool` | `true` | no |
| enable\_eks\_protection | Enable EKS audit log monitoring for GuardDuty to detect suspicious activities in EKS clusters | `bool` | `true` | no |
| enable\_lambda\_protection | Enable Lambda network activity monitoring for GuardDuty to detect suspicious network traffic from Lambda functions | `bool` | `true` | no |
| enable\_malware\_protection | Enable malware scanning for EC2 instances with EBS volumes when a GuardDuty finding indicates potential malware | `bool` | `true` | no |
| enable\_rds\_protection | Enable RDS login activity monitoring for GuardDuty to detect suspicious login attempts to RDS databases | `bool` | `true` | no |
| enable\_runtime\_monitoring | Enable runtime monitoring for GuardDuty to detect threats at the operating system level on EKS, ECS, and EC2 | `bool` | `true` | no |
| enable\_s3\_protection | Enable S3 data event monitoring for GuardDuty to detect suspicious activities in S3 buckets | `bool` | `true` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| filters | Map of GuardDuty filter configurations. Each key is the filter name. Action must be ARCHIVE or NOOP | <pre>map(object({<br/>    action      = string<br/>    description = optional(string)<br/>    rank        = optional(number, 1)<br/>    criteria = list(object({<br/>      field                 = string<br/>      equals                = optional(list(string))<br/>      not_equals            = optional(list(string))<br/>      greater_than          = optional(string)<br/>      greater_than_or_equal = optional(string)<br/>      less_than             = optional(string)<br/>      less_than_or_equal    = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
| finding\_publishing\_frequency | Frequency of notifications sent about subsequent finding occurrences. Valid values: FIFTEEN\_MINUTES, ONE\_HOUR, SIX\_HOURS | `string` | `"FIFTEEN_MINUTES"` | no |
| ipsets | Map of IPSet configurations. Each key is the IPSet name. Format must be one of: TXT, STIX, OTX\_CSV, ALIEN\_VAULT, PROOF\_POINT, FIRE\_EYE | <pre>map(object({<br/>    activate = optional(bool, true)<br/>    format   = string<br/>    location = string<br/>  }))</pre> | `{}` | no |
| member\_accounts | Map of member account configurations to associate with the GuardDuty detector. Each key is a friendly identifier | <pre>map(object({<br/>    account_id                 = string<br/>    email                      = string<br/>    invite                     = optional(bool, true)<br/>    invitation_message         = optional(string, "GuardDuty member invitation")<br/>    disable_email_notification = optional(bool, true)<br/>  }))</pre> | `{}` | no |
| name | Name identifier for the GuardDuty deployment, used for naming and tagging conventions | `string` | `null` | no |
| organization\_configuration\_features | Map of GuardDuty detector features to auto-enable for organization member accounts.<br/>Each key is the feature name (e.g. S3\_DATA\_EVENTS, EKS\_AUDIT\_LOGS, EBS\_MALWARE\_PROTECTION,<br/>RDS\_LOGIN\_EVENTS, LAMBDA\_NETWORK\_LOGS, RUNTIME\_MONITORING). auto\_enable must be ALL, NEW,<br/>or NONE. additional\_configuration supports nested agent-management settings for<br/>RUNTIME\_MONITORING (EKS\_ADDON\_MANAGEMENT, ECS\_FARGATE\_AGENT\_MANAGEMENT, EC2\_AGENT\_MANAGEMENT). | <pre>map(object({<br/>    auto_enable = string<br/>    additional_configuration = optional(list(object({<br/>      name        = string<br/>      auto_enable = string<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| publishing\_destination | Configuration for exporting GuardDuty findings to an S3 bucket. Requires destination\_arn and kms\_key\_arn | <pre>object({<br/>    destination_arn  = string<br/>    kms_key_arn      = string<br/>    destination_type = optional(string, "S3")<br/>  })</pre> | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| threat\_intel\_sets | Map of ThreatIntelSet configurations. Each key is the ThreatIntelSet name. Format must be one of: TXT, STIX, OTX\_CSV, ALIEN\_VAULT, PROOF\_POINT, FIRE\_EYE | <pre>map(object({<br/>    activate = optional(bool, true)<br/>    format   = string<br/>    location = string<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| detector\_account\_id | AWS account ID of the GuardDuty detector |
| detector\_arn | ARN of the GuardDuty detector |
| detector\_id | ID of the GuardDuty detector |
| filter\_arns | Map of filter names to their ARNs |
| filter\_ids | Map of filter names to their IDs |
| ipset\_arns | Map of IPSet names to their ARNs |
| ipset\_ids | Map of IPSet names to their IDs |
| member\_account\_ids | Map of member account friendly names to their account IDs |
| name | Name identifier for the GuardDuty deployment |
| organization\_admin\_account\_id | AWS account ID of the GuardDuty delegated administrator account |
| organization\_configuration\_feature\_names | List of GuardDuty feature names managed by the organization configuration |
| organization\_configuration\_id | ID (detector ID) of the GuardDuty organization configuration |
| publishing\_destination\_id | ID of the GuardDuty publishing destination |
| threatintelset\_arns | Map of ThreatIntelSet names to their ARNs |
| threatintelset\_ids | Map of ThreatIntelSet names to their IDs |
<!-- END_TF_DOCS -->

## Examples

### Basic Detector with All Protections Enabled

A minimal deployment that enables GuardDuty with all protection features using sensible defaults.

```hcl
module "guardduty" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//guardduty?depth=1&ref=master"

  name = "guardduty-prod"

  tags = {
    Environment = "production"
    Team        = "security"
  }
}
```

### Detector with Finding Export and Threat Intel

GuardDuty with findings exported to S3 and custom threat intelligence feeds for enhanced detection.

```hcl
module "guardduty" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//guardduty?depth=1&ref=master"

  name                         = "guardduty-prod"
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  publishing_destination = {
    destination_arn = "arn:aws:s3:::my-guardduty-findings-bucket"
    kms_key_arn     = "arn:aws:kms:us-east-1:123456789012:key/abcd-1234"
  }

  threat_intel_sets = {
    custom-threats = {
      format   = "TXT"
      location = "s3://my-threat-intel-bucket/malicious-ips.txt"
    }
  }

  ipsets = {
    trusted-ips = {
      format   = "TXT"
      location = "s3://my-threat-intel-bucket/trusted-ips.txt"
    }
  }

  tags = {
    Environment = "production"
    Team        = "security"
  }
}
```

### Organization Management

Designate a delegated administrator from the organization management account, then manage
organization-wide auto-enable settings from the delegated administrator account.

```hcl
# In the organization management account
module "guardduty_mgmt" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//guardduty?depth=1&ref=master"

  name = "guardduty-org"

  create_organization_admin_account = true
  admin_account_id                  = "111111111111" # security/audit account
}

# In the delegated administrator (security) account
module "guardduty_admin" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//guardduty?depth=1&ref=master"

  name = "guardduty-org-admin"

  create_organization_configuration = true
  auto_enable_organization_members  = "ALL" # ALL, NEW, or NONE

  organization_configuration_features = {
    S3_DATA_EVENTS = {
      auto_enable = "ALL"
    }
    EKS_AUDIT_LOGS = {
      auto_enable = "NEW"
    }
    RUNTIME_MONITORING = {
      auto_enable = "NEW"
      additional_configuration = [
        {
          name        = "EKS_ADDON_MANAGEMENT"
          auto_enable = "NEW"
        }
      ]
    }
  }
}
```

### Multi-Account with Filters

GuardDuty with member accounts and finding filters to suppress known benign activities.

```hcl
module "guardduty" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//guardduty?depth=1&ref=master"

  name = "guardduty-org"

  member_accounts = {
    dev = {
      account_id = "111111111111"
      email      = "dev-account@example.com"
    }
    staging = {
      account_id = "222222222222"
      email      = "staging-account@example.com"
    }
  }

  filters = {
    suppress-known-scanners = {
      action      = "ARCHIVE"
      description = "Suppress findings from known security scanning tools"
      rank        = 1
      criteria = [
        {
          field  = "service.action.networkConnectionAction.remoteIpDetails.ipAddressV4"
          equals = ["10.0.0.100", "10.0.0.101"]
        }
      ]
    }
  }

  tags = {
    Environment = "production"
    Team        = "security"
  }
}
```
