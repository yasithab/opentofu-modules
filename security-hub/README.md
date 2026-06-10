# AWS Security Hub

OpenTofu module for provisioning and managing AWS Security Hub with standards subscriptions, multi-region aggregation, organization configuration, custom action targets, automation rules, and custom insights.

## Features

- **Security Hub Account** - Central security findings aggregation with configurable control finding generation and auto-enable controls
- **Standards Subscriptions** - Enable industry-standard compliance frameworks including AWS Foundational Security Best Practices, CIS AWS Foundations Benchmark, PCI DSS, and NIST 800-53
- **Finding Aggregator** - Cross-region finding aggregation with flexible linking modes (all regions, specified regions, or all except specified)
- **Organization Configuration** - Automatically enable Security Hub and default standards for new member accounts across the organization
- **Member Account Management** - Invite and manage member accounts for centralized security posture visibility
- **Custom Action Targets** - Define custom actions for Security Hub findings to integrate with EventBridge rules and automated remediation workflows
- **Automation Rules** - Automatically update or suppress findings that match criteria (e.g. suppress informational findings, escalate severity, set workflow status, attach notes)
- **Custom Insights** - Saved, grouped views over findings (e.g. critical findings grouped by resource) for posture dashboards and triage

## Notes

- `name` is optional. When set, it is used as a prefix for custom action target display names (`<name>-<key>`).
- Most Security Hub resources managed by this module (`aws_securityhub_account`,
  `aws_securityhub_standards_subscription`, `aws_securityhub_member`, `aws_securityhub_finding_aggregator`,
  `aws_securityhub_organization_configuration`, `aws_securityhub_action_target`, `aws_securityhub_insight`)
  do not support tagging; `tags` is applied to the resources that do (automation rules).
- Automation rules run in `rule_order` (lowest first). A rule with `is_terminal = true` stops further
  rules from processing a matching finding.

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

### Automation Rules and Custom Insights

Suppress noisy findings automatically and create a saved insight grouping critical findings by resource.

```hcl
module "security_hub" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//security-hub?depth=1&ref=master"

  standards_arns = [
    "arn:aws:securityhub:eu-west-1::standards/aws-foundational-security-best-practices/v/1.0.0",
  ]

  automation_rules = {
    suppress-sandbox-informational = {
      rule_order  = 1
      description = "Suppress informational findings from the sandbox account"

      criteria = {
        aws_account_id = [{ comparison = "EQUALS", value = "111111111111" }]
        severity_label = [{ comparison = "EQUALS", value = "INFORMATIONAL" }]
      }

      actions = {
        workflow_status = "SUPPRESSED"
        note_text       = "Sandbox findings are auto-suppressed"
      }
    }

    escalate-public-s3 = {
      rule_order  = 2
      description = "Escalate severity of public S3 bucket findings"
      is_terminal = true

      criteria = {
        resource_type = [{ comparison = "EQUALS", value = "AwsS3Bucket" }]
        title         = [{ comparison = "CONTAINS", value = "public" }]
        record_state  = [{ comparison = "EQUALS", value = "ACTIVE" }]
      }

      actions = {
        severity_label = "CRITICAL"
        types          = ["Software and Configuration Checks/Industry and Regulatory Standards"]
        user_defined_fields = {
          escalated = "true"
        }
      }
    }
  }

  insights = {
    critical-findings-by-resource = {
      group_by_attribute = "ResourceId"

      filters = {
        severity_label  = [{ comparison = "EQUALS", value = "CRITICAL" }]
        workflow_status = [{ comparison = "EQUALS", value = "NEW" }]
        record_state    = [{ comparison = "EQUALS", value = "ACTIVE" }]
      }
    }

    failed-cis-controls-by-account = {
      group_by_attribute = "AwsAccountId"

      filters = {
        generator_id      = [{ comparison = "PREFIX", value = "cis-aws-foundations-benchmark" }]
        compliance_status = [{ comparison = "EQUALS", value = "FAILED" }]
      }
    }
  }

  tags = {
    Environment = "production"
    Team        = "security"
  }
}
```
