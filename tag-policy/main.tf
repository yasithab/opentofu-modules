data "aws_organizations_organization" "org" {}

locals {
  name = var.name
  tags = merge(var.tags, { ManagedBy = "opentofu" })

  tag_policy_content = {
    tags = {
      for tag_name, tag in var.tag_policy : tag_name => merge(
        # tag key handling
        {
          tag_key = merge(
            tag.enforced_for_operators_allowed_for_child_policies != null ? {
              "@@operators_allowed_for_child_policies" = tag.enforced_for_operators_allowed_for_child_policies
            } : {},
            {
              (coalesce(tag.tag_key_operator, "@@assign")) = tag.tag_key
            }
          )
        },

        # optional tag values
        tag.values != null ? {
          tag_value = merge(
            tag.values_operators_allowed_for_child_policies != null ? {
              "@@operators_allowed_for_child_policies" = tag.values_operators_allowed_for_child_policies
            } : {},
            {
              (coalesce(tag.values_operator, "@@assign")) = tag.values
            }
          )
        } : {},

        # enforced_for handling
        tag.enforced_for != null ? {
          enforced_for = merge(
            tag.enforced_for_operators_allowed_for_child_policies != null ? {
              "@@operators_allowed_for_child_policies" = tag.enforced_for_operators_allowed_for_child_policies
            } : {},
            {
              (coalesce(tag.enforced_for_operator, "@@assign")) = tag.enforced_for
            }
          )
        } : {}
      )
    }
  }
}

resource "aws_organizations_policy" "this" {
  name         = local.name
  description  = var.description
  content      = jsonencode(local.tag_policy_content)
  type         = "TAG_POLICY"
  skip_destroy = var.skip_destroy

  tags = local.tags
}

resource "aws_organizations_policy_attachment" "attach_ous" {
  for_each = toset(var.attach_ous)

  policy_id = aws_organizations_policy.this.id
  target_id = each.value
}

resource "aws_organizations_policy_attachment" "attach_org" {
  policy_id = aws_organizations_policy.this.id
  target_id = data.aws_organizations_organization.org.roots[0].id

  lifecycle {
    enabled = var.attach_to_org
  }
}
