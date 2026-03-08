locals {
  enabled = var.enabled
  name    = var.name

  security_group_ids = local.enabled && var.create_security_group ? [aws_security_group.default.id] : var.security_group_ids
  ip_addresses       = var.ip_addresses

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

resource "aws_route53_resolver_endpoint" "default" {
  name      = local.name
  direction = var.direction

  resolver_endpoint_type             = var.type
  security_group_ids                 = local.security_group_ids
  rni_enhanced_metrics_enabled       = var.rni_enhanced_metrics_enabled
  target_name_server_metrics_enabled = var.target_name_server_metrics_enabled

  dynamic "ip_address" {
    for_each = local.ip_addresses

    content {
      subnet_id = ip_address.value.subnet_id
      ip        = ip_address.value.ip
      ipv6      = ip_address.value.ipv6
    }
  }

  protocols = var.protocols

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}

resource "aws_security_group" "default" {
  name        = var.security_group_name_prefix == null ? coalesce(var.security_group_name, local.name) : null
  name_prefix = var.security_group_name_prefix
  description = var.security_group_description
  vpc_id      = var.vpc_id

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_security_group
  }
}

resource "aws_vpc_security_group_ingress_rule" "dns_tcp" {
  for_each = local.enabled && var.create_security_group ? toset(var.security_group_ingress_cidr_blocks) : toset([])

  security_group_id = aws_security_group.default.id
  description       = "Allow DNS over TCP"
  ip_protocol       = "tcp"
  from_port         = 53
  to_port           = 53
  cidr_ipv4         = each.value

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "dns_udp" {
  for_each = local.enabled && var.create_security_group ? toset(var.security_group_ingress_cidr_blocks) : toset([])

  security_group_id = aws_security_group.default.id
  description       = "Allow DNS over UDP"
  ip_protocol       = "udp"
  from_port         = 53
  to_port           = 53
  cidr_ipv4         = each.value

  tags = local.tags
}

# trivy:ignore:AVD-AWS-0104 - Route53 resolver endpoints require broad egress to forward DNS queries to unknown on-premises resolver IPs
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.default.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_security_group
  }
}
