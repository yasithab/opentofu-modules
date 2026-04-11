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
