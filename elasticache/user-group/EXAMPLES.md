# ElastiCache User Group Module - Examples

## Basic Usage

Redis user group with a custom default user that has no access.

```hcl
module "elasticache_user_group" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache/user-group?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache/user-group?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//elasticache/user-group?depth=1&ref=v2.0.0"

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
