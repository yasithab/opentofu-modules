# Service Control Policy Module - Examples

## Basic Policy: Deny Root Account and Leaving the Organisation

Create a foundational SCP that prevents the use of root credentials and stops member accounts from leaving the AWS Organisation, attached to specific OUs.

```hcl
module "scp_baseline" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//service-control-policy?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//service-control-policy?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//service-control-policy?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//service-control-policy?depth=1&ref=v2.0.0"

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
