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
