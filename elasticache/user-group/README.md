# ElastiCache User Group

OpenTofu module to create an Amazon ElastiCache user group with users for Redis-based access control. Manages the user group, a default user, additional users, and user-group associations.

## Features

- **User Group Management** - Create an ElastiCache user group for Redis with configurable engine settings
- **Default User** - Optionally create a custom default user with configurable access strings and authentication modes, or reference an existing one
- **Additional Users** - Define multiple users with individual access strings, authentication modes, and tags
- **Automatic Association** - Users are automatically associated with the user group via `aws_elasticache_user_group_association`
- **Authentication Modes** - Support for password-based and IAM authentication modes
- **Cross-Region** - Optionally specify a region different from the provider default
- **Lifecycle Management** - Toggle resource creation with the `enabled` variable

## Security notes

- **Prefer IAM authentication** (`authentication_mode = { type = "iam" }`) over password-based users. Passwords supplied via `users`/`default_user` are stored in OpenTofu state even though the variables and the `users` output are marked `sensitive`. With IAM authentication no long-lived credential exists in state, and access is governed by IAM policies.
- The `users` and `default_user` variables and the `users` output are marked `sensitive`; ensure your state backend is encrypted and access-restricted regardless.

## Usage

```hcl
module "elasticache_user_group" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache/user-group?depth=1&ref=master"

  user_group_id = "my-app-users"

  default_user = {
    user_id       = "my-default-user"
    access_string = "on ~* +@read"
    authentication_mode = {
      type = "no-password-required"
    }
  }

  users = {
    app-user = {
      access_string = "on ~app::* +@all"
      authentication_mode = {
        type      = "password"
        passwords = ["my-secure-password-1"]
      }
    }
    readonly-user = {
      access_string = "on ~* +@read"
      authentication_mode = {
        type      = "password"
        passwords = ["my-secure-password-2"]
      }
    }
  }

  tags = {
    Environment = "production"
  }
}
```

### Using an Existing Default User

```hcl
module "elasticache_user_group" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache/user-group?depth=1&ref=master"

  user_group_id       = "my-app-users"
  create_default_user = false
  default_user_id     = "existing-default-user-id"

  users = {
    app-user = {
      access_string = "on ~app::* +@all"
      authentication_mode = {
        type = "iam"
      }
    }
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
| create\_default\_user | Determines whether a default user will be created | `bool` | `true` | no |
| create\_group | Determines whether a user group will be created | `bool` | `true` | no |
| default\_user | A map of default user attributes | `any` | `{}` | no |
| default\_user\_id | The ID of the default user | `string` | `"default"` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| engine | The engine the user group applies to. Valid values are `REDIS` and `VALKEY` | `string` | `"REDIS"` | no |
| region | Region where the resource(s) will be managed. Defaults to the region set in the provider configuration | `string` | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| user\_group\_id | The ID of the user group | `string` | `null` | no |
| users | A map of users to create. May contain plaintext passwords - prefer authentication\_mode type `iam` | `any` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| group\_arn | The ARN that identifies the user group |
| group\_id | The user group identifier |
| users | A map of users created and their attributes |
<!-- END_TF_DOCS -->

## Examples

## Basic Usage

Redis user group with a custom default user that has no access.

```hcl
module "elasticache_user_group" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache/user-group?depth=1&ref=master"

  enabled       = true
  engine        = "REDIS"
  user_group_id = "app-user-group"

  create_default_user = true
  default_user = {
    user_id       = "default"
    user_name     = "default"
    access_string = "off ~* +@all"
    passwords     = []
    no_password_required = true
  }

  tags = {
    Environment = "production"
  }
}
```

## With Application Users

User group with a restricted default user and application-specific users with access controls.

```hcl
module "elasticache_user_group" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache/user-group?depth=1&ref=master"

  enabled       = true
  engine        = "REDIS"
  user_group_id = "production-user-group"

  create_default_user = true
  default_user = {
    user_id       = "default"
    user_name     = "default"
    access_string = "off ~* -@all"
    no_password_required = true
  }

  users = {
    app_readwrite = {
      user_id       = "app-readwrite"
      user_name     = "app-readwrite"
      access_string = "on ~app:* +@read +@write"
      passwords     = ["Str0ngP@ssw0rd!"]
    }
    app_readonly = {
      user_id       = "app-readonly"
      user_name     = "app-readonly"
      access_string = "on ~app:* +@read"
      passwords     = ["R3adOnlyP@ss!"]
    }
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## With IAM Authentication

User group with IAM-authenticated users (no password) for secure IRSA-based access.

```hcl
module "elasticache_user_group" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache/user-group?depth=1&ref=master"

  enabled       = true
  engine        = "REDIS"
  user_group_id = "iam-user-group"

  create_default_user = true
  default_user = {
    user_id       = "default"
    user_name     = "default"
    access_string = "off ~* -@all"
    no_password_required = true
  }

  users = {
    iam_app = {
      user_id              = "iam-app-user"
      user_name            = "iam-app-user"
      access_string        = "on ~* +@all"
      authentication_mode  = {
        type = "iam"
      }
    }
  }

  tags = {
    Environment = "production"
    AuthMode    = "iam"
  }
}
```
