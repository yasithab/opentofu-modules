# AWS Config Conformance Pack

OpenTofu module to create an AWS Config conformance pack at the account level or organization level. Conformance packs are collections of AWS Config rules and remediation actions that can be deployed as a single entity.

## Features

- **Account-Level Packs** - Create conformance packs scoped to a single AWS account
- **Organization-Level Packs** - Optionally create organization conformance packs that apply across all member accounts in AWS Organizations
- **Flexible Templates** - Provide conformance pack templates inline via `template_body` or from S3 via `template_s3_uri`
- **Input Parameters** - Pass parameters to the conformance pack template for customization
- **S3 Delivery** - Optionally configure an S3 bucket and key prefix for conformance pack results
- **Account Exclusions** - Exclude specific AWS account IDs from organization conformance packs
- **Lifecycle Management** - Toggle resource creation with the `enabled` variable

## Usage

### Account-Level Conformance Pack

```hcl
module "conformance_pack" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//aws-config/modules/conformance-pack?depth=1&ref=master"

  name          = "security-best-practices"
  template_body = file("${path.module}/templates/security-pack.yaml")

  input_parameters = {
    S3BucketName = "my-config-bucket"
    MaxAge       = "90"
  }
}
```

### Organization Conformance Pack

```hcl
module "org_conformance_pack" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//aws-config/modules/conformance-pack?depth=1&ref=master"

  name                                 = "org-security-baseline"
  create_organization_conformance_pack = true
  template_s3_uri                      = "s3://my-config-bucket/templates/security-baseline.yaml"

  delivery_s3_bucket     = "my-config-results-bucket"
  delivery_s3_key_prefix = "conformance-packs"

  excluded_account_ids = ["111111111111", "222222222222"]

  input_parameters = {
    RequiredTagKey = "Environment"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Name for the conformance pack | `string` | n/a | yes |
| `template_body` | Inline YAML or JSON template body (exactly one of `template_body` or `template_s3_uri` must be provided) | `string` | `null` | no |
| `template_s3_uri` | S3 URI of the conformance pack template (exactly one of `template_body` or `template_s3_uri` must be provided) | `string` | `null` | no |
| `input_parameters` | Map of parameter name to value passed to the template | `map(string)` | `{}` | no |
| `delivery_s3_bucket` | S3 bucket for conformance pack results | `string` | `null` | no |
| `delivery_s3_key_prefix` | S3 key prefix for conformance pack delivery | `string` | `null` | no |
| `create_organization_conformance_pack` | Set to true to create an organization-level conformance pack | `bool` | `false` | no |
| `excluded_account_ids` | List of AWS account IDs to exclude from the organization conformance pack | `list(string)` | `[]` | no |
| `enabled` | Set to false to disable all resources in this module | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| `conformance_pack_arn` | ARN of the account-level conformance pack (null when organization pack) |
| `conformance_pack_id` | ID of the account-level conformance pack (null when organization pack) |
| `organization_conformance_pack_arn` | ARN of the organization conformance pack (null when account-level pack) |
| `organization_conformance_pack_id` | ID of the organization conformance pack (null when account-level pack) |


## Examples

## Basic Usage (Inline Template)

Deploys an account-level conformance pack using an inline YAML template. Useful when the template is small and managed in the same repository.

```hcl
module "config_conformance_pack" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//aws-config/modules/conformance-pack?depth=1&ref=master"

  enabled = true
  name    = "operational-best-practices-s3"

  template_body = <<-EOT
    Parameters:
      S3BucketPublicWriteProhibitedParamScope:
        Default: S3Bucket
        Type: String
    Resources:
      S3BucketPublicWriteProhibited:
        Type: AWS::Config::ConfigRule
        Properties:
          ConfigRuleName: S3BucketPublicWriteProhibited
          Source:
            Owner: AWS
            SourceIdentifier: S3_BUCKET_PUBLIC_WRITE_PROHIBITED
          Scope:
            ComplianceResourceTypes:
              - !Ref S3BucketPublicWriteProhibitedParamScope
  EOT
}
```

## With S3-Hosted Template and Parameters

Loads a conformance pack template stored in S3 and passes input parameters to customise its rules. Suitable for large or shared templates managed centrally.

```hcl
module "config_conformance_pack_s3" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//aws-config/modules/conformance-pack?depth=1&ref=master"

  enabled = true
  name    = "cis-aws-foundations-benchmark"

  template_s3_uri    = "s3://my-org-config-templates-us-east-1/conformance-packs/cis-aws-foundations-v1.4.0.yaml"
  delivery_s3_bucket = "my-org-config-history-us-east-1"
  delivery_s3_key_prefix = "conformance-packs"

  input_parameters = {
    AccessKeysRotatedParamMaxAccessKeyAge = "90"
    RootAccountMFAEnabledParam            = "true"
  }
}
```

## Organization Conformance Pack

Deploys the same conformance pack to all AWS Organization member accounts simultaneously, excluding sandbox and legacy accounts.

```hcl
module "config_org_conformance_pack" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//aws-config/modules/conformance-pack?depth=1&ref=master"

  enabled = true
  name    = "org-security-baseline"

  create_organization_conformance_pack = true

  template_s3_uri    = "s3://my-org-config-templates-us-east-1/conformance-packs/security-baseline.yaml"
  delivery_s3_bucket = "my-org-config-history-us-east-1"

  # Exclude accounts that are not subject to this policy
  excluded_account_ids = [
    "111122223333",  # sandbox
    "444455556666",  # legacy account under migration
  ]

  input_parameters = {
    RequiredTagKey   = "CostCenter"
    MaxRetentionDays = "365"
  }
}
```
