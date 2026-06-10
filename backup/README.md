# AWS Backup Terraform Module

Terraform module for managing AWS Backup infrastructure. Creates and configures backup vaults,
backup plans with rules, backup selections, compliance frameworks, report plans, restore testing,
and region-level settings. Supports logically air-gapped vaults and cross-region replication.

## Resources Created

| Resource | Terraform Type | Controlled By |
|----------|---------------|---------------|
| Backup vault | `aws_backup_vault` | `var.vault_enabled` |
| Vault lock | `aws_backup_vault_lock_configuration` | `var.vault_lock != null` |
| Vault resource policy | `aws_backup_vault_policy` | `var.vault_policy != null` |
| SNS vault notifications | `aws_backup_vault_notifications` | `var.notifications != null` |
| Logically air-gapped vault | `aws_backup_logically_air_gapped_vault` | `var.air_gapped_vault != null` |
| IAM role | `aws_iam_role` | `var.iam_role_enabled` |
| IAM policy attachments (4 default + extras) | `aws_iam_role_policy_attachment` | `var.iam_role_enabled` |
| Backup plan | `aws_backup_plan` | `var.plan_enabled` |
| Backup selections (map) | `aws_backup_selection` | `var.plan_enabled && var.selections` |
| Compliance frameworks (map) | `aws_backup_framework` | `var.frameworks` |
| Report plans (map) | `aws_backup_report_plan` | `var.report_plans` |
| Region settings | `aws_backup_region_settings` | `var.region_settings != null` |
| Restore testing plan | `aws_backup_restore_testing_plan` | `var.restore_testing_plan != null` |
| Restore testing selections (map) | `aws_backup_restore_testing_selection` | `var.restore_testing_plan != null && var.restore_testing_selections` |

## Cross-Region Backup

Cross-region replication is configured per rule via `copy_actions`. Each copy action targets
a vault ARN in a destination region. The destination vault must exist before copies can be sent
to it, so create it as a separate module invocation with a provider alias.

```hcl
# Primary region ap-southeast-1 with DR copy to eu-west-1

provider "aws" {
  alias  = "eu_west_1"
  region = "eu-west-1"
}

# DR vault in eu-west-1 - vault only, no plan
module "backup_dr" {
  source    = "../backup"
  providers = { aws = aws.eu_west_1 }

  name         = "myapp"
  plan_enabled = false
}

# Primary backup in ap-southeast-1 with copy_actions referencing the DR vault
module "backup_primary" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//backup?depth=1&ref=master"

  name = "myapp"

  rules = [
    {
      name     = "daily"
      schedule = "cron(0 3 * * ? *)"
      lifecycle = { delete_after = 35 }
      copy_actions = [
        {
          destination_vault_arn = module.backup_dr.backup_vault_arn
          lifecycle             = { delete_after = 90 }
        }
      ]
    }
  ]

  selections = {
    all-tagged = {
      selection_tags = [{ type = "STRINGEQUALS", key = "Backup", value = "true" }]
    }
  }
}
```

### Multiple DR Regions with OpenTofu provider for_each

OpenTofu supports `for_each` on provider blocks, enabling a single module invocation to manage
vaults in many DR regions without repeating provider and module blocks per region.

```hcl
locals {
  dr_regions = toset(["eu-west-1", "us-east-1", "ap-northeast-1"])
}

provider "aws" {
  for_each = local.dr_regions
  alias    = each.key
  region   = each.key
}

# One DR vault per region
module "backup_dr" {
  source    = "../backup"
  for_each  = local.dr_regions
  providers = { aws = aws[each.key] }

  name         = "myapp"
  plan_enabled = false
}

# Primary plan copies to all DR vaults
module "backup_primary" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//backup?depth=1&ref=master"

  name = "myapp"

  rules = [
    {
      name     = "daily"
      schedule = "cron(0 3 * * ? *)"
      lifecycle = { delete_after = 35 }
      copy_actions = [
        for region in local.dr_regions : {
          destination_vault_arn = module.backup_dr[region].backup_vault_arn
          lifecycle             = { delete_after = 90 }
        }
      ]
    }
  ]
}
```

## Quick Start

```hcl
module "backup" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//backup?depth=1&ref=master"

  name = "my-app"
  tags = {
    Environment = "prod"
    Team        = "platform"
  }

  rules = [
    {
      name     = "daily"
      schedule = "cron(0 5 ? * * *)"
      lifecycle = { delete_after = 35 }
    }
  ]

  selections = {
    all-tagged = {
      selection_tags = [
        { type = "STRINGEQUALS", key = "Backup", value = "true" }
      ]
    }
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
| advanced\_backup\_setting | Advanced backup settings per resource type (e.g. Windows VSS backups for EC2). | <pre>object({<br/>    backup_options = map(string)<br/>    resource_type  = string<br/>  })</pre> | `null` | no |
| air\_gapped\_vault | Configuration for a logically air-gapped backup vault. No air-gapped vault is created when null.<br/>- name: Override the vault name. Defaults to "<name>-airgap".<br/>- min\_retention\_days / max\_retention\_days: Required retention bounds (non-optional - AWS requires both).<br/>- encryption\_key\_arn: Optional KMS key ARN for encryption. | <pre>object({<br/>    name               = optional(string)<br/>    min_retention_days = number<br/>    max_retention_days = number<br/>    encryption_key_arn = optional(string)<br/>  })</pre> | `null` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| frameworks | Map of AWS Backup Frameworks to create. Key is used as the framework name. | <pre>map(object({<br/>    description = optional(string)<br/>    controls = list(object({<br/>      name = string<br/>      input_parameters = optional(list(object({<br/>        name  = string<br/>        value = string<br/>      })), [])<br/>      scope = optional(object({<br/>        compliance_resource_ids   = optional(list(string))<br/>        compliance_resource_types = optional(list(string))<br/>        tags                      = optional(map(string))<br/>      }))<br/>    }))<br/>  }))</pre> | `{}` | no |
| iam\_role\_enabled | Set to true to create an IAM role for AWS Backup. Set to false to use an existing role resolved by iam\_role\_name. | `bool` | `true` | no |
| iam\_role\_extra\_policies | Additional policy ARNs to attach to the backup IAM role beyond the four default AWS managed backup policies. | `list(string)` | `[]` | no |
| iam\_role\_name | Override the IAM role name. Defaults to "<name>-backup" when null. | `string` | `null` | no |
| kms\_key\_arn | ARN of the KMS key used to encrypt the backup vault. Uses the AWS-managed key when null. | `string` | `null` | no |
| name | Name to use for resource naming and tagging. | `string` | n/a | yes |
| notifications | SNS notification configuration. Null disables notifications.<br/>- sns\_topic\_arn: ARN of the SNS topic. The topic policy must allow backup.amazonaws.com to publish.<br/>- events: Vault events to send. Defaults to all job start/complete/fail events when null. | <pre>object({<br/>    sns_topic_arn = string<br/>    events        = optional(list(string))<br/>  })</pre> | `null` | no |
| permissions\_boundary | ARN of the IAM policy to use as permissions boundary for the backup IAM role. | `string` | `null` | no |
| plan\_enabled | Set to true to create a backup plan and backup selections. | `bool` | `true` | no |
| plan\_name\_suffix | Optional suffix appended to the plan name as: <name>\_<suffix>. | `string` | `null` | no |
| region\_settings | AWS Backup region-level settings. When set, configures which resource types are opted in<br/>to backup and which use AWS Backup-managed policies. This is a region-wide resource -<br/>only one configuration exists per region per account. | <pre>object({<br/>    resource_type_opt_in_preference     = map(bool)<br/>    resource_type_management_preference = optional(map(bool))<br/>  })</pre> | `null` | no |
| report\_plans | Map of AWS Backup Report Plans to create. Key is used as the report plan name.<br/>report\_template must be one of: RESOURCE\_COMPLIANCE\_REPORT, CONTROL\_COMPLIANCE\_REPORT,<br/>BACKUP\_JOB\_REPORT, COPY\_JOB\_REPORT, RESTORE\_JOB\_REPORT. | <pre>map(object({<br/>    description        = optional(string)<br/>    s3_bucket_name     = string<br/>    s3_key_prefix      = optional(string)<br/>    formats            = optional(list(string), ["CSV"])<br/>    report_template    = string<br/>    accounts           = optional(list(string), [])<br/>    regions            = optional(list(string), [])<br/>    framework_arns     = optional(list(string), [])<br/>    organization_units = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| restore\_testing\_plan | Restore testing plan configuration. When set, creates an aws\_backup\_restore\_testing\_plan.<br/>- name: Defaults to "<name>-restore-test".<br/>- schedule\_expression: Cron expression for when restore tests run. The module falls back to "cron(0 5 ? * * *)" (daily at 05:00 UTC) if unset.<br/>- algorithm: RANDOM\_WITHIN\_WINDOW or LATEST\_WITHIN\_WINDOW.<br/>- recovery\_point\_types: e.g. ["CONTINUOUS", "SNAPSHOT"]. | <pre>object({<br/>    name                         = optional(string)<br/>    schedule_expression          = string<br/>    schedule_expression_timezone = optional(string)<br/>    start_window_hours           = optional(number)<br/>    recovery_point_selection = object({<br/>      algorithm             = string<br/>      include_vaults        = list(string)<br/>      recovery_point_types  = list(string)<br/>      exclude_vaults        = optional(list(string))<br/>      selection_window_days = optional(number)<br/>    })<br/>  })</pre> | `null` | no |
| restore\_testing\_selections | Map of restore testing selections. Key is used as the selection name. Requires<br/>restore\_testing\_plan to be configured. Uses the module IAM role when iam\_role\_arn is null. | <pre>map(object({<br/>    protected_resource_type    = string<br/>    iam_role_arn               = optional(string)<br/>    protected_resource_arns    = optional(list(string), [])<br/>    restore_metadata_overrides = optional(map(string), {})<br/>    validation_window_hours    = optional(number)<br/>    protected_resource_conditions = optional(object({<br/>      string_equals     = optional(list(object({ key = string, value = string })), [])<br/>      string_not_equals = optional(list(object({ key = string, value = string })), [])<br/>    }), {})<br/>  }))</pre> | `{}` | no |
| rules | List of backup plan rules. Each rule defines a backup schedule, retention policy, and optional<br/>cross-region copy actions.<br/>- scan\_mode: "FULL\_SCAN" or "INCREMENTAL\_SCAN".<br/>- Use target\_logically\_air\_gapped\_backup\_vault\_arn = "self" to reference the module's own air-gapped vault. | <pre>list(object({<br/>    name                                         = string<br/>    schedule                                     = optional(string)<br/>    schedule_expression_timezone                 = optional(string)<br/>    enable_continuous_backup                     = optional(bool)<br/>    start_window                                 = optional(number)<br/>    completion_window                            = optional(number)<br/>    target_logically_air_gapped_backup_vault_arn = optional(string)<br/>    recovery_point_tags                          = optional(map(string))<br/>    lifecycle = optional(object({<br/>      cold_storage_after                        = optional(number)<br/>      delete_after                              = optional(number)<br/>      opt_in_to_archive_for_supported_resources = optional(bool)<br/>    }))<br/>    copy_actions = optional(list(object({<br/>      destination_vault_arn = string<br/>      lifecycle = optional(object({<br/>        cold_storage_after                        = optional(number)<br/>        delete_after                              = optional(number)<br/>        opt_in_to_archive_for_supported_resources = optional(bool)<br/>      }))<br/>    })), [])<br/>    scan_action = optional(object({<br/>      malware_scanner = string<br/>      scan_mode       = string<br/>    }))<br/>  }))</pre> | `[]` | no |
| scan\_setting | Malware scan settings for the backup plan. When set, AWS Backup scans recovery points for<br/>malware using the specified scanner.<br/>- malware\_scanner: Scanner type identifier.<br/>- resource\_types: Resource types to scan (e.g. ["EC2", "EFS"]).<br/>- scanner\_role\_arn: ARN of the IAM role used by the malware scanner. | <pre>object({<br/>    malware_scanner  = string<br/>    resource_types   = list(string)<br/>    scanner_role_arn = string<br/>  })</pre> | `null` | no |
| selections | Map of backup selections. The map key is used as the selection name. Each selection can<br/>specify resources by ARN, exclusion patterns, tag-based selection, and tag conditions.<br/>Condition keys are full paths, e.g. "aws:ResourceTag/MyTag". They are NOT auto-prefixed.<br/>Uses the module IAM role when iam\_role\_arn is null. | <pre>map(object({<br/>    iam_role_arn  = optional(string)<br/>    resources     = optional(list(string), [])<br/>    not_resources = optional(list(string), [])<br/>    selection_tags = optional(list(object({<br/>      type  = string<br/>      key   = string<br/>      value = string<br/>    })), [])<br/>    conditions = optional(object({<br/>      string_equals     = optional(list(object({ key = string, value = string })), [])<br/>      string_not_equals = optional(list(object({ key = string, value = string })), [])<br/>      string_like       = optional(list(object({ key = string, value = string })), [])<br/>      string_not_like   = optional(list(object({ key = string, value = string })), [])<br/>    }), {})<br/>  }))</pre> | `{}` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| vault\_enabled | Set to true to create a new backup vault. Set to false to use an existing vault resolved by vault\_name. | `bool` | `true` | no |
| vault\_force\_destroy | Allow the vault to be destroyed even when it contains recovery points. All recovery points are deleted before vault deletion. | `bool` | `false` | no |
| vault\_lock | Vault lock configuration. Null disables vault lock.<br/>- changeable\_for\_days: Creates compliance-mode lock (irremovable for N days). Omit for governance mode.<br/>- min\_retention\_days / max\_retention\_days: Retention range enforced by the lock. | <pre>object({<br/>    changeable_for_days = optional(number)<br/>    max_retention_days  = optional(number)<br/>    min_retention_days  = optional(number)<br/>  })</pre> | `null` | no |
| vault\_name | Override the vault name. Defaults to var.name when null. | `string` | `null` | no |
| vault\_policy | JSON IAM resource policy document to attach to the vault (e.g. for cross-account sharing). No policy is attached when null. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| air\_gapped\_vault\_arn | Logically air-gapped vault ARN. Empty string when not created. |
| air\_gapped\_vault\_id | Logically air-gapped vault ID (name). Empty string when not created. |
| backup\_plan\_arn | Backup plan ARN. |
| backup\_plan\_id | Backup plan ID. |
| backup\_plan\_version | Version UUID of the backup plan, updated on every change. |
| backup\_selection\_ids | Map of selection name to selection ID. |
| backup\_vault\_arn | Backup vault ARN. |
| backup\_vault\_id | Backup vault ID (name). |
| backup\_vault\_recovery\_points | Number of recovery points stored in the vault. |
| framework\_arns | Map of framework name to ARN. |
| iam\_role\_arn | ARN of the IAM role used by AWS Backup. |
| iam\_role\_name | Name of the IAM role used by AWS Backup. |
| report\_plan\_arns | Map of report plan name to ARN. |
| restore\_testing\_plan\_arn | Restore testing plan ARN. Null when not created. |
<!-- END_TF_DOCS -->

## Rule Object Schema

```hcl
{
  name                                         = string           # required
  schedule                                     = optional(string) # cron or rate expression
  schedule_expression_timezone                 = optional(string) # e.g. "Australia/Sydney"
  enable_continuous_backup                     = optional(bool)
  start_window                                 = optional(number) # minutes
  completion_window                            = optional(number) # minutes
  target_logically_air_gapped_backup_vault_arn = optional(string) # "self" = module's own air-gapped vault
  recovery_point_tags                          = optional(map(string))

  lifecycle = optional(object({
    cold_storage_after                        = optional(number) # days before cold tier
    delete_after                              = optional(number) # days before deletion
    opt_in_to_archive_for_supported_resources = optional(bool)
  }))

  copy_actions = optional(list(object({
    destination_vault_arn = string
    lifecycle = optional(object({
      cold_storage_after                        = optional(number)
      delete_after                              = optional(number)
      opt_in_to_archive_for_supported_resources = optional(bool)
    }))
  })), [])

  scan_action = optional(object({
    malware_scanner = string          # scanner type identifier
    scan_mode       = string          # "FULL_SCAN" or "INCREMENTAL_SCAN"
  }))
}
```

## Examples

All examples reference the module via its Git source URL.

---

## 1. Basic Daily Backup

Minimal configuration - single rule, tag-based selection. Backs up all resources tagged
`Backup = true` daily at 05:00 UTC with 35-day retention.

```hcl
module "backup" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//backup?depth=1&ref=master"

  name = "prod-daily"
  tags = {
    Environment = "prod"
    Team        = "platform"
  }

  rules = [
    {
      name              = "daily-0500"
      schedule          = "cron(0 5 ? * * *)"
      start_window      = 480
      completion_window = 10080
      lifecycle = {
        delete_after = 35
      }
    }
  ]

  selections = {
    rds-and-dynamodb = {
      selection_tags = [
        {
          type  = "STRINGEQUALS"
          key   = "Backup"
          value = "true"
        }
      ]
    }
  }
}
```

---

## 2. Multi-Rule Plan (Daily, Weekly, Monthly)

Three rules with different schedules, start windows, and retention periods.

```hcl
module "backup" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//backup?depth=1&ref=master"

  name = "prod-tiered"

  rules = [
    {
      name              = "daily"
      schedule          = "cron(0 5 ? * * *)"
      start_window      = 480
      completion_window = 10080
      lifecycle = {
        delete_after = 35
      }
    },
    {
      name              = "weekly"
      schedule          = "cron(0 5 ? * SAT *)"
      start_window      = 480
      completion_window = 10080
      lifecycle = {
        cold_storage_after = 30
        delete_after       = 90
      }
    },
    {
      name              = "monthly"
      schedule          = "cron(0 5 1 * ? *)"
      start_window      = 480
      completion_window = 10080
      lifecycle = {
        cold_storage_after = 90
        delete_after       = 365
      }
    }
  ]

  selections = {
    all-tagged = {
      selection_tags = [
        {
          type  = "STRINGEQUALS"
          key   = "BackupPolicy"
          value = "tiered"
        }
      ]
    }
  }
}
```

---

## 3. Cross-Region Backup (ap-southeast-1 primary, eu-west-1 DR)

Primary backups run in `ap-southeast-1`. Each backup rule copies to a vault in `eu-west-1`
via `copy_actions`. The DR vault is created with a separate provider-aliased invocation of
this same module with `plan_enabled = false`.

```hcl
provider "aws" {
  alias  = "eu_west_1"
  region = "eu-west-1"
}

# DR vault in eu-west-1 - vault only, no plan or IAM role
module "backup_dr" {
  source    = "../backup"
  providers = { aws = aws.eu_west_1 }

  name         = "prod-eu"
  plan_enabled = false

  tags = { Environment = "prod" }
}

# Primary backup in ap-southeast-1
module "backup_primary" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//backup?depth=1&ref=master"

  name = "prod"
  tags = { Environment = "prod" }

  rules = [
    {
      name              = "daily"
      schedule          = "cron(0 5 ? * * *)"
      start_window      = 480
      completion_window = 10080
      lifecycle = {
        delete_after = 35
      }
      # Copy every daily backup to the DR vault in eu-west-1
      copy_actions = [
        {
          destination_vault_arn = module.backup_dr.backup_vault_arn
          lifecycle             = { delete_after = 90 }
        }
      ]
    }
  ]

  selections = {
    all-tagged = {
      selection_tags = [
        { type = "STRINGEQUALS", key = "Backup", value = "true" }
      ]
    }
  }
}
```

### Multiple DR regions using OpenTofu provider for_each

OpenTofu supports `for_each` on provider blocks, so adding a new DR region is a one-line
change to `local.dr_regions`.

```hcl
locals {
  dr_regions = toset(["eu-west-1", "us-east-1", "ap-northeast-1"])
}

provider "aws" {
  for_each = local.dr_regions
  alias    = each.key
  region   = each.key
}

# One DR vault per region
module "backup_dr" {
  source    = "../backup"
  for_each  = local.dr_regions
  providers = { aws = aws[each.key] }

  name         = "prod"
  plan_enabled = false

  tags = { Environment = "prod" }
}

# Primary plan copies to every DR vault
module "backup_primary" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//backup?depth=1&ref=master"

  name = "prod"

  rules = [
    {
      name     = "daily"
      schedule = "cron(0 5 ? * * *)"
      lifecycle = { delete_after = 35 }
      copy_actions = [
        for region in local.dr_regions : {
          destination_vault_arn = module.backup_dr[region].backup_vault_arn
          lifecycle             = { delete_after = 90 }
        }
      ]
    }
  ]

  selections = {
    all-tagged = {
      selection_tags = [{ type = "STRINGEQUALS", key = "Backup", value = "true" }]
    }
  }
}
```

---

## 4. Full Production Setup

Vault lock (compliance mode), SNS notifications, geo-redundant backup, and multiple selections
scoped to different resource types. Uses the new `vault_lock` and `notifications` variables.

```hcl
module "backup" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//backup?depth=1&ref=master"

  name        = "prod-full"
  kms_key_arn = "arn:aws:kms:ap-southeast-1:123456789012:key/mrk-abc123"
  tags = {
    Environment = "prod"
    Compliance  = "pci"
  }

  # Vault lock - compliance mode, irremovable for 14 days
  vault_lock = {
    changeable_for_days = 14
    min_retention_days  = 7
    max_retention_days  = 365
  }

  # SNS notifications for all vault events
  notifications = {
    sns_topic_arn = "arn:aws:sns:ap-southeast-1:123456789012:backup-alerts"
    # events = null uses the default set: all job start/complete/fail events
  }

  rules = [
    {
      name              = "daily"
      schedule          = "cron(0 5 ? * * *)"
      start_window      = 480
      completion_window = 10080
      lifecycle = {
        delete_after = 35
      }
      copy_actions = [
        {
          destination_vault_arn = "arn:aws:backup:eu-west-1:123456789012:backup-vault:prod-full"
          lifecycle             = { delete_after = 90 }
        }
      ]
    },
    {
      name              = "weekly"
      schedule          = "cron(0 5 ? * SAT *)"
      start_window      = 480
      completion_window = 10080
      lifecycle = {
        cold_storage_after = 30
        delete_after       = 90
      }
    }
  ]

  # Multiple selections scoped by resource type
  selections = {
    databases = {
      resources = [
        "arn:aws:rds:*:*:db:*",
        "arn:aws:dynamodb:*:*:table/*",
      ]
      selection_tags = [
        {
          type  = "STRINGEQUALS"
          key   = "Backup"
          value = "true"
        }
      ]
    }
    efs-volumes = {
      resources = ["arn:aws:elasticfilesystem:*:*:file-system/*"]
    }
    ebs-snapshots = {
      resources = ["arn:aws:ec2:*:*:volume/*"]
      selection_tags = [
        {
          type  = "STRINGEQUALS"
          key   = "BackupEBS"
          value = "true"
        }
      ]
    }
  }
}
```

---

## 5. Compliance Framework and Reporting

Creates a BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN framework and a daily compliance report
delivered to S3 in CSV and JSON formats.

```hcl
module "backup" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//backup?depth=1&ref=master"

  name = "prod-compliance"

  rules = [
    {
      name     = "daily"
      schedule = "cron(0 5 ? * * *)"
      lifecycle = { delete_after = 35 }
    }
  ]

  selections = {
    all-tagged = {
      selection_tags = [
        { type = "STRINGEQUALS", key = "Backup", value = "true" }
      ]
    }
  }

  frameworks = {
    prod-backup-framework = {
      description = "PCI backup compliance framework"
      controls = [
        {
          name = "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN"
          input_parameters = [
            { name = "requiredRetentionDays", value = "35" }
          ]
          scope = {
            compliance_resource_types = ["RDS", "DynamoDB", "EFS"]
          }
        },
        {
          name = "BACKUP_RECOVERY_POINT_MINIMUM_RETENTION_CHECK"
          input_parameters = [
            { name = "requiredRetentionDays", value = "35" }
          ]
        }
      ]
    }
  }

  report_plans = {
    prod-compliance-report = {
      description     = "Daily resource compliance report"
      s3_bucket_name  = "my-backup-reports-bucket"
      s3_key_prefix   = "backup/compliance"
      formats         = ["CSV", "JSON"]
      report_template = "RESOURCE_COMPLIANCE_REPORT"
    }
  }
}
```

---

## 6. Restore Testing

Validates that backups can actually be restored. Creates a weekly restore test targeting all
RDS snapshots from the past 7 days. Uses the module IAM role for restore execution.

```hcl
module "backup" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//backup?depth=1&ref=master"

  name = "prod-restore-test"

  rules = [
    {
      name                     = "daily"
      schedule                 = "cron(0 5 ? * * *)"
      enable_continuous_backup = true
      lifecycle                = { delete_after = 35 }
    }
  ]

  selections = {
    rds = {
      resources = ["arn:aws:rds:*:*:db:*"]
    }
  }

  restore_testing_plan = {
    name                = "prod-rds-restore-test"
    schedule_expression = "cron(0 8 ? * SUN *)"
    start_window_hours  = 2
    recovery_point_selection = {
      algorithm             = "RANDOM_WITHIN_WINDOW"
      include_vaults        = ["arn:aws:backup:ap-southeast-1:123456789012:backup-vault:prod-restore-test"]
      recovery_point_types  = ["SNAPSHOT"]
      selection_window_days = 7
    }
  }

  restore_testing_selections = {
    rds-restore = {
      protected_resource_type = "RDS"
      restore_metadata_overrides = {
        DBInstanceIdentifier = "restore-test-instance"
        MultiAZ              = "false"
      }
      validation_window_hours = 4
    }
  }
}
```

---

## 7. Air-Gapped Vault

Creates a logically air-gapped vault alongside the regular vault for immutable, isolated
backup storage. A dedicated weekly rule targets the air-gapped vault using the `"self"`
sentinel, which the module resolves to the air-gapped vault ARN at plan time.

Both `min_retention_days` and `max_retention_days` are required because AWS mandates them
when creating a logically air-gapped vault.

```hcl
module "backup" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//backup?depth=1&ref=master"

  name = "prod-airgap"

  # Air-gapped vault with 7-365 day retention bounds
  air_gapped_vault = {
    min_retention_days = 7
    max_retention_days = 365
    encryption_key_arn = "arn:aws:kms:ap-southeast-1:123456789012:key/mrk-abc123"
    # name defaults to "prod-airgap-airgap" when not set
  }

  rules = [
    # Standard daily rule targeting the regular vault
    {
      name     = "daily-standard"
      schedule = "cron(0 5 ? * * *)"
      lifecycle = { delete_after = 35 }
    },
    # Weekly rule targeting the air-gapped vault via "self" sentinel
    {
      name                                         = "weekly-airgap"
      schedule                                     = "cron(0 5 ? * SAT *)"
      target_logically_air_gapped_backup_vault_arn = "self"
      lifecycle = {
        delete_after = 90
      }
    }
  ]

  selections = {
    critical-databases = {
      resources = [
        "arn:aws:rds:*:*:db:prod-*",
        "arn:aws:dynamodb:*:*:table/prod-*",
      ]
    }
  }
}

output "air_gapped_vault_arn" {
  value = module.backup.air_gapped_vault_arn
}
```
