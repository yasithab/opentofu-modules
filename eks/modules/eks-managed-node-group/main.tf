locals {
  enabled = var.enabled
  name    = var.name

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

################################################################################
# User Data
################################################################################

module "user_data" {
  source = "../_user_data"

  enabled  = var.enabled
  ami_type = var.ami_type

  cluster_name         = var.cluster_name
  cluster_endpoint     = var.cluster_endpoint
  cluster_auth_base64  = var.cluster_auth_base64
  cluster_ip_family    = var.cluster_ip_family
  cluster_service_cidr = var.cluster_service_cidr != null ? var.cluster_service_cidr : ""

  enable_bootstrap_user_data = var.enable_bootstrap_user_data
  pre_bootstrap_user_data    = var.pre_bootstrap_user_data
  post_bootstrap_user_data   = var.post_bootstrap_user_data
  bootstrap_extra_args       = var.bootstrap_extra_args
  user_data_template_path    = var.user_data_template_path

  cloudinit_pre_nodeadm  = var.cloudinit_pre_nodeadm
  cloudinit_post_nodeadm = var.cloudinit_post_nodeadm
}

################################################################################
# EFA Support
################################################################################

data "aws_ec2_instance_type" "this" {
  count = local.enabled && var.enable_efa_support ? 1 : 0

  instance_type = local.efa_instance_type
}

locals {
  enable_efa_support = local.enabled && var.enable_efa_support

  efa_instance_type = try(element(var.instance_types, 0), "")
  num_network_cards = try(data.aws_ec2_instance_type.this[0].maximum_network_cards, 0)

  # Primary network interface must be EFA, remaining can be EFA or EFA-only
  efa_network_interfaces = [
    for i in range(local.num_network_cards) : {
      associate_carrier_ip_address      = null
      associate_public_ip_address       = false
      connection_tracking_specification = null
      delete_on_termination             = true
      description                       = null
      device_index                      = i == 0 ? 0 : 1
      ena_srd_specification             = null
      interface_type                    = var.enable_efa_only ? contains(concat([0], var.efa_indices), i) ? "efa" : "efa-only" : "efa"
      ipv4_address_count                = null
      ipv4_addresses                    = []
      ipv4_prefix_count                 = null
      ipv4_prefixes                     = null
      ipv6_address_count                = null
      ipv6_addresses                    = []
      ipv6_prefix_count                 = null
      ipv6_prefixes                     = []
      network_card_index                = i
      network_interface_id              = null
      primary_ipv6                      = null
      private_ip_address                = null
      security_groups                   = []
    }
  ]

  network_interfaces = local.enable_efa_support ? local.efa_network_interfaces : var.network_interfaces
}

################################################################################
# Launch template
################################################################################

locals {
  launch_template_name = coalesce(var.launch_template_name, "${var.name}-eks-node-group")
  security_group_ids   = compact(concat([var.cluster_primary_security_group_id], var.vpc_security_group_ids))

  placement = local.create_placement_group ? {
    affinity                = null
    availability_zone       = null
    group_id                = null
    group_name              = aws_placement_group.this.name
    host_id                 = null
    host_resource_group_arn = null
    partition_number        = null
    spread_domain           = null
    tenancy                 = null
  } : var.placement
}

resource "aws_launch_template" "this" {
  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings

    content {
      device_name = block_device_mappings.value.device_name

      dynamic "ebs" {
        for_each = block_device_mappings.value.ebs != null ? [block_device_mappings.value.ebs] : []

        content {
          delete_on_termination      = ebs.value.delete_on_termination
          encrypted                  = ebs.value.encrypted
          iops                       = ebs.value.iops
          kms_key_id                 = ebs.value.kms_key_id
          snapshot_id                = ebs.value.snapshot_id
          throughput                 = ebs.value.throughput
          volume_initialization_rate = ebs.value.volume_initialization_rate
          volume_size                = ebs.value.volume_size
          volume_type                = ebs.value.volume_type
        }
      }

      no_device    = block_device_mappings.value.no_device
      virtual_name = block_device_mappings.value.virtual_name
    }
  }

  dynamic "capacity_reservation_specification" {
    for_each = var.capacity_reservation_specification != null ? [var.capacity_reservation_specification] : []

    content {
      capacity_reservation_preference = capacity_reservation_specification.value.capacity_reservation_preference

      dynamic "capacity_reservation_target" {
        for_each = capacity_reservation_specification.value.capacity_reservation_target != null ? [capacity_reservation_specification.value.capacity_reservation_target] : []

        content {
          capacity_reservation_id                 = capacity_reservation_target.value.capacity_reservation_id
          capacity_reservation_resource_group_arn = capacity_reservation_target.value.capacity_reservation_resource_group_arn
        }
      }
    }
  }

  dynamic "cpu_options" {
    for_each = var.cpu_options != null ? [var.cpu_options] : []

    content {
      amd_sev_snp           = cpu_options.value.amd_sev_snp
      core_count            = cpu_options.value.core_count
      nested_virtualization = cpu_options.value.nested_virtualization
      threads_per_core      = cpu_options.value.threads_per_core
    }
  }

  dynamic "credit_specification" {
    for_each = var.credit_specification != null ? [var.credit_specification] : []

    content {
      cpu_credits = credit_specification.value.cpu_credits
    }
  }

  default_version         = var.launch_template_default_version
  description             = var.launch_template_description
  disable_api_stop        = var.disable_api_stop
  disable_api_termination = var.disable_api_termination
  ebs_optimized           = var.ebs_optimized

  dynamic "enclave_options" {
    for_each = var.enclave_options != null ? [var.enclave_options] : []

    content {
      enabled = enclave_options.value.enabled
    }
  }

  # Set on EKS managed node group, will fail if set here
  # https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-basics
  # dynamic "hibernation_options" {
  #   for_each = length(var.hibernation_options) > 0 ? [var.hibernation_options] : []

  #   content {
  #     configured = hibernation_options.value.configured
  #   }
  # }

  # Set on EKS managed node group, will fail if set here
  # https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-basics
  # dynamic "iam_instance_profile" {
  #   for_each = [var.iam_instance_profile]
  #   content {
  #     name = lookup(var.iam_instance_profile, "name", null)
  #     arn  = lookup(var.iam_instance_profile, "arn", null)
  #   }
  # }

  image_id = var.ami_id
  # Set on EKS managed node group, will fail if set here
  # https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-basics
  # instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior

  dynamic "instance_market_options" {
    for_each = var.instance_market_options != null ? [var.instance_market_options] : []

    content {
      market_type = instance_market_options.value.market_type

      dynamic "spot_options" {
        for_each = instance_market_options.value.spot_options != null ? [instance_market_options.value.spot_options] : []

        content {
          block_duration_minutes         = spot_options.value.block_duration_minutes
          instance_interruption_behavior = spot_options.value.instance_interruption_behavior
          max_price                      = spot_options.value.max_price
          spot_instance_type             = spot_options.value.spot_instance_type
          valid_until                    = spot_options.value.valid_until
        }
      }
    }
  }

  # Instance type(s) are generally set on the node group,
  # except when a ML capacity block reseravtion is used
  instance_type = var.capacity_type == "CAPACITY_BLOCK" ? element(var.instance_types, 0) : null
  kernel_id     = var.kernel_id
  key_name      = var.key_name

  dynamic "license_specification" {
    for_each = var.license_specifications

    content {
      license_configuration_arn = license_specification.value.license_configuration_arn
    }
  }

  dynamic "maintenance_options" {
    for_each = var.maintenance_options != null ? [var.maintenance_options] : []

    content {
      auto_recovery = maintenance_options.value.auto_recovery
    }
  }

  dynamic "metadata_options" {
    for_each = var.metadata_options != null ? [var.metadata_options] : []

    content {
      http_endpoint               = metadata_options.value.http_endpoint
      http_protocol_ipv6          = metadata_options.value.http_protocol_ipv6
      http_put_response_hop_limit = metadata_options.value.http_put_response_hop_limit
      http_tokens                 = metadata_options.value.http_tokens
      instance_metadata_tags      = metadata_options.value.instance_metadata_tags
    }
  }

  dynamic "monitoring" {
    for_each = var.enable_monitoring ? [1] : []

    content {
      enabled = var.enable_monitoring
    }
  }

  name        = var.launch_template_use_name_prefix ? null : local.launch_template_name
  name_prefix = var.launch_template_use_name_prefix ? "${local.launch_template_name}-" : null

  dynamic "network_performance_options" {
    for_each = length(var.network_performance_options) > 0 ? [var.network_performance_options] : []

    content {
      bandwidth_weighting = try(network_performance_options.value.bandwidth_weighting, null)
    }
  }

  dynamic "network_interfaces" {
    for_each = local.network_interfaces

    content {
      associate_carrier_ip_address = network_interfaces.value.associate_carrier_ip_address
      associate_public_ip_address  = network_interfaces.value.associate_public_ip_address
      delete_on_termination        = network_interfaces.value.delete_on_termination
      description                  = network_interfaces.value.description
      device_index                 = network_interfaces.value.device_index
      interface_type               = network_interfaces.value.interface_type
      ipv4_address_count           = network_interfaces.value.ipv4_address_count
      ipv4_addresses               = network_interfaces.value.ipv4_addresses
      ipv4_prefix_count            = network_interfaces.value.ipv4_prefix_count
      ipv4_prefixes                = network_interfaces.value.ipv4_prefixes
      ipv6_address_count           = network_interfaces.value.ipv6_address_count
      ipv6_addresses               = network_interfaces.value.ipv6_addresses
      ipv6_prefix_count            = network_interfaces.value.ipv6_prefix_count
      ipv6_prefixes                = network_interfaces.value.ipv6_prefixes
      network_card_index           = network_interfaces.value.network_card_index
      network_interface_id         = network_interfaces.value.network_interface_id
      primary_ipv6                 = network_interfaces.value.primary_ipv6
      private_ip_address           = network_interfaces.value.private_ip_address
      # Ref: https://github.com/hashicorp/terraform-provider-aws/issues/4570
      security_groups = compact(concat(network_interfaces.value.security_groups, local.security_group_ids))
      # Set on EKS managed node group, will fail if set here
      # https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-basics
      # subnet_id       = network_interfaces.value.subnet_id

      dynamic "ena_srd_specification" {
        for_each = network_interfaces.value.ena_srd_specification != null ? [network_interfaces.value.ena_srd_specification] : []

        content {
          ena_srd_enabled = ena_srd_specification.value.ena_srd_enabled

          dynamic "ena_srd_udp_specification" {
            for_each = ena_srd_specification.value.ena_srd_udp_specification != null ? [ena_srd_specification.value.ena_srd_udp_specification] : []

            content {
              ena_srd_udp_enabled = ena_srd_udp_specification.value.ena_srd_udp_enabled
            }
          }
        }
      }

      dynamic "connection_tracking_specification" {
        for_each = network_interfaces.value.connection_tracking_specification != null ? [network_interfaces.value.connection_tracking_specification] : []

        content {
          tcp_established_timeout = connection_tracking_specification.value.tcp_established_timeout
          udp_stream_timeout      = connection_tracking_specification.value.udp_stream_timeout
          udp_timeout             = connection_tracking_specification.value.udp_timeout
        }
      }
    }
  }

  dynamic "placement" {
    for_each = local.placement != null ? [local.placement] : []

    content {
      affinity                = placement.value.affinity
      availability_zone       = placement.value.availability_zone
      group_id                = placement.value.group_id
      group_name              = placement.value.group_name
      host_id                 = placement.value.host_id
      host_resource_group_arn = placement.value.host_resource_group_arn
      partition_number        = placement.value.partition_number
      spread_domain           = placement.value.spread_domain
      tenancy                 = placement.value.tenancy
    }
  }

  dynamic "private_dns_name_options" {
    for_each = var.private_dns_name_options != null ? [var.private_dns_name_options] : []

    content {
      enable_resource_name_dns_aaaa_record = private_dns_name_options.value.enable_resource_name_dns_aaaa_record
      enable_resource_name_dns_a_record    = private_dns_name_options.value.enable_resource_name_dns_a_record
      hostname_type                        = private_dns_name_options.value.hostname_type
    }
  }

  ram_disk_id = var.ram_disk_id

  dynamic "tag_specifications" {
    for_each = toset(var.tag_specifications)

    content {
      resource_type = tag_specifications.key
      tags          = merge(local.tags, { Name = local.name }, var.launch_template_tags)
    }
  }

  update_default_version = var.update_launch_template_default_version
  user_data              = module.user_data.user_data
  vpc_security_group_ids = length(local.network_interfaces) > 0 ? [] : local.security_group_ids
  security_group_names   = var.security_group_names

  dynamic "secondary_interfaces" {
    for_each = var.secondary_interfaces

    content {
      delete_on_termination    = secondary_interfaces.value.delete_on_termination
      device_index             = secondary_interfaces.value.device_index
      interface_type           = secondary_interfaces.value.interface_type
      network_card_index       = secondary_interfaces.value.network_card_index
      private_ip_address_count = secondary_interfaces.value.private_ip_address_count
      private_ip_addresses     = secondary_interfaces.value.private_ip_addresses
      secondary_subnet_id      = secondary_interfaces.value.secondary_subnet_id
    }
  }

  tags = merge(local.tags, var.launch_template_tags)

  # Prevent premature access of policies by pods that
  # require permissions on create/destroy that depend on nodes
  depends_on = [
    aws_iam_role_policy_attachment.this,
    aws_iam_role_policy_attachment.additional,
  ]

  lifecycle {
    enabled               = local.enabled && var.create_launch_template && var.use_custom_launch_template
    create_before_destroy = true
  }
}

################################################################################
# AMI SSM Parameter
################################################################################

locals {
  # Just to ensure templating doesn't fail when values are not provided
  ssm_cluster_version = var.cluster_version != null ? var.cluster_version : ""
  ssm_ami_type        = var.ami_type != null ? var.ami_type : ""

  # Map the AMI type to the respective SSM param path
  ssm_ami_type_to_ssm_param = {
    AL2_x86_64                 = "/aws/service/eks/optimized-ami/${local.ssm_cluster_version}/amazon-linux-2/recommended/release_version"
    AL2_x86_64_GPU             = "/aws/service/eks/optimized-ami/${local.ssm_cluster_version}/amazon-linux-2-gpu/recommended/release_version"
    AL2_ARM_64                 = "/aws/service/eks/optimized-ami/${local.ssm_cluster_version}/amazon-linux-2-arm64/recommended/release_version"
    CUSTOM                     = "NONE"
    BOTTLEROCKET_ARM_64        = "/aws/service/bottlerocket/aws-k8s-${local.ssm_cluster_version}/arm64/latest/image_version"
    BOTTLEROCKET_x86_64        = "/aws/service/bottlerocket/aws-k8s-${local.ssm_cluster_version}/x86_64/latest/image_version"
    BOTTLEROCKET_ARM_64_FIPS   = "/aws/service/bottlerocket/aws-k8s-${local.ssm_cluster_version}-fips/arm64/latest/image_version"
    BOTTLEROCKET_x86_64_FIPS   = "/aws/service/bottlerocket/aws-k8s-${local.ssm_cluster_version}-fips/x86_64/latest/image_version"
    BOTTLEROCKET_ARM_64_NVIDIA = "/aws/service/bottlerocket/aws-k8s-${local.ssm_cluster_version}-nvidia/arm64/latest/image_version"
    BOTTLEROCKET_x86_64_NVIDIA = "/aws/service/bottlerocket/aws-k8s-${local.ssm_cluster_version}-nvidia/x86_64/latest/image_version"
    WINDOWS_CORE_2019_x86_64   = "/aws/service/ami-windows-latest/Windows_Server-2019-English-Full-EKS_Optimized-${local.ssm_cluster_version}"
    WINDOWS_FULL_2019_x86_64   = "/aws/service/ami-windows-latest/Windows_Server-2019-English-Core-EKS_Optimized-${local.ssm_cluster_version}"
    WINDOWS_CORE_2022_x86_64   = "/aws/service/ami-windows-latest/Windows_Server-2022-English-Full-EKS_Optimized-${local.ssm_cluster_version}"
    WINDOWS_FULL_2022_x86_64   = "/aws/service/ami-windows-latest/Windows_Server-2022-English-Core-EKS_Optimized-${local.ssm_cluster_version}"
    AL2023_x86_64_STANDARD     = "/aws/service/eks/optimized-ami/${local.ssm_cluster_version}/amazon-linux-2023/x86_64/standard/recommended/release_version"
    AL2023_ARM_64_STANDARD     = "/aws/service/eks/optimized-ami/${local.ssm_cluster_version}/amazon-linux-2023/arm64/standard/recommended/release_version"
    AL2023_x86_64_NEURON       = "/aws/service/eks/optimized-ami/${local.ssm_cluster_version}/amazon-linux-2023/x86_64/neuron/recommended/release_version"
    AL2023_x86_64_NVIDIA       = "/aws/service/eks/optimized-ami/${local.ssm_cluster_version}/amazon-linux-2023/x86_64/nvidia/recommended/release_version"
  }

  # The Windows SSM params currently do not have a release version, so we have to get the full output JSON blob and parse out the release version
  windows_latest_ami_release_version = local.enabled && var.use_latest_ami_release_version && startswith(local.ssm_ami_type, "WINDOWS") ? nonsensitive(jsondecode(data.aws_ssm_parameter.ami[0].value)["release_version"]) : null
  # Based on the steps above, try to get an AMI release version - if not, `null` is returned
  latest_ami_release_version = startswith(local.ssm_ami_type, "WINDOWS") ? local.windows_latest_ami_release_version : try(nonsensitive(data.aws_ssm_parameter.ami[0].value), null)
}

data "aws_ssm_parameter" "ami" {
  count = local.enabled && var.use_latest_ami_release_version ? 1 : 0

  name = local.ssm_ami_type_to_ssm_param[var.ami_type]

  lifecycle {
    precondition {
      condition     = contains(keys(local.ssm_ami_type_to_ssm_param), local.ssm_ami_type) && local.ssm_ami_type != "CUSTOM"
      error_message = "use_latest_ami_release_version requires an ami_type that supports the latest AMI release version lookup. Valid values: ${join(", ", [for k in keys(local.ssm_ami_type_to_ssm_param) : k if k != "CUSTOM"])}."
    }
  }
}

################################################################################
# Node Group
################################################################################

locals {
  launch_template_id = local.enabled && var.create_launch_template ? try(aws_launch_template.this.id, null) : var.launch_template_id
  # Change order to allow users to set version priority before using defaults
  launch_template_version = coalesce(var.launch_template_version, try(aws_launch_template.this.default_version, "$Default"))
}

resource "aws_eks_node_group" "this" {
  # Required
  cluster_name  = var.cluster_name
  node_role_arn = var.create_iam_role ? aws_iam_role.this.arn : var.iam_role_arn
  subnet_ids    = local.create_placement_group ? try(data.aws_subnets.placement_group[0].ids, var.subnet_ids) : var.subnet_ids

  scaling_config {
    min_size     = var.min_size
    max_size     = var.max_size
    desired_size = var.desired_size
  }

  # Optional
  node_group_name        = var.use_name_prefix ? null : local.name
  node_group_name_prefix = var.use_name_prefix ? "${var.name}-" : null

  # https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-custom-ami
  ami_type        = var.ami_id != null ? null : var.ami_type
  release_version = var.ami_id != null ? null : var.use_latest_ami_release_version ? local.latest_ami_release_version : var.ami_release_version
  version         = var.ami_id != null ? null : var.cluster_version

  capacity_type        = var.capacity_type
  disk_size            = var.use_custom_launch_template ? null : var.disk_size # if using a custom LT, set disk size on custom LT or else it will error here
  force_update_version = var.force_update_version
  # ML capacity block reservation requires instance type to be set on the launch template
  instance_types = var.capacity_type == "CAPACITY_BLOCK" ? null : var.instance_types
  labels         = var.labels

  dynamic "launch_template" {
    for_each = var.use_custom_launch_template ? [1] : []

    content {
      id      = local.launch_template_id
      version = local.launch_template_version
    }
  }

  dynamic "remote_access" {
    for_each = var.remote_access != null ? [var.remote_access] : []

    content {
      ec2_ssh_key               = remote_access.value.ec2_ssh_key
      source_security_group_ids = remote_access.value.source_security_group_ids
    }
  }

  dynamic "taint" {
    for_each = var.taints

    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  dynamic "update_config" {
    for_each = var.update_config != null ? [var.update_config] : []

    content {
      max_unavailable_percentage = update_config.value.max_unavailable_percentage
      max_unavailable            = update_config.value.max_unavailable
      update_strategy            = update_config.value.update_strategy
    }
  }

  dynamic "node_repair_config" {
    for_each = var.node_repair_config != null ? [var.node_repair_config] : []

    content {
      enabled                                 = node_repair_config.value.enabled
      max_parallel_nodes_repaired_count       = node_repair_config.value.max_parallel_nodes_repaired_count
      max_parallel_nodes_repaired_percentage  = node_repair_config.value.max_parallel_nodes_repaired_percentage
      max_unhealthy_node_threshold_count      = node_repair_config.value.max_unhealthy_node_threshold_count
      max_unhealthy_node_threshold_percentage = node_repair_config.value.max_unhealthy_node_threshold_percentage

      dynamic "node_repair_config_overrides" {
        for_each = node_repair_config.value.node_repair_config_overrides

        content {
          min_repair_wait_time_mins = node_repair_config_overrides.value.min_repair_wait_time_mins
          node_monitoring_condition = node_repair_config_overrides.value.node_monitoring_condition
          node_unhealthy_reason     = node_repair_config_overrides.value.node_unhealthy_reason
          repair_action             = node_repair_config_overrides.value.repair_action
        }
      }
    }
  }

  timeouts {
    create = lookup(var.timeouts, "create", null)
    update = lookup(var.timeouts, "update", null)
    delete = lookup(var.timeouts, "delete", null)
  }

  # Ensure IAM permissions are in place before (and removed after) the node
  # group - nodes fail to join the cluster if role policies are not attached
  depends_on = [
    aws_iam_role_policy_attachment.this,
    aws_iam_role_policy_attachment.additional,
  ]

  lifecycle {
    enabled               = local.enabled
    create_before_destroy = true
    ignore_changes = [
      scaling_config[0].desired_size,
    ]
  }

  tags = merge(local.tags, { Name = local.name })
}

################################################################################
# IAM Role
################################################################################

locals {
  create_iam_role = local.enabled && var.create_iam_role

  iam_role_name          = coalesce(var.iam_role_name, "${var.name}-eks-node-group")
  iam_role_policy_prefix = "arn:${data.aws_partition.current.partition}:iam::aws:policy"

  ipv4_cni_policy = { for k, v in {
    AmazonEKS_CNI_Policy = "${local.iam_role_policy_prefix}/AmazonEKS_CNI_Policy"
  } : k => v if var.iam_role_attach_cni_policy && var.cluster_ip_family == "ipv4" }
  ipv6_cni_policy = { for k, v in {
    AmazonEKS_CNI_IPv6_Policy = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/AmazonEKS_CNI_IPv6_Policy"
  } : k => v if var.iam_role_attach_cni_policy && var.cluster_ip_family == "ipv6" }
}

data "aws_iam_policy_document" "assume_role_policy" {
  count = local.create_iam_role ? 1 : 0

  statement {
    sid     = "EKSNodeAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name        = var.iam_role_use_name_prefix ? null : local.iam_role_name
  name_prefix = var.iam_role_use_name_prefix ? "${local.iam_role_name}-" : null
  path        = var.iam_role_path
  description = var.iam_role_description

  assume_role_policy    = try(data.aws_iam_policy_document.assume_role_policy[0].json, "")
  permissions_boundary  = var.iam_role_permissions_boundary
  force_detach_policies = true

  tags = merge(local.tags, var.iam_role_tags)

  lifecycle {
    enabled = local.create_iam_role
  }
}

# Policies attached ref https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group
resource "aws_iam_role_policy_attachment" "this" {
  for_each = { for k, v in merge(
    {
      AmazonEKSWorkerNodePolicy          = "${local.iam_role_policy_prefix}/AmazonEKSWorkerNodePolicy"
      AmazonEC2ContainerRegistryReadOnly = "${local.iam_role_policy_prefix}/AmazonEC2ContainerRegistryReadOnly"
    },
    local.ipv4_cni_policy,
    local.ipv6_cni_policy
  ) : k => v if local.create_iam_role }

  policy_arn = each.value
  role       = aws_iam_role.this.name
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = { for k, v in var.iam_role_additional_policies : k => v if local.create_iam_role }

  policy_arn = each.value
  role       = aws_iam_role.this.name
}

################################################################################
# IAM Role Policy
################################################################################

locals {
  create_iam_role_policy = local.create_iam_role && var.create_iam_role_policy && length(var.iam_role_policy_statements) > 0
}

data "aws_iam_policy_document" "role" {
  count = local.create_iam_role_policy ? 1 : 0

  dynamic "statement" {
    for_each = var.iam_role_policy_statements

    content {
      sid           = statement.value.sid
      actions       = statement.value.actions
      not_actions   = statement.value.not_actions
      effect        = statement.value.effect
      resources     = statement.value.resources
      not_resources = statement.value.not_resources

      dynamic "principals" {
        for_each = statement.value.principals

        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "not_principals" {
        for_each = statement.value.not_principals

        content {
          type        = not_principals.value.type
          identifiers = not_principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = statement.value.conditions

        content {
          test     = condition.value.test
          values   = condition.value.values
          variable = condition.value.variable
        }
      }
    }
  }
}

resource "aws_iam_role_policy" "this" {
  name        = var.iam_role_use_name_prefix ? null : local.iam_role_name
  name_prefix = var.iam_role_use_name_prefix ? "${local.iam_role_name}-" : null
  policy      = try(data.aws_iam_policy_document.role[0].json, "")
  role        = aws_iam_role.this.id

  lifecycle {
    enabled = local.create_iam_role_policy
  }
}

################################################################################
# Placement Group
################################################################################

locals {
  create_placement_group = local.enabled && (local.enable_efa_support || var.create_placement_group)
}

resource "aws_placement_group" "this" {
  name     = "${var.cluster_name}-${var.name}"
  strategy = "cluster"

  tags = local.tags

  lifecycle {
    enabled = local.create_placement_group
  }
}

################################################################################
# Instance AZ Lookup
################################################################################

# Reverse the lookup to find one of the subnets provided based on the availability zone
data "aws_subnets" "placement_group" {
  count = local.create_placement_group ? 1 : 0

  filter {
    name   = "subnet-id"
    values = var.subnet_ids
  }

  dynamic "filter" {
    for_each = var.placement_group_az != null ? [var.placement_group_az] : []

    content {
      name   = "availability-zone"
      values = [filter.value]
    }
  }
}

################################################################################
# Autoscaling Group Schedule
################################################################################

resource "aws_autoscaling_schedule" "this" {
  for_each = { for k, v in var.schedules : k => v if local.enabled && var.create_schedule }

  scheduled_action_name  = each.key
  autoscaling_group_name = aws_eks_node_group.this.resources[0].autoscaling_groups[0].name

  min_size         = each.value.min_size != null ? each.value.min_size : -1
  max_size         = each.value.max_size != null ? each.value.max_size : -1
  desired_capacity = each.value.desired_size != null ? each.value.desired_size : -1
  start_time       = each.value.start_time
  end_time         = each.value.end_time
  time_zone        = each.value.time_zone

  # [Minute] [Hour] [Day_of_Month] [Month_of_Year] [Day_of_Week]
  # Cron examples: https://crontab.guru/examples.html
  recurrence = each.value.recurrence
}
