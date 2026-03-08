# AWS Config Conformance Pack Module - Examples

## Basic Usage (Inline Template)

Deploys an account-level conformance pack using an inline YAML template. Useful when the template is small and managed in the same repository.

```hcl
module "config_conformance_pack" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//aws-config/modules/conformance-pack?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//aws-config/modules/conformance-pack?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//aws-config/modules/conformance-pack?depth=1&ref=v2.0.0"

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
