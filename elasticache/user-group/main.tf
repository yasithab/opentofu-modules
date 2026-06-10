locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
    Region    = data.aws_region.current.region
  })
}

################################################################################
# Group
################################################################################

resource "aws_elasticache_user_group" "this" {
  region = var.region

  engine        = lower(var.engine)
  user_group_id = var.user_group_id
  tags          = local.tags
  user_ids      = var.create_default_user ? [aws_elasticache_user.default.user_id] : [var.default_user_id]

  lifecycle {
    enabled        = local.enabled && var.create_group
    ignore_changes = [user_ids]
  }
}

resource "aws_elasticache_user" "default" {
  region = var.region

  access_string = try(var.default_user.access_string, "on ~* +@read")

  dynamic "authentication_mode" {
    for_each = try([var.default_user.authentication_mode], [])

    content {
      passwords = try(authentication_mode.value.passwords, null)
      type      = authentication_mode.value.type
    }
  }

  engine               = try(lower(var.default_user.engine), "redis")
  no_password_required = try(var.default_user.no_password_required, null)
  passwords            = try(var.default_user.passwords, null)
  user_id              = try(var.default_user.user_id, null)
  user_name            = "default"

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_default_user
  }
}

################################################################################
# User(s)
################################################################################

resource "aws_elasticache_user" "this" {
  # var.users is sensitive, so iterate over its (nonsensitive) keys to keep
  # for_each valid while the user attributes themselves stay sensitive
  for_each = toset([for k in nonsensitive(keys(var.users)) : k if local.enabled])

  region = var.region

  access_string = var.users[each.key].access_string

  dynamic "authentication_mode" {
    for_each = try([var.users[each.key].authentication_mode], [])

    content {
      passwords = try(authentication_mode.value.passwords, null)
      type      = authentication_mode.value.type
    }
  }

  engine               = try(lower(var.users[each.key].engine), "redis")
  no_password_required = try(var.users[each.key].no_password_required, null)
  passwords            = try(var.users[each.key].passwords, null)
  user_id              = try(var.users[each.key].user_id, each.key)
  user_name            = try(var.users[each.key].user_name, each.key)

  tags = merge(local.tags, try(var.users[each.key].tags, {}))
}

resource "aws_elasticache_user_group_association" "this" {
  for_each = toset([for k in nonsensitive(keys(var.users)) : k if local.enabled])

  user_group_id = local.enabled && var.create_group ? aws_elasticache_user_group.this.user_group_id : try(coalesce(try(var.users[each.key].user_group_id, null), var.user_group_id), var.user_group_id)
  user_id       = aws_elasticache_user.this[each.key].user_id

  dynamic "timeouts" {
    for_each = try([var.users[each.key].timeouts], [])
    content {
      create = try(timeouts.value.create, null)
      delete = try(timeouts.value.delete, null)
    }
  }
}

data "aws_region" "current" {}
