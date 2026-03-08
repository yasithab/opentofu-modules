# AWS Backup Module - Examples

All examples reference the module locally. Adjust the `source` path as needed.

---

## 1. Basic Daily Backup

Minimal configuration - single rule, tag-based selection. Backs up all resources tagged
`Backup = true` daily at 05:00 UTC with 35-day retention.

```hcl
module "backup" {
  source = "../backup"

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
  source = "../backup"

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
  source = "../backup"

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
  source = "../backup"

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
  source = "../backup"

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
  source = "../backup"

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
  source = "../backup"

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
  source = "../backup"

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
