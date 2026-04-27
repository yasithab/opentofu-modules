locals {
  name = var.name

  len_public_subnets      = max(length(var.public_subnets), length(var.public_subnet_ipv6_prefixes))
  len_private_subnets     = max(length(var.private_subnets), length(var.private_subnet_ipv6_prefixes))
  len_database_subnets    = max(length(var.database_subnets), length(var.database_subnet_ipv6_prefixes))
  len_elasticache_subnets = max(length(var.elasticache_subnets), length(var.elasticache_subnet_ipv6_prefixes))
  len_redshift_subnets    = max(length(var.redshift_subnets), length(var.redshift_subnet_ipv6_prefixes))
  len_intra_subnets       = max(length(var.intra_subnets), length(var.intra_subnet_ipv6_prefixes))
  len_outpost_subnets     = max(length(var.outpost_subnets), length(var.outpost_subnet_ipv6_prefixes))

  max_subnet_length = max(
    local.len_private_subnets,
    local.len_public_subnets,
    local.len_elasticache_subnets,
    local.len_database_subnets,
    local.len_redshift_subnets,
  )

  # Use `local.vpc_id` to give a hint to Terraform that subnets should be deleted before secondary CIDR blocks can be free!
  vpc_id = try(aws_vpc_ipv4_cidr_block_association.this[0].vpc_id, aws_vpc.this.id, "")

  enabled = var.enabled

  nat_type = var.nat_gateway_type

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

################################################################################
# VPC
################################################################################

resource "aws_vpc" "this" {
  cidr_block          = var.use_ipam_pool ? null : var.cidr
  ipv4_ipam_pool_id   = var.ipv4_ipam_pool_id
  ipv4_netmask_length = var.ipv4_netmask_length

  assign_generated_ipv6_cidr_block     = var.enable_ipv6 && !var.use_ipam_pool ? true : null
  ipv6_cidr_block                      = var.ipv6_cidr
  ipv6_ipam_pool_id                    = var.ipv6_ipam_pool_id
  ipv6_netmask_length                  = var.ipv6_netmask_length
  ipv6_cidr_block_network_border_group = var.ipv6_cidr_block_network_border_group

  instance_tenancy                     = var.instance_tenancy
  enable_dns_hostnames                 = var.enable_dns_hostnames
  enable_dns_support                   = var.enable_dns_support
  enable_network_address_usage_metrics = var.enable_network_address_usage_metrics

  tags = merge(local.tags, var.vpc_tags, { "Name" = local.name })

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_vpc_ipv4_cidr_block_association" "this" {
  count = local.enabled && length(var.secondary_cidr_blocks) > 0 ? length(var.secondary_cidr_blocks) : 0

  # Do not turn this into `local.vpc_id`
  vpc_id = aws_vpc.this.id

  cidr_block = element(var.secondary_cidr_blocks, count.index)
}

resource "aws_vpc_block_public_access_options" "this" {
  internet_gateway_block_mode = try(var.vpc_block_public_access_options["internet_gateway_block_mode"], null)

  lifecycle {
    enabled = local.enabled && length(keys(var.vpc_block_public_access_options)) > 0
  }
}

resource "aws_vpc_block_public_access_exclusion" "this" {
  for_each = { for k, v in var.vpc_block_public_access_exclusions : k => v if local.enabled }

  vpc_id = lookup(each.value, "exclude_vpc", false) ? local.vpc_id : null

  subnet_id = lookup(each.value, "exclude_subnet", false) ? lookup(
    {
      private     = aws_subnet.private[*].id,
      public      = aws_subnet.public[*].id,
      database    = aws_subnet.database[*].id,
      redshift    = aws_subnet.redshift[*].id,
      elasticache = aws_subnet.elasticache[*].id,
      intra       = aws_subnet.intra[*].id,
      outpost     = aws_subnet.outpost[*].id
    },
    each.value.subnet_type,
    null
  )[each.value.subnet_index] : null

  internet_gateway_exclusion_mode = each.value.internet_gateway_exclusion_mode

  tags = local.tags
}

################################################################################
# DHCP Options Set
################################################################################

resource "aws_vpc_dhcp_options" "this" {
  domain_name                       = var.dhcp_options_domain_name
  domain_name_servers               = var.dhcp_options_domain_name_servers
  ntp_servers                       = var.dhcp_options_ntp_servers
  netbios_name_servers              = var.dhcp_options_netbios_name_servers
  netbios_node_type                 = var.dhcp_options_netbios_node_type
  ipv6_address_preferred_lease_time = var.dhcp_options_ipv6_address_preferred_lease_time

  tags = merge(local.tags, var.dhcp_options_tags, { "Name" = local.name })

  lifecycle {
    enabled = local.enabled && var.enable_dhcp_options
  }
}

resource "aws_vpc_dhcp_options_association" "this" {
  vpc_id          = local.vpc_id
  dhcp_options_id = aws_vpc_dhcp_options.this.id

  lifecycle {
    enabled = local.enabled && var.enable_dhcp_options
  }
}

################################################################################
# Publiс Subnets
################################################################################

locals {
  create_public_subnets = local.enabled && local.len_public_subnets > 0
}

resource "aws_subnet" "public" {
  count = local.create_public_subnets && (local.nat_type != "multi_az" || local.len_public_subnets >= length(var.azs)) ? local.len_public_subnets : 0

  assign_ipv6_address_on_creation                = var.enable_ipv6 && var.public_subnet_ipv6_native ? true : var.public_subnet_assign_ipv6_address_on_creation
  availability_zone                              = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id                           = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  cidr_block                                     = var.public_subnet_ipv6_native ? null : element(concat(var.public_subnets, [""]), count.index)
  enable_dns64                                   = var.enable_ipv6 && var.public_subnet_enable_dns64
  enable_resource_name_dns_aaaa_record_on_launch = var.enable_ipv6 && var.public_subnet_enable_resource_name_dns_aaaa_record_on_launch
  enable_resource_name_dns_a_record_on_launch    = !var.public_subnet_ipv6_native && var.public_subnet_enable_resource_name_dns_a_record_on_launch
  ipv6_cidr_block                                = var.enable_ipv6 && length(var.public_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, var.public_subnet_ipv6_prefixes[count.index]) : null
  ipv6_native                                    = var.enable_ipv6 && var.public_subnet_ipv6_native
  map_public_ip_on_launch                        = var.map_public_ip_on_launch
  private_dns_hostname_type_on_launch            = var.public_subnet_private_dns_hostname_type_on_launch
  vpc_id                                         = local.vpc_id

  tags = merge(local.tags, {
    Name = try(
      var.public_subnet_names[count.index],
      format("${local.name}-${var.public_subnet_suffix}-%s", element(var.azs, count.index))
    )
  }, var.public_subnet_tags, lookup(var.public_subnet_tags_per_az, element(var.azs, count.index), {}))
}

locals {
  num_public_route_tables = var.create_multiple_public_route_tables ? local.len_public_subnets : 1
}

resource "aws_route_table" "public" {
  count = local.create_public_subnets ? local.num_public_route_tables : 0

  vpc_id = local.vpc_id

  tags = merge(local.tags, {
    "Name" = var.create_multiple_public_route_tables ? format(
      "${local.name}-${var.public_subnet_suffix}-%s",
      element(var.azs, count.index),
    ) : "${local.name}-${var.public_subnet_suffix}"
  }, var.public_route_table_tags)
}

resource "aws_route_table_association" "public" {
  count = local.create_public_subnets ? local.len_public_subnets : 0

  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = element(aws_route_table.public[*].id, var.create_multiple_public_route_tables ? count.index : 0)
}

resource "aws_route" "public_internet_gateway" {
  count = local.create_public_subnets && var.create_igw ? local.num_public_route_tables : 0

  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "public_internet_gateway_ipv6" {
  count = local.create_public_subnets && var.create_igw && var.enable_ipv6 ? local.num_public_route_tables : 0

  route_table_id              = aws_route_table.public[count.index].id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.this.id
}

################################################################################
# Public Network ACLs
################################################################################

resource "aws_network_acl" "public" {
  vpc_id     = local.vpc_id
  subnet_ids = aws_subnet.public[*].id

  tags = merge(local.tags, { "Name" = "${local.name}-${var.public_subnet_suffix}" }, var.public_acl_tags)

  lifecycle {
    enabled = local.create_public_subnets && var.public_dedicated_network_acl
  }
}

resource "aws_network_acl_rule" "public_inbound" {
  count = local.create_public_subnets && var.public_dedicated_network_acl ? length(var.public_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.public.id

  egress          = false
  rule_number     = var.public_inbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.public_inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.public_inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.public_inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.public_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.public_inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.public_inbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.public_inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.public_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "public_outbound" {
  count = local.create_public_subnets && var.public_dedicated_network_acl ? length(var.public_outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.public.id

  egress          = true
  rule_number     = var.public_outbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.public_outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.public_outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.public_outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.public_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.public_outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.public_outbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.public_outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.public_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

################################################################################
# Private Subnets
################################################################################

locals {
  create_private_subnets = local.enabled && local.len_private_subnets > 0
}

resource "aws_subnet" "private" {
  count = local.create_private_subnets ? local.len_private_subnets : 0

  assign_ipv6_address_on_creation                = var.enable_ipv6 && var.private_subnet_ipv6_native ? true : var.private_subnet_assign_ipv6_address_on_creation
  availability_zone                              = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id                           = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  cidr_block                                     = var.private_subnet_ipv6_native ? null : element(concat(var.private_subnets, [""]), count.index)
  enable_dns64                                   = var.enable_ipv6 && var.private_subnet_enable_dns64
  enable_resource_name_dns_aaaa_record_on_launch = var.enable_ipv6 && var.private_subnet_enable_resource_name_dns_aaaa_record_on_launch
  enable_resource_name_dns_a_record_on_launch    = !var.private_subnet_ipv6_native && var.private_subnet_enable_resource_name_dns_a_record_on_launch
  ipv6_cidr_block                                = var.enable_ipv6 && length(var.private_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, var.private_subnet_ipv6_prefixes[count.index]) : null
  ipv6_native                                    = var.enable_ipv6 && var.private_subnet_ipv6_native
  private_dns_hostname_type_on_launch            = var.private_subnet_private_dns_hostname_type_on_launch
  vpc_id                                         = local.vpc_id

  tags = merge(local.tags, {
    Name = try(
      var.private_subnet_names[count.index],
      format("${local.name}-${var.private_subnet_suffix}-%s", element(var.azs, count.index))
    )
  }, var.private_subnet_tags, lookup(var.private_subnet_tags_per_az, element(var.azs, count.index), {}))
}

locals {
  num_private_route_tables = var.enable_nat_gateway && local.nat_type == "multi_az" && var.create_multiple_private_route_tables && local.len_private_subnets > 0 ? local.len_private_subnets : (local.len_private_subnets > 0 ? 1 : 0)
}

# One route table per AZ when multi_az, otherwise one shared route table
resource "aws_route_table" "private" {
  count = local.create_private_subnets && local.max_subnet_length > 0 ? local.num_private_route_tables : 0

  vpc_id = local.vpc_id

  tags = merge(local.tags, {
    "Name" = local.num_private_route_tables == 1 ? "${local.name}-${var.private_subnet_suffix}" : format(
      "${local.name}-${var.private_subnet_suffix}-%s",
      element(var.azs, count.index),
    )
  }, var.private_route_table_tags)
}

resource "aws_route_table_association" "private" {
  count = local.create_private_subnets ? local.len_private_subnets : 0

  subnet_id = element(aws_subnet.private[*].id, count.index)
  route_table_id = element(
    aws_route_table.private[*].id,
    local.num_private_route_tables == 1 ? 0 : count.index,
  )
}

################################################################################
# Private Network ACLs
################################################################################

locals {
  create_private_network_acl = local.create_private_subnets && var.private_dedicated_network_acl
}

resource "aws_network_acl" "private" {
  vpc_id     = local.vpc_id
  subnet_ids = aws_subnet.private[*].id

  tags = merge(local.tags, { "Name" = "${local.name}-${var.private_subnet_suffix}" }, var.private_acl_tags)

  lifecycle {
    enabled = local.create_private_network_acl
  }
}

resource "aws_network_acl_rule" "private_inbound" {
  count = local.create_private_network_acl ? length(var.private_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.private.id

  egress          = false
  rule_number     = var.private_inbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.private_inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.private_inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.private_inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.private_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.private_inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.private_inbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.private_inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.private_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "private_outbound" {
  count = local.create_private_network_acl ? length(var.private_outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.private.id

  egress          = true
  rule_number     = var.private_outbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.private_outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.private_outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.private_outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.private_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.private_outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.private_outbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.private_outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.private_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

################################################################################
# Database Subnets
################################################################################

locals {
  create_database_subnets     = local.enabled && local.len_database_subnets > 0
  create_database_route_table = local.create_database_subnets && var.create_database_subnet_route_table
}

resource "aws_subnet" "database" {
  count = local.create_database_subnets ? local.len_database_subnets : 0

  assign_ipv6_address_on_creation                = var.enable_ipv6 && var.database_subnet_ipv6_native ? true : var.database_subnet_assign_ipv6_address_on_creation
  availability_zone                              = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id                           = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  cidr_block                                     = var.database_subnet_ipv6_native ? null : element(concat(var.database_subnets, [""]), count.index)
  enable_dns64                                   = var.enable_ipv6 && var.database_subnet_enable_dns64
  enable_resource_name_dns_aaaa_record_on_launch = var.enable_ipv6 && var.database_subnet_enable_resource_name_dns_aaaa_record_on_launch
  enable_resource_name_dns_a_record_on_launch    = !var.database_subnet_ipv6_native && var.database_subnet_enable_resource_name_dns_a_record_on_launch
  ipv6_cidr_block                                = var.enable_ipv6 && length(var.database_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, var.database_subnet_ipv6_prefixes[count.index]) : null
  ipv6_native                                    = var.enable_ipv6 && var.database_subnet_ipv6_native
  private_dns_hostname_type_on_launch            = var.database_subnet_private_dns_hostname_type_on_launch
  vpc_id                                         = local.vpc_id

  tags = merge(local.tags, {
    Name = try(
      var.database_subnet_names[count.index],
      format("${local.name}-${var.database_subnet_suffix}-%s", element(var.azs, count.index), )
    )
  }, var.database_subnet_tags)
}

resource "aws_db_subnet_group" "database" {
  name        = lower(coalesce(var.database_subnet_group_name, local.name))
  description = "Database subnet group for ${local.name}"
  subnet_ids  = aws_subnet.database[*].id

  tags = merge(local.tags, {
    "Name" = lower(coalesce(var.database_subnet_group_name, local.name))
  }, var.database_subnet_group_tags)

  lifecycle {
    enabled = local.create_database_subnets && var.create_database_subnet_group
  }
}

locals {
  num_database_route_tables = var.create_multiple_database_route_tables && local.len_database_subnets > 0 ? local.len_database_subnets : (local.len_database_subnets > 0 ? 1 : 0)
}

resource "aws_route_table" "database" {
  count = local.create_database_route_table ? (local.num_database_route_tables == 1 || local.nat_type != "multi_az" || var.create_database_internet_gateway_route ? 1 : local.len_database_subnets) : 0

  vpc_id = local.vpc_id

  tags = merge(local.tags, {
    "Name" = local.num_database_route_tables == 1 || local.nat_type != "multi_az" || var.create_database_internet_gateway_route ? "${local.name}-${var.database_subnet_suffix}" : format(
      "${local.name}-${var.database_subnet_suffix}-%s",
      element(var.azs, count.index),
    )
  }, var.database_route_table_tags)
}

resource "aws_route_table_association" "database" {
  count = local.create_database_subnets ? local.len_database_subnets : 0

  subnet_id = element(aws_subnet.database[*].id, count.index)
  route_table_id = element(
    coalescelist(aws_route_table.database[*].id, aws_route_table.private[*].id),
    var.create_database_subnet_route_table
    ? (local.num_database_route_tables == 1 || local.nat_type != "multi_az" || var.create_database_internet_gateway_route ? 0 : count.index)
    : count.index,
  )
}

resource "aws_route" "database_internet_gateway" {
  count = local.create_database_route_table && var.create_igw && var.create_database_internet_gateway_route && !var.create_database_nat_gateway_route ? (local.num_database_route_tables == 1 ? 1 : local.len_database_subnets) : 0

  route_table_id         = aws_route_table.database[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id

  timeouts {
    create = "5m"
  }
}


resource "aws_route" "database_nat_gateway" {
  count = local.create_database_route_table && !var.create_database_internet_gateway_route && var.create_database_nat_gateway_route && var.enable_nat_gateway && local.nat_type != "regional" ? (local.num_database_route_tables == 1 || local.nat_type == "single" ? 1 : local.len_database_subnets) : 0

  route_table_id         = element(aws_route_table.database[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this[*].id, count.index)

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "database_regional_nat_gateway" {
  count = local.create_database_route_table && !var.create_database_internet_gateway_route && var.create_database_nat_gateway_route && var.enable_nat_gateway && local.nat_type == "regional" ? 1 : 0

  route_table_id         = aws_route_table.database[0].id
  destination_cidr_block = var.nat_gateway_destination_cidr_block
  nat_gateway_id         = aws_nat_gateway.regional[0].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "database_dns64_nat_gateway" {
  count = local.create_database_route_table && !var.create_database_internet_gateway_route && var.create_database_nat_gateway_route && var.enable_nat_gateway && var.enable_ipv6 && var.private_subnet_enable_dns64 && local.nat_type != "regional" ? (local.num_database_route_tables == 1 || local.nat_type == "single" ? 1 : local.len_database_subnets) : 0

  route_table_id              = element(aws_route_table.database[*].id, count.index)
  destination_ipv6_cidr_block = "64:ff9b::/96"
  nat_gateway_id              = element(aws_nat_gateway.this[*].id, count.index)

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "database_dns64_regional_nat_gateway" {
  count = local.create_database_route_table && !var.create_database_internet_gateway_route && var.create_database_nat_gateway_route && var.enable_nat_gateway && local.nat_type == "regional" && var.enable_ipv6 && var.private_subnet_enable_dns64 ? 1 : 0

  route_table_id              = aws_route_table.database[0].id
  destination_ipv6_cidr_block = "64:ff9b::/96"
  nat_gateway_id              = aws_nat_gateway.regional[0].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "database_ipv6_egress" {
  count = local.create_database_route_table && var.create_egress_only_igw && var.enable_ipv6 && var.create_database_internet_gateway_route ? (local.num_database_route_tables == 1 ? 1 : local.len_database_subnets) : 0

  route_table_id              = aws_route_table.database[0].id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.this.id

  timeouts {
    create = "5m"
  }
}

################################################################################
# Database Network ACLs
################################################################################

locals {
  create_database_network_acl = local.create_database_subnets && var.database_dedicated_network_acl
}

resource "aws_network_acl" "database" {
  vpc_id     = local.vpc_id
  subnet_ids = aws_subnet.database[*].id

  tags = merge(local.tags, { "Name" = "${local.name}-${var.database_subnet_suffix}" }, var.database_acl_tags)

  lifecycle {
    enabled = local.create_database_network_acl
  }
}

resource "aws_network_acl_rule" "database_inbound" {
  count = local.create_database_network_acl ? length(var.database_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.database.id

  egress          = false
  rule_number     = var.database_inbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.database_inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.database_inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.database_inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.database_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.database_inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.database_inbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.database_inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.database_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "database_outbound" {
  count = local.create_database_network_acl ? length(var.database_outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.database.id

  egress          = true
  rule_number     = var.database_outbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.database_outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.database_outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.database_outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.database_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.database_outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.database_outbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.database_outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.database_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

################################################################################
# Redshift Subnets
################################################################################

locals {
  create_redshift_subnets     = local.enabled && local.len_redshift_subnets > 0
  create_redshift_route_table = local.create_redshift_subnets && var.create_redshift_subnet_route_table
}

resource "aws_subnet" "redshift" {
  count = local.create_redshift_subnets ? local.len_redshift_subnets : 0

  assign_ipv6_address_on_creation                = var.enable_ipv6 && var.redshift_subnet_ipv6_native ? true : var.redshift_subnet_assign_ipv6_address_on_creation
  availability_zone                              = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id                           = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  cidr_block                                     = var.redshift_subnet_ipv6_native ? null : element(concat(var.redshift_subnets, [""]), count.index)
  enable_dns64                                   = var.enable_ipv6 && var.redshift_subnet_enable_dns64
  enable_resource_name_dns_aaaa_record_on_launch = var.enable_ipv6 && var.redshift_subnet_enable_resource_name_dns_aaaa_record_on_launch
  enable_resource_name_dns_a_record_on_launch    = !var.redshift_subnet_ipv6_native && var.redshift_subnet_enable_resource_name_dns_a_record_on_launch
  ipv6_cidr_block                                = var.enable_ipv6 && length(var.redshift_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, var.redshift_subnet_ipv6_prefixes[count.index]) : null
  ipv6_native                                    = var.enable_ipv6 && var.redshift_subnet_ipv6_native
  private_dns_hostname_type_on_launch            = var.redshift_subnet_private_dns_hostname_type_on_launch
  vpc_id                                         = local.vpc_id

  tags = merge(local.tags, {
    Name = try(
      var.redshift_subnet_names[count.index],
      format("${local.name}-${var.redshift_subnet_suffix}-%s", element(var.azs, count.index))
    )
  }, var.redshift_subnet_tags)
}

resource "aws_redshift_subnet_group" "redshift" {
  name        = lower(coalesce(var.redshift_subnet_group_name, local.name))
  description = "Redshift subnet group for ${local.name}"
  subnet_ids  = aws_subnet.redshift[*].id

  tags = merge(local.tags, { "Name" = coalesce(var.redshift_subnet_group_name, local.name) }, var.redshift_subnet_group_tags)

  lifecycle {
    enabled = local.create_redshift_subnets && var.create_redshift_subnet_group
  }
}

resource "aws_route_table" "redshift" {
  vpc_id = local.vpc_id

  tags = merge(local.tags, { "Name" = "${local.name}-${var.redshift_subnet_suffix}" }, var.redshift_route_table_tags)

  lifecycle {
    enabled = local.create_redshift_route_table
  }
}

resource "aws_route_table_association" "redshift" {
  count = local.create_redshift_subnets && !var.enable_public_redshift ? local.len_redshift_subnets : 0

  subnet_id = element(aws_subnet.redshift[*].id, count.index)
  route_table_id = element(
    coalescelist(try(aws_route_table.redshift.id, null), aws_route_table.private[*].id),
    local.nat_type != "multi_az" || var.create_redshift_subnet_route_table ? 0 : count.index,
  )
}

resource "aws_route_table_association" "redshift_public" {
  count = local.create_redshift_subnets && var.enable_public_redshift ? local.len_redshift_subnets : 0

  subnet_id = element(aws_subnet.redshift[*].id, count.index)
  route_table_id = element(
    coalescelist(try(aws_route_table.redshift.id, null), aws_route_table.public[*].id),
    local.nat_type != "multi_az" || var.create_redshift_subnet_route_table ? 0 : count.index,
  )
}

################################################################################
# Redshift Network ACLs
################################################################################

locals {
  create_redshift_network_acl = local.create_redshift_subnets && var.redshift_dedicated_network_acl
}

resource "aws_network_acl" "redshift" {
  vpc_id     = local.vpc_id
  subnet_ids = aws_subnet.redshift[*].id

  tags = merge(local.tags, { "Name" = "${local.name}-${var.redshift_subnet_suffix}" }, var.redshift_acl_tags)

  lifecycle {
    enabled = local.create_redshift_network_acl
  }
}

resource "aws_network_acl_rule" "redshift_inbound" {
  count = local.create_redshift_network_acl ? length(var.redshift_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.redshift.id

  egress          = false
  rule_number     = var.redshift_inbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.redshift_inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.redshift_inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.redshift_inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.redshift_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.redshift_inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.redshift_inbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.redshift_inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.redshift_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "redshift_outbound" {
  count = local.create_redshift_network_acl ? length(var.redshift_outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.redshift.id

  egress          = true
  rule_number     = var.redshift_outbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.redshift_outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.redshift_outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.redshift_outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.redshift_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.redshift_outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.redshift_outbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.redshift_outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.redshift_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

################################################################################
# Elasticache Subnets
################################################################################

locals {
  create_elasticache_subnets     = local.enabled && local.len_elasticache_subnets > 0
  create_elasticache_route_table = local.create_elasticache_subnets && var.create_elasticache_subnet_route_table
}

resource "aws_subnet" "elasticache" {
  count = local.create_elasticache_subnets ? local.len_elasticache_subnets : 0

  assign_ipv6_address_on_creation                = var.enable_ipv6 && var.elasticache_subnet_ipv6_native ? true : var.elasticache_subnet_assign_ipv6_address_on_creation
  availability_zone                              = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id                           = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  cidr_block                                     = var.elasticache_subnet_ipv6_native ? null : element(concat(var.elasticache_subnets, [""]), count.index)
  enable_dns64                                   = var.enable_ipv6 && var.elasticache_subnet_enable_dns64
  enable_resource_name_dns_aaaa_record_on_launch = var.enable_ipv6 && var.elasticache_subnet_enable_resource_name_dns_aaaa_record_on_launch
  enable_resource_name_dns_a_record_on_launch    = !var.elasticache_subnet_ipv6_native && var.elasticache_subnet_enable_resource_name_dns_a_record_on_launch
  ipv6_cidr_block                                = var.enable_ipv6 && length(var.elasticache_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, var.elasticache_subnet_ipv6_prefixes[count.index]) : null
  ipv6_native                                    = var.enable_ipv6 && var.elasticache_subnet_ipv6_native
  private_dns_hostname_type_on_launch            = var.elasticache_subnet_private_dns_hostname_type_on_launch
  vpc_id                                         = local.vpc_id

  tags = merge(local.tags, {
    Name = try(
      var.elasticache_subnet_names[count.index],
      format("${local.name}-${var.elasticache_subnet_suffix}-%s", element(var.azs, count.index))
    )
  }, var.elasticache_subnet_tags)
}

resource "aws_elasticache_subnet_group" "elasticache" {
  name        = coalesce(var.elasticache_subnet_group_name, local.name)
  description = "ElastiCache subnet group for ${local.name}"
  subnet_ids  = aws_subnet.elasticache[*].id

  tags = merge(local.tags, { "Name" = coalesce(var.elasticache_subnet_group_name, local.name) }, var.elasticache_subnet_group_tags)

  lifecycle {
    enabled = local.create_elasticache_subnets && var.create_elasticache_subnet_group
  }
}

resource "aws_route_table" "elasticache" {
  vpc_id = local.vpc_id

  tags = merge(local.tags, { "Name" = "${local.name}-${var.elasticache_subnet_suffix}" }, var.elasticache_route_table_tags)

  lifecycle {
    enabled = local.create_elasticache_route_table
  }
}

resource "aws_route_table_association" "elasticache" {
  count = local.create_elasticache_subnets ? local.len_elasticache_subnets : 0

  subnet_id = element(aws_subnet.elasticache[*].id, count.index)
  route_table_id = element(
    coalescelist(
      try(aws_route_table.elasticache.id, null),
      aws_route_table.private[*].id,
    ),
    local.nat_type != "multi_az" || var.create_elasticache_subnet_route_table ? 0 : count.index,
  )
}

################################################################################
# Elasticache Network ACLs
################################################################################

locals {
  create_elasticache_network_acl = local.create_elasticache_subnets && var.elasticache_dedicated_network_acl
}

resource "aws_network_acl" "elasticache" {
  vpc_id     = local.vpc_id
  subnet_ids = aws_subnet.elasticache[*].id

  tags = merge(local.tags, { "Name" = "${local.name}-${var.elasticache_subnet_suffix}" }, var.elasticache_acl_tags)

  lifecycle {
    enabled = local.create_elasticache_network_acl
  }
}

resource "aws_network_acl_rule" "elasticache_inbound" {
  count = local.create_elasticache_network_acl ? length(var.elasticache_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.elasticache.id

  egress          = false
  rule_number     = var.elasticache_inbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.elasticache_inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.elasticache_inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.elasticache_inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.elasticache_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.elasticache_inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.elasticache_inbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.elasticache_inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.elasticache_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "elasticache_outbound" {
  count = local.create_elasticache_network_acl ? length(var.elasticache_outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.elasticache.id

  egress          = true
  rule_number     = var.elasticache_outbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.elasticache_outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.elasticache_outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.elasticache_outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.elasticache_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.elasticache_outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.elasticache_outbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.elasticache_outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.elasticache_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

################################################################################
# Intra Subnets
################################################################################

locals {
  create_intra_subnets = local.enabled && local.len_intra_subnets > 0
}

resource "aws_subnet" "intra" {
  count = local.create_intra_subnets ? local.len_intra_subnets : 0

  assign_ipv6_address_on_creation                = var.enable_ipv6 && var.intra_subnet_ipv6_native ? true : var.intra_subnet_assign_ipv6_address_on_creation
  availability_zone                              = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id                           = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  cidr_block                                     = var.intra_subnet_ipv6_native ? null : element(concat(var.intra_subnets, [""]), count.index)
  enable_dns64                                   = var.enable_ipv6 && var.intra_subnet_enable_dns64
  enable_resource_name_dns_aaaa_record_on_launch = var.enable_ipv6 && var.intra_subnet_enable_resource_name_dns_aaaa_record_on_launch
  enable_resource_name_dns_a_record_on_launch    = !var.intra_subnet_ipv6_native && var.intra_subnet_enable_resource_name_dns_a_record_on_launch
  ipv6_cidr_block                                = var.enable_ipv6 && length(var.intra_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, var.intra_subnet_ipv6_prefixes[count.index]) : null
  ipv6_native                                    = var.enable_ipv6 && var.intra_subnet_ipv6_native
  private_dns_hostname_type_on_launch            = var.intra_subnet_private_dns_hostname_type_on_launch
  vpc_id                                         = local.vpc_id

  tags = merge(local.tags, {
    Name = try(
      var.intra_subnet_names[count.index],
      format("${local.name}-${var.intra_subnet_suffix}-%s", element(var.azs, count.index))
    )
  }, var.intra_subnet_tags)
}

locals {
  num_intra_route_tables = var.create_multiple_intra_route_tables ? local.len_intra_subnets : 1
}

resource "aws_route_table" "intra" {
  count = local.create_intra_subnets ? local.num_intra_route_tables : 0

  vpc_id = local.vpc_id

  tags = merge(local.tags, {
    "Name" = var.create_multiple_intra_route_tables ? format(
      "${local.name}-${var.intra_subnet_suffix}-%s",
      element(var.azs, count.index),
    ) : "${local.name}-${var.intra_subnet_suffix}"
  }, var.intra_route_table_tags)
}

resource "aws_route_table_association" "intra" {
  count = local.create_intra_subnets ? local.len_intra_subnets : 0

  subnet_id      = element(aws_subnet.intra[*].id, count.index)
  route_table_id = element(aws_route_table.intra[*].id, var.create_multiple_intra_route_tables ? count.index : 0)
}

################################################################################
# Intra Network ACLs
################################################################################

locals {
  create_intra_network_acl = local.create_intra_subnets && var.intra_dedicated_network_acl
}

resource "aws_network_acl" "intra" {
  vpc_id     = local.vpc_id
  subnet_ids = aws_subnet.intra[*].id

  tags = merge(local.tags, { "Name" = "${local.name}-${var.intra_subnet_suffix}" }, var.intra_acl_tags)

  lifecycle {
    enabled = local.create_intra_network_acl
  }
}

resource "aws_network_acl_rule" "intra_inbound" {
  count = local.create_intra_network_acl ? length(var.intra_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.intra.id

  egress          = false
  rule_number     = var.intra_inbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.intra_inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.intra_inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.intra_inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.intra_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.intra_inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.intra_inbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.intra_inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.intra_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "intra_outbound" {
  count = local.create_intra_network_acl ? length(var.intra_outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.intra.id

  egress          = true
  rule_number     = var.intra_outbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.intra_outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.intra_outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.intra_outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.intra_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.intra_outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.intra_outbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.intra_outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.intra_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

################################################################################
# Outpost Subnets
################################################################################

locals {
  create_outpost_subnets = local.enabled && local.len_outpost_subnets > 0
}

resource "aws_subnet" "outpost" {
  count = local.create_outpost_subnets ? local.len_outpost_subnets : 0

  assign_ipv6_address_on_creation                = var.enable_ipv6 && var.outpost_subnet_ipv6_native ? true : var.outpost_subnet_assign_ipv6_address_on_creation
  availability_zone                              = var.outpost_az
  cidr_block                                     = var.outpost_subnet_ipv6_native ? null : element(concat(var.outpost_subnets, [""]), count.index)
  customer_owned_ipv4_pool                       = var.customer_owned_ipv4_pool
  enable_dns64                                   = var.enable_ipv6 && var.outpost_subnet_enable_dns64
  enable_resource_name_dns_aaaa_record_on_launch = var.enable_ipv6 && var.outpost_subnet_enable_resource_name_dns_aaaa_record_on_launch
  enable_resource_name_dns_a_record_on_launch    = !var.outpost_subnet_ipv6_native && var.outpost_subnet_enable_resource_name_dns_a_record_on_launch
  ipv6_cidr_block                                = var.enable_ipv6 && length(var.outpost_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, var.outpost_subnet_ipv6_prefixes[count.index]) : null
  ipv6_native                                    = var.enable_ipv6 && var.outpost_subnet_ipv6_native
  map_customer_owned_ip_on_launch                = var.map_customer_owned_ip_on_launch
  outpost_arn                                    = var.outpost_arn
  private_dns_hostname_type_on_launch            = var.outpost_subnet_private_dns_hostname_type_on_launch
  vpc_id                                         = local.vpc_id

  tags = merge(local.tags, {
    Name = try(
      var.outpost_subnet_names[count.index],
      format("${local.name}-${var.outpost_subnet_suffix}-%s", var.outpost_az)
    )
  }, var.outpost_subnet_tags)
}

resource "aws_route_table_association" "outpost" {
  count = local.create_outpost_subnets ? local.len_outpost_subnets : 0

  subnet_id = element(aws_subnet.outpost[*].id, count.index)
  route_table_id = element(
    aws_route_table.private[*].id,
    local.nat_type != "multi_az" ? 0 : count.index,
  )
}

################################################################################
# Outpost Network ACLs
################################################################################

locals {
  create_outpost_network_acl = local.create_outpost_subnets && var.outpost_dedicated_network_acl
}

resource "aws_network_acl" "outpost" {
  vpc_id     = local.vpc_id
  subnet_ids = aws_subnet.outpost[*].id

  tags = merge(local.tags, { "Name" = "${local.name}-${var.outpost_subnet_suffix}" }, var.outpost_acl_tags)

  lifecycle {
    enabled = local.create_outpost_network_acl
  }
}

resource "aws_network_acl_rule" "outpost_inbound" {
  count = local.create_outpost_network_acl ? length(var.outpost_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.outpost.id

  egress          = false
  rule_number     = var.outpost_inbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.outpost_inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.outpost_inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.outpost_inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.outpost_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.outpost_inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.outpost_inbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.outpost_inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.outpost_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "outpost_outbound" {
  count = local.create_outpost_network_acl ? length(var.outpost_outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.outpost.id

  egress          = true
  rule_number     = var.outpost_outbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.outpost_outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.outpost_outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.outpost_outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.outpost_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.outpost_outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.outpost_outbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.outpost_outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.outpost_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

################################################################################
# Internet Gateway
################################################################################

resource "aws_internet_gateway" "this" {
  vpc_id = local.vpc_id

  tags = merge(local.tags, { "Name" = local.name }, var.igw_tags)

  lifecycle {
    enabled = local.create_public_subnets && var.create_igw
  }
}

resource "aws_egress_only_internet_gateway" "this" {
  vpc_id = local.vpc_id

  tags = merge(local.tags, { "Name" = local.name }, var.igw_tags)

  lifecycle {
    enabled = local.enabled && var.create_egress_only_igw && var.enable_ipv6 && local.max_subnet_length > 0
  }
}

resource "aws_route" "private_ipv6_egress" {
  count = local.enabled && var.create_egress_only_igw && var.enable_ipv6 && local.len_private_subnets > 0 ? local.num_private_route_tables : 0

  route_table_id              = element(aws_route_table.private[*].id, count.index)
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = element(try(aws_egress_only_internet_gateway.this.id, null), 0)
}

################################################################################
# NAT Gateway
################################################################################

locals {
  nat_gateway_count = {
    single   = 1
    multi_az = length(var.azs)
    regional = 0
  }[local.nat_type]
  nat_gateway_ips = var.reuse_nat_ips ? var.external_nat_ip_ids : aws_eip.nat[*].id
}

resource "aws_eip" "nat" {
  count = local.enabled && var.enable_nat_gateway && !var.reuse_nat_ips ? local.nat_gateway_count : 0

  domain = "vpc"

  tags = merge(local.tags, {
    "Name" = format(
      "${local.name}-%s",
      element(var.azs, local.nat_type == "single" ? 0 : count.index),
    )
  }, var.nat_eip_tags)

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = local.enabled && var.enable_nat_gateway ? local.nat_gateway_count : 0

  allocation_id = var.nat_gateway_connectivity_type == "public" ? element(
    local.nat_gateway_ips,
    local.nat_type == "single" ? 0 : count.index,
  ) : null
  subnet_id = element(
    var.nat_gateway_connectivity_type == "public" ? aws_subnet.public[*].id : aws_subnet.private[*].id,
    local.nat_type == "single" ? 0 : count.index,
  )
  connectivity_type = var.nat_gateway_connectivity_type

  secondary_allocation_ids           = length(var.nat_gateway_secondary_allocation_ids) > 0 ? var.nat_gateway_secondary_allocation_ids : null
  secondary_private_ip_address_count = var.nat_gateway_secondary_private_ip_address_count
  secondary_private_ip_addresses     = length(var.nat_gateway_secondary_private_ip_addresses) > 0 ? var.nat_gateway_secondary_private_ip_addresses : null

  tags = merge(local.tags, {
    "Name" = format(
      "${local.name}-%s",
      element(var.azs, local.nat_type == "single" ? 0 : count.index),
    )
  }, var.nat_gateway_tags)

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "regional" {
  count = local.enabled && var.enable_nat_gateway && local.nat_type == "regional" ? 1 : 0

  availability_mode = "regional"
  vpc_id            = local.vpc_id

  tags = merge(local.tags, {
    "Name" = "${local.name}-regional"
  }, var.nat_gateway_tags)

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route" "private_nat_gateway" {
  count = local.enabled && var.enable_nat_gateway && var.create_private_nat_gateway_route && local.nat_type != "regional" ? local.num_private_route_tables : 0

  route_table_id         = element(aws_route_table.private[*].id, count.index)
  destination_cidr_block = var.nat_gateway_destination_cidr_block
  nat_gateway_id         = element(aws_nat_gateway.this[*].id, count.index)

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "private_regional_nat_gateway" {
  count = local.enabled && var.enable_nat_gateway && local.nat_type == "regional" && var.create_private_nat_gateway_route ? local.num_private_route_tables : 0

  route_table_id         = element(aws_route_table.private[*].id, count.index)
  destination_cidr_block = var.nat_gateway_destination_cidr_block
  nat_gateway_id         = aws_nat_gateway.regional[0].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "private_dns64_nat_gateway" {
  count = local.enabled && var.enable_nat_gateway && var.enable_ipv6 && var.private_subnet_enable_dns64 && local.nat_type != "regional" ? local.num_private_route_tables : 0

  route_table_id              = element(aws_route_table.private[*].id, count.index)
  destination_ipv6_cidr_block = "64:ff9b::/96"
  nat_gateway_id              = element(aws_nat_gateway.this[*].id, count.index)

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "private_dns64_regional_nat_gateway" {
  count = local.enabled && var.enable_nat_gateway && local.nat_type == "regional" && var.enable_ipv6 && var.private_subnet_enable_dns64 ? local.num_private_route_tables : 0

  route_table_id              = element(aws_route_table.private[*].id, count.index)
  destination_ipv6_cidr_block = "64:ff9b::/96"
  nat_gateway_id              = aws_nat_gateway.regional[0].id

  timeouts {
    create = "5m"
  }
}

################################################################################
# Customer Gateways
################################################################################

resource "aws_customer_gateway" "this" {
  for_each = var.customer_gateways

  bgp_asn     = each.value["bgp_asn"]
  ip_address  = each.value["ip_address"]
  device_name = lookup(each.value, "device_name", null)
  type        = "ipsec.1"

  tags = merge(local.tags, { "Name" = "${local.name}-${each.key}" }, var.customer_gateway_tags)

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# VPN Gateway
################################################################################

resource "aws_vpn_gateway" "this" {
  vpc_id            = local.vpc_id
  amazon_side_asn   = var.amazon_side_asn
  availability_zone = var.vpn_gateway_az

  tags = merge(local.tags, { "Name" = local.name }, var.vpn_gateway_tags)

  lifecycle {
    enabled = local.enabled && var.enable_vpn_gateway
  }
}

resource "aws_vpn_gateway_attachment" "this" {
  vpc_id         = local.vpc_id
  vpn_gateway_id = var.vpn_gateway_id

  lifecycle {
    enabled = var.vpn_gateway_id != null
  }
}

resource "aws_vpn_gateway_route_propagation" "public" {
  count = local.enabled && var.propagate_public_route_tables_vgw && (var.enable_vpn_gateway || var.vpn_gateway_id != null) ? local.len_public_subnets : 0

  route_table_id = element(aws_route_table.public[*].id, count.index)
  vpn_gateway_id = element(
    concat(
      try(aws_vpn_gateway.this.id, null),
      try(aws_vpn_gateway_attachment.this.vpn_gateway_id, null),
    ),
    count.index,
  )
}

resource "aws_vpn_gateway_route_propagation" "private" {
  count = local.enabled && var.propagate_private_route_tables_vgw && (var.enable_vpn_gateway || var.vpn_gateway_id != null) ? local.len_private_subnets : 0

  route_table_id = element(aws_route_table.private[*].id, count.index)
  vpn_gateway_id = element(
    concat(
      try(aws_vpn_gateway.this.id, null),
      try(aws_vpn_gateway_attachment.this.vpn_gateway_id, null),
    ),
    count.index,
  )
}

resource "aws_vpn_gateway_route_propagation" "intra" {
  count = local.enabled && var.propagate_intra_route_tables_vgw && (var.enable_vpn_gateway || var.vpn_gateway_id != null) ? local.len_intra_subnets : 0

  route_table_id = element(aws_route_table.intra[*].id, count.index)
  vpn_gateway_id = element(
    concat(
      try(aws_vpn_gateway.this.id, null),
      try(aws_vpn_gateway_attachment.this.vpn_gateway_id, null),
    ),
    count.index,
  )
}

################################################################################
# Default VPC
################################################################################

# trivy:ignore:AVD-AWS-0101 - aws_default_vpc is used intentionally to manage (tag/delete) the default VPC; controlled by lifecycle { enabled = var.manage_default_vpc }
resource "aws_default_vpc" "this" {
  enable_dns_support   = var.default_vpc_enable_dns_support
  enable_dns_hostnames = var.default_vpc_enable_dns_hostnames

  tags = merge(local.tags, { "Name" = coalesce(var.default_vpc_name, "default") }, var.default_vpc_tags)

  lifecycle {
    enabled = var.manage_default_vpc
  }
}

resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  dynamic "ingress" {
    for_each = var.default_security_group_ingress
    content {
      self             = lookup(ingress.value, "self", null)
      cidr_blocks      = compact(split(",", lookup(ingress.value, "cidr_blocks", "")))
      ipv6_cidr_blocks = compact(split(",", lookup(ingress.value, "ipv6_cidr_blocks", "")))
      prefix_list_ids  = compact(split(",", lookup(ingress.value, "prefix_list_ids", "")))
      security_groups  = compact(split(",", lookup(ingress.value, "security_groups", "")))
      description      = lookup(ingress.value, "description", null)
      from_port        = lookup(ingress.value, "from_port", 0)
      to_port          = lookup(ingress.value, "to_port", 0)
      protocol         = lookup(ingress.value, "protocol", "-1")
    }
  }

  dynamic "egress" {
    for_each = var.default_security_group_egress
    content {
      self             = lookup(egress.value, "self", null)
      cidr_blocks      = compact(split(",", lookup(egress.value, "cidr_blocks", "")))
      ipv6_cidr_blocks = compact(split(",", lookup(egress.value, "ipv6_cidr_blocks", "")))
      prefix_list_ids  = compact(split(",", lookup(egress.value, "prefix_list_ids", "")))
      security_groups  = compact(split(",", lookup(egress.value, "security_groups", "")))
      description      = lookup(egress.value, "description", null)
      from_port        = lookup(egress.value, "from_port", 0)
      to_port          = lookup(egress.value, "to_port", 0)
      protocol         = lookup(egress.value, "protocol", "-1")
    }
  }

  tags = merge(local.tags, { "Name" = coalesce(var.default_security_group_name, "${local.name}-default") }, var.default_security_group_tags)

  lifecycle {
    enabled = local.enabled && var.manage_default_security_group
  }
}

################################################################################
# Default Network ACLs
################################################################################

resource "aws_default_network_acl" "this" {
  default_network_acl_id = aws_vpc.this.default_network_acl_id

  # subnet_ids is using lifecycle ignore_changes, so it is not necessary to list
  # any explicitly. See https://github.com/terraform-aws-modules/terraform-aws-vpc/issues/736
  subnet_ids = null

  dynamic "ingress" {
    for_each = var.default_network_acl_ingress
    content {
      action          = ingress.value.action
      cidr_block      = lookup(ingress.value, "cidr_block", null)
      from_port       = ingress.value.from_port
      icmp_code       = lookup(ingress.value, "icmp_code", null)
      icmp_type       = lookup(ingress.value, "icmp_type", null)
      ipv6_cidr_block = lookup(ingress.value, "ipv6_cidr_block", null)
      protocol        = ingress.value.protocol
      rule_no         = ingress.value.rule_no
      to_port         = ingress.value.to_port
    }
  }
  dynamic "egress" {
    for_each = var.default_network_acl_egress
    content {
      action          = egress.value.action
      cidr_block      = lookup(egress.value, "cidr_block", null)
      from_port       = egress.value.from_port
      icmp_code       = lookup(egress.value, "icmp_code", null)
      icmp_type       = lookup(egress.value, "icmp_type", null)
      ipv6_cidr_block = lookup(egress.value, "ipv6_cidr_block", null)
      protocol        = egress.value.protocol
      rule_no         = egress.value.rule_no
      to_port         = egress.value.to_port
    }
  }

  tags = merge(local.tags, { "Name" = coalesce(var.default_network_acl_name, "${local.name}-default") }, var.default_network_acl_tags)

  lifecycle {
    enabled        = local.enabled && var.manage_default_network_acl
    ignore_changes = [subnet_ids]
  }
}

################################################################################
# Default Route
################################################################################

resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.this.default_route_table_id
  propagating_vgws       = var.default_route_table_propagating_vgws

  dynamic "route" {
    for_each = var.default_route_table_routes
    content {
      # One of the following destinations must be provided
      cidr_block      = route.value.cidr_block
      ipv6_cidr_block = lookup(route.value, "ipv6_cidr_block", null)

      # One of the following targets must be provided
      egress_only_gateway_id    = lookup(route.value, "egress_only_gateway_id", null)
      gateway_id                = lookup(route.value, "gateway_id", null)
      instance_id               = lookup(route.value, "instance_id", null)
      nat_gateway_id            = lookup(route.value, "nat_gateway_id", null)
      network_interface_id      = lookup(route.value, "network_interface_id", null)
      transit_gateway_id        = lookup(route.value, "transit_gateway_id", null)
      vpc_endpoint_id           = lookup(route.value, "vpc_endpoint_id", null)
      vpc_peering_connection_id = lookup(route.value, "vpc_peering_connection_id", null)
    }
  }

  timeouts {
    create = "5m"
    update = "5m"
  }

  tags = merge(local.tags, { "Name" = coalesce(var.default_route_table_name, "${local.name}-default") }, var.default_route_table_tags)

  lifecycle {
    enabled = local.enabled && var.manage_default_route_table
  }
}

################################################################################
# OpenTofu Check Blocks
################################################################################

check "flow_logs_enabled" {
  assert {
    condition     = !var.enabled || var.enable_flow_log
    error_message = "VPC should have flow logs enabled for network monitoring and security auditing."
  }
}
