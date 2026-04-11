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

## Input Reference

### Core

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `enabled` | `bool` | `true` | Set to false to prevent all resource creation. |
| `name` | `string` | required | Name used for all resource naming. |
| `tags` | `map(string)` | `{}` | Tags applied to all resources. |

### Vault

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `vault_enabled` | `bool` | `true` | Create a new vault. False looks up existing vault by `vault_name`. |
| `vault_name` | `string` | `null` | Override vault name. Defaults to `var.name`. |
| `kms_key_arn` | `string` | `null` | KMS key ARN for vault encryption. Uses AWS-managed key when null. |
| `vault_force_destroy` | `bool` | `false` | Allow vault deletion even when it contains recovery points. |
| `vault_policy` | `string` | `null` | JSON IAM resource policy for cross-account access. |
| `vault_lock` | `object` | `null` | Vault lock config. `changeable_for_days` enables compliance mode. |

#### vault_lock schema

```hcl
vault_lock = {
  changeable_for_days = 14    # optional - omit for governance mode, set for compliance mode
  min_retention_days  = 7     # optional - minimum enforced retention days
  max_retention_days  = 365   # optional - maximum enforced retention days
}
```

### Notifications

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `notifications` | `object` | `null` | SNS notification config. Null disables notifications entirely. |

#### notifications schema

```hcl
notifications = {
  sns_topic_arn = "arn:aws:sns:ap-southeast-1:123456789012:backup-alerts"
  events        = null   # null defaults to all job start/complete/fail events
}
```

When `events` is null, the following events are used:
`BACKUP_JOB_STARTED`, `BACKUP_JOB_COMPLETED`, `BACKUP_JOB_FAILED`,
`COPY_JOB_STARTED`, `COPY_JOB_FAILED`,
`RESTORE_JOB_COMPLETED`, `RESTORE_JOB_FAILED`

### Air-Gapped Vault

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `air_gapped_vault` | `object` | `null` | Creates a logically air-gapped vault. Null disables creation. |

#### air_gapped_vault schema

```hcl
air_gapped_vault = {
  name               = null    # optional, defaults to "<name>-airgap"
  min_retention_days = 7       # required
  max_retention_days = 365     # required
  encryption_key_arn = null    # optional KMS key ARN
}
```

Both `min_retention_days` and `max_retention_days` are required because AWS enforces them
when creating a logically air-gapped vault.

### IAM

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `iam_role_enabled` | `bool` | `true` | Create a new IAM role. False looks up existing role by `iam_role_name`. |
| `iam_role_name` | `string` | `null` | Override IAM role name. Defaults to `"${var.name}-backup"`. |
| `permissions_boundary` | `string` | `null` | IAM permissions boundary ARN for the role. |
| `iam_role_extra_policies` | `list(string)` | `[]` | Additional policy ARNs beyond the four default backup policies. |

Default policies always attached:
- `AWSBackupServiceRolePolicyForBackup`
- `AWSBackupServiceRolePolicyForS3Backup`
- `AWSBackupServiceRolePolicyForRestores`
- `AWSBackupServiceRolePolicyForS3Restore`

### Backup Plan

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `plan_enabled` | `bool` | `true` | Create a backup plan and selections. |
| `plan_name_suffix` | `string` | `null` | Optional suffix appended as `"<name>_<suffix>"`. |
| `rules` | `list(object)` | `[]` | Backup plan rules. See Rule Object Schema. |
| `advanced_backup_setting` | `object` | `null` | Per-resource-type advanced backup options (e.g. Windows VSS for EC2). |
| `scan_setting` | `object` | `null` | Malware scan settings for the plan. |

### Backup Selections

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `selections` | `map(object)` | `{}` | Map of backup selections. Key is used as the selection name. |

Each selection supports: `iam_role_arn`, `resources`, `not_resources`, `selection_tags`,
and `conditions` (with `string_equals`, `string_not_equals`, `string_like`, `string_not_like`
sub-lists).

Condition keys are passed through unchanged. Use full paths such as
`aws:ResourceTag/MyTag`. Keys are NOT auto-prefixed by this module.

### Frameworks and Reporting

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `frameworks` | `map(object)` | `{}` | AWS Backup compliance frameworks. Key is the framework name. |
| `report_plans` | `map(object)` | `{}` | AWS Backup report plans. Key is the report plan name. |
| `region_settings` | `object` | `null` | Region-level opt-in and management preferences. One per region per account. |

### Restore Testing

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `restore_testing_plan` | `object` | `null` | Restore testing plan configuration. |
| `restore_testing_selections` | `map(object)` | `{}` | Map of restore testing selections. Requires `restore_testing_plan`. |

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

## Output Reference

| Name | Description |
|------|-------------|
| `backup_vault_id` | Backup vault ID (name). |
| `backup_vault_arn` | Backup vault ARN. |
| `backup_vault_recovery_points` | Number of recovery points in the vault. |
| `air_gapped_vault_id` | Air-gapped vault ID. Empty string when not created. |
| `air_gapped_vault_arn` | Air-gapped vault ARN. Empty string when not created. |
| `backup_plan_id` | Backup plan ID. |
| `backup_plan_arn` | Backup plan ARN. |
| `backup_plan_version` | Backup plan version UUID, updated on every change. |
| `backup_selection_ids` | Map of selection name to selection ID. |
| `iam_role_name` | IAM role name. |
| `iam_role_arn` | IAM role ARN. |
| `framework_arns` | Map of framework name to ARN. |
| `report_plan_arns` | Map of report plan name to ARN. |
| `restore_testing_plan_arn` | Restore testing plan ARN. Null when not created. |

## Requirements

| Name | Version |
|------|---------|
| OpenTofu | `>= 1.11.0` |
| AWS provider | `~> 6.34` |


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
