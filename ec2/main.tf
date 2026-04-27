data "aws_partition" "current" {}

locals {
  enabled = var.enabled

  is_t_instance_type = replace(var.instance_type, "/^t(2|3|3a|4g){1}\\..*$/", "1") == "1" ? true : false

  ami = try(coalesce(var.ami, try(nonsensitive(data.aws_ssm_parameter.this[0].value), null)), null)

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

data "aws_ssm_parameter" "this" {
  count = local.enabled && var.ami == null ? 1 : 0

  name = var.ami_ssm_parameter
}

################################################################################
# Instance
################################################################################

# trivy:ignore:AVD-AWS-0131 - root_block_device encryption is caller-controlled via var.root_block_device; defaults to encrypted=true when supplied
resource "aws_instance" "this" {
  ami           = local.ami
  instance_type = var.instance_type
  hibernation   = var.hibernation
  force_destroy = var.force_destroy

  user_data                   = var.user_data
  user_data_base64            = var.user_data_base64
  user_data_replace_on_change = var.user_data_replace_on_change

  availability_zone      = var.availability_zone
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids

  key_name             = var.key_name
  monitoring           = var.monitoring
  get_password_data    = var.get_password_data
  iam_instance_profile = var.create_iam_instance_profile ? aws_iam_instance_profile.this.name : var.iam_instance_profile

  associate_public_ip_address = var.associate_public_ip_address
  enable_primary_ipv6         = var.enable_primary_ipv6
  private_ip                  = var.private_ip
  secondary_private_ips       = var.secondary_private_ips
  ipv6_address_count          = var.ipv6_address_count
  ipv6_addresses              = var.ipv6_addresses

  ebs_optimized = var.ebs_optimized

  placement_group            = var.placement_group
  placement_group_id         = var.placement_group_id
  placement_partition_number = var.placement_partition_number

  dynamic "cpu_options" {
    for_each = length(var.cpu_options) > 0 ? [var.cpu_options] : []

    content {
      core_count            = try(cpu_options.value.core_count, null)
      threads_per_core      = try(cpu_options.value.threads_per_core, null)
      amd_sev_snp           = try(cpu_options.value.amd_sev_snp, null)
      nested_virtualization = try(cpu_options.value.nested_virtualization, null)
    }
  }

  dynamic "capacity_reservation_specification" {
    for_each = length(var.capacity_reservation_specification) > 0 ? [var.capacity_reservation_specification] : []

    content {
      capacity_reservation_preference = try(capacity_reservation_specification.value.capacity_reservation_preference, null)

      dynamic "capacity_reservation_target" {
        for_each = try([capacity_reservation_specification.value.capacity_reservation_target], [])

        content {
          capacity_reservation_id                 = try(capacity_reservation_target.value.capacity_reservation_id, null)
          capacity_reservation_resource_group_arn = try(capacity_reservation_target.value.capacity_reservation_resource_group_arn, null)
        }
      }
    }
  }

  dynamic "root_block_device" {
    for_each = var.root_block_device

    content {
      delete_on_termination = try(root_block_device.value.delete_on_termination, null)
      encrypted             = try(root_block_device.value.encrypted, true)
      iops                  = try(root_block_device.value.iops, null)
      kms_key_id            = lookup(root_block_device.value, "kms_key_id", null)
      volume_size           = try(root_block_device.value.volume_size, null)
      volume_type           = try(root_block_device.value.volume_type, null)
      throughput            = try(root_block_device.value.throughput, null)

      tags = merge(local.tags, try(root_block_device.value.tags, {}))
    }
  }

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_device

    content {
      delete_on_termination = try(ebs_block_device.value.delete_on_termination, null)
      device_name           = ebs_block_device.value.device_name
      encrypted             = try(ebs_block_device.value.encrypted, null)
      iops                  = try(ebs_block_device.value.iops, null)
      kms_key_id            = lookup(ebs_block_device.value, "kms_key_id", null)
      snapshot_id           = lookup(ebs_block_device.value, "snapshot_id", null)
      volume_size           = try(ebs_block_device.value.volume_size, null)
      volume_type           = try(ebs_block_device.value.volume_type, null)
      throughput            = try(ebs_block_device.value.throughput, null)

      tags = merge(local.tags, try(ebs_block_device.value.tags, {}))
    }
  }

  dynamic "ephemeral_block_device" {
    for_each = var.ephemeral_block_device

    content {
      device_name  = ephemeral_block_device.value.device_name
      no_device    = try(ephemeral_block_device.value.no_device, null)
      virtual_name = try(ephemeral_block_device.value.virtual_name, null)
    }
  }

  dynamic "metadata_options" {
    for_each = length(var.metadata_options) > 0 ? [var.metadata_options] : []

    content {
      http_endpoint               = try(metadata_options.value.http_endpoint, "enabled")
      http_protocol_ipv6          = try(metadata_options.value.http_protocol_ipv6, null)
      http_tokens                 = try(metadata_options.value.http_tokens, "required")
      http_put_response_hop_limit = try(metadata_options.value.http_put_response_hop_limit, 1)
      instance_metadata_tags      = try(metadata_options.value.instance_metadata_tags, null)
    }
  }

  dynamic "network_interface" {
    for_each = var.network_interface

    content {
      device_index          = network_interface.value.device_index
      network_interface_id  = lookup(network_interface.value, "network_interface_id", null)
      delete_on_termination = try(network_interface.value.delete_on_termination, false)
      network_card_index    = try(network_interface.value.network_card_index, null)
    }
  }

  dynamic "primary_network_interface" {
    for_each = var.primary_network_interface != null ? [var.primary_network_interface] : []

    content {
      network_interface_id = primary_network_interface.value.network_interface_id
    }
  }

  dynamic "secondary_network_interface" {
    for_each = var.secondary_network_interface

    content {
      secondary_subnet_id      = secondary_network_interface.value.secondary_subnet_id
      network_card_index       = secondary_network_interface.value.network_card_index
      delete_on_termination    = try(secondary_network_interface.value.delete_on_termination, null)
      device_index             = try(secondary_network_interface.value.device_index, null)
      interface_type           = try(secondary_network_interface.value.interface_type, null)
      private_ip_address_count = try(secondary_network_interface.value.private_ip_address_count, null)
    }
  }

  dynamic "private_dns_name_options" {
    for_each = length(var.private_dns_name_options) > 0 ? [var.private_dns_name_options] : []

    content {
      hostname_type                        = try(private_dns_name_options.value.hostname_type, null)
      enable_resource_name_dns_a_record    = try(private_dns_name_options.value.enable_resource_name_dns_a_record, null)
      enable_resource_name_dns_aaaa_record = try(private_dns_name_options.value.enable_resource_name_dns_aaaa_record, null)
    }
  }

  dynamic "instance_market_options" {
    for_each = length(var.instance_market_options) > 0 ? [var.instance_market_options] : []

    content {
      market_type = try(instance_market_options.value.market_type, null)

      dynamic "spot_options" {
        for_each = try([instance_market_options.value.spot_options], [])

        content {
          instance_interruption_behavior = try(spot_options.value.instance_interruption_behavior, null)
          max_price                      = try(spot_options.value.max_price, null)
          spot_instance_type             = try(spot_options.value.spot_instance_type, null)
          valid_until                    = try(spot_options.value.valid_until, null)
        }
      }
    }
  }

  dynamic "launch_template" {
    for_each = length(var.launch_template) > 0 ? [var.launch_template] : []

    content {
      id      = lookup(launch_template.value, "id", null)
      name    = lookup(launch_template.value, "name", null)
      version = lookup(launch_template.value, "version", null)
    }
  }

  dynamic "maintenance_options" {
    for_each = length(var.maintenance_options) > 0 ? [var.maintenance_options] : []

    content {
      auto_recovery = try(maintenance_options.value.auto_recovery, null)
    }
  }

  enclave_options {
    enabled = var.enclave_options_enabled
  }

  source_dest_check                    = length(var.network_interface) > 0 ? null : var.source_dest_check
  disable_api_termination              = var.disable_api_termination
  disable_api_stop                     = var.disable_api_stop
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  tenancy                              = var.tenancy
  host_id                              = var.host_id
  host_resource_group_arn              = var.host_resource_group_arn

  credit_specification {
    cpu_credits = local.is_t_instance_type ? var.cpu_credits : null
  }

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    delete = try(var.timeouts.delete, null)
  }

  volume_tags = var.enable_volume_tags ? merge({ "Name" = var.instance_name }, var.volume_tags) : null

  tags = merge(local.tags, { "Name" = var.instance_name }, var.instance_tags)

  lifecycle {
    enabled = local.enabled && !var.ignore_ami_changes && !var.create_spot_instance
  }
}

################################################################################
# Instance - Ignore AMI Changes
################################################################################

# trivy:ignore:AVD-AWS-0131 - root_block_device encryption is caller-controlled via var.root_block_device; defaults to encrypted=true when supplied
resource "aws_instance" "ignore_ami" {
  ami           = local.ami
  instance_type = var.instance_type
  hibernation   = var.hibernation
  force_destroy = var.force_destroy

  user_data                   = var.user_data
  user_data_base64            = var.user_data_base64
  user_data_replace_on_change = var.user_data_replace_on_change

  availability_zone      = var.availability_zone
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids

  key_name             = var.key_name
  monitoring           = var.monitoring
  get_password_data    = var.get_password_data
  iam_instance_profile = var.create_iam_instance_profile ? aws_iam_instance_profile.this.name : var.iam_instance_profile

  associate_public_ip_address = var.associate_public_ip_address
  enable_primary_ipv6         = var.enable_primary_ipv6
  private_ip                  = var.private_ip
  secondary_private_ips       = var.secondary_private_ips
  ipv6_address_count          = var.ipv6_address_count
  ipv6_addresses              = var.ipv6_addresses

  ebs_optimized = var.ebs_optimized

  placement_group            = var.placement_group
  placement_group_id         = var.placement_group_id
  placement_partition_number = var.placement_partition_number

  dynamic "cpu_options" {
    for_each = length(var.cpu_options) > 0 ? [var.cpu_options] : []

    content {
      core_count            = try(cpu_options.value.core_count, null)
      threads_per_core      = try(cpu_options.value.threads_per_core, null)
      amd_sev_snp           = try(cpu_options.value.amd_sev_snp, null)
      nested_virtualization = try(cpu_options.value.nested_virtualization, null)
    }
  }

  dynamic "capacity_reservation_specification" {
    for_each = length(var.capacity_reservation_specification) > 0 ? [var.capacity_reservation_specification] : []

    content {
      capacity_reservation_preference = try(capacity_reservation_specification.value.capacity_reservation_preference, null)

      dynamic "capacity_reservation_target" {
        for_each = try([capacity_reservation_specification.value.capacity_reservation_target], [])

        content {
          capacity_reservation_id                 = try(capacity_reservation_target.value.capacity_reservation_id, null)
          capacity_reservation_resource_group_arn = try(capacity_reservation_target.value.capacity_reservation_resource_group_arn, null)
        }
      }
    }
  }

  dynamic "root_block_device" {
    for_each = var.root_block_device

    content {
      delete_on_termination = try(root_block_device.value.delete_on_termination, null)
      encrypted             = try(root_block_device.value.encrypted, true)
      iops                  = try(root_block_device.value.iops, null)
      kms_key_id            = lookup(root_block_device.value, "kms_key_id", null)
      volume_size           = try(root_block_device.value.volume_size, null)
      volume_type           = try(root_block_device.value.volume_type, null)
      throughput            = try(root_block_device.value.throughput, null)

      tags = merge(local.tags, try(root_block_device.value.tags, {}))
    }
  }

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_device

    content {
      delete_on_termination = try(ebs_block_device.value.delete_on_termination, null)
      device_name           = ebs_block_device.value.device_name
      encrypted             = try(ebs_block_device.value.encrypted, null)
      iops                  = try(ebs_block_device.value.iops, null)
      kms_key_id            = lookup(ebs_block_device.value, "kms_key_id", null)
      snapshot_id           = lookup(ebs_block_device.value, "snapshot_id", null)
      volume_size           = try(ebs_block_device.value.volume_size, null)
      volume_type           = try(ebs_block_device.value.volume_type, null)
      throughput            = try(ebs_block_device.value.throughput, null)

      tags = merge(local.tags, try(ebs_block_device.value.tags, {}))
    }
  }

  dynamic "ephemeral_block_device" {
    for_each = var.ephemeral_block_device

    content {
      device_name  = ephemeral_block_device.value.device_name
      no_device    = try(ephemeral_block_device.value.no_device, null)
      virtual_name = try(ephemeral_block_device.value.virtual_name, null)
    }
  }

  dynamic "metadata_options" {
    for_each = length(var.metadata_options) > 0 ? [var.metadata_options] : []

    content {
      http_endpoint               = try(metadata_options.value.http_endpoint, "enabled")
      http_protocol_ipv6          = try(metadata_options.value.http_protocol_ipv6, null)
      http_tokens                 = try(metadata_options.value.http_tokens, "required")
      http_put_response_hop_limit = try(metadata_options.value.http_put_response_hop_limit, 1)
      instance_metadata_tags      = try(metadata_options.value.instance_metadata_tags, null)
    }
  }

  dynamic "network_interface" {
    for_each = var.network_interface

    content {
      device_index          = network_interface.value.device_index
      network_interface_id  = lookup(network_interface.value, "network_interface_id", null)
      delete_on_termination = try(network_interface.value.delete_on_termination, false)
      network_card_index    = try(network_interface.value.network_card_index, null)
    }
  }

  dynamic "primary_network_interface" {
    for_each = var.primary_network_interface != null ? [var.primary_network_interface] : []

    content {
      network_interface_id = primary_network_interface.value.network_interface_id
    }
  }

  dynamic "secondary_network_interface" {
    for_each = var.secondary_network_interface

    content {
      secondary_subnet_id      = secondary_network_interface.value.secondary_subnet_id
      network_card_index       = secondary_network_interface.value.network_card_index
      delete_on_termination    = try(secondary_network_interface.value.delete_on_termination, null)
      device_index             = try(secondary_network_interface.value.device_index, null)
      interface_type           = try(secondary_network_interface.value.interface_type, null)
      private_ip_address_count = try(secondary_network_interface.value.private_ip_address_count, null)
    }
  }

  dynamic "private_dns_name_options" {
    for_each = length(var.private_dns_name_options) > 0 ? [var.private_dns_name_options] : []

    content {
      hostname_type                        = try(private_dns_name_options.value.hostname_type, null)
      enable_resource_name_dns_a_record    = try(private_dns_name_options.value.enable_resource_name_dns_a_record, null)
      enable_resource_name_dns_aaaa_record = try(private_dns_name_options.value.enable_resource_name_dns_aaaa_record, null)
    }
  }

  dynamic "instance_market_options" {
    for_each = length(var.instance_market_options) > 0 ? [var.instance_market_options] : []

    content {
      market_type = try(instance_market_options.value.market_type, null)

      dynamic "spot_options" {
        for_each = try([instance_market_options.value.spot_options], [])

        content {
          instance_interruption_behavior = try(spot_options.value.instance_interruption_behavior, null)
          max_price                      = try(spot_options.value.max_price, null)
          spot_instance_type             = try(spot_options.value.spot_instance_type, null)
          valid_until                    = try(spot_options.value.valid_until, null)
        }
      }
    }
  }

  dynamic "launch_template" {
    for_each = length(var.launch_template) > 0 ? [var.launch_template] : []

    content {
      id      = lookup(launch_template.value, "id", null)
      name    = lookup(launch_template.value, "name", null)
      version = lookup(launch_template.value, "version", null)
    }
  }

  dynamic "maintenance_options" {
    for_each = length(var.maintenance_options) > 0 ? [var.maintenance_options] : []

    content {
      auto_recovery = try(maintenance_options.value.auto_recovery, null)
    }
  }

  enclave_options {
    enabled = var.enclave_options_enabled
  }

  source_dest_check                    = length(var.network_interface) > 0 ? null : var.source_dest_check
  disable_api_termination              = var.disable_api_termination
  disable_api_stop                     = var.disable_api_stop
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  tenancy                              = var.tenancy
  host_id                              = var.host_id
  host_resource_group_arn              = var.host_resource_group_arn

  credit_specification {
    cpu_credits = local.is_t_instance_type ? var.cpu_credits : null
  }

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    delete = try(var.timeouts.delete, null)
  }

  volume_tags = var.enable_volume_tags ? merge({ "Name" = var.instance_name }, var.volume_tags) : null

  tags = merge(local.tags, { "Name" = var.instance_name }, var.instance_tags)

  lifecycle {
    enabled = local.enabled && var.ignore_ami_changes && !var.create_spot_instance
    ignore_changes = [
      ami
    ]
  }
}

################################################################################
# Spot Instance
################################################################################

resource "aws_spot_instance_request" "this" {
  ami           = local.ami
  instance_type = var.instance_type
  hibernation   = var.hibernation
  force_destroy = var.force_destroy

  user_data                   = var.user_data
  user_data_base64            = var.user_data_base64
  user_data_replace_on_change = var.user_data_replace_on_change

  availability_zone      = var.availability_zone
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids

  key_name             = var.key_name
  monitoring           = var.monitoring
  get_password_data    = var.get_password_data
  iam_instance_profile = var.create_iam_instance_profile ? aws_iam_instance_profile.this.name : var.iam_instance_profile

  associate_public_ip_address = var.associate_public_ip_address
  enable_primary_ipv6         = var.enable_primary_ipv6
  private_ip                  = var.private_ip
  secondary_private_ips       = var.secondary_private_ips
  ipv6_address_count          = var.ipv6_address_count
  ipv6_addresses              = var.ipv6_addresses

  ebs_optimized = var.ebs_optimized

  placement_group            = var.placement_group
  placement_group_id         = var.placement_group_id
  placement_partition_number = var.placement_partition_number

  # Spot request specific attributes
  spot_price                     = var.spot_price
  wait_for_fulfillment           = var.spot_wait_for_fulfillment
  spot_type                      = var.spot_type
  launch_group                   = var.spot_launch_group
  instance_interruption_behavior = var.spot_instance_interruption_behavior
  valid_until                    = var.spot_valid_until
  valid_from                     = var.spot_valid_from
  # End spot request specific attributes

  dynamic "cpu_options" {
    for_each = length(var.cpu_options) > 0 ? [var.cpu_options] : []

    content {
      core_count            = try(cpu_options.value.core_count, null)
      threads_per_core      = try(cpu_options.value.threads_per_core, null)
      amd_sev_snp           = try(cpu_options.value.amd_sev_snp, null)
      nested_virtualization = try(cpu_options.value.nested_virtualization, null)
    }
  }

  dynamic "capacity_reservation_specification" {
    for_each = length(var.capacity_reservation_specification) > 0 ? [var.capacity_reservation_specification] : []

    content {
      capacity_reservation_preference = try(capacity_reservation_specification.value.capacity_reservation_preference, null)

      dynamic "capacity_reservation_target" {
        for_each = try([capacity_reservation_specification.value.capacity_reservation_target], [])
        content {
          capacity_reservation_id                 = try(capacity_reservation_target.value.capacity_reservation_id, null)
          capacity_reservation_resource_group_arn = try(capacity_reservation_target.value.capacity_reservation_resource_group_arn, null)
        }
      }
    }
  }

  dynamic "root_block_device" {
    for_each = var.root_block_device

    content {
      delete_on_termination = try(root_block_device.value.delete_on_termination, null)
      encrypted             = try(root_block_device.value.encrypted, true)
      iops                  = try(root_block_device.value.iops, null)
      kms_key_id            = lookup(root_block_device.value, "kms_key_id", null)
      volume_size           = try(root_block_device.value.volume_size, null)
      volume_type           = try(root_block_device.value.volume_type, null)
      throughput            = try(root_block_device.value.throughput, null)

      tags = merge(local.tags, try(root_block_device.value.tags, {}))
    }
  }

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_device

    content {
      delete_on_termination = try(ebs_block_device.value.delete_on_termination, null)
      device_name           = ebs_block_device.value.device_name
      encrypted             = try(ebs_block_device.value.encrypted, null)
      iops                  = try(ebs_block_device.value.iops, null)
      kms_key_id            = lookup(ebs_block_device.value, "kms_key_id", null)
      snapshot_id           = lookup(ebs_block_device.value, "snapshot_id", null)
      volume_size           = try(ebs_block_device.value.volume_size, null)
      volume_type           = try(ebs_block_device.value.volume_type, null)
      throughput            = try(ebs_block_device.value.throughput, null)

      tags = merge(local.tags, try(ebs_block_device.value.tags, {}))
    }
  }

  dynamic "ephemeral_block_device" {
    for_each = var.ephemeral_block_device

    content {
      device_name  = ephemeral_block_device.value.device_name
      no_device    = try(ephemeral_block_device.value.no_device, null)
      virtual_name = try(ephemeral_block_device.value.virtual_name, null)
    }
  }

  dynamic "metadata_options" {
    for_each = length(var.metadata_options) > 0 ? [var.metadata_options] : []

    content {
      http_endpoint               = try(metadata_options.value.http_endpoint, "enabled")
      http_protocol_ipv6          = try(metadata_options.value.http_protocol_ipv6, null)
      http_tokens                 = try(metadata_options.value.http_tokens, "required")
      http_put_response_hop_limit = try(metadata_options.value.http_put_response_hop_limit, 1)
      instance_metadata_tags      = try(metadata_options.value.instance_metadata_tags, null)
    }
  }

  dynamic "network_interface" {
    for_each = var.network_interface

    content {
      device_index          = network_interface.value.device_index
      network_interface_id  = lookup(network_interface.value, "network_interface_id", null)
      delete_on_termination = try(network_interface.value.delete_on_termination, false)
      network_card_index    = try(network_interface.value.network_card_index, null)
    }
  }

  dynamic "secondary_network_interface" {
    for_each = var.secondary_network_interface

    content {
      secondary_subnet_id      = secondary_network_interface.value.secondary_subnet_id
      network_card_index       = secondary_network_interface.value.network_card_index
      delete_on_termination    = try(secondary_network_interface.value.delete_on_termination, null)
      device_index             = try(secondary_network_interface.value.device_index, null)
      interface_type           = try(secondary_network_interface.value.interface_type, null)
      private_ip_address_count = try(secondary_network_interface.value.private_ip_address_count, null)
    }
  }

  dynamic "private_dns_name_options" {
    for_each = length(var.private_dns_name_options) > 0 ? [var.private_dns_name_options] : []

    content {
      hostname_type                        = try(private_dns_name_options.value.hostname_type, null)
      enable_resource_name_dns_a_record    = try(private_dns_name_options.value.enable_resource_name_dns_a_record, null)
      enable_resource_name_dns_aaaa_record = try(private_dns_name_options.value.enable_resource_name_dns_aaaa_record, null)
    }
  }

  dynamic "launch_template" {
    for_each = length(var.launch_template) > 0 ? [var.launch_template] : []

    content {
      id      = lookup(launch_template.value, "id", null)
      name    = lookup(launch_template.value, "name", null)
      version = lookup(launch_template.value, "version", null)
    }
  }

  dynamic "maintenance_options" {
    for_each = length(var.maintenance_options) > 0 ? [var.maintenance_options] : []

    content {
      auto_recovery = try(maintenance_options.value.auto_recovery, null)
    }
  }

  enclave_options {
    enabled = var.enclave_options_enabled
  }

  source_dest_check                    = length(var.network_interface) > 0 ? null : var.source_dest_check
  disable_api_termination              = var.disable_api_termination
  disable_api_stop                     = var.disable_api_stop
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  tenancy                              = var.tenancy
  host_id                              = var.host_id
  host_resource_group_arn              = var.host_resource_group_arn

  credit_specification {
    cpu_credits = local.is_t_instance_type ? var.cpu_credits : null
  }

  timeouts {
    create = try(var.timeouts.create, null)
    delete = try(var.timeouts.delete, null)
  }

  volume_tags = var.enable_volume_tags ? merge({ "Name" = var.instance_name }, var.volume_tags) : null

  tags = merge(local.tags, { "Name" = var.instance_name }, var.instance_tags)

  lifecycle {
    enabled = local.enabled && var.create_spot_instance
  }
}

################################################################################
# IAM Role / Instance Profile
################################################################################

locals {
  iam_role_name = try(coalesce(var.iam_role_name, var.instance_name), "")
}

data "aws_iam_policy_document" "assume_role_policy" {
  count = var.enabled && var.create_iam_instance_profile ? 1 : 0

  statement {
    sid     = "EC2AssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.${data.aws_partition.current.dns_suffix}"]
    }
  }
}

resource "aws_iam_role" "this" {
  name        = var.iam_role_use_name_prefix ? null : local.iam_role_name
  name_prefix = var.iam_role_use_name_prefix ? "${local.iam_role_name}-" : null
  path        = var.iam_role_path
  description = var.iam_role_description

  assume_role_policy    = data.aws_iam_policy_document.assume_role_policy[0].json
  permissions_boundary  = var.iam_role_permissions_boundary
  force_detach_policies = true
  max_session_duration  = var.iam_role_max_session_duration

  tags = merge(local.tags, merge(var.tags, var.iam_role_tags))

  lifecycle {
    enabled = var.enabled && var.create_iam_instance_profile
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = { for k, v in var.iam_role_policies : k => v if var.enabled && var.create_iam_instance_profile }

  policy_arn = each.value
  role       = aws_iam_role.this.name
}

resource "aws_iam_instance_profile" "this" {
  role = aws_iam_role.this.name

  name        = var.iam_role_use_name_prefix ? null : local.iam_role_name
  name_prefix = var.iam_role_use_name_prefix ? "${local.iam_role_name}-" : null
  path        = var.iam_role_path

  tags = merge(local.tags, merge(var.tags, var.iam_role_tags))

  lifecycle {
    enabled               = var.enabled && var.create_iam_instance_profile
    create_before_destroy = true
  }
}

################################################################################
# Elastic IP
################################################################################

resource "aws_eip" "this" {
  instance = try(
    aws_instance.this.id,
    aws_instance.ignore_ami.id,
  )

  domain                    = var.eip_domain
  address                   = var.eip_address
  associate_with_private_ip = var.eip_associate_with_private_ip
  customer_owned_ipv4_pool  = var.eip_customer_owned_ipv4_pool
  ipam_pool_id              = var.eip_ipam_pool_id
  network_border_group      = var.eip_network_border_group
  network_interface         = var.eip_network_interface
  public_ipv4_pool          = var.eip_public_ipv4_pool

  tags = merge(local.tags, merge(var.tags, var.eip_tags))

  lifecycle {
    enabled = local.enabled && var.create_eip && !var.create_spot_instance
  }
}
