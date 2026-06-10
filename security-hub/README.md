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
| action\_targets | Map of custom action targets. Each key is the action target name. Identifier must be alphanumeric (max 20 chars) | <pre>map(object({<br/>    identifier  = string<br/>    description = string<br/>  }))</pre> | `{}` | no |
| auto\_enable\_controls | Whether to automatically enable new controls when they are added to standards that are enabled | `bool` | `true` | no |
| automation\_rules | Map of Security Hub automation rules. Each rule matches findings against `criteria`<br/>(string filters with `comparison` of EQUALS, NOT\_EQUALS, PREFIX, PREFIX\_NOT\_EQUALS, or CONTAINS)<br/>and applies the finding-field updates in `actions`. `rule_name` defaults to the map key.<br/>Lower `rule_order` values run first; set `is_terminal = true` to stop processing subsequent rules. | <pre>map(object({<br/>    rule_name   = optional(string)<br/>    rule_order  = number<br/>    description = string<br/>    rule_status = optional(string, "ENABLED")<br/>    is_terminal = optional(bool, false)<br/>    criteria = object({<br/>      aws_account_id                 = optional(list(object({ comparison = string, value = string })), [])<br/>      compliance_status              = optional(list(object({ comparison = string, value = string })), [])<br/>      compliance_security_control_id = optional(list(object({ comparison = string, value = string })), [])<br/>      generator_id                   = optional(list(object({ comparison = string, value = string })), [])<br/>      product_name                   = optional(list(object({ comparison = string, value = string })), [])<br/>      record_state                   = optional(list(object({ comparison = string, value = string })), [])<br/>      resource_type                  = optional(list(object({ comparison = string, value = string })), [])<br/>      severity_label                 = optional(list(object({ comparison = string, value = string })), [])<br/>      title                          = optional(list(object({ comparison = string, value = string })), [])<br/>      type                           = optional(list(object({ comparison = string, value = string })), [])<br/>      workflow_status                = optional(list(object({ comparison = string, value = string })), [])<br/>    })<br/>    actions = object({<br/>      severity_label      = optional(string)<br/>      workflow_status     = optional(string)<br/>      verification_state  = optional(string)<br/>      confidence          = optional(number)<br/>      criticality         = optional(number)<br/>      types               = optional(list(string))<br/>      user_defined_fields = optional(map(string))<br/>      note_text           = optional(string)<br/>      note_updated_by     = optional(string, "opentofu")<br/>    })<br/>  }))</pre> | `{}` | no |
| control\_finding\_generator | Updates whether the calling account has consolidated control findings turned on. Valid values: SECURITY\_CONTROL, STANDARD\_CONTROL | `string` | `"SECURITY_CONTROL"` | no |
| enable\_default\_standards | Whether to enable the default security standards when Security Hub is enabled. Set to false to manually control which standards to enable | `bool` | `false` | no |
| enable\_finding\_aggregator | Whether to enable the finding aggregator for cross-region finding aggregation | `bool` | `false` | no |
| enable\_organization\_configuration | Whether to enable the organization-level Security Hub configuration | `bool` | `false` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| finding\_aggregator\_linking\_mode | Linking mode for the finding aggregator. Valid values: ALL\_REGIONS, ALL\_REGIONS\_EXCEPT\_SPECIFIED, SPECIFIED\_REGIONS | `string` | `"ALL_REGIONS"` | no |
| finding\_aggregator\_regions | List of regions to include or exclude based on the linking mode. Only used when linking\_mode is SPECIFIED\_REGIONS or ALL\_REGIONS\_EXCEPT\_SPECIFIED | `list(string)` | `[]` | no |
| insights | Map of Security Hub custom insights. Each insight groups findings matching `filters`<br/>(string filters with `comparison` of EQUALS, NOT\_EQUALS, PREFIX, PREFIX\_NOT\_EQUALS, or CONTAINS)<br/>by `group_by_attribute` (e.g. ResourceId, AwsAccountId, SeverityLabel, Type).<br/>`name` defaults to the map key. | <pre>map(object({<br/>    name               = optional(string)<br/>    group_by_attribute = string<br/>    filters = object({<br/>      aws_account_id    = optional(list(object({ comparison = string, value = string })), [])<br/>      compliance_status = optional(list(object({ comparison = string, value = string })), [])<br/>      generator_id      = optional(list(object({ comparison = string, value = string })), [])<br/>      product_name      = optional(list(object({ comparison = string, value = string })), [])<br/>      record_state      = optional(list(object({ comparison = string, value = string })), [])<br/>      resource_type     = optional(list(object({ comparison = string, value = string })), [])<br/>      severity_label    = optional(list(object({ comparison = string, value = string })), [])<br/>      title             = optional(list(object({ comparison = string, value = string })), [])<br/>      type              = optional(list(object({ comparison = string, value = string })), [])<br/>      workflow_status   = optional(list(object({ comparison = string, value = string })), [])<br/>    })<br/>  }))</pre> | `{}` | no |
| member\_accounts | Map of member account configurations to associate with Security Hub. Each key is a friendly identifier | <pre>map(object({<br/>    account_id = string<br/>    email      = optional(string)<br/>    invite     = optional(bool, true)<br/>  }))</pre> | `{}` | no |
| name | Optional name prefix for Security Hub resources. When set, custom action target names are prefixed with it | `string` | `null` | no |
| organization\_auto\_enable | Whether to automatically enable Security Hub for new member accounts in the organization | `bool` | `true` | no |
| organization\_auto\_enable\_standards | Whether to automatically enable default standards for new member accounts. Valid values: DEFAULT, NONE | `string` | `"DEFAULT"` | no |
| organization\_configuration\_type | Organization configuration type. Valid values: CENTRAL, LOCAL. Set to null to skip the organization\_configuration block | `string` | `null` | no |
| standards\_arns | List of security standard ARNs to enable. Common standards: AWS Foundational Security Best Practices, CIS AWS Foundations Benchmark, PCI DSS, NIST 800-53 | `list(string)` | `[]` | no |
| tags | Map of tags for module convention. Security Hub resources do not currently support tags; kept for forward compatibility | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| action\_target\_arns | Map of action target names to their ARNs |
| automation\_rule\_arns | Map of automation rule keys to their ARNs |
| finding\_aggregator\_arn | ARN of the finding aggregator |
| hub\_arn | ARN of the Security Hub account |
| hub\_id | ID of the Security Hub account |
| hub\_name | Name identifier for the Security Hub deployment |
| insight\_arns | Map of insight keys to their ARNs |
| member\_account\_ids | Map of member account friendly names to their account IDs |
| standards\_subscription\_arns | Map of standards ARNs to their subscription ARNs |
<!-- END_TF_DOCS -->

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
