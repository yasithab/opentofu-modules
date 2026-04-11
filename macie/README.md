# Amazon Macie

OpenTofu module for provisioning and managing Amazon Macie sensitive data discovery with classification jobs, custom data identifiers, allow lists, and multi-account support.

## Features

- **Macie Account** - Enable Macie with configurable finding publishing frequency for sensitive data discovery and protection
- **Classification Jobs** - Schedule one-time or recurring sensitive data discovery jobs targeting specific S3 buckets with scoping filters
- **Custom Data Identifiers** - Define custom regex patterns and keyword-based identifiers for organization-specific sensitive data types
- **Allow Lists** - Create S3-backed word lists or regex-based allow lists to exclude known acceptable data patterns from findings
- **Member Account Management** - Invite and manage member accounts for centralized sensitive data discovery across the organization
- **Classification Export** - Export classification results to an S3 bucket with KMS encryption for long-term retention and compliance

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
