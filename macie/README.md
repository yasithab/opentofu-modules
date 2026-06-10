# Amazon Macie

OpenTofu module for provisioning and managing Amazon Macie sensitive data discovery with classification jobs, custom data identifiers, allow lists, and multi-account support.

## Features

- **Macie Account** - Enable Macie with configurable finding publishing frequency for sensitive data discovery and protection
- **Classification Jobs** - Schedule one-time or recurring sensitive data discovery jobs targeting specific S3 buckets with scoping filters
- **Custom Data Identifiers** - Define custom regex patterns and keyword-based identifiers for organization-specific sensitive data types
- **Allow Lists** - Create S3-backed word lists or regex-based allow lists to exclude known acceptable data patterns from findings
- **Member Account Management** - Invite and manage member accounts for centralized sensitive data discovery across the organization
- **Classification Export** - Export classification results to an S3 bucket with KMS encryption for long-term retention and compliance
- **Organization Support** - Designate a delegated Macie administrator and auto-enable Macie for new AWS Organizations member accounts

## Notes

- `name` is optional (defaults to `null`); it is exposed via the `name` output for composition.
- `classification_export_kms_key_arn` is required whenever `classification_export_bucket_name`
  is set - Macie mandates KMS encryption for classification results.

## Usage

```hcl
module "macie" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//macie?depth=1&ref=master"

  name = "macie-prod"

  finding_publishing_frequency = "FIFTEEN_MINUTES"

  tags = {
    Environment = "production"
  }
}
```

## Examples

### Basic Macie Enablement

Enable Macie with default settings and frequent finding publication.

```hcl
module "macie" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//macie?depth=1&ref=master"

  name                         = "macie-prod"
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  tags = {
    Environment = "production"
    Team        = "security"
  }
}
```

### Macie with Classification Jobs and Custom Identifiers

Macie with scheduled classification jobs and custom data identifiers for organization-specific sensitive data.

```hcl
module "macie" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//macie?depth=1&ref=master"

  name = "macie-prod"

  classification_jobs = {
    pii-scan = {
      job_type = "SCHEDULED"
      bucket_definitions = [
        {
          account_id = "123456789012"
          buckets    = ["my-data-bucket", "my-uploads-bucket"]
        }
      ]
      description         = "Weekly PII scan of data buckets"
      sampling_percentage = 100
      schedule_frequency = {
        weekly_schedule = "MONDAY"
      }
    }
  }

  custom_data_identifiers = {
    employee-id = {
      regex       = "EMP-[0-9]{6}"
      keywords    = ["employee", "emp-id"]
      description = "Matches internal employee ID format"
    }
    internal-project-code = {
      regex       = "PRJ-[A-Z]{3}-[0-9]{4}"
      keywords    = ["project"]
      description = "Matches internal project code format"
    }
  }

  classification_export_bucket_name = "my-macie-results-bucket"
  classification_export_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/abcd-1234"
  classification_export_key_prefix  = "macie-results/"

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
module "macie_mgmt" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//macie?depth=1&ref=master"

  name = "macie-org"

  create_organization_admin_account = true
  admin_account_id                  = "111111111111" # security/audit account
}

# In the delegated administrator (security) account
module "macie_admin" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//macie?depth=1&ref=master"

  name = "macie-org-admin"

  create_organization_configuration = true
  auto_enable_organization_members  = true
}
```

### Multi-Account Macie with Allow Lists

Macie with member accounts and allow lists to reduce false positives.

```hcl
module "macie" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//macie?depth=1&ref=master"

  name = "macie-org"

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

  allow_lists = {
    known-test-data = {
      description = "Known test data patterns that are not real PII"
      s3_words_list = {
        bucket_name = "my-macie-config-bucket"
        object_key  = "allow-lists/test-data.txt"
      }
    }
    internal-ids = {
      description = "Internal ID patterns that are not sensitive"
      regex       = "TEST-[0-9]{10}"
    }
  }

  tags = {
    Environment = "production"
    Team        = "security"
  }
}
```

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
| admin\_account\_id | AWS account ID to designate as the Macie delegated administrator. Required when create\_organization\_admin\_account is true | `string` | `null` | no |
| auto\_enable\_organization\_members | Whether to automatically enable Macie for new accounts that join the organization | `bool` | `true` | no |
| classification\_export\_bucket\_name | S3 bucket name for exporting Macie classification results. Set to null to skip export configuration | `string` | `null` | no |
| classification\_export\_key\_prefix | S3 key prefix for exported Macie classification results | `string` | `null` | no |
| classification\_export\_kms\_key\_arn | ARN of the KMS key to encrypt exported Macie classification results in S3 | `string` | `null` | no |
| classification\_jobs | Map of classification job configurations. Each key is the job name. Job type must be ONE\_TIME or SCHEDULED | <pre>map(object({<br/>    job_type = string<br/>    bucket_definitions = list(object({<br/>      account_id = string<br/>      buckets    = list(string)<br/>    }))<br/>    description         = optional(string)<br/>    sampling_percentage = optional(number, 100)<br/>    initial_run         = optional(bool, true)<br/>    scoping = optional(object({<br/>      excludes = optional(object({<br/>        and = optional(list(object({<br/>          simple_scope_term = optional(object({<br/>            comparator = string<br/>            key        = string<br/>            values     = list(string)<br/>          }))<br/>        })), [])<br/>      }))<br/>      includes = optional(object({<br/>        and = optional(list(object({<br/>          simple_scope_term = optional(object({<br/>            comparator = string<br/>            key        = string<br/>            values     = list(string)<br/>          }))<br/>        })), [])<br/>      }))<br/>    }))<br/>    schedule_frequency = optional(object({<br/>      monthly_schedule = optional(number)<br/>      weekly_schedule  = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
| create\_organization\_admin\_account | Whether to designate a delegated Macie administrator account for the organization. Apply from the organization management account | `bool` | `false` | no |
| create\_organization\_configuration | Whether to manage the organization-wide Macie configuration. Apply from the delegated administrator account | `bool` | `false` | no |
| custom\_data\_identifiers | Map of custom data identifier configurations. Each key is the identifier name. At least one of regex or keywords must be specified | <pre>map(object({<br/>    regex                  = optional(string)<br/>    keywords               = optional(list(string))<br/>    ignore_words           = optional(list(string))<br/>    maximum_match_distance = optional(number)<br/>    description            = optional(string)<br/>  }))</pre> | `{}` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| finding\_publishing\_frequency | Frequency at which Macie publishes updates to policy findings. Valid values: FIFTEEN\_MINUTES, ONE\_HOUR, SIX\_HOURS | `string` | `"FIFTEEN_MINUTES"` | no |
| member\_accounts | Map of member account configurations to associate with Macie. Each key is a friendly identifier | <pre>map(object({<br/>    account_id                 = string<br/>    email                      = string<br/>    invite                     = optional(bool, true)<br/>    invitation_message         = optional(string, "Macie member invitation")<br/>    disable_email_notification = optional(bool, true)<br/>    status                     = optional(string, "ENABLED")<br/>  }))</pre> | `{}` | no |
| name | Name identifier for the Macie deployment, used for naming and tagging conventions | `string` | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| account\_arn | ARN of the Macie account (service-linked role ARN) |
| account\_id | ID of the Macie account |
| classification\_export\_configuration\_id | ID of the classification export configuration |
| classification\_job\_arns | Map of classification job names to their ARNs |
| classification\_job\_ids | Map of classification job names to their IDs |
| custom\_data\_identifier\_arns | Map of custom data identifier names to their ARNs |
| custom\_data\_identifier\_ids | Map of custom data identifier names to their IDs |
| member\_account\_ids | Map of member account friendly names to their account IDs |
| name | Name identifier for the Macie deployment |
| organization\_admin\_account\_id | AWS account ID of the Macie delegated administrator account |
| organization\_configuration\_auto\_enable | Whether the Macie organization configuration auto-enables new member accounts |
<!-- END_TF_DOCS -->

</details>
