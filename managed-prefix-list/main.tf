################################################################################
# General
################################################################################

locals {
  enabled      = var.enabled
  prefix_lists = var.prefix_lists != null ? var.prefix_lists : {}

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

################################################################################
# Prefix Lists
################################################################################

resource "aws_ec2_managed_prefix_list" "this" {
  for_each = local.enabled ? local.prefix_lists : {}

  name           = each.value.name
  address_family = lookup(each.value, "address_family", "IPv4")
  max_entries    = length(each.value.cidr_list)

  dynamic "entry" {
    for_each = each.value.cidr_list
    content {
      cidr        = entry.value.cidr
      description = try(entry.value.description, null)
    }
  }

  tags = merge(local.tags, lookup(each.value, "tags", {}))
}

################################################################################
# RAM Resource Share
################################################################################

resource "aws_ram_resource_share" "this" {
  for_each = local.enabled && var.enable_ram_share ? local.prefix_lists : {}

  name                      = each.value.name
  allow_external_principals = var.ram_allow_external_principals
  permission_arns           = var.ram_permission_arns

  tags = merge(local.tags, { Name = "prefix-list-${each.value.name}" }, var.ram_tags)
}

resource "aws_ram_resource_association" "this" {
  for_each = local.enabled && var.enable_ram_share ? local.prefix_lists : {}

  resource_arn       = aws_ec2_managed_prefix_list.this[each.key].arn
  resource_share_arn = aws_ram_resource_share.this[each.key].arn
}

resource "aws_ram_principal_association" "this" {
  for_each = {
    for combination in setproduct(
      local.enabled && var.enable_ram_share ? keys(local.prefix_lists) : [],
      var.ram_principals
    ) : "${combination[0]}-${combination[1]}" => combination
  }

  principal          = each.value[1]
  resource_share_arn = aws_ram_resource_share.this[each.value[0]].arn
}

################################################################################
