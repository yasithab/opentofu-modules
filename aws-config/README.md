# AWS Config

Deploys AWS Config with a configuration recorder, delivery channel, managed/custom/Guard-backed rules, tag enforcement, retention policies, and multi-account aggregation support.

## Features

- **Configuration Recorder** - Records resource configurations with configurable recording groups, modes, and global resource handling for multi-region deployments
- **Delivery Channel** - Delivers configuration history and snapshots to S3 with optional SNS notifications and KMS encryption
- **Managed Rules** - Deploy AWS managed Config rules by map key convention, with per-rule scoping, evaluation modes, and enable/disable toggles
- **Custom Rules** - Support for Lambda-backed and AWS CloudFormation Guard-backed custom policy rules
- **Tag Enforcement** - Convenience variable to auto-generate a REQUIRED_TAGS rule from a simple key-value map
- **Configuration Aggregator** - Central account aggregation across accounts or entire AWS Organizations
- **Aggregator Authorization** - Child account authorization for cross-account Config data collection
- **IAM Role Management** - Automatic creation of the Config service IAM role, or bring your own
- **Retention Configuration** - Configurable history retention period (30 to 2557 days)

## Usage

```hcl
module "aws_config" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//aws-config?depth=1&ref=master"

  name                         = "my-config"
  delivery_channel_s3_bucket_name = "my-config-bucket"

  required_tags = {
    Environment = ""
    ManagedBy   = "opentofu"
  }

  managed_rules = {
    ENCRYPTED_VOLUMES = {
      description = "Checks whether attached EBS volumes are encrypted"
    }
  }

  tags = {
    Environment = "production"
  }
}
```


## Examples

## Basic Usage

Enables AWS Config in a single account with S3 delivery, continuous recording of all supported resource types, and a handful of standard managed rules.

```hcl
module "aws_config" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//aws-config?depth=1&ref=master"

  enabled = true
  name    = "platform"

  delivery_channel_s3_bucket_name = "my-org-config-history-us-east-1"
  delivery_channel_s3_key_prefix  = "aws-config"

  managed_rules = {
    CLOUD_TRAIL_ENABLED = {
      description = "Checks that AWS CloudTrail is enabled."
    }
    ROOT_ACCOUNT_MFA_ENABLED = {
      description = "Checks whether the root user of your AWS account requires multi-factor authentication for console sign-in."
    }
    S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED = {
      description = "Checks that your Amazon S3 bucket either has Amazon S3 default encryption enabled."
    }
  }

  tags = {
    Environment = "production"
    Team        = "security"
  }
}
```

## With Tag Enforcement and Encrypted Delivery

Adds a `REQUIRED_TAGS` managed rule that enforces mandatory tags on EC2 and RDS resources, and encrypts Config history in S3 with a KMS key.

```hcl
module "aws_config_tags" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//aws-config?depth=1&ref=master"

  enabled = true
  name    = "platform"

  delivery_channel_s3_bucket_name  = "my-org-config-history-us-east-1"
  delivery_channel_s3_key_prefix   = "aws-config"
  delivery_channel_s3_kms_key_arn  = "arn:aws:kms:us-east-1:123456789012:key/mrk-1234abcd-12ab-34cd-56ef-1234567890ab"
  delivery_channel_sns_topic_arn   = "arn:aws:sns:us-east-1:123456789012:config-notifications"
  snapshot_delivery_frequency      = "Six_Hours"

  # Automatically creates a REQUIRED_TAGS managed Config rule
  required_tags = {
    Environment = "production"
    Team        = ""    # any value is acceptable
    CostCenter  = ""
  }
  required_tags_resource_types = [
    "AWS::EC2::Instance",
    "AWS::RDS::DBInstance",
  ]

  managed_rules = {
    CLOUD_TRAIL_ENABLED = {}
    ENCRYPTED_VOLUMES = {
      description = "Checks whether EBS volumes that are in an attached state are encrypted."
    }
  }

  tags = {
    Environment = "production"
    Team        = "security"
  }
}
```

## Multi-Region Setup with Global Resource Collector

In multi-region deployments, designates `us-east-1` as the single region that records global resources (IAM) to avoid duplicate Config items. Child regions set `global_resource_collector_region` to the same value but skip creating global records themselves.

```hcl
# -- Primary region (us-east-1) -----------------------------------------------
module "aws_config_primary" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//aws-config?depth=1&ref=master"

  enabled = true
  name    = "platform"

  global_resource_collector_region = "us-east-1"   # this region records IAM resources

  delivery_channel_s3_bucket_name = "my-org-config-history-us-east-1"

  recording_mode = {
    recording_frequency = "CONTINUOUS"
  }

  managed_rules = {
    CLOUD_TRAIL_ENABLED = {}
  }

  tags = {
    Environment = "production"
    Team        = "security"
    Region      = "us-east-1"
  }
}

# -- Secondary region (eu-west-1) ---------------------------------------------
module "aws_config_secondary" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//aws-config?depth=1&ref=master"

  enabled = true
  name    = "platform"

  global_resource_collector_region = "us-east-1"   # suppresses IAM recording here

  delivery_channel_s3_bucket_name = "my-org-config-history-eu-west-1"

  tags = {
    Environment = "production"
    Team        = "security"
    Region      = "eu-west-1"
  }
}
```

## Central Aggregator (Security Account)

Creates a configuration aggregator in a central security account that collects Config data from all member accounts across all regions.

```hcl
module "aws_config_aggregator" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//aws-config?depth=1&ref=master"

  enabled = true
  name    = "security-aggregator"

  delivery_channel_s3_bucket_name = "my-org-config-history-us-east-1"

  create_aggregator = true
  aggregator_organization = {
    all_aws_regions = true
  }

  retention_period_in_days = 365

  tags = {
    Environment = "production"
    Team        = "security"
    Role        = "aggregator"
  }
}
```
