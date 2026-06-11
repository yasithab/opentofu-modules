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

## Notes

- `recording_group` and `recording_mode` are typed objects with `optional()` attributes
  (previously `any`). Existing object-shaped inputs keep working unchanged.
- `recording_mode` now defaults to `null` (no `recording_mode` block managed, AWS default
  CONTINUOUS applies). Passing an empty object `{}` now manages an explicit
  `recording_mode` block with `recording_frequency = "CONTINUOUS"`; previously `{}` was
  treated the same as unset.
- IAM policy and S3 ARNs are built with the current AWS partition (`aws`, `aws-cn`,
  `aws-us-gov`) via `data.aws_partition`.

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
| terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| aggregator\_account\_id | AWS account ID of the central Config aggregator. Required when create\_aggregator\_authorization = true. | `string` | `null` | no |
| aggregator\_account\_region | AWS region where the central Config aggregator resides. Defaults to the current region when not set. | `string` | `null` | no |
| aggregator\_accounts | Account-level aggregation source. Set account\_ids and aws\_regions (or all\_aws\_regions = true). | <pre>object({<br/>    account_ids     = list(string)<br/>    aws_regions     = optional(list(string))<br/>    all_aws_regions = optional(bool, false)<br/>  })</pre> | `null` | no |
| aggregator\_name | Name for the configuration aggregator. Defaults to recorder\_name + '-aggregator'. | `string` | `null` | no |
| aggregator\_organization | Organization-level aggregation source. Set aws\_regions (or all\_aws\_regions = true) and<br/>optionally role\_arn to override the default service-linked role. | <pre>object({<br/>    aws_regions     = optional(list(string))<br/>    all_aws_regions = optional(bool, false)<br/>    role_arn        = optional(string)<br/>  })</pre> | `null` | no |
| create\_aggregator | Whether to create a configuration aggregator (central/security account). | `bool` | `false` | no |
| create\_aggregator\_authorization | Set to true in child/member accounts to authorize a central aggregator account<br/>to collect Config data from this account. Supply aggregator\_account\_id and<br/>aggregator\_account\_region alongside this flag. | `bool` | `false` | no |
| create\_iam\_role | Whether to create an IAM role for the AWS Config service. Set to false and supply iam\_role\_arn to use an existing role. | `bool` | `true` | no |
| custom\_policy\_rules | Map of custom policy (AWS Guard-backed) Config rules to create. The map key is used<br/>as the rule name. policy\_text must contain the AWS CloudFormation Guard policy and<br/>policy\_runtime must be set (currently only "guard-2.x.x" is supported).<br/>Set enabled = false on any entry to skip that rule without removing it from the map. | <pre>map(object({<br/>    description                 = optional(string)<br/>    policy_runtime              = string<br/>    policy_text                 = string<br/>    enable_debug_log_delivery   = optional(bool, false)<br/>    input_parameters            = optional(string)<br/>    maximum_execution_frequency = optional(string)<br/>    resource_types_scope        = optional(list(string), [])<br/>    compliance_resource_id      = optional(string)<br/>    tag_key_scope               = optional(string)<br/>    tag_value_scope             = optional(string)<br/>    evaluation_mode             = optional(string)<br/>    source_details = optional(list(object({<br/>      event_source                = optional(string)<br/>      message_type                = optional(string)<br/>      maximum_execution_frequency = optional(string)<br/>    })), [])<br/>    tags    = optional(map(string), {})<br/>    enabled = optional(bool, true)<br/>  }))</pre> | `{}` | no |
| custom\_rules | Map of custom (Lambda-backed) Config rules to create. The map key is used as the<br/>rule name. source\_identifier must be set to the Lambda function ARN.<br/>Set enabled = false on any entry to skip that rule without removing it from the map.<br/>source\_details supports a list of objects with optional event\_source, message\_type,<br/>and maximum\_execution\_frequency for advanced trigger configuration. | <pre>map(object({<br/>    description                 = optional(string)<br/>    source_identifier           = string<br/>    input_parameters            = optional(string)<br/>    maximum_execution_frequency = optional(string)<br/>    resource_types_scope        = optional(list(string), [])<br/>    compliance_resource_id      = optional(string)<br/>    tag_key_scope               = optional(string)<br/>    tag_value_scope             = optional(string)<br/>    evaluation_mode             = optional(string)<br/>    source_details = optional(list(object({<br/>      event_source                = optional(string)<br/>      message_type                = optional(string)<br/>      maximum_execution_frequency = optional(string)<br/>    })), [])<br/>    tags    = optional(map(string), {})<br/>    enabled = optional(bool, true)<br/>  }))</pre> | `{}` | no |
| delivery\_channel\_s3\_bucket\_name | Name of the S3 bucket for AWS Config history and snapshots. The module does not create this bucket. | `string` | `null` | no |
| delivery\_channel\_s3\_key\_prefix | S3 key prefix for AWS Config delivery. | `string` | `null` | no |
| delivery\_channel\_s3\_kms\_key\_arn | KMS key ARN used to encrypt Config history objects in S3. | `string` | `null` | no |
| delivery\_channel\_sns\_topic\_arn | SNS topic ARN for AWS Config change notifications. | `string` | `null` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| global\_resource\_collector\_region | AWS region that is responsible for recording global resources (IAM users, roles,<br/>policies, etc.). When set, include\_global\_resource\_types is automatically enabled<br/>only in this region, preventing duplicate config items in multi-region deployments.<br/>When null, the value from recording\_group.include\_global\_resource\_types is used. | `string` | `null` | no |
| iam\_role\_arn | ARN of an existing IAM role to use for the configuration recorder. Required when create\_iam\_role is false. | `string` | `null` | no |
| iam\_role\_name | Override the IAM role name. Defaults to recorder\_name + '-config-role'. | `string` | `null` | no |
| managed\_rules | Map of AWS managed Config rules to create. The map key is used as the rule name<br/>and as the source\_identifier unless source\_identifier is explicitly overridden.<br/>Set enabled = false on any entry to skip that rule without removing it from the map.<br/>source\_details supports a list of objects with optional event\_source, message\_type,<br/>and maximum\_execution\_frequency for advanced trigger configuration. | <pre>map(object({<br/>    description                 = optional(string)<br/>    source_identifier           = optional(string)<br/>    input_parameters            = optional(string)<br/>    maximum_execution_frequency = optional(string)<br/>    resource_types_scope        = optional(list(string), [])<br/>    compliance_resource_id      = optional(string)<br/>    tag_key_scope               = optional(string)<br/>    tag_value_scope             = optional(string)<br/>    evaluation_mode             = optional(string)<br/>    source_details = optional(list(object({<br/>      event_source                = optional(string)<br/>      message_type                = optional(string)<br/>      maximum_execution_frequency = optional(string)<br/>    })), [])<br/>    tags    = optional(map(string), {})<br/>    enabled = optional(bool, true)<br/>  }))</pre> | `{}` | no |
| name | Naming base used for the configuration recorder and delivery channel when recorder\_name is not set. | `string` | `null` | no |
| recorder\_name | Override the configuration recorder (and delivery channel) name. Falls back to var.name then 'default'. | `string` | `null` | no |
| recording\_group | Configuration recorder recording group settings.<br/>Supports all\_supported, include\_global\_resource\_types (overridden by<br/>global\_resource\_collector\_region when set), exclusion\_by\_resource\_types,<br/>and recording\_strategy sub-objects. | <pre>object({<br/>    all_supported                 = optional(bool, true)<br/>    include_global_resource_types = optional(bool, false)<br/>    exclusion_by_resource_types = optional(object({<br/>      resource_types = list(string)<br/>    }))<br/>    recording_strategy = optional(object({<br/>      use_only = string<br/>    }))<br/>  })</pre> | `{}` | no |
| recording\_mode | Recording mode configuration. Set recording\_frequency to CONTINUOUS or DAILY.<br/>Optionally supply recording\_mode\_override list for per-resource-type overrides.<br/>Set to null (the default) to use the AWS default (CONTINUOUS) without managing<br/>a recording\_mode block. | <pre>object({<br/>    recording_frequency = optional(string, "CONTINUOUS")<br/>    recording_mode_override = optional(list(object({<br/>      description         = optional(string)<br/>      recording_frequency = string<br/>      resource_types      = list(string)<br/>    })), [])<br/>  })</pre> | `null` | no |
| required\_tags | Map of tags that must be present on AWS resources. Key = tag name; value = required<br/>tag value (set to "" or null to accept any value). When non-empty, a REQUIRED\_TAGS<br/>managed Config rule is automatically created.<br/>Override or disable the auto-rule by adding REQUIRED\_TAGS = { enabled = false } to<br/>the managed\_rules variable. | `map(string)` | `{}` | no |
| required\_tags\_resource\_types | Limit the REQUIRED\_TAGS rule to these resource types (e.g. ["AWS::EC2::Instance"]). Empty list = all supported types. | `list(string)` | `[]` | no |
| retention\_period\_in\_days | Number of days AWS Config retains configuration history. Must be between 30 and 2557. Set to null to skip creating a retention configuration. | `number` | `2557` | no |
| snapshot\_delivery\_frequency | How often AWS Config delivers configuration snapshots. Valid values: One\_Hour \| Three\_Hours \| Six\_Hours \| Twelve\_Hours \| TwentyFour\_Hours. | `string` | `"TwentyFour_Hours"` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| configuration\_aggregator\_arn | ARN of the configuration aggregator. Empty when create\_aggregator is false. |
| configuration\_aggregator\_authorization\_id | ID of the aggregator authorization created in this (child) account. Empty when create\_aggregator\_authorization is false. |
| configuration\_aggregator\_id | ID of the configuration aggregator. Empty when create\_aggregator is false. |
| configuration\_recorder\_id | The name (ID) of the AWS Config configuration recorder. |
| custom\_config\_rule\_arns | Map of custom Config rule name to ARN. |
| custom\_policy\_config\_rule\_arns | Map of custom policy (Guard-backed) Config rule name to ARN. |
| delivery\_channel\_id | The name (ID) of the AWS Config delivery channel. |
| iam\_role\_arn | ARN of the IAM role used by the configuration recorder (created or provided). |
| iam\_role\_name | Name of the IAM role used by the configuration recorder. Empty when an external role is supplied. |
| managed\_config\_rule\_arns | Map of managed Config rule name to ARN. |
<!-- END_TF_DOCS -->

</details>
