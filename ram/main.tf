locals {
  enabled                 = var.enabled
  ram_principals_provided = length(var.ram_principals) > 0
  ram_principals = toset(local.enabled ? toset(
    local.ram_principals_provided ? concat(
      var.ram_principals,
      ) : [
      data.aws_organizations_organization.default[0].arn
    ]
  ) : [])

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

################################################################################
# RAM Sharing with Organization
################################################################################

resource "aws_ram_sharing_with_organization" "default" {
  lifecycle {
    enabled = local.enabled && var.enable_sharing_with_organization
  }
}

################################################################################
# Resource Share
################################################################################

# Resource Access Manager (RAM) share for the Transit Gateway
# https://docs.aws.amazon.com/ram/latest/userguide/what-is.html
resource "aws_ram_resource_share" "default" {
  name                      = var.ram_resource_share_name
  allow_external_principals = var.allow_external_principals
  permission_arns           = length(var.permission_arns) > 0 ? var.permission_arns : null

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}

# Share the Transit Gateway with the Organization if RAM principal was not provided
data "aws_organizations_organization" "default" {
  count = local.enabled && !local.ram_principals_provided ? 1 : 0
}

resource "aws_ram_resource_association" "default" {
  resource_arn       = var.ram_resource_arn
  resource_share_arn = try(aws_ram_resource_share.default.id, "")

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_ram_principal_association" "default" {
  for_each           = local.ram_principals
  principal          = each.value
  resource_share_arn = try(aws_ram_resource_share.default.id, "")
}
