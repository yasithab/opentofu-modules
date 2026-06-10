# Service Control Policy

OpenTofu module to create and attach AWS Organizations Service Control Policies (SCPs) with a library of pre-built security guardrails.

## Features

- **Pre-Built Security Guardrails** - Toggle-based boolean variables to enable common SCP rules without writing any policy JSON
- **Deny Leaving Organization** - Prevents member accounts from leaving the AWS Organization
- **Deny Creating IAM Users** - Blocks creation of IAM users and access keys to enforce federated access
- **Deny Deleting KMS Keys** - Protects KMS keys from deletion or scheduled deletion
- **Deny Deleting Route53 Zones** - Prevents accidental deletion of Route53 hosted zones
- **Deny Deleting CloudWatch Logs** - Protects VPC flow logs, log groups, and log streams from deletion
- **Deny Root Account** - Blocks all actions by the root user
- **Protect S3 Buckets** - Prevents deletion of specified S3 buckets and objects
- **Deny S3 Public Access** - Blocks changes to S3 bucket public access settings
- **Protect IAM Roles** - Prevents modification or deletion of specified IAM roles
- **Limit EC2 Instance Types** - Restricts EC2 usage to an approved list of instance types
- **Limit Regions** - Restricts operations to approved AWS regions while exempting global services
- **Require S3 Encryption** - Denies unencrypted S3 object uploads and enforces encryption headers
- **Deny Network Modifications** - Blocks changes to network ACLs and security groups
- **Deny VPC Modifications** - Prevents creation, deletion, or modification of VPCs and peering connections
- **Require MFA** - Enforces multi-factor authentication for sensitive IAM actions
- **Enforce CloudTrail Logging** - Prevents stopping or deleting CloudTrail trails
- **Enforce Resource Tagging** - Denies resource creation without required tags on specified actions
- **Deny All Access** - Option to create a full deny-all SCP for quarantine scenarios
- **Flexible Attachment** - Attach the policy to specific OUs via `attach_ous`, or to the entire organization root by setting `attach_to_org = true`
- **Skip Destroy** - Option to protect the policy from accidental deletion during destroy operations

## Usage

```hcl
module "scp" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//service-control-policy?depth=1&ref=master"

  name        = "security-guardrails"
  description = "Baseline security guardrails for all accounts"

  deny_leaving_orgs          = true
  deny_creating_iam_users    = true
  deny_root_account          = true
  enforce_cloudtrail_logging = true
  require_s3_encryption      = true

  limit_regions   = true
  allowed_regions = ["us-east-1", "us-west-2"]

  attach_ous = ["ou-abc1-12345678"]

  tags = {
    Environment = "organization"
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
| allowed\_ec2\_instance\_types | EC2 instance types allowed for use | `list(string)` | `[]` | no |
| allowed\_regions | AWS Regions allowed for use | `list(string)` | `[]` | no |
| attach\_ous | List of OU IDs to attach the tag policies to | `list(string)` | `[]` | no |
| attach\_to\_org | Whether to attach the tag policy to the organization (set to false if you want to attach to OUs) | `bool` | `false` | no |
| deny\_all | If false, create a combined policy. If true, deny all access | `bool` | `false` | no |
| deny\_creating\_iam\_users | Deny creating IAM users | `bool` | `false` | no |
| deny\_deleting\_cloudwatch\_logs | Deny deleting CloudWatch logs | `bool` | `false` | no |
| deny\_deleting\_kms\_keys | Deny deleting KMS keys | `bool` | `false` | no |
| deny\_deleting\_route53\_zones | Deny deleting Route53 zones | `bool` | `false` | no |
| deny\_leaving\_orgs | Deny leaving AWS Organizations | `bool` | `false` | no |
| deny\_network\_modifications | Deny modifications to network ACLs and security groups | `bool` | `false` | no |
| deny\_root\_account | Deny root account access | `bool` | `false` | no |
| deny\_s3\_bucket\_public\_access\_resources | S3 bucket resource ARNs to block public access | `list(string)` | `[]` | no |
| deny\_s3\_buckets\_public\_access | Deny S3 buckets public access | `bool` | `false` | no |
| deny\_vpc\_modifications | Deny modifications to VPC configurations | `bool` | `false` | no |
| description | Description of the service control policy | `string` | `null` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| enforce\_cloudtrail\_logging | Enforce continuous CloudTrail logging | `bool` | `false` | no |
| enforce\_resource\_tagging | Enforce tagging on resource creation | `bool` | `false` | no |
| limit\_ec2\_instance\_types | Limit allowed EC2 instance types | `bool` | `false` | no |
| limit\_regions | Limit allowed AWS regions | `bool` | `false` | no |
| name | Name to use for resource naming and tagging. | `string` | n/a | yes |
| protect\_iam\_role\_resources | IAM role resource ARNs to protect | `list(string)` | `[]` | no |
| protect\_iam\_roles | Protect IAM roles from modification | `bool` | `false` | no |
| protect\_s3\_bucket\_resources | S3 bucket resource ARNs to protect | `list(string)` | `[]` | no |
| protect\_s3\_buckets | Protect S3 buckets from deletion | `bool` | `false` | no |
| require\_mfa | Require Multi-Factor Authentication for sensitive actions | `bool` | `false` | no |
| require\_s3\_encryption | Require S3 bucket encryption | `bool` | `false` | no |
| required\_tag\_keys | List of tags to enforce on resources | `list(string)` | `[]` | no |
| skip\_destroy | If set to true, the policy will not be deleted when the resource is destroyed. This is useful to prevent accidental deletion of SCPs that are attached to the organization. | `bool` | `false` | no |
| tag\_enforcement\_actions | List of actions to enforce tagging on | `list(string)` | `[]` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| attached\_org\_root\_id | Organization root ID the policy is attached to if the policy is attached to the root |
| attached\_ou\_ids | List of OU IDs the policy is attached to |
| policy\_arn | The ARN of the created SCP |
| policy\_id | ID of the created service control policy |
| policy\_type | The type of the policy |
<!-- END_TF_DOCS -->

## Examples

## Basic Policy: Deny Root Account and Leaving the Organisation

Create a foundational SCP that prevents the use of root credentials and stops member accounts from leaving the AWS Organisation, attached to specific OUs.

```hcl
module "scp_baseline" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//service-control-policy?depth=1&ref=master"

  name        = "scp-baseline-guardrails"
  description = "Baseline guardrails applied to all workload OUs"

  deny_root_account  = true
  deny_leaving_orgs  = true

  attach_ous = [
    "ou-abcd-12345678",
    "ou-efgh-87654321",
  ]

  tags = {
    Environment = "all"
    Team        = "security"
  }
}
```

## Security Hardening Policy

Enforce CloudTrail logging, require MFA for sensitive IAM actions, deny KMS key deletion, and protect critical S3 buckets from accidental removal.

```hcl
module "scp_security" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//service-control-policy?depth=1&ref=master"

  name        = "scp-security-hardening"
  description = "Security hardening controls for production OU"

  enforce_cloudtrail_logging = true
  require_mfa                = true
  deny_deleting_kms_keys     = true
  deny_deleting_route53_zones = true
  deny_deleting_cloudwatch_logs = true

  protect_s3_buckets = true
  protect_s3_bucket_resources = [
    "arn:aws:s3:::my-cloudtrail-logs-prod",
    "arn:aws:s3:::my-cloudtrail-logs-prod/*",
    "arn:aws:s3:::my-compliance-archive-prod",
    "arn:aws:s3:::my-compliance-archive-prod/*",
  ]

  skip_destroy = true

  attach_ous = ["ou-abcd-11111111"]

  tags = {
    Environment = "production"
    Team        = "security"
    Sensitivity = "critical"
  }
}
```

## Region Restriction Policy

Limit all account activity to approved AWS regions, preventing accidental or unauthorised resource creation in other regions.

```hcl
module "scp_region_lock" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//service-control-policy?depth=1&ref=master"

  name        = "scp-region-restriction"
  description = "Restrict workloads to approved AWS regions only"

  limit_regions   = true
  allowed_regions = ["eu-west-1", "eu-central-1", "us-east-1"]

  attach_ous = [
    "ou-abcd-12345678",
    "ou-efgh-87654321",
  ]

  tags = {
    Environment = "all"
    Team        = "platform"
  }
}
```

## Deny All - Emergency Lockout Policy

Create a deny-all SCP used as an emergency lockout for a compromised or decommissioned OU.

```hcl
module "scp_deny_all" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//service-control-policy?depth=1&ref=master"

  name        = "scp-emergency-lockout"
  description = "Deny all actions - used for emergency account isolation"

  deny_all = true

  attach_ous = ["ou-abcd-99999999"]

  tags = {
    Environment = "quarantine"
    Team        = "security"
    Reason      = "incident-response"
  }
}
```

## Notes

### `require_s3_encryption` and the SSE header conditions

The `require_s3_encryption` toggle adds two statements: `DenyUnEncryptedObjectUploads`
(denies `s3:PutObject` when the `s3:x-amz-server-side-encryption` header is absent) and
`DenyIncorrectEncryptionHeader` (denies the upload when the header is present but not
`AES256` or `aws:kms`).

Since January 2023, **Amazon S3 encrypts all new objects by default** (SSE-S3), even when no
encryption header is sent. As a consequence:

- Uploads without the header are already encrypted; denying them mainly *breaks* clients and
  SDKs that (correctly) omit the header and rely on bucket/account default encryption.
- If your intent is to require **SSE-KMS specifically**, prefer bucket policies or bucket
  default-encryption configuration over this header-matching SCP.

Keep this toggle only if you have a compliance requirement for the explicit header; otherwise
rely on S3 default encryption.

### Module behaviour

- `enabled = false` skips creation of the policy and all attachments.
- At least one statement toggle (or `deny_all = true`) is required - an SCP with an empty
  statement list is rejected by AWS at apply time, so the module fails fast at plan instead.
- `name` is required.
