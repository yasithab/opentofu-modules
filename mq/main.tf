################################################################################
# General
################################################################################

locals {
  create          = var.enabled
  security_groups = var.create_security_group ? try(aws_security_group.this.id, null) : var.security_groups

  default_rabbitmq_ingress_rules = tolist([
    {
      description      = "RabbitMQ AMQP TLS access"
      from_port        = 5671
      to_port          = 5671
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    },
    {
      description      = "RabbitMQ management console access"
      from_port        = 15671
      to_port          = 15671
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    },
    {
      description      = "RabbitMQ management console access"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    }
  ])

  default_activemq_ingress_rules = tolist([
    {
      description      = "ActiveMQ AMQP access"
      from_port        = 5671
      to_port          = 5671
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    },
    {
      description      = "ActiveMQ STOMP access"
      from_port        = 61614
      to_port          = 61614
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    },
    {
      description      = "ActiveMQ MQTT access"
      from_port        = 8883
      to_port          = 8883
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    },
    {
      description      = "ActiveMQ WSS access"
      from_port        = 61619
      to_port          = 61619
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    },
    {
      description      = "ActiveMQ OpenWire access"
      from_port        = 61617
      to_port          = 61617
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    },
    {
      description      = "ActiveMQ web console access"
      from_port        = 8162
      to_port          = 8162
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    }
  ])

  computed_ingress_rules = coalesce(
    var.ingress_rules,
    var.engine_type == "RabbitMQ" ? local.default_rabbitmq_ingress_rules : local.default_activemq_ingress_rules
  )

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

################################################################################
# Security Groups
################################################################################

# trivy:ignore:AVD-AWS-0104 - MQ broker egress rules are caller-controlled via var.egress_rules
resource "aws_security_group" "this" {
  name        = var.security_group_name != null ? var.security_group_name : null
  name_prefix = var.security_group_name == null ? coalesce(var.security_group_name_prefix, "${var.broker_name}-") : null
  description = var.security_group_description
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = local.computed_ingress_rules
    content {
      description      = ingress.value.description
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      cidr_blocks      = lookup(ingress.value, "cidr_blocks", null)
      ipv6_cidr_blocks = lookup(ingress.value, "ipv6_cidr_blocks", null)
      prefix_list_ids  = lookup(ingress.value, "prefix_list_ids", null)
      security_groups  = lookup(ingress.value, "security_groups", null)
      self             = lookup(ingress.value, "self", null)
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      description      = egress.value.description
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      cidr_blocks      = lookup(egress.value, "cidr_blocks", null)
      ipv6_cidr_blocks = lookup(egress.value, "ipv6_cidr_blocks", null)
      prefix_list_ids  = lookup(egress.value, "prefix_list_ids", null)
      security_groups  = lookup(egress.value, "security_groups", null)
      self             = lookup(egress.value, "self", null)
    }
  }

  tags = merge(local.tags, var.security_group_tags)

  lifecycle {
    enabled = var.create_security_group
  }
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
  security_groups                     = local.security_groups
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
    enabled = local.create
  }
}

################################################################################
