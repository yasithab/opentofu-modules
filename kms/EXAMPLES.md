# KMS Module - Examples

## Basic Usage

Create a symmetric CMK with automatic key rotation and a friendly alias.

```hcl
module "kms" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kms?depth=1&ref=v2.0.0"

  enabled = true

  description         = "CMK for application secrets encryption"
  aliases             = ["alias/my-app-key"]
  enable_key_rotation = true

  key_administrators = ["arn:aws:iam::123456789012:role/KMSAdminRole"]
  key_users          = ["arn:aws:iam::123456789012:role/AppRole"]

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Multi-Region Key

Create a multi-region primary key that can be replicated to other regions.

```hcl
module "kms_multi_region" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kms?depth=1&ref=v2.0.0"

  enabled = true

  description             = "Multi-region CMK for cross-region replication"
  multi_region            = true
  aliases                 = ["alias/my-app-mrk"]
  deletion_window_in_days = 14
  enable_key_rotation     = true
  rotation_period_in_days = 180

  key_administrators = ["arn:aws:iam::123456789012:role/KMSAdminRole"]
  key_users          = [
    "arn:aws:iam::123456789012:role/AppRole",
    "arn:aws:iam::123456789012:role/DataRole"
  ]

  tags = {
    Environment = "production"
    Purpose     = "cross-region"
  }
}
```

## Asymmetric Key for Signing

Create an RSA key pair for digital signing.

```hcl
module "kms_signing_key" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kms?depth=1&ref=v2.0.0"

  enabled = true

  description              = "RSA key for JWT token signing"
  customer_master_key_spec = "RSA_2048"
  key_usage                = "SIGN_VERIFY"
  aliases                  = ["alias/jwt-signing-key"]
  enable_key_rotation      = false

  key_administrators             = ["arn:aws:iam::123456789012:role/KMSAdminRole"]
  key_asymmetric_sign_verify_users = ["arn:aws:iam::123456789012:role/AuthServiceRole"]

  tags = {
    Environment = "production"
    Purpose     = "jwt-signing"
  }
}
```

## With Route53 DNSSEC and Key Grants

Enable DNSSEC signing support and create a grant for an external service.

```hcl
module "kms_dnssec" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kms?depth=1&ref=v2.0.0"

  enabled = true

  description              = "CMK for Route53 DNSSEC signing"
  customer_master_key_spec = "ECC_NIST_P256"
  key_usage                = "SIGN_VERIFY"
  aliases                  = ["alias/route53-dnssec-key"]
  enable_key_rotation      = false
  enable_route53_dnssec    = true

  route53_dnssec_sources = [
    {
      account_ids      = ["123456789012"]
      hosted_zone_arn  = "arn:aws:route53:::hostedzone/Z1D633PJN98FT9"
    }
  ]

  key_administrators = ["arn:aws:iam::123456789012:role/KMSAdminRole"]

  grants = {
    route53_grant = {
      grantee_principal = "arn:aws:iam::123456789012:role/Route53DnssecRole"
      operations        = ["Sign", "GetPublicKey", "DescribeKey"]
    }
  }

  tags = {
    Environment = "production"
    Purpose     = "dnssec"
  }
}
```
