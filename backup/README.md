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
  source = "../backup"

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
  source = "../backup"

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
  source = "../backup"

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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.11.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.38.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.38.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | Name to use for resource naming and tagging. | `string` | n/a | yes |
| <a name="input_advanced_backup_setting"></a> [advanced\_backup\_setting](#input\_advanced\_backup\_setting) | Advanced backup settings per resource type (e.g. Windows VSS backups for EC2). | <pre>object({<br/>    backup_options = map(string)<br/>    resource_type  = string<br/>  })</pre> | `null` | no |
| <a name="input_air_gapped_vault"></a> [air\_gapped\_vault](#input\_air\_gapped\_vault) | Configuration for a logically air-gapped backup vault. No air-gapped vault is created when null.<br/>- name: Override the vault name. Defaults to "<name>-airgap".<br/>- min\_retention\_days / max\_retention\_days: Required retention bounds (non-optional - AWS requires both).<br/>- encryption\_key\_arn: Optional KMS key ARN for encryption. | <pre>object({<br/>    name               = optional(string)<br/>    min_retention_days = number<br/>    max_retention_days = number<br/>    encryption_key_arn = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_frameworks"></a> [frameworks](#input\_frameworks) | Map of AWS Backup Frameworks to create. Key is used as the framework name. | <pre>map(object({<br/>    description = optional(string)<br/>    controls = list(object({<br/>      name = string<br/>      input_parameters = optional(list(object({<br/>        name  = string<br/>        value = string<br/>      })), [])<br/>      scope = optional(object({<br/>        compliance_resource_ids   = optional(list(string))<br/>        compliance_resource_types = optional(list(string))<br/>        tags                      = optional(map(string))<br/>      }))<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_iam_role_enabled"></a> [iam\_role\_enabled](#input\_iam\_role\_enabled) | Set to true to create an IAM role for AWS Backup. Set to false to use an existing role resolved by iam\_role\_name. | `bool` | `true` | no |
| <a name="input_iam_role_extra_policies"></a> [iam\_role\_extra\_policies](#input\_iam\_role\_extra\_policies) | Additional policy ARNs to attach to the backup IAM role beyond the four default AWS managed backup policies. | `list(string)` | `[]` | no |
| <a name="input_iam_role_name"></a> [iam\_role\_name](#input\_iam\_role\_name) | Override the IAM role name. Defaults to "<name>-backup" when null. | `string` | `null` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | ARN of the KMS key used to encrypt the backup vault. Uses the AWS-managed key when null. | `string` | `null` | no |
| <a name="input_notifications"></a> [notifications](#input\_notifications) | SNS notification configuration. Null disables notifications.<br/>- sns\_topic\_arn: ARN of the SNS topic. The topic policy must allow backup.amazonaws.com to publish.<br/>- events: Vault events to send. Defaults to all job start/complete/fail events when null. | <pre>object({<br/>    sns_topic_arn = string<br/>    events        = optional(list(string))<br/>  })</pre> | `null` | no |
| <a name="input_permissions_boundary"></a> [permissions\_boundary](#input\_permissions\_boundary) | ARN of the IAM policy to use as permissions boundary for the backup IAM role. | `string` | `null` | no |
| <a name="input_plan_enabled"></a> [plan\_enabled](#input\_plan\_enabled) | Set to true to create a backup plan and backup selections. | `bool` | `true` | no |
| <a name="input_plan_name_suffix"></a> [plan\_name\_suffix](#input\_plan\_name\_suffix) | Optional suffix appended to the plan name as: <name>\_<suffix>. | `string` | `null` | no |
| <a name="input_region_settings"></a> [region\_settings](#input\_region\_settings) | AWS Backup region-level settings. When set, configures which resource types are opted in<br/>to backup and which use AWS Backup-managed policies. This is a region-wide resource -<br/>only one configuration exists per region per account. | <pre>object({<br/>    resource_type_opt_in_preference     = map(bool)<br/>    resource_type_management_preference = optional(map(bool))<br/>  })</pre> | `null` | no |
| <a name="input_report_plans"></a> [report\_plans](#input\_report\_plans) | Map of AWS Backup Report Plans to create. Key is used as the report plan name.<br/>report\_template must be one of: RESOURCE\_COMPLIANCE\_REPORT, CONTROL\_COMPLIANCE\_REPORT,<br/>BACKUP\_JOB\_REPORT, COPY\_JOB\_REPORT, RESTORE\_JOB\_REPORT. | <pre>map(object({<br/>    description        = optional(string)<br/>    s3_bucket_name     = string<br/>    s3_key_prefix      = optional(string)<br/>    formats            = optional(list(string), ["CSV"])<br/>    report_template    = string<br/>    accounts           = optional(list(string), [])<br/>    regions            = optional(list(string), [])<br/>    framework_arns     = optional(list(string), [])<br/>    organization_units = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_restore_testing_plan"></a> [restore\_testing\_plan](#input\_restore\_testing\_plan) | Restore testing plan configuration. When set, creates an aws\_backup\_restore\_testing\_plan.<br/>- name: Defaults to "<name>-restore-test".<br/>- algorithm: RANDOM\_WITHIN\_WINDOW or LATEST\_WITHIN\_WINDOW.<br/>- recovery\_point\_types: e.g. ["CONTINUOUS", "SNAPSHOT"]. | <pre>object({<br/>    name                         = optional(string)<br/>    schedule_expression          = string<br/>    schedule_expression_timezone = optional(string)<br/>    start_window_hours           = optional(number)<br/>    recovery_point_selection = object({<br/>      algorithm             = string<br/>      include_vaults        = list(string)<br/>      recovery_point_types  = list(string)<br/>      exclude_vaults        = optional(list(string))<br/>      selection_window_days = optional(number)<br/>    })<br/>  })</pre> | `null` | no |
| <a name="input_restore_testing_selections"></a> [restore\_testing\_selections](#input\_restore\_testing\_selections) | Map of restore testing selections. Key is used as the selection name. Requires<br/>restore\_testing\_plan to be configured. Uses the module IAM role when iam\_role\_arn is null. | <pre>map(object({<br/>    protected_resource_type    = string<br/>    iam_role_arn               = optional(string)<br/>    protected_resource_arns    = optional(list(string), [])<br/>    restore_metadata_overrides = optional(map(string), {})<br/>    validation_window_hours    = optional(number)<br/>    protected_resource_conditions = optional(object({<br/>      string_equals     = optional(list(object({ key = string, value = string })), [])<br/>      string_not_equals = optional(list(object({ key = string, value = string })), [])<br/>    }), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_rules"></a> [rules](#input\_rules) | List of backup plan rules. Each rule defines a backup schedule, retention policy, and optional<br/>cross-region copy actions.<br/>- scan\_mode: "FULL\_SCAN" or "INCREMENTAL\_SCAN".<br/>- Use target\_logically\_air\_gapped\_backup\_vault\_arn = "self" to reference the module's own air-gapped vault. | <pre>list(object({<br/>    name                                         = string<br/>    schedule                                     = optional(string)<br/>    schedule_expression_timezone                 = optional(string)<br/>    enable_continuous_backup                     = optional(bool)<br/>    start_window                                 = optional(number)<br/>    completion_window                            = optional(number)<br/>    target_logically_air_gapped_backup_vault_arn = optional(string)<br/>    recovery_point_tags                          = optional(map(string))<br/>    lifecycle = optional(object({<br/>      cold_storage_after                        = optional(number)<br/>      delete_after                              = optional(number)<br/>      opt_in_to_archive_for_supported_resources = optional(bool)<br/>    }))<br/>    copy_actions = optional(list(object({<br/>      destination_vault_arn = string<br/>      lifecycle = optional(object({<br/>        cold_storage_after                        = optional(number)<br/>        delete_after                              = optional(number)<br/>        opt_in_to_archive_for_supported_resources = optional(bool)<br/>      }))<br/>    })), [])<br/>    scan_action = optional(object({<br/>      malware_scanner = string<br/>      scan_mode       = string<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_scan_setting"></a> [scan\_setting](#input\_scan\_setting) | Malware scan settings for the backup plan. When set, AWS Backup scans recovery points for<br/>malware using the specified scanner.<br/>- malware\_scanner: Scanner type identifier.<br/>- resource\_types: Resource types to scan (e.g. ["EC2", "EFS"]).<br/>- scanner\_role\_arn: ARN of the IAM role used by the malware scanner. | <pre>object({<br/>    malware_scanner  = string<br/>    resource_types   = list(string)<br/>    scanner_role_arn = string<br/>  })</pre> | `null` | no |
| <a name="input_selections"></a> [selections](#input\_selections) | Map of backup selections. The map key is used as the selection name. Each selection can<br/>specify resources by ARN, exclusion patterns, tag-based selection, and tag conditions.<br/>Condition keys are full paths, e.g. "aws:ResourceTag/MyTag". They are NOT auto-prefixed.<br/>Uses the module IAM role when iam\_role\_arn is null. | <pre>map(object({<br/>    iam_role_arn  = optional(string)<br/>    resources     = optional(list(string), [])<br/>    not_resources = optional(list(string), [])<br/>    selection_tags = optional(list(object({<br/>      type  = string<br/>      key   = string<br/>      value = string<br/>    })), [])<br/>    conditions = optional(object({<br/>      string_equals     = optional(list(object({ key = string, value = string })), [])<br/>      string_not_equals = optional(list(object({ key = string, value = string })), [])<br/>      string_like       = optional(list(object({ key = string, value = string })), [])<br/>      string_not_like   = optional(list(object({ key = string, value = string })), [])<br/>    }), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_vault_enabled"></a> [vault\_enabled](#input\_vault\_enabled) | Set to true to create a new backup vault. Set to false to use an existing vault resolved by vault\_name. | `bool` | `true` | no |
| <a name="input_vault_force_destroy"></a> [vault\_force\_destroy](#input\_vault\_force\_destroy) | Allow the vault to be destroyed even when it contains recovery points. All recovery points are deleted before vault deletion. | `bool` | `false` | no |
| <a name="input_vault_lock"></a> [vault\_lock](#input\_vault\_lock) | Vault lock configuration. Null disables vault lock.<br/>- changeable\_for\_days: Creates compliance-mode lock (irremovable for N days). Omit for governance mode.<br/>- min\_retention\_days / max\_retention\_days: Retention range enforced by the lock. | <pre>object({<br/>    changeable_for_days = optional(number)<br/>    max_retention_days  = optional(number)<br/>    min_retention_days  = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_vault_name"></a> [vault\_name](#input\_vault\_name) | Override the vault name. Defaults to var.name when null. | `string` | `null` | no |
| <a name="input_vault_policy"></a> [vault\_policy](#input\_vault\_policy) | JSON IAM resource policy document to attach to the vault (e.g. for cross-account sharing). No policy is attached when null. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_air_gapped_vault_arn"></a> [air\_gapped\_vault\_arn](#output\_air\_gapped\_vault\_arn) | Logically air-gapped vault ARN. Empty string when not created. |
| <a name="output_air_gapped_vault_id"></a> [air\_gapped\_vault\_id](#output\_air\_gapped\_vault\_id) | Logically air-gapped vault ID (name). Empty string when not created. |
| <a name="output_backup_plan_arn"></a> [backup\_plan\_arn](#output\_backup\_plan\_arn) | Backup plan ARN. |
| <a name="output_backup_plan_id"></a> [backup\_plan\_id](#output\_backup\_plan\_id) | Backup plan ID. |
| <a name="output_backup_plan_version"></a> [backup\_plan\_version](#output\_backup\_plan\_version) | Version UUID of the backup plan, updated on every change. |
| <a name="output_backup_selection_ids"></a> [backup\_selection\_ids](#output\_backup\_selection\_ids) | Map of selection name to selection ID. |
| <a name="output_backup_vault_arn"></a> [backup\_vault\_arn](#output\_backup\_vault\_arn) | Backup vault ARN. |
| <a name="output_backup_vault_id"></a> [backup\_vault\_id](#output\_backup\_vault\_id) | Backup vault ID (name). |
| <a name="output_backup_vault_recovery_points"></a> [backup\_vault\_recovery\_points](#output\_backup\_vault\_recovery\_points) | Number of recovery points stored in the vault. |
| <a name="output_framework_arns"></a> [framework\_arns](#output\_framework\_arns) | Map of framework name to ARN. |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | ARN of the IAM role used by AWS Backup. |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | Name of the IAM role used by AWS Backup. |
| <a name="output_report_plan_arns"></a> [report\_plan\_arns](#output\_report\_plan\_arns) | Map of report plan name to ARN. |
| <a name="output_restore_testing_plan_arn"></a> [restore\_testing\_plan\_arn](#output\_restore\_testing\_plan\_arn) | Restore testing plan ARN. Null when not created. |
<!-- END_TF_DOCS -->