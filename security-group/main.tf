###############################################################################################################
# Get ID of created Security Group
###############################################################################################################

locals {
  enabled = var.enabled
  name    = var.name

  this_sg_id = var.enabled ? coalesce(try(aws_security_group.this.id, null), try(aws_security_group.this_name_prefix.id, null), "") : var.security_group_id

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

###############################################################################################################
# Security group with name
###############################################################################################################

resource "aws_security_group" "this" {
  name                   = local.name
  description            = var.description
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = var.revoke_rules_on_delete

  tags = merge(local.tags, {
    "Name" = format("%s", local.name)
  })

  timeouts {
    create = var.create_timeout
    delete = var.delete_timeout
  }

  lifecycle {
    enabled = local.enabled && var.enabled && !var.use_name_prefix
  }
}

###############################################################################################################
# Security group with name_prefix
###############################################################################################################

resource "aws_security_group" "this_name_prefix" {
  name_prefix            = "${local.name}-"
  description            = var.description
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = var.revoke_rules_on_delete

  tags = merge(local.tags, {
    "Name" = format("%s", local.name)
  })

  lifecycle {
    enabled               = local.enabled && var.enabled && var.use_name_prefix
    create_before_destroy = true
  }

  timeouts {
    create = var.create_timeout
    delete = var.delete_timeout
  }
}

###############################################################################################################
# Ingress - List of rules (simple)
###############################################################################################################

# Security group rules with "cidr_blocks" and it uses list of rules names
resource "aws_vpc_security_group_ingress_rule" "ingress_rules" {
  count = local.enabled ? length(var.ingress_rules) : 0

  security_group_id = local.this_sg_id
  ip_protocol       = var.rules[var.ingress_rules[count.index]][2]
  from_port         = tostring(var.rules[var.ingress_rules[count.index]][2]) == "-1" ? null : var.rules[var.ingress_rules[count.index]][0]
  to_port           = tostring(var.rules[var.ingress_rules[count.index]][2]) == "-1" ? null : var.rules[var.ingress_rules[count.index]][1]
  description       = var.rules[var.ingress_rules[count.index]][3]

  cidr_ipv4      = length(var.ingress_cidr_blocks) > 0 ? var.ingress_cidr_blocks[0] : null
  cidr_ipv6      = length(var.ingress_ipv6_cidr_blocks) > 0 ? var.ingress_ipv6_cidr_blocks[0] : null
  prefix_list_id = length(var.ingress_prefix_list_ids) > 0 ? var.ingress_prefix_list_ids[0] : null

  tags = local.tags
}

# Computed - Security group rules with "cidr_blocks" and it uses list of rules names
resource "aws_vpc_security_group_ingress_rule" "computed_ingress_rules" {
  count = local.enabled ? var.number_of_computed_ingress_rules : 0

  security_group_id = local.this_sg_id
  ip_protocol       = var.rules[var.computed_ingress_rules[count.index]][2]
  from_port         = tostring(var.rules[var.computed_ingress_rules[count.index]][2]) == "-1" ? null : var.rules[var.computed_ingress_rules[count.index]][0]
  to_port           = tostring(var.rules[var.computed_ingress_rules[count.index]][2]) == "-1" ? null : var.rules[var.computed_ingress_rules[count.index]][1]
  description       = var.rules[var.computed_ingress_rules[count.index]][3]

  cidr_ipv4      = length(var.ingress_cidr_blocks) > 0 ? var.ingress_cidr_blocks[0] : null
  cidr_ipv6      = length(var.ingress_ipv6_cidr_blocks) > 0 ? var.ingress_ipv6_cidr_blocks[0] : null
  prefix_list_id = length(var.ingress_prefix_list_ids) > 0 ? var.ingress_prefix_list_ids[0] : null

  tags = local.tags
}

###############################################################################################################
# Ingress - Maps of rules
###############################################################################################################

# Security group rules with "source_security_group_id", but without "cidr_blocks" and "self"
resource "aws_vpc_security_group_ingress_rule" "ingress_with_source_security_group_id" {
  count = local.enabled ? length(var.ingress_with_source_security_group_id) : 0

  security_group_id            = local.this_sg_id
  referenced_security_group_id = var.ingress_with_source_security_group_id[count.index]["source_security_group_id"]
  prefix_list_id               = length(var.ingress_prefix_list_ids) > 0 ? var.ingress_prefix_list_ids[0] : null
  description = lookup(
    var.ingress_with_source_security_group_id[count.index],
    "description",
    "Ingress Rule",
  )

  ip_protocol = lookup(
    var.ingress_with_source_security_group_id[count.index],
    "protocol",
    var.rules[lookup(
      var.ingress_with_source_security_group_id[count.index],
      "rule",
      "_",
    )][2],
  )
  from_port = tostring(lookup(
    var.ingress_with_source_security_group_id[count.index],
    "protocol",
    var.rules[lookup(
      var.ingress_with_source_security_group_id[count.index],
      "rule",
      "_",
    )][2],
    )) == "-1" ? null : lookup(
    var.ingress_with_source_security_group_id[count.index],
    "from_port",
    var.rules[lookup(
      var.ingress_with_source_security_group_id[count.index],
      "rule",
      "_",
    )][0],
  )
  to_port = tostring(lookup(
    var.ingress_with_source_security_group_id[count.index],
    "protocol",
    var.rules[lookup(
      var.ingress_with_source_security_group_id[count.index],
      "rule",
      "_",
    )][2],
    )) == "-1" ? null : lookup(
    var.ingress_with_source_security_group_id[count.index],
    "to_port",
    var.rules[lookup(
      var.ingress_with_source_security_group_id[count.index],
      "rule",
      "_",
    )][1],
  )

  tags = local.tags
}

# Computed - Security group rules with "source_security_group_id", but without "cidr_blocks" and "self"
resource "aws_vpc_security_group_ingress_rule" "computed_ingress_with_source_security_group_id" {
  count = local.enabled ? var.number_of_computed_ingress_with_source_security_group_id : 0

  security_group_id            = local.this_sg_id
  referenced_security_group_id = var.computed_ingress_with_source_security_group_id[count.index]["source_security_group_id"]
  prefix_list_id               = length(var.ingress_prefix_list_ids) > 0 ? var.ingress_prefix_list_ids[0] : null
  description = lookup(
    var.computed_ingress_with_source_security_group_id[count.index],
    "description",
    "Ingress Rule",
  )

  ip_protocol = lookup(
    var.computed_ingress_with_source_security_group_id[count.index],
    "protocol",
    var.rules[lookup(
      var.computed_ingress_with_source_security_group_id[count.index],
      "rule",
      "_",
    )][2],
  )
  from_port = tostring(lookup(
    var.computed_ingress_with_source_security_group_id[count.index],
    "protocol",
    var.rules[lookup(
      var.computed_ingress_with_source_security_group_id[count.index],
      "rule",
      "_",
    )][2],
    )) == "-1" ? null : lookup(
    var.computed_ingress_with_source_security_group_id[count.index],
    "from_port",
    var.rules[lookup(
      var.computed_ingress_with_source_security_group_id[count.index],
      "rule",
      "_",
    )][0],
  )
  to_port = tostring(lookup(
    var.computed_ingress_with_source_security_group_id[count.index],
    "protocol",
    var.rules[lookup(
      var.computed_ingress_with_source_security_group_id[count.index],
      "rule",
      "_",
    )][2],
    )) == "-1" ? null : lookup(
    var.computed_ingress_with_source_security_group_id[count.index],
    "to_port",
    var.rules[lookup(
      var.computed_ingress_with_source_security_group_id[count.index],
      "rule",
      "_",
    )][1],
  )

  tags = local.tags
}

# Security group rules with "cidr_blocks", but without "ipv6_cidr_blocks", "source_security_group_id" and "self"
resource "aws_vpc_security_group_ingress_rule" "ingress_with_cidr_blocks" {
  count = local.enabled ? length(var.ingress_with_cidr_blocks) : 0

  security_group_id = local.this_sg_id
  cidr_ipv4 = compact(split(
    ",",
    lookup(
      var.ingress_with_cidr_blocks[count.index],
      "cidr_blocks",
      join(",", var.ingress_cidr_blocks),
    ),
  ))[0]

  description = lookup(
    var.ingress_with_cidr_blocks[count.index],
    "description",
    "Ingress Rule",
  )

  ip_protocol = lookup(
    var.ingress_with_cidr_blocks[count.index],
    "protocol",
    var.rules[lookup(var.ingress_with_cidr_blocks[count.index], "rule", "_")][2],
  )
  from_port = tostring(lookup(
    var.ingress_with_cidr_blocks[count.index],
    "protocol",
    var.rules[lookup(var.ingress_with_cidr_blocks[count.index], "rule", "_")][2],
    )) == "-1" ? null : lookup(
    var.ingress_with_cidr_blocks[count.index],
    "from_port",
    var.rules[lookup(var.ingress_with_cidr_blocks[count.index], "rule", "_")][0],
  )
  to_port = tostring(lookup(
    var.ingress_with_cidr_blocks[count.index],
    "protocol",
    var.rules[lookup(var.ingress_with_cidr_blocks[count.index], "rule", "_")][2],
    )) == "-1" ? null : lookup(
    var.ingress_with_cidr_blocks[count.index],
    "to_port",
    var.rules[lookup(var.ingress_with_cidr_blocks[count.index], "rule", "_")][1],
  )

  tags = local.tags
}

# Computed - Security group rules with "cidr_blocks", but without "ipv6_cidr_blocks", "source_security_group_id" and "self"
resource "aws_vpc_security_group_ingress_rule" "computed_ingress_with_cidr_blocks" {
  count = local.enabled ? var.number_of_computed_ingress_with_cidr_blocks : 0

  security_group_id = local.this_sg_id
  cidr_ipv4 = compact(split(
    ",",
    lookup(
      var.computed_ingress_with_cidr_blocks[count.index],
      "cidr_blocks",
      join(",", var.ingress_cidr_blocks),
    ),
  ))[0]

  description = lookup(
    var.computed_ingress_with_cidr_blocks[count.index],
    "description",
    "Ingress Rule",
  )

  ip_protocol = lookup(
    var.computed_ingress_with_cidr_blocks[count.index],
    "protocol",
    var.rules[lookup(
      var.computed_ingress_with_cidr_blocks[count.index],
      "rule",
      "_",
    )][2],
  )
  from_port = tostring(lookup(
    var.computed_ingress_with_cidr_blocks[count.index],
    "protocol",
    var.rules[lookup(
      var.computed_ingress_with_cidr_blocks[count.index],
      "rule",
      "_",
    )][2],
    )) == "-1" ? null : lookup(
    var.computed_ingress_with_cidr_blocks[count.index],
    "from_port",
    var.rules[lookup(
      var.computed_ingress_with_cidr_blocks[count.index],
      "rule",
      "_",
    )][0],
  )
  to_port = tostring(lookup(
    var.computed_ingress_with_cidr_blocks[count.index],
    "protocol",
    var.rules[lookup(
      var.computed_ingress_with_cidr_blocks[count.index],
      "rule",
      "_",
    )][2],
    )) == "-1" ? null : lookup(
    var.computed_ingress_with_cidr_blocks[count.index],
    "to_port",
    var.rules[lookup(
      var.computed_ingress_with_cidr_blocks[count.index],
      "rule",
      "_",
    )][1],
  )

  tags = local.tags
}

# Security group rules with "ipv6_cidr_blocks", but without "cidr_blocks", "source_security_group_id" and "self"
resource "aws_vpc_security_group_ingress_rule" "ingress_with_ipv6_cidr_blocks" {
  count = local.enabled ? length(var.ingress_with_ipv6_cidr_blocks) : 0

  security_group_id = local.this_sg_id
  cidr_ipv6 = compact(split(
    ",",
    lookup(
      var.ingress_with_ipv6_cidr_blocks[count.index],
      "ipv6_cidr_blocks",
      join(",", var.ingress_ipv6_cidr_blocks),
    ),
  ))[0]
  prefix_list_id = length(var.ingress_prefix_list_ids) > 0 ? var.ingress_prefix_list_ids[0] : null
  description = lookup(
    var.ingress_with_ipv6_cidr_blocks[count.index],
    "description",
    "Ingress Rule",
  )

  ip_protocol = lookup(
    var.ingress_with_ipv6_cidr_blocks[count.index],
    "protocol",
    var.rules[lookup(var.ingress_with_ipv6_cidr_blocks[count.index], "rule", "_")][2],
  )
  from_port = tostring(lookup(
    var.ingress_with_ipv6_cidr_blocks[count.index],
    "protocol",
    var.rules[lookup(var.ingress_with_ipv6_cidr_blocks[count.index], "rule", "_")][2],
    )) == "-1" ? null : lookup(
    var.ingress_with_ipv6_cidr_blocks[count.index],
    "from_port",
    var.rules[lookup(var.ingress_with_ipv6_cidr_blocks[count.index], "rule", "_")][0],
  )
  to_port = tostring(lookup(
    var.ingress_with_ipv6_cidr_blocks[count.index],
    "protocol",
    var.rules[lookup(var.ingress_with_ipv6_cidr_blocks[count.index], "rule", "_")][2],
    )) == "-1" ? null : lookup(
    var.ingress_with_ipv6_cidr_blocks[count.index],
    "to_port",
    var.rules[lookup(var.ingress_with_ipv6_cidr_blocks[count.index], "rule", "_")][1],
  )

  tags = local.tags
}

# Computed - Security group rules with "ipv6_cidr_blocks", but without "cidr_blocks", "source_security_group_id" and "self"
resource "aws_vpc_security_group_ingress_rule" "computed_ingress_with_ipv6_cidr_blocks" {
  count = local.enabled ? var.number_of_computed_ingress_with_ipv6_cidr_blocks : 0

  security_group_id = local.this_sg_id
  cidr_ipv6 = compact(split(
    ",",
    lookup(
      var.computed_ingress_with_ipv6_cidr_blocks[count.index],
      "ipv6_cidr_blocks",
      join(",", var.ingress_ipv6_cidr_blocks),
    ),
  ))[0]
  prefix_list_id = length(var.ingress_prefix_list_ids) > 0 ? var.ingress_prefix_list_ids[0] : null
  description = lookup(
    var.computed_ingress_with_ipv6_cidr_blocks[count.index],
    "description",
    "Ingress Rule",
  )

  ip_protocol = lookup(
    var.computed_ingress_with_ipv6_cidr_blocks[count.index],
    "protocol",
    var.rules[lookup(
      var.computed_ingress_with_ipv6_cidr_blocks[count.index],
      "rule",
      "_",
    )][2],
  )
  from_port = tostring(lookup(
    var.computed_ingress_with_ipv6_cidr_blocks[count.index],
    "protocol",
    var.rules[lookup(
      var.computed_ingress_with_ipv6_cidr_blocks[count.index],
      "rule",
      "_",
    )][2],
    )) == "-1" ? null : lookup(
    var.computed_ingress_with_ipv6_cidr_blocks[count.index],
    "from_port",
    var.rules[lookup(
      var.computed_ingress_with_ipv6_cidr_blocks[count.index],
      "rule",
      "_",
    )][0],
  )
  to_port = tostring(lookup(
    var.computed_ingress_with_ipv6_cidr_blocks[count.index],
    "protocol",
    var.rules[lookup(
      var.computed_ingress_with_ipv6_cidr_blocks[count.index],
      "rule",
      "_",
    )][2],
    )) == "-1" ? null : lookup(
    var.computed_ingress_with_ipv6_cidr_blocks[count.index],
    "to_port",
    var.rules[lookup(
      var.computed_ingress_with_ipv6_cidr_blocks[count.index],
      "rule",
      "_",
    )][1],
  )

  tags = local.tags
}

# Security group rules with "self", but without "cidr_blocks" and "source_security_group_id"
resource "aws_vpc_security_group_ingress_rule" "ingress_with_self" {
  count = local.enabled ? length(var.ingress_with_self) : 0

  security_group_id            = local.this_sg_id
  referenced_security_group_id = local.this_sg_id
  prefix_list_id               = length(var.ingress_prefix_list_ids) > 0 ? var.ingress_prefix_list_ids[0] : null
  description = lookup(
    var.ingress_with_self[count.index],
    "description",
    "Ingress Rule",
  )

  ip_protocol = lookup(
    var.ingress_with_self[count.index],
    "protocol",
    var.rules[lookup(var.ingress_with_self[count.index], "rule", "_")][2],
  )
  from_port = tostring(lookup(
    var.ingress_with_self[count.index],
    "protocol",
    var.rules[lookup(var.ingress_with_self[count.index], "rule", "_")][2],
    )) == "-1" ? null : lookup(
    var.ingress_with_self[count.index],
    "from_port",
    var.rules[lookup(var.ingress_with_self[count.index], "rule", "_")][0],
  )
  to_port = tostring(lookup(
    var.ingress_with_self[count.index],
    "protocol",
    var.rules[lookup(var.ingress_with_self[count.index], "rule", "_")][2],
    )) == "-1" ? null : lookup(
    var.ingress_with_self[count.index],
    "to_port",
    var.rules[lookup(var.ingress_with_self[count.index], "rule", "_")][1],
  )

  tags = local.tags
}

# Computed - Security group rules with "self", but without "cidr_blocks" and "source_security_group_id"
resource "aws_vpc_security_group_ingress_rule" "computed_ingress_with_self" {
  count = local.enabled ? var.number_of_computed_ingress_with_self : 0

  security_group_id            = local.this_sg_id
  referenced_security_group_id = local.this_sg_id
  prefix_list_id               = length(var.ingress_prefix_list_ids) > 0 ? var.ingress_prefix_list_ids[0] : null
  description = lookup(
    var.computed_ingress_with_self[count.index],
    "description",
    "Ingress Rule",
  )

  ip_protocol = lookup(
    var.computed_ingress_with_self[count.index],
    "protocol",
    var.rules[lookup(var.computed_ingress_with_self[count.index], "rule", "_")][2],
  )
  from_port = tostring(lookup(
    var.computed_ingress_with_self[count.index],
    "protocol",
    var.rules[lookup(var.computed_ingress_with_self[count.index], "rule", "_")][2],
    )) == "-1" ? null : lookup(
    var.computed_ingress_with_self[count.index],
    "from_port",
    var.rules[lookup(var.computed_ingress_with_self[count.index], "rule", "_")][0],
  )
  to_port = tostring(lookup(
    var.computed_ingress_with_self[count.index],
    "protocol",
    var.rules[lookup(var.computed_ingress_with_self[count.index], "rule", "_")][2],
    )) == "-1" ? null : lookup(
    var.computed_ingress_with_self[count.index],
    "to_port",
    var.rules[lookup(var.computed_ingress_with_self[count.index], "rule", "_")][1],
  )

  tags = local.tags
}

# Security group rules with "prefix_list_ids", but without "cidr_blocks", "self" or "source_security_group_id"
resource "aws_vpc_security_group_ingress_rule" "ingress_with_prefix_list_ids" {
  count = local.enabled ? length(var.ingress_with_prefix_list_ids) : 0

  security_group_id = local.this_sg_id
  prefix_list_id = compact(split(
    ",",
    lookup(
      var.ingress_with_prefix_list_ids[count.index],
      "prefix_list_ids",
      join(",", var.ingress_prefix_list_ids)
    )
  ))[0]

  description = lookup(
    var.ingress_with_prefix_list_ids[count.index],
    "description",
    "Ingress Rule",
  )

  ip_protocol = lookup(
    var.ingress_with_prefix_list_ids[count.index],
    "protocol",
    var.rules[lookup(var.ingress_with_prefix_list_ids[count.index], "rule", "_")][2],
  )
  from_port = tostring(lookup(
    var.ingress_with_prefix_list_ids[count.index],
    "protocol",
    var.rules[lookup(var.ingress_with_prefix_list_ids[count.index], "rule", "_")][2],
    )) == "-1" ? null : lookup(
    var.ingress_with_prefix_list_ids[count.index],
    "from_port",
    var.rules[lookup(var.ingress_with_prefix_list_ids[count.index], "rule", "_")][0],
  )
  to_port = tostring(lookup(
    var.ingress_with_prefix_list_ids[count.index],
    "protocol",
    var.rules[lookup(var.ingress_with_prefix_list_ids[count.index], "rule", "_")][2],
    )) == "-1" ? null : lookup(
    var.ingress_with_prefix_list_ids[count.index],
    "to_port",
    var.rules[lookup(var.ingress_with_prefix_list_ids[count.index], "rule", "_")][1],
  )

  tags = local.tags
}

# Computed - Security group rules with "prefix_list_ids", but without "cidr_blocks", "self" or "source_security_group_id"
resource "aws_vpc_security_group_ingress_rule" "computed_ingress_with_prefix_list_ids" {
  count = local.enabled ? var.number_of_computed_ingress_with_prefix_list_ids : 0

  security_group_id = local.this_sg_id
  prefix_list_id = compact(split(
    ",",
    lookup(
      var.computed_ingress_with_prefix_list_ids[count.index],
      "prefix_list_ids",
      join(",", var.ingress_prefix_list_ids)
    )
  ))[0]

  description = lookup(
    var.computed_ingress_with_prefix_list_ids[count.index],
    "description",
    "Ingress Rule",
  )

  ip_protocol = lookup(
    var.computed_ingress_with_prefix_list_ids[count.index],
    "protocol",
    var.rules[lookup(var.computed_ingress_with_prefix_list_ids[count.index], "rule", "_")][2],
  )
  from_port = tostring(lookup(
    var.computed_ingress_with_prefix_list_ids[count.index],
    "protocol",
    var.rules[lookup(var.computed_ingress_with_prefix_list_ids[count.index], "rule", "_")][2],
    )) == "-1" ? null : lookup(
    var.computed_ingress_with_prefix_list_ids[count.index],
    "from_port",
    var.rules[lookup(var.computed_ingress_with_prefix_list_ids[count.index], "rule", "_")][0],
  )
  to_port = tostring(lookup(
    var.computed_ingress_with_prefix_list_ids[count.index],
    "protocol",
    var.rules[lookup(var.computed_ingress_with_prefix_list_ids[count.index], "rule", "_")][2],
    )) == "-1" ? null : lookup(
    var.computed_ingress_with_prefix_list_ids[count.index],
    "to_port",
    var.rules[lookup(var.computed_ingress_with_prefix_list_ids[count.index], "rule", "_")][1],
  )

  tags = local.tags
}

#################
# End of ingress
#################

##################################
# Egress - List of rules (simple)
##################################

# Security group rules with "cidr_blocks" and it uses list of rules names
resource "aws_vpc_security_group_egress_rule" "egress_rules" {
  count = local.enabled ? length(var.egress_rules) : 0

  security_group_id = local.this_sg_id
  ip_protocol       = var.rules[var.egress_rules[count.index]][2]
  from_port         = tostring(var.rules[var.egress_rules[count.index]][2]) == "-1" ? null : var.rules[var.egress_rules[count.index]][0]
  to_port           = tostring(var.rules[var.egress_rules[count.index]][2]) == "-1" ? null : var.rules[var.egress_rules[count.index]][1]
  description       = var.rules[var.egress_rules[count.index]][3]

  cidr_ipv4      = length(var.egress_cidr_blocks) > 0 ? var.egress_cidr_blocks[0] : null
  cidr_ipv6      = length(var.egress_ipv6_cidr_blocks) > 0 ? var.egress_ipv6_cidr_blocks[0] : null
  prefix_list_id = length(var.egress_prefix_list_ids) > 0 ? var.egress_prefix_list_ids[0] : null

  tags = local.tags
}

# Computed - Security group rules with "cidr_blocks" and it uses list of rules names
resource "aws_vpc_security_group_egress_rule" "computed_egress_rules" {
  count = local.enabled ? var.number_of_computed_egress_rules : 0

  security_group_id = local.this_sg_id
  ip_protocol       = var.rules[var.computed_egress_rules[count.index]][2]
  from_port         = tostring(var.rules[var.computed_egress_rules[count.index]][2]) == "-1" ? null : var.rules[var.computed_egress_rules[count.index]][0]
  to_port           = tostring(var.rules[var.computed_egress_rules[count.index]][2]) == "-1" ? null : var.rules[var.computed_egress_rules[count.index]][1]
  description       = var.rules[var.computed_egress_rules[count.index]][3]

  cidr_ipv4      = length(var.egress_cidr_blocks) > 0 ? var.egress_cidr_blocks[0] : null
  cidr_ipv6      = length(var.egress_ipv6_cidr_blocks) > 0 ? var.egress_ipv6_cidr_blocks[0] : null
  prefix_list_id = length(var.egress_prefix_list_ids) > 0 ? var.egress_prefix_list_ids[0] : null

  tags = local.tags
}

#########################
# Egress - Maps of rules
#########################

# Security group rules with "source_security_group_id", but without "cidr_blocks" and "self"
resource "aws_vpc_security_group_egress_rule" "egress_with_source_security_group_id" {
  count = local.enabled ? length(var.egress_with_source_security_group_id) : 0

  security_group_id            = local.this_sg_id
  referenced_security_group_id = var.egress_with_source_security_group_id[count.index]["source_security_group_id"]
  prefix_list_id               = length(var.egress_prefix_list_ids) > 0 ? var.egress_prefix_list_ids[0] : null
  description = lookup(
    var.egress_with_source_security_group_id[count.index],
    "description",
    "Egress Rule",
  )

  ip_protocol = lookup(
    var.egress_with_source_security_group_id[count.index],
    "protocol",
    var.rules[lookup(
      var.egress_with_source_security_group_id[count.index],
      "rule",
      "_",
    )][2],
  )
  from_port = tostring(lookup(
    var.egress_with_source_security_group_id[count.index],
    "protocol",
    var.rules[lookup(
      var.egress_with_source_security_group_id[count.index],
      "rule",
      "_",
    )][2],
    )) == "-1" ? null : lookup(
    var.egress_with_source_security_group_id[count.index],
    "from_port",
    var.rules[lookup(
      var.egress_with_source_security_group_id[count.index],
      "rule",
      "_",
    )][0],
  )
  to_port = tostring(lookup(
    var.egress_with_source_security_group_id[count.index],
    "protocol",
    var.rules[lookup(
      var.egress_with_source_security_group_id[count.index],
      "rule",
      "_",
    )][2],
    )) == "-1" ? null : lookup(
    var.egress_with_source_security_group_id[count.index],
    "to_port",
    var.rules[lookup(
      var.egress_with_source_security_group_id[count.index],
      "rule",
      "_",
    )][1],
  )

  tags = local.tags
}

# Computed - Security group rules with "source_security_group_id", but without "cidr_blocks" and "self"
resource "aws_vpc_security_group_egress_rule" "computed_egress_with_source_security_group_id" {
  count = local.enabled ? var.number_of_computed_egress_with_source_security_group_id : 0

  security_group_id            = local.this_sg_id
  referenced_security_group_id = var.computed_egress_with_source_security_group_id[count.index]["source_security_group_id"]
  prefix_list_id               = length(var.egress_prefix_list_ids) > 0 ? var.egress_prefix_list_ids[0] : null
  description = lookup(
    var.computed_egress_with_source_security_group_id[count.index],
    "description",
    "Egress Rule",
  )

  ip_protocol = lookup(
    var.computed_egress_with_source_security_group_id[count.index],
    "protocol",
    var.rules[lookup(
      var.computed_egress_with_source_security_group_id[count.index],
      "rule",
      "_",
    )][2],
  )
  from_port = tostring(lookup(
    var.computed_egress_with_source_security_group_id[count.index],
    "protocol",
    var.rules[lookup(
      var.computed_egress_with_source_security_group_id[count.index],
      "rule",
      "_",
    )][2],
    )) == "-1" ? null : lookup(
    var.computed_egress_with_source_security_group_id[count.index],
    "from_port",
    var.rules[lookup(
      var.computed_egress_with_source_security_group_id[count.index],
      "rule",
      "_",
    )][0],
  )
  to_port = tostring(lookup(
    var.computed_egress_with_source_security_group_id[count.index],
    "protocol",
    var.rules[lookup(
      var.computed_egress_with_source_security_group_id[count.index],
      "rule",
      "_",
    )][2],
    )) == "-1" ? null : lookup(
    var.computed_egress_with_source_security_group_id[count.index],
    "to_port",
    var.rules[lookup(
      var.computed_egress_with_source_security_group_id[count.index],
      "rule",
      "_",
    )][1],
  )

  tags = local.tags
}

# Security group rules with "cidr_blocks", but without "ipv6_cidr_blocks", "source_security_group_id" and "self"
resource "aws_vpc_security_group_egress_rule" "egress_with_cidr_blocks" {
  count = local.enabled ? length(var.egress_with_cidr_blocks) : 0

  security_group_id = local.this_sg_id
  cidr_ipv4 = compact(split(
    ",",
    lookup(
      var.egress_with_cidr_blocks[count.index],
      "cidr_blocks",
      join(",", var.egress_cidr_blocks),
    ),
  ))[0]

  description = lookup(
    var.egress_with_cidr_blocks[count.index],
    "description",
    "Egress Rule",
  )

  ip_protocol = lookup(
    var.egress_with_cidr_blocks[count.index],
    "protocol",
    var.rules[lookup(var.egress_with_cidr_blocks[count.index], "rule", "_")][2],
  )
  from_port = tostring(lookup(
    var.egress_with_cidr_blocks[count.index],
    "protocol",
    var.rules[lookup(var.egress_with_cidr_blocks[count.index], "rule", "_")][2],
    )) == "-1" ? null : lookup(
    var.egress_with_cidr_blocks[count.index],
    "from_port",
    var.rules[lookup(var.egress_with_cidr_blocks[count.index], "rule", "_")][0],
  )
  to_port = tostring(lookup(
    var.egress_with_cidr_blocks[count.index],
    "protocol",
    var.rules[lookup(var.egress_with_cidr_blocks[count.index], "rule", "_")][2],
    )) == "-1" ? null : lookup(
    var.egress_with_cidr_blocks[count.index],
    "to_port",
    var.rules[lookup(var.egress_with_cidr_blocks[count.index], "rule", "_")][1],
  )

  tags = local.tags
}

# Computed - Security group rules with "cidr_blocks", but without "ipv6_cidr_blocks", "source_security_group_id" and "self"
resource "aws_vpc_security_group_egress_rule" "computed_egress_with_cidr_blocks" {
  count = local.enabled ? var.number_of_computed_egress_with_cidr_blocks : 0

  security_group_id = local.this_sg_id
  cidr_ipv4 = compact(split(
    ",",
    lookup(
      var.computed_egress_with_cidr_blocks[count.index],
      "cidr_blocks",
      join(",", var.egress_cidr_blocks),
    ),
  ))[0]

  description = lookup(
    var.computed_egress_with_cidr_blocks[count.index],
    "description",
    "Egress Rule",
  )

  ip_protocol = lookup(
    var.computed_egress_with_cidr_blocks[count.index],
    "protocol",
    var.rules[lookup(
      var.computed_egress_with_cidr_blocks[count.index],
      "rule",
      "_",
    )][2],
  )
  from_port = tostring(lookup(
    var.computed_egress_with_cidr_blocks[count.index],
    "protocol",
    var.rules[lookup(
      var.computed_egress_with_cidr_blocks[count.index],
      "rule",
      "_",
    )][2],
    )) == "-1" ? null : lookup(
    var.computed_egress_with_cidr_blocks[count.index],
    "from_port",
    var.rules[lookup(
      var.computed_egress_with_cidr_blocks[count.index],
      "rule",
      "_",
    )][0],
  )
  to_port = tostring(lookup(
    var.computed_egress_with_cidr_blocks[count.index],
    "protocol",
    var.rules[lookup(
      var.computed_egress_with_cidr_blocks[count.index],
      "rule",
      "_",
    )][2],
    )) == "-1" ? null : lookup(
    var.computed_egress_with_cidr_blocks[count.index],
    "to_port",
    var.rules[lookup(
      var.computed_egress_with_cidr_blocks[count.index],
      "rule",
      "_",
    )][1],
  )

  tags = local.tags
}

# Security group rules with "ipv6_cidr_blocks", but without "cidr_blocks", "source_security_group_id" and "self"
resource "aws_vpc_security_group_egress_rule" "egress_with_ipv6_cidr_blocks" {
  count = local.enabled ? length(var.egress_with_ipv6_cidr_blocks) : 0

  security_group_id = local.this_sg_id
  cidr_ipv6 = compact(split(
    ",",
    lookup(
      var.egress_with_ipv6_cidr_blocks[count.index],
      "ipv6_cidr_blocks",
      join(",", var.egress_ipv6_cidr_blocks),
    ),
  ))[0]
  prefix_list_id = length(var.egress_prefix_list_ids) > 0 ? var.egress_prefix_list_ids[0] : null
  description = lookup(
    var.egress_with_ipv6_cidr_blocks[count.index],
    "description",
    "Egress Rule",
  )

  ip_protocol = lookup(
    var.egress_with_ipv6_cidr_blocks[count.index],
    "protocol",
    var.rules[lookup(var.egress_with_ipv6_cidr_blocks[count.index], "rule", "_")][2],
  )
  from_port = tostring(lookup(
    var.egress_with_ipv6_cidr_blocks[count.index],
    "protocol",
    var.rules[lookup(var.egress_with_ipv6_cidr_blocks[count.index], "rule", "_")][2],
    )) == "-1" ? null : lookup(
    var.egress_with_ipv6_cidr_blocks[count.index],
    "from_port",
    var.rules[lookup(var.egress_with_ipv6_cidr_blocks[count.index], "rule", "_")][0],
  )
  to_port = tostring(lookup(
    var.egress_with_ipv6_cidr_blocks[count.index],
    "protocol",
    var.rules[lookup(var.egress_with_ipv6_cidr_blocks[count.index], "rule", "_")][2],
    )) == "-1" ? null : lookup(
    var.egress_with_ipv6_cidr_blocks[count.index],
    "to_port",
    var.rules[lookup(var.egress_with_ipv6_cidr_blocks[count.index], "rule", "_")][1],
  )

  tags = local.tags
}

# Computed - Security group rules with "ipv6_cidr_blocks", but without "cidr_blocks", "source_security_group_id" and "self"
resource "aws_vpc_security_group_egress_rule" "computed_egress_with_ipv6_cidr_blocks" {
  count = local.enabled ? var.number_of_computed_egress_with_ipv6_cidr_blocks : 0

  security_group_id = local.this_sg_id
  cidr_ipv6 = compact(split(
    ",",
    lookup(
      var.computed_egress_with_ipv6_cidr_blocks[count.index],
      "ipv6_cidr_blocks",
      join(",", var.egress_ipv6_cidr_blocks),
    ),
  ))[0]
  prefix_list_id = length(var.egress_prefix_list_ids) > 0 ? var.egress_prefix_list_ids[0] : null
  description = lookup(
    var.computed_egress_with_ipv6_cidr_blocks[count.index],
    "description",
    "Egress Rule",
  )

  ip_protocol = lookup(
    var.computed_egress_with_ipv6_cidr_blocks[count.index],
    "protocol",
    var.rules[lookup(
      var.computed_egress_with_ipv6_cidr_blocks[count.index],
      "rule",
      "_",
    )][2],
  )
  from_port = tostring(lookup(
    var.computed_egress_with_ipv6_cidr_blocks[count.index],
    "protocol",
    var.rules[lookup(
      var.computed_egress_with_ipv6_cidr_blocks[count.index],
      "rule",
      "_",
    )][2],
    )) == "-1" ? null : lookup(
    var.computed_egress_with_ipv6_cidr_blocks[count.index],
    "from_port",
    var.rules[lookup(
      var.computed_egress_with_ipv6_cidr_blocks[count.index],
      "rule",
      "_",
    )][0],
  )
  to_port = tostring(lookup(
    var.computed_egress_with_ipv6_cidr_blocks[count.index],
    "protocol",
    var.rules[lookup(
      var.computed_egress_with_ipv6_cidr_blocks[count.index],
      "rule",
      "_",
    )][2],
    )) == "-1" ? null : lookup(
    var.computed_egress_with_ipv6_cidr_blocks[count.index],
    "to_port",
    var.rules[lookup(
      var.computed_egress_with_ipv6_cidr_blocks[count.index],
      "rule",
      "_",
    )][1],
  )

  tags = local.tags
}

# Security group rules with "self", but without "cidr_blocks" and "source_security_group_id"
resource "aws_vpc_security_group_egress_rule" "egress_with_self" {
  count = local.enabled ? length(var.egress_with_self) : 0

  security_group_id            = local.this_sg_id
  referenced_security_group_id = local.this_sg_id
  prefix_list_id               = length(var.egress_prefix_list_ids) > 0 ? var.egress_prefix_list_ids[0] : null
  description = lookup(
    var.egress_with_self[count.index],
    "description",
    "Egress Rule",
  )

  ip_protocol = lookup(
    var.egress_with_self[count.index],
    "protocol",
    var.rules[lookup(var.egress_with_self[count.index], "rule", "_")][2],
  )
  from_port = tostring(lookup(
    var.egress_with_self[count.index],
    "protocol",
    var.rules[lookup(var.egress_with_self[count.index], "rule", "_")][2],
    )) == "-1" ? null : lookup(
    var.egress_with_self[count.index],
    "from_port",
    var.rules[lookup(var.egress_with_self[count.index], "rule", "_")][0],
  )
  to_port = tostring(lookup(
    var.egress_with_self[count.index],
    "protocol",
    var.rules[lookup(var.egress_with_self[count.index], "rule", "_")][2],
    )) == "-1" ? null : lookup(
    var.egress_with_self[count.index],
    "to_port",
    var.rules[lookup(var.egress_with_self[count.index], "rule", "_")][1],
  )

  tags = local.tags
}

# Computed - Security group rules with "self", but without "cidr_blocks" and "source_security_group_id"
resource "aws_vpc_security_group_egress_rule" "computed_egress_with_self" {
  count = local.enabled ? var.number_of_computed_egress_with_self : 0

  security_group_id            = local.this_sg_id
  referenced_security_group_id = local.this_sg_id
  prefix_list_id               = length(var.egress_prefix_list_ids) > 0 ? var.egress_prefix_list_ids[0] : null
  description = lookup(
    var.computed_egress_with_self[count.index],
    "description",
    "Egress Rule",
  )

  ip_protocol = lookup(
    var.computed_egress_with_self[count.index],
    "protocol",
    var.rules[lookup(var.computed_egress_with_self[count.index], "rule", "_")][2],
  )
  from_port = tostring(lookup(
    var.computed_egress_with_self[count.index],
    "protocol",
    var.rules[lookup(var.computed_egress_with_self[count.index], "rule", "_")][2],
    )) == "-1" ? null : lookup(
    var.computed_egress_with_self[count.index],
    "from_port",
    var.rules[lookup(var.computed_egress_with_self[count.index], "rule", "_")][0],
  )
  to_port = tostring(lookup(
    var.computed_egress_with_self[count.index],
    "protocol",
    var.rules[lookup(var.computed_egress_with_self[count.index], "rule", "_")][2],
    )) == "-1" ? null : lookup(
    var.computed_egress_with_self[count.index],
    "to_port",
    var.rules[lookup(var.computed_egress_with_self[count.index], "rule", "_")][1],
  )

  tags = local.tags
}

# Security group rules with "egress_prefix_list_ids", but without "cidr_blocks", "self" or "source_security_group_id"
resource "aws_vpc_security_group_egress_rule" "egress_with_prefix_list_ids" {
  count = local.enabled ? length(var.egress_with_prefix_list_ids) : 0

  security_group_id = local.this_sg_id
  prefix_list_id = compact(split(
    ",",
    lookup(
      var.egress_with_prefix_list_ids[count.index],
      "prefix_list_ids",
      join(",", var.egress_prefix_list_ids)
    ))
  )[0]

  description = lookup(
    var.egress_with_prefix_list_ids[count.index],
    "description",
    "Egress Rule",
  )

  ip_protocol = lookup(
    var.egress_with_prefix_list_ids[count.index],
    "protocol",
    var.rules[lookup(
      var.egress_with_prefix_list_ids[count.index],
      "rule",
      "_",
    )][2],
  )
  from_port = tostring(lookup(
    var.egress_with_prefix_list_ids[count.index],
    "protocol",
    var.rules[lookup(
      var.egress_with_prefix_list_ids[count.index],
      "rule",
      "_",
    )][2],
    )) == "-1" ? null : lookup(
    var.egress_with_prefix_list_ids[count.index],
    "from_port",
    var.rules[lookup(
      var.egress_with_prefix_list_ids[count.index],
      "rule",
      "_",
    )][0],
  )
  to_port = tostring(lookup(
    var.egress_with_prefix_list_ids[count.index],
    "protocol",
    var.rules[lookup(
      var.egress_with_prefix_list_ids[count.index],
      "rule",
      "_",
    )][2],
    )) == "-1" ? null : lookup(
    var.egress_with_prefix_list_ids[count.index],
    "to_port",
    var.rules[lookup(
      var.egress_with_prefix_list_ids[count.index],
      "rule",
      "_",
    )][1],
  )

  tags = local.tags
}

# Computed - Security group rules with "prefix_list_ids"
resource "aws_vpc_security_group_egress_rule" "computed_egress_with_prefix_list_ids" {
  count = local.enabled ? var.number_of_computed_egress_with_prefix_list_ids : 0

  security_group_id = local.this_sg_id
  prefix_list_id = compact(split(
    ",",
    lookup(
      var.computed_egress_with_prefix_list_ids[count.index],
      "prefix_list_ids",
      join(",", var.egress_prefix_list_ids)
    )
  ))[0]

  description = lookup(
    var.computed_egress_with_prefix_list_ids[count.index],
    "description",
    "Egress Rule",
  )

  ip_protocol = lookup(
    var.computed_egress_with_prefix_list_ids[count.index],
    "protocol",
    var.rules[lookup(
      var.computed_egress_with_prefix_list_ids[count.index],
      "rule",
      "_",
    )][2],
  )
  from_port = tostring(lookup(
    var.computed_egress_with_prefix_list_ids[count.index],
    "protocol",
    var.rules[lookup(
      var.computed_egress_with_prefix_list_ids[count.index],
      "rule",
      "_",
    )][2],
    )) == "-1" ? null : lookup(
    var.computed_egress_with_prefix_list_ids[count.index],
    "from_port",
    var.rules[lookup(
      var.computed_egress_with_prefix_list_ids[count.index],
      "rule",
      "_",
    )][0],
  )
  to_port = tostring(lookup(
    var.computed_egress_with_prefix_list_ids[count.index],
    "protocol",
    var.rules[lookup(
      var.computed_egress_with_prefix_list_ids[count.index],
      "rule",
      "_",
    )][2],
    )) == "-1" ? null : lookup(
    var.computed_egress_with_prefix_list_ids[count.index],
    "to_port",
    var.rules[lookup(
      var.computed_egress_with_prefix_list_ids[count.index],
      "rule",
      "_",
    )][1],
  )

  tags = local.tags
}

###############################################################################################################
# End of egress
###############################################################################################################
