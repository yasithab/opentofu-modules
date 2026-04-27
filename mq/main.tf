################################################################################
# General
################################################################################

locals {
  enabled            = var.enabled
  security_group_ids = var.create_security_group ? [aws_security_group.this.id] : var.security_groups

  create_security_group = local.enabled && var.create_security_group
  security_group_name   = try(coalesce(var.security_group_name, var.broker_name), "")

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

################################################################################
# Security Groups
################################################################################

resource "aws_security_group" "this" {
  name        = var.security_group_use_name_prefix ? null : local.security_group_name
  name_prefix = var.security_group_use_name_prefix ? "${local.security_group_name}-" : null
  description = coalesce(var.security_group_description, "Security group for MQ broker ${var.broker_name}")
  vpc_id      = var.vpc_id

  tags = merge(local.tags, var.security_group_tags, { Name = local.security_group_name })

  lifecycle {
    enabled               = local.create_security_group
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = { for k, v in var.security_group_rules : k => v if local.create_security_group && try(v.type, "ingress") == "ingress" }

  security_group_id = aws_security_group.this.id
  ip_protocol       = try(each.value.ip_protocol, "tcp")

  cidr_ipv4                    = lookup(each.value, "cidr_ipv4", null)
  cidr_ipv6                    = lookup(each.value, "cidr_ipv6", null)
  description                  = try(each.value.description, null)
  from_port                    = try(each.value.from_port, null)
  prefix_list_id               = lookup(each.value, "prefix_list_id", null)
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)
  to_port                      = try(each.value.to_port, null)

  tags = merge(local.tags, var.security_group_tags, try(each.value.tags, {}))
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = { for k, v in var.security_group_rules : k => v if local.create_security_group && try(v.type, "ingress") == "egress" }

  security_group_id = aws_security_group.this.id
  ip_protocol       = try(each.value.ip_protocol, "tcp")

  cidr_ipv4                    = lookup(each.value, "cidr_ipv4", null)
  cidr_ipv6                    = lookup(each.value, "cidr_ipv6", null)
  description                  = try(each.value.description, null)
  from_port                    = try(each.value.from_port, null)
  prefix_list_id               = lookup(each.value, "prefix_list_id", null)
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)
  to_port                      = try(each.value.to_port, null)

  tags = merge(local.tags, var.security_group_tags, try(each.value.tags, {}))
}

################################################################################
# Broker Configurations
################################################################################

resource "aws_mq_broker" "this" {
  broker_name        = var.broker_name
  engine_type        = var.engine_type
  engine_version     = var.engine_version
  host_instance_type = var.host_instance_type
  deployment_mode    = var.deployment_mode
  subnet_ids         = var.subnet_ids

  # Optional parameters
  apply_immediately                   = var.apply_immediately
  auto_minor_version_upgrade          = var.auto_minor_version_upgrade
  data_replication_mode               = var.data_replication_mode
  data_replication_primary_broker_arn = var.data_replication_primary_broker_arn
  publicly_accessible                 = var.publicly_accessible
  security_groups                     = local.security_group_ids
  storage_type                        = var.storage_type
  authentication_strategy             = var.authentication_strategy

  # Encryption
  dynamic "encryption_options" {
    for_each = var.encryption_options != null ? [var.encryption_options] : []
    content {
      kms_key_id        = lookup(encryption_options.value, "kms_key_id", null)
      use_aws_owned_key = lookup(encryption_options.value, "use_aws_owned_key", true)
    }
  }

  # LDAP Authentication (only for ActiveMQ)
  dynamic "ldap_server_metadata" {
    for_each = var.ldap_server_metadata != null ? [var.ldap_server_metadata] : []
    content {
      hosts                    = lookup(ldap_server_metadata.value, "hosts", null)
      role_base                = lookup(ldap_server_metadata.value, "role_base", null)
      role_name                = lookup(ldap_server_metadata.value, "role_name", null)
      role_search_matching     = lookup(ldap_server_metadata.value, "role_search_matching", null)
      role_search_subtree      = lookup(ldap_server_metadata.value, "role_search_subtree", null)
      service_account_password = lookup(ldap_server_metadata.value, "service_account_password", null)
      service_account_username = lookup(ldap_server_metadata.value, "service_account_username", null)
      user_base                = lookup(ldap_server_metadata.value, "user_base", null)
      user_role_name           = lookup(ldap_server_metadata.value, "user_role_name", null)
      user_search_matching     = lookup(ldap_server_metadata.value, "user_search_matching", null)
      user_search_subtree      = lookup(ldap_server_metadata.value, "user_search_subtree", null)
    }
  }

  # Logs configuration
  dynamic "logs" {
    for_each = var.logs != null ? [var.logs] : []
    content {
      audit   = lookup(logs.value, "audit", false)
      general = lookup(logs.value, "general", false)
    }
  }

  # Maintenance window
  dynamic "maintenance_window_start_time" {
    for_each = var.maintenance_window_start_time != null ? [var.maintenance_window_start_time] : []
    content {
      day_of_week = maintenance_window_start_time.value.day_of_week
      time_of_day = maintenance_window_start_time.value.time_of_day
      time_zone   = maintenance_window_start_time.value.time_zone
    }
  }

  # Users
  dynamic "user" {
    for_each = var.users
    content {
      username         = user.value.username
      password         = user.value.password
      console_access   = lookup(user.value, "console_access", false)
      groups           = lookup(user.value, "groups", null)
      replication_user = lookup(user.value, "replication_user", false)
    }
  }

  # Configuration
  dynamic "configuration" {
    for_each = var.configuration != null ? [var.configuration] : []
    content {
      id       = configuration.value.id
      revision = configuration.value.revision
    }
  }

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}

################################################################################
# OpenTofu Check Blocks
################################################################################

check "encryption_enabled" {
  assert {
    condition     = !var.enabled || try(aws_mq_broker.this.encryption_options[0].use_aws_owned_key, false) || try(aws_mq_broker.this.encryption_options[0].kms_key_id, "") != ""
    error_message = "MQ broker should have encryption at rest enabled."
  }
}

################################################################################
