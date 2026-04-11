# AWS Security Hub

OpenTofu module for provisioning and managing AWS Security Hub with standards subscriptions, multi-region aggregation, organization configuration, and custom action targets.

## Features

- **Security Hub Account** - Central security findings aggregation with configurable control finding generation and auto-enable controls
- **Standards Subscriptions** - Enable industry-standard compliance frameworks including AWS Foundational Security Best Practices, CIS AWS Foundations Benchmark, PCI DSS, and NIST 800-53
- **Finding Aggregator** - Cross-region finding aggregation with flexible linking modes (all regions, specified regions, or all except specified)
- **Organization Configuration** - Automatically enable Security Hub and default standards for new member accounts across the organization
- **Member Account Management** - Invite and manage member accounts for centralized security posture visibility
- **Custom Action Targets** - Define custom actions for Security Hub findings to integrate with EventBridge rules and automated remediation workflows

## Usage

```hcl
module "security_hub" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//security-hub?depth=1&ref=master"

  name = "security-hub-prod"

  enable_default_standards = false

  standards_arns = [
    "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0",
    "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.4.0",
  ]

  tags = {
    Environment = "production"
  }
}
```

## Examples

### Basic Security Hub with AWS Foundational Best Practices

Enable Security Hub with the AWS Foundational Security Best Practices standard.

```hcl
module "security_hub" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//security-hub?depth=1&ref=master"

  name                     = "security-hub-prod"
  enable_default_standards = false
  auto_enable_controls     = true

  standards_arns = [
    "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0",
  ]

  tags = {
    Environment = "production"
    Team        = "security"
  }
}
```

### Multi-Region Aggregation with Organization Configuration

Security Hub with cross-region finding aggregation and automatic enablement for organization member accounts.

```hcl
module "security_hub" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//security-hub?depth=1&ref=master"

  name                     = "security-hub-org"
  enable_default_standards = false

  standards_arns = [
    "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0",
    "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.4.0",
    "arn:aws:securityhub:us-east-1::standards/pci-dss/v/3.2.1",
    "arn:aws:securityhub:us-east-1::standards/nist-800-53/v/5.0.0",
  ]

  enable_finding_aggregator         = true
  finding_aggregator_linking_mode   = "ALL_REGIONS"

  enable_organization_configuration  = true
  organization_auto_enable           = true
  organization_auto_enable_standards = "DEFAULT"
  organization_configuration_type    = "CENTRAL"

  tags = {
    Environment = "production"
    Team        = "security"
  }
}
```

### Security Hub with Custom Action Targets

Security Hub with custom actions for integration with EventBridge automated remediation.

```hcl
module "security_hub" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//security-hub?depth=1&ref=master"

  name                     = "security-hub-prod"
  enable_default_standards = false

  standards_arns = [
    "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0",
  ]

  action_targets = {
    SendToSlack = {
      identifier  = "SendToSlack"
      description = "Send finding details to the security Slack channel"
    }
    RemediateS3 = {
      identifier  = "RemediateS3"
      description = "Trigger automated S3 bucket remediation"
    }
  }

  tags = {
    Environment = "production"
    Team        = "security"
  }
}
```
