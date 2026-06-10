# KMS

OpenTofu module for managing AWS KMS keys with support for standard, external, replica, and multi-region key types, along with aliases, grants, and fine-grained key policies.

## Features

- **Multiple key types** - standard symmetric, external (bring your own key material), replica, and replica external keys
- **Multi-region support** - create primary multi-region keys that can be replicated across AWS regions
- **Asymmetric key support** - RSA, ECC, and HMAC key specs for signing, encryption, and MAC generation
- **Fine-grained key policies** - built-in policy statements for key owners, administrators, users, service users, and autoscaling roles
- **Aliases and grants** - manage key aliases (static and computed) and grants with optional encryption context constraints
- **Route53 DNSSEC** - pre-built policy support for Route53 DNSSEC signing
- **Custom key store** - deploy keys to CloudHSM-backed custom key stores or external key stores (XKS)

## Usage

```hcl
module "kms" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kms?depth=1&ref=master"

  description         = "CMK for application secrets"
  aliases             = ["my-app-key"]
  enable_key_rotation = true

  key_administrators = ["arn:aws:iam::123456789012:role/KMSAdminRole"]
  key_users          = ["arn:aws:iam::123456789012:role/AppRole"]

  tags = {
    Environment = "production"
  }
}
```


## Examples

## Basic Usage

Create a symmetric CMK with automatic key rotation and a friendly alias.

```hcl
module "kms" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kms?depth=1&ref=master"

  enabled = true

  description         = "CMK for application secrets encryption"
  aliases             = ["my-app-key"]
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
  source = "git::https://github.com/yasithab/opentofu-modules.git//kms?depth=1&ref=master"

  enabled = true

  description             = "Multi-region CMK for cross-region replication"
  multi_region            = true
  aliases                 = ["my-app-mrk"]
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
  source = "git::https://github.com/yasithab/opentofu-modules.git//kms?depth=1&ref=master"

  enabled = true

  description              = "RSA key for JWT token signing"
  customer_master_key_spec = "RSA_2048"
  key_usage                = "SIGN_VERIFY"
  aliases                  = ["jwt-signing-key"]
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
  source = "git::https://github.com/yasithab/opentofu-modules.git//kms?depth=1&ref=master"

  enabled = true

  description              = "CMK for Route53 DNSSEC signing"
  customer_master_key_spec = "ECC_NIST_P256"
  key_usage                = "SIGN_VERIFY"
  aliases                  = ["route53-dnssec-key"]
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

## Variable Notes

### Policy sources

The key policy is built from `policy` (verbatim JSON, takes precedence) or the generated
`aws_iam_policy_document` composed of `source_policy_documents`, `override_policy_documents`,
the built-in statements (`enable_default_policy`, `key_owners`, `key_administrators`, `key_users`,
`key_service_users`, `key_service_roles_for_autoscaling`, `key_*_users`, `enable_route53_dnssec`)
and `key_statements`.

When `enable_default_policy = false`, at least one other policy source **must** be provided —
the module fails validation otherwise. This prevents creating a key with an empty policy,
which would make the key unmanageable.

### `key_statements` schema

`key_statements` is a fully typed `list(object)`; unknown attributes are rejected.

```hcl
key_statements = [
  {
    sid           = optional(string)
    effect        = optional(string)        # "Allow" or "Deny"
    actions       = optional(list(string))
    not_actions   = optional(list(string))
    resources     = optional(list(string))
    not_resources = optional(list(string))
    principals = optional(list(object({
      type        = string                  # e.g. "AWS", "Service"
      identifiers = list(string)
    })), [])
    not_principals = optional(list(object({
      type        = string
      identifiers = list(string)
    })), [])
    conditions = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })), [])
  }
]
```

### Typed maps

- `grants` is a typed `map(object)` — see `variables.tf` for the full schema. Unknown attributes are rejected.
- `computed_aliases` is `map(object({ name = string }))`.
- `key_material_base64` is marked `sensitive` and is stored in the OpenTofu state — protect state access accordingly.
