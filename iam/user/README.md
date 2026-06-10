# IAM User

Manages an IAM user with optional console access, programmatic access keys, managed and inline policy attachments, group membership, SSH keys, and virtual MFA devices.

## Features

- **IAM User** - Create a user with configurable path, permissions boundary, and force-destroy
- **Console Access** - Optional login profile with configurable password length and reset requirement
- **Programmatic Access** - Optional access key with PGP encryption support for secure secret handling
- **Managed Policy Attachments** - Attach any number of AWS or customer managed policy ARNs
- **Inline Policies** - Define per-user inline policies via a simple name-to-JSON map
- **Group Membership** - Add the user to one or more IAM groups
- **SSH Public Key** - Upload an SSH public key for CodeCommit access
- **Virtual MFA Device** - Create a virtual MFA device for multi-factor authentication

## Usage

```hcl
module "user" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam/user?depth=1&ref=master"

  name = "deploy-bot"

  create_access_key    = true
  managed_policy_arns  = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]

  tags = {
    Environment = "production"
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
| access\_key\_status | Access key status. Active or Inactive. | `string` | `"Active"` | no |
| allow\_plaintext\_credentials\_in\_state | Explicit opt-out: allow creating login profiles/access keys without `pgp_key`, storing the generated credentials in plaintext in the OpenTofu state. Default false. | `bool` | `false` | no |
| create\_access\_key | Whether to create an IAM access key for the user. | `bool` | `false` | no |
| create\_login\_profile | Whether to create an IAM user login profile (console access). | `bool` | `false` | no |
| create\_virtual\_mfa\_device | Whether to create a virtual MFA device for the user. | `bool` | `false` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| force\_destroy | When destroying this user, destroy even if it has non-OpenTofu-managed IAM access keys, login profile, or MFA devices. | `bool` | `false` | no |
| groups | Set of IAM group names to add the user to. | `set(string)` | `[]` | no |
| inline\_policies | Map of inline policy names to their JSON policy documents. | `map(string)` | `{}` | no |
| managed\_policy\_arns | Set of managed policy ARNs to attach to the user. | `set(string)` | `[]` | no |
| name | The name of the IAM user. | `string` | n/a | yes |
| password\_length | The length of the generated password on resource creation. | `number` | `20` | no |
| password\_reset\_required | Whether the user should be forced to reset the generated password on resource creation. | `bool` | `true` | no |
| path | Path in which to create the user. | `string` | `"/"` | no |
| permissions\_boundary | The ARN of the policy that is used to set the permissions boundary for the user. | `string` | `null` | no |
| pgp\_key | A PGP key (base-64 encoded) or a Keybase username in the form keybase:username. Used to encrypt the password and access key secret. | `string` | `null` | no |
| ssh\_key\_encoding | The public key encoding format. Valid values are SSH and PEM. | `string` | `"SSH"` | no |
| ssh\_key\_status | The status of the SSH public key. Active or Inactive. | `string` | `"Active"` | no |
| ssh\_public\_key | SSH public key (for CodeCommit). Must be encoded in SSH authorized\_keys format. | `string` | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| virtual\_mfa\_device\_path | The path for the virtual MFA device. | `string` | `"/"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| access\_key\_encrypted\_secret | The encrypted secret, base64 encoded. Only available if pgp\_key is supplied. |
| access\_key\_encrypted\_ses\_smtp\_password\_v4 | The encrypted SES SMTP password, base64 encoded. Only available if pgp\_key is supplied. |
| access\_key\_id | The access key ID. |
| access\_key\_key\_fingerprint | The fingerprint of the PGP key used to encrypt the secret. |
| access\_key\_secret | The access key secret. Only available when pgp\_key is not supplied. |
| access\_key\_ses\_smtp\_password\_v4 | The SES SMTP password. Only available when pgp\_key is not supplied. |
| access\_key\_status | The status of the access key (Active or Inactive). |
| arn | The ARN assigned by AWS for this user. |
| group\_membership | The list of groups the user belongs to. |
| login\_profile\_key\_fingerprint | The fingerprint of the PGP key used to encrypt the password. |
| login\_profile\_password | The encrypted password, base64 encoded. Only available if pgp\_key is supplied. |
| name | The name of the IAM user. |
| ssh\_key\_fingerprint | The MD5 message digest of the SSH public key. |
| ssh\_key\_id | The unique identifier for the SSH public key. |
| tags\_all | A map of tags assigned to the user, including those inherited from the provider. |
| unique\_id | The unique ID assigned by AWS. |
| virtual\_mfa\_device\_arn | The ARN of the virtual MFA device. |
| virtual\_mfa\_device\_base\_32\_string\_seed | The base32 seed defined as specified in RFC 3548. Used to configure MFA applications. |
| virtual\_mfa\_device\_qr\_code\_png | A QR code PNG image that encodes the MFA seed. Base64 encoded. |
<!-- END_TF_DOCS -->

## Examples

### Basic User

Create a minimal IAM user with no additional configuration.

```hcl
module "basic_user" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam/user?depth=1&ref=master"

  name = "john.doe"
  path = "/users/"

  tags = {
    Department = "engineering"
  }
}
```

### User with Console Access

Create a user with a login profile for AWS Management Console access.

```hcl
module "console_user" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam/user?depth=1&ref=master"

  name                    = "jane.doe"
  path                    = "/users/"
  create_login_profile    = true
  password_length         = 24
  password_reset_required = true
  pgp_key                 = "keybase:janedoe"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
  ]

  tags = {
    Department = "engineering"
    Access     = "console"
  }
}
```

### User with Programmatic Access

Create a user with an access key for API and CLI usage, with PGP-encrypted secret.

```hcl
module "programmatic_user" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam/user?depth=1&ref=master"

  name              = "ci-deploy"
  path              = "/service-accounts/"
  create_access_key = true
  pgp_key           = "keybase:ops_team"

  managed_policy_arns = [
    "arn:aws:iam::123456789012:policy/deploy-policy",
  ]

  tags = {
    Purpose = "ci-cd"
  }
}
```

### User with Multiple Policy Attachments

Attach multiple managed policies and an inline policy to a user.

```hcl
module "multi_policy_user" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam/user?depth=1&ref=master"

  name          = "app-developer"
  path          = "/users/"
  force_destroy = true

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AWSLambda_FullAccess",
  ]

  inline_policies = {
    ecr-access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["ecr:GetAuthorizationToken", "ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"]
          Resource = "*"
        }
      ]
    })
  }

  tags = {
    Team = "backend"
  }
}
```

### User in Groups with MFA

Create a user that belongs to multiple groups and has a virtual MFA device provisioned.

```hcl
module "mfa_user" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam/user?depth=1&ref=master"

  name                      = "alice.smith"
  path                      = "/users/"
  create_login_profile      = true
  password_reset_required   = true
  pgp_key                   = "keybase:alicesmith"
  create_virtual_mfa_device = true

  groups = [
    "developers",
    "readonly-production",
  ]

  tags = {
    Department = "platform"
  }
}
```

### Service Account (Programmatic Only, No Console)

Create a service account intended for automation with programmatic access only.

```hcl
module "service_account" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//iam/user?depth=1&ref=master"

  name              = "svc-github-actions"
  path              = "/service-accounts/"
  force_destroy     = true
  create_access_key = true

  permissions_boundary = "arn:aws:iam::123456789012:policy/service-account-boundary"

  managed_policy_arns = [
    "arn:aws:iam::123456789012:policy/github-actions-deploy",
  ]

  inline_policies = {
    assume-deploy-role = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "sts:AssumeRole"
          Resource = "arn:aws:iam::123456789012:role/deploy-role"
        }
      ]
    })
  }

  tags = {
    ManagedBy = "opentofu"
    Purpose   = "github-actions"
  }
}
```

## Security Notes

### Credentials in state (BREAKING validation)

Creating a login profile (`create_login_profile = true`) or access key (`create_access_key = true`)
without a `pgp_key` causes the generated password / secret access key to be stored **in plaintext
in the OpenTofu state**. The module now fails validation in this situation. Either:

- provide `pgp_key` (base64-encoded PGP public key or `keybase:username`) so credentials are
  encrypted before being stored, or
- set `allow_plaintext_credentials_in_state = true` to explicitly accept the risk
  (default `false`).

### Virtual MFA seed in state

When `create_virtual_mfa_device = true`, the device's `base_32_string_seed` and `qr_code_png`
attributes are stored in the OpenTofu state. Anyone with state access can enroll the MFA device.
Protect state access accordingly, or create MFA devices outside of OpenTofu.

### Inline policy wildcards

`inline_policies` values are raw JSON and are not validated by this module. Avoid wildcard
actions/resources (`"Action": "*"`, `"Resource": "*"`) in inline policies; prefer scoped managed
policies reviewed through your normal policy pipeline.
