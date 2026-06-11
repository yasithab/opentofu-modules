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

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| aliases | A list of aliases to create. Note - due to the use of `toset()`, values must be static strings and not computed values | `list(string)` | `[]` | no |
| aliases\_use\_name\_prefix | Determines whether the alias name is used as a prefix | `bool` | `false` | no |
| bypass\_policy\_lockout\_safety\_check | A flag to indicate whether to bypass the key policy lockout safety check. Setting this value to true increases the risk that the KMS key becomes unmanageable | `bool` | `null` | no |
| computed\_aliases | A map of aliases to create. Values provided via the `name` key of the map can be computed from upstream resources | <pre>map(object({<br/>    name = string<br/>  }))</pre> | `{}` | no |
| create\_external | Determines whether an external CMK (externally provided material) will be created or a standard CMK (AWS provided material) | `bool` | `false` | no |
| create\_replica | Determines whether a replica standard CMK will be created (AWS provided material) | `bool` | `false` | no |
| create\_replica\_external | Determines whether a replica external CMK will be created (externally provided material) | `bool` | `false` | no |
| custom\_key\_store\_id | ID of the KMS Custom Key Store where the key will be stored instead of KMS (eg CloudHSM). | `string` | `null` | no |
| customer\_master\_key\_spec | Specifies whether the key contains a symmetric key or an asymmetric key pair and the encryption algorithms or signing algorithms that the key supports. Valid values: `SYMMETRIC_DEFAULT`, `RSA_2048`, `RSA_3072`, `RSA_4096`, `HMAC_256`, `ECC_NIST_P256`, `ECC_NIST_P384`, `ECC_NIST_P521`, or `ECC_SECG_P256K1`. Defaults to `SYMMETRIC_DEFAULT` | `string` | `null` | no |
| deletion\_window\_in\_days | The waiting period, specified in number of days. After the waiting period ends, AWS KMS deletes the KMS key. If you specify a value, it must be between `7` and `30`, inclusive. If you do not specify a value, it defaults to `30` | `number` | `null` | no |
| description | The description of the key as viewed in AWS console | `string` | `null` | no |
| enable\_default\_policy | Specifies whether to enable the default key policy. Defaults to `true` | `bool` | `true` | no |
| enable\_key\_rotation | Specifies whether key rotation is enabled. Defaults to `true` | `bool` | `true` | no |
| enable\_route53\_dnssec | Determines whether the KMS policy used for Route53 DNSSEC signing is enabled | `bool` | `false` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| grants | A map of grant definitions to create. The map key is used as the grant name when `name` is not set | <pre>map(object({<br/>    name              = optional(string)<br/>    grantee_principal = string<br/>    operations        = list(string)<br/>    constraints = optional(object({<br/>      encryption_context_equals = optional(map(string))<br/>      encryption_context_subset = optional(map(string))<br/>    }))<br/>    retiring_principal    = optional(string)<br/>    grant_creation_tokens = optional(list(string))<br/>    retire_on_delete      = optional(bool)<br/>  }))</pre> | `{}` | no |
| is\_enabled | Specifies whether the key is enabled. Defaults to `true` | `bool` | `null` | no |
| key\_administrators | A list of IAM ARNs for [key administrators](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-administrators) | `list(string)` | `[]` | no |
| key\_asymmetric\_public\_encryption\_users | A list of IAM ARNs for [key asymmetric public encryption users](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-users-crypto) | `list(string)` | `[]` | no |
| key\_asymmetric\_sign\_verify\_users | A list of IAM ARNs for [key asymmetric sign and verify users](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-users-crypto) | `list(string)` | `[]` | no |
| key\_hmac\_users | A list of IAM ARNs for [key HMAC users](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-users-crypto) | `list(string)` | `[]` | no |
| key\_material\_base64 | Base64 encoded 256-bit symmetric encryption key material to import. The CMK is permanently associated with this key material. External key only. Note: this value is stored in the OpenTofu state - protect your state accordingly | `string` | `null` | no |
| key\_owners | A list of IAM ARNs for those who will have full key permissions (`kms:*`) | `list(string)` | `[]` | no |
| key\_service\_roles\_for\_autoscaling | A list of IAM ARNs for [AWSServiceRoleForAutoScaling roles](https://docs.aws.amazon.com/autoscaling/ec2/userguide/key-policy-requirements-EBS-encryption.html#policy-example-cmk-access) | `list(string)` | `[]` | no |
| key\_service\_users | A list of IAM ARNs for [key service users](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-service-integration) | `list(string)` | `[]` | no |
| key\_statements | A list of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage | <pre>list(object({<br/>    sid           = optional(string)<br/>    effect        = optional(string)<br/>    actions       = optional(list(string))<br/>    not_actions   = optional(list(string))<br/>    resources     = optional(list(string))<br/>    not_resources = optional(list(string))<br/>    principals = optional(list(object({<br/>      type        = string<br/>      identifiers = list(string)<br/>    })), [])<br/>    not_principals = optional(list(object({<br/>      type        = string<br/>      identifiers = list(string)<br/>    })), [])<br/>    conditions = optional(list(object({<br/>      test     = string<br/>      variable = string<br/>      values   = list(string)<br/>    })), [])<br/>  }))</pre> | `[]` | no |
| key\_symmetric\_encryption\_users | A list of IAM ARNs for [key symmetric encryption users](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-users-crypto) | `list(string)` | `[]` | no |
| key\_usage | Specifies the intended use of the key. Valid values: `ENCRYPT_DECRYPT`, `SIGN_VERIFY`, or `GENERATE_VERIFY_MAC`. Defaults to `ENCRYPT_DECRYPT` | `string` | `null` | no |
| key\_users | A list of IAM ARNs for [key users](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-users) | `list(string)` | `[]` | no |
| multi\_region | Indicates whether the KMS key is a multi-Region (`true`) or regional (`false`) key. Defaults to `false` | `bool` | `false` | no |
| override\_policy\_documents | List of IAM policy documents that are merged together into the exported document. In merging, statements with non-blank `sid`s will override statements with the same `sid` | `list(string)` | `[]` | no |
| policy | A valid policy JSON document. Although this is a key policy, not an IAM policy, an `aws_iam_policy_document`, in the form that designates a principal, can be used | `string` | `null` | no |
| primary\_external\_key\_arn | The primary external key arn of a multi-region replica external key | `string` | `null` | no |
| primary\_key\_arn | The primary key arn of a multi-region replica key | `string` | `null` | no |
| region | Region where the resource(s) will be managed. Defaults to the region set in the provider configuration | `string` | `null` | no |
| rotation\_period\_in\_days | Custom period of time between each rotation date. Must be a number between 90 and 2560 (inclusive) | `number` | `null` | no |
| route53\_dnssec\_sources | A list of maps containing `account_ids` and Route53 `hosted_zone_arn` that will be allowed to sign DNSSEC records | `list(any)` | `[]` | no |
| source\_policy\_documents | List of IAM policy documents that are merged together into the exported document. Statements must have unique `sid`s | `list(string)` | `[]` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| valid\_to | Time at which the imported key material expires. When the key material expires, AWS KMS deletes the key material and the CMK becomes unusable. If not specified, key material does not expire | `string` | `null` | no |
| xks\_key\_id | ID of the external key that serves as key material inside AWS KMS for an XKS key. Required when creating an XKS key (customer\_master\_key\_spec = SYMMETRIC\_DEFAULT and custom\_key\_store\_id points to an external key store) | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| aliases | A map of aliases created and their attributes |
| external\_key\_expiration\_model | Whether the key material expires. Empty when pending key material import, otherwise `KEY_MATERIAL_EXPIRES` or `KEY_MATERIAL_DOES_NOT_EXPIRE` |
| external\_key\_state | The state of the CMK |
| external\_key\_usage | The cryptographic operations for which you can use the CMK |
| grants | A map of grants created and their attributes |
| key\_arn | The Amazon Resource Name (ARN) of the key |
| key\_id | The globally unique identifier for the key |
| key\_policy | The IAM resource policy set on the key |
<!-- END_TF_DOCS -->

</details>
