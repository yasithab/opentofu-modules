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
