locals {
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  # EKS managed node group
  default_update_config = {
    max_unavailable_percentage = 33
  }

  # Self-managed node group
  default_instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 66
    }
  }

  kubernetes_network_config = try(aws_eks_cluster.this.kubernetes_network_config[0], {})
}

# This sleep resource is used to provide a timed gap between the cluster creation and the downstream dependencies
# that consume the outputs from here. Any of the values that are used as triggers can be used in dependencies
# to ensure that the downstream resources are created after both the cluster is ready and the sleep time has passed.
# This was primarily added to give addons that need to be configured BEFORE data plane compute resources
# enough time to create and configure themselves before the data plane compute resources are created.
resource "time_sleep" "this" {
  create_duration = var.dataplane_wait_duration

  triggers = {
    cluster_name         = aws_eks_cluster.this.id
    cluster_endpoint     = aws_eks_cluster.this.endpoint
    cluster_version      = aws_eks_cluster.this.version
    cluster_service_cidr = var.cluster_ip_family == "ipv6" ? try(local.kubernetes_network_config.service_ipv6_cidr, "") : try(local.kubernetes_network_config.service_ipv4_cidr, "")

    cluster_certificate_authority_data = aws_eks_cluster.this.certificate_authority[0].data
  }

  lifecycle {
    enabled = local.enabled
  }
}

################################################################################
# EKS IPV6 CNI Policy
# https://docs.aws.amazon.com/eks/latest/userguide/cni-iam-role.html#cni-iam-role-create-ipv6-policy
################################################################################

data "aws_iam_policy_document" "cni_ipv6_policy" {
  count = local.enabled && var.create_cni_ipv6_iam_policy ? 1 : 0

  statement {
    sid = "AssignDescribe"
    actions = [
      "ec2:AssignIpv6Addresses",
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeInstanceTypes"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "CreateTags"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:${local.partition}:ec2:*:*:network-interface/*"]
  }
}

# Note - we are keeping this to a minimum in hopes that its soon replaced with an AWS managed policy like `AmazonEKS_CNI_Policy`
resource "aws_iam_policy" "cni_ipv6_policy" {
  # Will cause conflicts if trying to create on multiple clusters but necessary to reference by exact name in sub-modules
  name        = var.cni_ipv6_iam_policy_name
  description = "IAM policy for EKS CNI to assign IPV6 addresses"
  policy      = data.aws_iam_policy_document.cni_ipv6_policy[0].json

  tags = local.tags

  lifecycle {
    enabled = local.enabled && var.create_cni_ipv6_iam_policy
  }
}

################################################################################
# Node Security Group
# Defaults follow https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html
# Plus NTP/HTTPS (otherwise nodes fail to launch)
################################################################################

locals {
  node_sg_name   = coalesce(var.node_security_group_name, "${var.name}-node")
  create_node_sg = local.enabled && var.create_node_security_group

  node_security_group_id = local.create_node_sg ? aws_security_group.node.id : var.node_security_group_id

  node_security_group_rules = {
    ingress_cluster_443 = {
      description                   = "Cluster API to node groups"
      protocol                      = "tcp"
      from_port                     = 443
      to_port                       = 443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_cluster_kubelet = {
      description                   = "Cluster API to node kubelets"
      protocol                      = "tcp"
      from_port                     = 10250
      to_port                       = 10250
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_self_coredns_tcp = {
      description = "Node to node CoreDNS"
      protocol    = "tcp"
      from_port   = 53
      to_port     = 53
      type        = "ingress"
      self        = true
    }
    ingress_self_coredns_udp = {
      description = "Node to node CoreDNS UDP"
      protocol    = "udp"
      from_port   = 53
      to_port     = 53
      type        = "ingress"
      self        = true
    }
  }

  node_security_group_recommended_rules = { for k, v in {
    ingress_nodes_ephemeral = {
      description = "Node to node ingress on ephemeral ports"
      protocol    = "tcp"
      from_port   = 1025
      to_port     = 65535
      type        = "ingress"
      self        = true
    }
    # metrics-server
    ingress_cluster_4443_webhook = {
      description                   = "Cluster API to node 4443/tcp webhook"
      protocol                      = "tcp"
      from_port                     = 4443
      to_port                       = 4443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    # prometheus-adapter
    ingress_cluster_6443_webhook = {
      description                   = "Cluster API to node 6443/tcp webhook"
      protocol                      = "tcp"
      from_port                     = 6443
      to_port                       = 6443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    # Karpenter
    ingress_cluster_8443_webhook = {
      description                   = "Cluster API to node 8443/tcp webhook"
      protocol                      = "tcp"
      from_port                     = 8443
      to_port                       = 8443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    # ALB controller, NGINX
    ingress_cluster_9443_webhook = {
      description                   = "Cluster API to node 9443/tcp webhook"
      protocol                      = "tcp"
      from_port                     = 9443
      to_port                       = 9443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    egress_all = {
      description      = "Allow all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = var.cluster_ip_family == "ipv6" ? ["::/0"] : null
    }
  } : k => v if var.node_security_group_enable_recommended_rules }

  efa_security_group_rules = { for k, v in
    {
      ingress_all_self_efa = {
        description = "Node to node EFA"
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        type        = "ingress"
        self        = true
      }
      egress_all_self_efa = {
        description = "Node to node EFA"
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        type        = "egress"
        self        = true
      }
    } : k => v if var.enable_efa_support
  }
}

resource "aws_security_group" "node" {
  name        = var.node_security_group_use_name_prefix ? null : local.node_sg_name
  name_prefix = var.node_security_group_use_name_prefix ? "${local.node_sg_name}${var.prefix_separator}" : null
  description = var.node_security_group_description
  vpc_id      = var.vpc_id

  tags = merge(
    local.tags,
    {
      "Name"                              = local.node_sg_name
      "kubernetes.io/cluster/${var.name}" = "owned"
    },
  var.node_security_group_tags)

  lifecycle {
    enabled               = local.create_node_sg
    create_before_destroy = true
  }
}

locals {
  all_node_security_group_rules = merge(
    local.efa_security_group_rules,
    local.node_security_group_rules,
    local.node_security_group_recommended_rules,
    var.node_security_group_additional_rules,
  )
}

resource "aws_vpc_security_group_ingress_rule" "node" {
  for_each = { for k, v in local.all_node_security_group_rules : k => v if local.create_node_sg && try(v.type, "ingress") == "ingress" }

  security_group_id = aws_security_group.node.id
  ip_protocol       = each.value.protocol
  from_port         = each.value.from_port == 0 && each.value.to_port == 0 ? null : each.value.from_port
  to_port           = each.value.from_port == 0 && each.value.to_port == 0 ? null : each.value.to_port

  description                  = lookup(each.value, "description", null)
  cidr_ipv4                    = try(each.value.cidr_blocks[0], null)
  cidr_ipv6                    = try(each.value.ipv6_cidr_blocks[0], null)
  prefix_list_id               = try(each.value.prefix_list_ids[0], null)
  referenced_security_group_id = try(each.value.source_cluster_security_group, false) ? local.cluster_security_group_id : try(each.value.self, false) ? aws_security_group.node.id : lookup(each.value, "source_security_group_id", null)

  tags = local.tags
}

# trivy:ignore:AVD-AWS-0104 - EKS nodes require unrestricted egress to reach the Kubernetes control plane and AWS services
resource "aws_vpc_security_group_egress_rule" "node" {
  for_each = { for k, v in local.all_node_security_group_rules : k => v if local.create_node_sg && try(v.type, "ingress") == "egress" }

  security_group_id = aws_security_group.node.id
  ip_protocol       = each.value.protocol
  from_port         = each.value.from_port == 0 && each.value.to_port == 0 ? null : each.value.from_port
  to_port           = each.value.from_port == 0 && each.value.to_port == 0 ? null : each.value.to_port

  description                  = lookup(each.value, "description", null)
  cidr_ipv4                    = try(each.value.cidr_blocks[0], null)
  cidr_ipv6                    = try(each.value.ipv6_cidr_blocks[0], null)
  prefix_list_id               = try(each.value.prefix_list_ids[0], null)
  referenced_security_group_id = try(each.value.self, false) ? aws_security_group.node.id : lookup(each.value, "source_security_group_id", null)

  tags = local.tags
}

################################################################################
# Fargate Profile
################################################################################

module "fargate_profile" {
  source = "./modules/fargate-profile"

  for_each = { for k, v in var.fargate_profiles : k => v if local.enabled && !local.create_outposts_local_cluster }

  enabled = each.value.create

  # Fargate Profile
  cluster_name      = time_sleep.this.triggers["cluster_name"]
  cluster_ip_family = var.cluster_ip_family
  name              = coalesce(each.value.name, each.key)
  subnet_ids        = try(coalesce(each.value.subnet_ids, var.fargate_profile_defaults.subnet_ids), var.subnet_ids)
  selectors         = try(coalesce(each.value.selectors, var.fargate_profile_defaults.selectors), [])
  timeouts          = try(coalesce(each.value.timeouts, var.fargate_profile_defaults.timeouts), {})

  # IAM role
  create_iam_role               = try(coalesce(each.value.create_iam_role, var.fargate_profile_defaults.create_iam_role), true)
  iam_role_arn                  = try(coalesce(each.value.iam_role_arn, var.fargate_profile_defaults.iam_role_arn), null)
  iam_role_name                 = try(coalesce(each.value.iam_role_name, var.fargate_profile_defaults.iam_role_name), null)
  iam_role_use_name_prefix      = try(coalesce(each.value.iam_role_use_name_prefix, var.fargate_profile_defaults.iam_role_use_name_prefix), true)
  iam_role_path                 = try(coalesce(each.value.iam_role_path, var.fargate_profile_defaults.iam_role_path), null)
  iam_role_description          = try(coalesce(each.value.iam_role_description, var.fargate_profile_defaults.iam_role_description), "Fargate profile IAM role")
  iam_role_permissions_boundary = try(coalesce(each.value.iam_role_permissions_boundary, var.fargate_profile_defaults.iam_role_permissions_boundary), null)
  iam_role_tags                 = try(coalesce(each.value.iam_role_tags, var.fargate_profile_defaults.iam_role_tags), {})
  iam_role_attach_cni_policy    = try(coalesce(each.value.iam_role_attach_cni_policy, var.fargate_profile_defaults.iam_role_attach_cni_policy), true)
  iam_role_additional_policies  = try(coalesce(each.value.iam_role_additional_policies, var.fargate_profile_defaults.iam_role_additional_policies), {})
  create_iam_role_policy        = try(coalesce(each.value.create_iam_role_policy, var.fargate_profile_defaults.create_iam_role_policy), true)
  iam_role_policy_statements    = try(coalesce(each.value.iam_role_policy_statements, var.fargate_profile_defaults.iam_role_policy_statements), [])

  tags = merge(var.tags, try(coalesce(each.value.tags, var.fargate_profile_defaults.tags), {}))
}

################################################################################
# EKS Managed Node Group
################################################################################

module "eks_managed_node_group" {
  source = "./modules/eks-managed-node-group"

  for_each = { for k, v in var.eks_managed_node_groups : k => v if local.enabled && !local.create_outposts_local_cluster }

  enabled = each.value.create

  cluster_name    = time_sleep.this.triggers["cluster_name"]
  cluster_version = try(coalesce(each.value.cluster_version, var.eks_managed_node_group_defaults.cluster_version), time_sleep.this.triggers["cluster_version"])

  # EKS Managed Node Group
  name            = coalesce(each.value.name, each.key)
  use_name_prefix = try(coalesce(each.value.use_name_prefix, var.eks_managed_node_group_defaults.use_name_prefix), true)

  subnet_ids = try(coalesce(each.value.subnet_ids, var.eks_managed_node_group_defaults.subnet_ids), var.subnet_ids)

  min_size     = try(coalesce(each.value.min_size, var.eks_managed_node_group_defaults.min_size), 1)
  max_size     = try(coalesce(each.value.max_size, var.eks_managed_node_group_defaults.max_size), 3)
  desired_size = try(coalesce(each.value.desired_size, var.eks_managed_node_group_defaults.desired_size), 1)

  ami_id                         = try(coalesce(each.value.ami_id, var.eks_managed_node_group_defaults.ami_id), "")
  ami_type                       = try(coalesce(each.value.ami_type, var.eks_managed_node_group_defaults.ami_type), null)
  ami_release_version            = try(coalesce(each.value.ami_release_version, var.eks_managed_node_group_defaults.ami_release_version), null)
  use_latest_ami_release_version = try(coalesce(each.value.use_latest_ami_release_version, var.eks_managed_node_group_defaults.use_latest_ami_release_version), false)

  capacity_type        = try(coalesce(each.value.capacity_type, var.eks_managed_node_group_defaults.capacity_type), null)
  disk_size            = try(coalesce(each.value.disk_size, var.eks_managed_node_group_defaults.disk_size), null)
  force_update_version = try(coalesce(each.value.force_update_version, var.eks_managed_node_group_defaults.force_update_version), null)
  instance_types       = try(coalesce(each.value.instance_types, var.eks_managed_node_group_defaults.instance_types), null)
  labels               = try(coalesce(each.value.labels, var.eks_managed_node_group_defaults.labels), null)
  node_repair_config   = try(coalesce(each.value.node_repair_config, var.eks_managed_node_group_defaults.node_repair_config), null)
  remote_access        = try(coalesce(each.value.remote_access, var.eks_managed_node_group_defaults.remote_access), null)
  taints               = try(coalesce(each.value.taints, var.eks_managed_node_group_defaults.taints), {})
  update_config        = try(coalesce(each.value.update_config, var.eks_managed_node_group_defaults.update_config), local.default_update_config)
  timeouts             = try(coalesce(each.value.timeouts, var.eks_managed_node_group_defaults.timeouts), {})

  # User data
  cluster_endpoint           = try(time_sleep.this.triggers["cluster_endpoint"], null)
  cluster_auth_base64        = try(time_sleep.this.triggers["cluster_certificate_authority_data"], null)
  cluster_ip_family          = var.cluster_ip_family
  cluster_service_cidr       = try(time_sleep.this.triggers["cluster_service_cidr"], null)
  enable_bootstrap_user_data = try(coalesce(each.value.enable_bootstrap_user_data, var.eks_managed_node_group_defaults.enable_bootstrap_user_data), false)
  pre_bootstrap_user_data    = try(coalesce(each.value.pre_bootstrap_user_data, var.eks_managed_node_group_defaults.pre_bootstrap_user_data), null)
  post_bootstrap_user_data   = try(coalesce(each.value.post_bootstrap_user_data, var.eks_managed_node_group_defaults.post_bootstrap_user_data), null)
  bootstrap_extra_args       = try(coalesce(each.value.bootstrap_extra_args, var.eks_managed_node_group_defaults.bootstrap_extra_args), null)
  user_data_template_path    = try(coalesce(each.value.user_data_template_path, var.eks_managed_node_group_defaults.user_data_template_path), null)
  cloudinit_pre_nodeadm      = try(coalesce(each.value.cloudinit_pre_nodeadm, var.eks_managed_node_group_defaults.cloudinit_pre_nodeadm), [])
  cloudinit_post_nodeadm     = try(coalesce(each.value.cloudinit_post_nodeadm, var.eks_managed_node_group_defaults.cloudinit_post_nodeadm), [])

  # Launch Template
  create_launch_template                 = try(coalesce(each.value.create_launch_template, var.eks_managed_node_group_defaults.create_launch_template), true)
  use_custom_launch_template             = try(coalesce(each.value.use_custom_launch_template, var.eks_managed_node_group_defaults.use_custom_launch_template), true)
  launch_template_id                     = try(coalesce(each.value.launch_template_id, var.eks_managed_node_group_defaults.launch_template_id), "")
  launch_template_name                   = try(coalesce(each.value.launch_template_name, var.eks_managed_node_group_defaults.launch_template_name), each.key)
  launch_template_use_name_prefix        = try(coalesce(each.value.launch_template_use_name_prefix, var.eks_managed_node_group_defaults.launch_template_use_name_prefix), true)
  launch_template_version                = try(coalesce(each.value.launch_template_version, var.eks_managed_node_group_defaults.launch_template_version), null)
  launch_template_default_version        = try(coalesce(each.value.launch_template_default_version, var.eks_managed_node_group_defaults.launch_template_default_version), null)
  update_launch_template_default_version = try(coalesce(each.value.update_launch_template_default_version, var.eks_managed_node_group_defaults.update_launch_template_default_version), true)
  launch_template_description            = try(coalesce(each.value.launch_template_description, var.eks_managed_node_group_defaults.launch_template_description), "Custom launch template for ${coalesce(each.value.name, each.key)} EKS managed node group")
  launch_template_tags                   = try(coalesce(each.value.launch_template_tags, var.eks_managed_node_group_defaults.launch_template_tags), {})
  tag_specifications                     = try(coalesce(each.value.tag_specifications, var.eks_managed_node_group_defaults.tag_specifications), ["instance", "volume", "network-interface"])

  ebs_optimized           = try(coalesce(each.value.ebs_optimized, var.eks_managed_node_group_defaults.ebs_optimized), null)
  key_name                = try(coalesce(each.value.key_name, var.eks_managed_node_group_defaults.key_name), null)
  disable_api_termination = try(coalesce(each.value.disable_api_termination, var.eks_managed_node_group_defaults.disable_api_termination), null)
  kernel_id               = try(coalesce(each.value.kernel_id, var.eks_managed_node_group_defaults.kernel_id), null)
  ram_disk_id             = try(coalesce(each.value.ram_disk_id, var.eks_managed_node_group_defaults.ram_disk_id), null)

  block_device_mappings              = try(coalesce(each.value.block_device_mappings, var.eks_managed_node_group_defaults.block_device_mappings), {})
  capacity_reservation_specification = try(coalesce(each.value.capacity_reservation_specification, var.eks_managed_node_group_defaults.capacity_reservation_specification), null)
  cpu_options                        = try(coalesce(each.value.cpu_options, var.eks_managed_node_group_defaults.cpu_options), null)
  credit_specification               = try(coalesce(each.value.credit_specification, var.eks_managed_node_group_defaults.credit_specification), null)
  enclave_options                    = try(coalesce(each.value.enclave_options, var.eks_managed_node_group_defaults.enclave_options), null)
  instance_market_options            = try(coalesce(each.value.instance_market_options, var.eks_managed_node_group_defaults.instance_market_options), null)
  license_specifications             = try(coalesce(each.value.license_specifications, var.eks_managed_node_group_defaults.license_specifications), {})
  metadata_options                   = try(coalesce(each.value.metadata_options, var.eks_managed_node_group_defaults.metadata_options), local.metadata_options)
  enable_monitoring                  = try(coalesce(each.value.enable_monitoring, var.eks_managed_node_group_defaults.enable_monitoring), false)
  enable_efa_support                 = try(coalesce(each.value.enable_efa_support, var.eks_managed_node_group_defaults.enable_efa_support), false)
  enable_efa_only                    = try(coalesce(each.value.enable_efa_only, var.eks_managed_node_group_defaults.enable_efa_only), true)
  efa_indices                        = try(coalesce(each.value.efa_indices, var.eks_managed_node_group_defaults.efa_indices), [0])
  create_placement_group             = try(coalesce(each.value.create_placement_group, var.eks_managed_node_group_defaults.create_placement_group), false)
  placement                          = try(coalesce(each.value.placement, var.eks_managed_node_group_defaults.placement), null)
  placement_group_az                 = try(coalesce(each.value.placement_group_az, var.eks_managed_node_group_defaults.placement_group_az), null)
  network_interfaces                 = try(coalesce(each.value.network_interfaces, var.eks_managed_node_group_defaults.network_interfaces), [])
  maintenance_options                = try(coalesce(each.value.maintenance_options, var.eks_managed_node_group_defaults.maintenance_options), null)
  private_dns_name_options           = try(coalesce(each.value.private_dns_name_options, var.eks_managed_node_group_defaults.private_dns_name_options), null)

  # IAM role
  create_iam_role               = try(coalesce(each.value.create_iam_role, var.eks_managed_node_group_defaults.create_iam_role), true)
  iam_role_arn                  = try(coalesce(each.value.iam_role_arn, var.eks_managed_node_group_defaults.iam_role_arn), null)
  iam_role_name                 = try(coalesce(each.value.iam_role_name, var.eks_managed_node_group_defaults.iam_role_name), null)
  iam_role_use_name_prefix      = try(coalesce(each.value.iam_role_use_name_prefix, var.eks_managed_node_group_defaults.iam_role_use_name_prefix), true)
  iam_role_path                 = try(coalesce(each.value.iam_role_path, var.eks_managed_node_group_defaults.iam_role_path), null)
  iam_role_description          = try(coalesce(each.value.iam_role_description, var.eks_managed_node_group_defaults.iam_role_description), "EKS managed node group IAM role")
  iam_role_permissions_boundary = try(coalesce(each.value.iam_role_permissions_boundary, var.eks_managed_node_group_defaults.iam_role_permissions_boundary), null)
  iam_role_tags                 = try(coalesce(each.value.iam_role_tags, var.eks_managed_node_group_defaults.iam_role_tags), {})
  iam_role_attach_cni_policy    = try(coalesce(each.value.iam_role_attach_cni_policy, var.eks_managed_node_group_defaults.iam_role_attach_cni_policy), true)
  iam_role_additional_policies  = try(coalesce(each.value.iam_role_additional_policies, var.eks_managed_node_group_defaults.iam_role_additional_policies), {})
  create_iam_role_policy        = try(coalesce(each.value.create_iam_role_policy, var.eks_managed_node_group_defaults.create_iam_role_policy), true)
  iam_role_policy_statements    = try(coalesce(each.value.iam_role_policy_statements, var.eks_managed_node_group_defaults.iam_role_policy_statements), [])

  # Autoscaling group schedule
  create_schedule = try(coalesce(each.value.create_schedule, var.eks_managed_node_group_defaults.create_schedule), true)
  schedules       = try(coalesce(each.value.schedules, var.eks_managed_node_group_defaults.schedules), {})

  # Security group
  vpc_security_group_ids            = compact(concat([local.node_security_group_id], try(coalesce(each.value.vpc_security_group_ids, var.eks_managed_node_group_defaults.vpc_security_group_ids), [])))
  cluster_primary_security_group_id = try(coalesce(each.value.attach_cluster_primary_security_group, var.eks_managed_node_group_defaults.attach_cluster_primary_security_group), false) ? aws_eks_cluster.this.vpc_config[0].cluster_security_group_id : null

  tags = merge(var.tags, try(coalesce(each.value.tags, var.eks_managed_node_group_defaults.tags), {}))
}

################################################################################
# Self Managed Node Group
################################################################################

module "self_managed_node_group" {
  source = "./modules/self-managed-node-group"

  for_each = { for k, v in var.self_managed_node_groups : k => v if local.enabled }

  enabled = each.value.create

  cluster_name = time_sleep.this.triggers["cluster_name"]

  # Autoscaling Group
  create_autoscaling_group = try(coalesce(each.value.create_autoscaling_group, var.self_managed_node_group_defaults.create_autoscaling_group), true)

  name            = coalesce(each.value.name, each.key)
  use_name_prefix = try(coalesce(each.value.use_name_prefix, var.self_managed_node_group_defaults.use_name_prefix), true)

  availability_zones = try(coalesce(each.value.availability_zones, var.self_managed_node_group_defaults.availability_zones), null)
  subnet_ids         = try(coalesce(each.value.subnet_ids, var.self_managed_node_group_defaults.subnet_ids), var.subnet_ids)

  min_size                  = try(coalesce(each.value.min_size, var.self_managed_node_group_defaults.min_size), 0)
  max_size                  = try(coalesce(each.value.max_size, var.self_managed_node_group_defaults.max_size), 3)
  desired_size              = try(coalesce(each.value.desired_size, var.self_managed_node_group_defaults.desired_size), 1)
  desired_size_type         = try(coalesce(each.value.desired_size_type, var.self_managed_node_group_defaults.desired_size_type), null)
  capacity_rebalance        = try(coalesce(each.value.capacity_rebalance, var.self_managed_node_group_defaults.capacity_rebalance), null)
  min_elb_capacity          = try(coalesce(each.value.min_elb_capacity, var.self_managed_node_group_defaults.min_elb_capacity), null)
  wait_for_elb_capacity     = try(coalesce(each.value.wait_for_elb_capacity, var.self_managed_node_group_defaults.wait_for_elb_capacity), null)
  wait_for_capacity_timeout = try(coalesce(each.value.wait_for_capacity_timeout, var.self_managed_node_group_defaults.wait_for_capacity_timeout), null)
  default_cooldown          = try(coalesce(each.value.default_cooldown, var.self_managed_node_group_defaults.default_cooldown), null)
  default_instance_warmup   = try(coalesce(each.value.default_instance_warmup, var.self_managed_node_group_defaults.default_instance_warmup), null)
  protect_from_scale_in     = try(coalesce(each.value.protect_from_scale_in, var.self_managed_node_group_defaults.protect_from_scale_in), null)
  context                   = try(coalesce(each.value.context, var.self_managed_node_group_defaults.context), null)

  target_group_arns         = try(coalesce(each.value.target_group_arns, var.self_managed_node_group_defaults.target_group_arns), [])
  create_placement_group    = try(coalesce(each.value.create_placement_group, var.self_managed_node_group_defaults.create_placement_group), false)
  placement_group           = try(coalesce(each.value.placement_group, var.self_managed_node_group_defaults.placement_group), null)
  placement_group_az        = try(coalesce(each.value.placement_group_az, var.self_managed_node_group_defaults.placement_group_az), null)
  health_check_type         = try(coalesce(each.value.health_check_type, var.self_managed_node_group_defaults.health_check_type), null)
  health_check_grace_period = try(coalesce(each.value.health_check_grace_period, var.self_managed_node_group_defaults.health_check_grace_period), null)

  ignore_failed_scaling_activities = try(coalesce(each.value.ignore_failed_scaling_activities, var.self_managed_node_group_defaults.ignore_failed_scaling_activities), null)

  force_delete           = try(coalesce(each.value.force_delete, var.self_managed_node_group_defaults.force_delete), null)
  force_delete_warm_pool = try(coalesce(each.value.force_delete_warm_pool, var.self_managed_node_group_defaults.force_delete_warm_pool), null)
  termination_policies   = try(coalesce(each.value.termination_policies, var.self_managed_node_group_defaults.termination_policies), [])
  suspended_processes    = try(coalesce(each.value.suspended_processes, var.self_managed_node_group_defaults.suspended_processes), [])
  max_instance_lifetime  = try(coalesce(each.value.max_instance_lifetime, var.self_managed_node_group_defaults.max_instance_lifetime), null)

  enabled_metrics         = try(coalesce(each.value.enabled_metrics, var.self_managed_node_group_defaults.enabled_metrics), [])
  metrics_granularity     = try(coalesce(each.value.metrics_granularity, var.self_managed_node_group_defaults.metrics_granularity), null)
  service_linked_role_arn = try(coalesce(each.value.service_linked_role_arn, var.self_managed_node_group_defaults.service_linked_role_arn), null)

  initial_lifecycle_hooks     = try(coalesce(each.value.initial_lifecycle_hooks, var.self_managed_node_group_defaults.initial_lifecycle_hooks), [])
  instance_maintenance_policy = try(coalesce(each.value.instance_maintenance_policy, var.self_managed_node_group_defaults.instance_maintenance_policy), null)
  instance_refresh            = try(coalesce(each.value.instance_refresh, var.self_managed_node_group_defaults.instance_refresh), local.default_instance_refresh)
  use_mixed_instances_policy  = try(coalesce(each.value.use_mixed_instances_policy, var.self_managed_node_group_defaults.use_mixed_instances_policy), false)
  mixed_instances_policy      = try(coalesce(each.value.mixed_instances_policy, var.self_managed_node_group_defaults.mixed_instances_policy), null)
  warm_pool                   = try(coalesce(each.value.warm_pool, var.self_managed_node_group_defaults.warm_pool), null)

  delete_timeout         = try(coalesce(each.value.delete_timeout, var.self_managed_node_group_defaults.delete_timeout), null)
  autoscaling_group_tags = try(coalesce(each.value.autoscaling_group_tags, var.self_managed_node_group_defaults.autoscaling_group_tags), {})

  # User data
  ami_type                 = try(coalesce(each.value.ami_type, var.self_managed_node_group_defaults.ami_type), "AL2023_x86_64_STANDARD")
  cluster_endpoint         = try(time_sleep.this.triggers["cluster_endpoint"], null)
  cluster_auth_base64      = try(time_sleep.this.triggers["cluster_certificate_authority_data"], null)
  cluster_service_cidr     = try(time_sleep.this.triggers["cluster_service_cidr"], null)
  cluster_ip_family        = var.cluster_ip_family
  pre_bootstrap_user_data  = try(coalesce(each.value.pre_bootstrap_user_data, var.self_managed_node_group_defaults.pre_bootstrap_user_data), null)
  post_bootstrap_user_data = try(coalesce(each.value.post_bootstrap_user_data, var.self_managed_node_group_defaults.post_bootstrap_user_data), null)
  bootstrap_extra_args     = try(coalesce(each.value.bootstrap_extra_args, var.self_managed_node_group_defaults.bootstrap_extra_args), null)
  user_data_template_path  = try(coalesce(each.value.user_data_template_path, var.self_managed_node_group_defaults.user_data_template_path), null)
  cloudinit_pre_nodeadm    = try(coalesce(each.value.cloudinit_pre_nodeadm, var.self_managed_node_group_defaults.cloudinit_pre_nodeadm), [])
  cloudinit_post_nodeadm   = try(coalesce(each.value.cloudinit_post_nodeadm, var.self_managed_node_group_defaults.cloudinit_post_nodeadm), [])

  # Launch Template
  create_launch_template                 = try(coalesce(each.value.create_launch_template, var.self_managed_node_group_defaults.create_launch_template), true)
  launch_template_id                     = try(coalesce(each.value.launch_template_id, var.self_managed_node_group_defaults.launch_template_id), null)
  launch_template_name                   = try(coalesce(each.value.launch_template_name, var.self_managed_node_group_defaults.launch_template_name), each.key)
  launch_template_use_name_prefix        = try(coalesce(each.value.launch_template_use_name_prefix, var.self_managed_node_group_defaults.launch_template_use_name_prefix), true)
  launch_template_version                = try(coalesce(each.value.launch_template_version, var.self_managed_node_group_defaults.launch_template_version), null)
  launch_template_default_version        = try(coalesce(each.value.launch_template_default_version, var.self_managed_node_group_defaults.launch_template_default_version), null)
  update_launch_template_default_version = try(coalesce(each.value.update_launch_template_default_version, var.self_managed_node_group_defaults.update_launch_template_default_version), true)
  launch_template_description            = try(coalesce(each.value.launch_template_description, var.self_managed_node_group_defaults.launch_template_description), "Custom launch template for ${coalesce(each.value.name, each.key)} self managed node group")
  launch_template_tags                   = try(coalesce(each.value.launch_template_tags, var.self_managed_node_group_defaults.launch_template_tags), {})
  tag_specifications                     = try(coalesce(each.value.tag_specifications, var.self_managed_node_group_defaults.tag_specifications), ["instance", "volume", "network-interface"])

  ebs_optimized   = try(coalesce(each.value.ebs_optimized, var.self_managed_node_group_defaults.ebs_optimized), null)
  ami_id          = try(coalesce(each.value.ami_id, var.self_managed_node_group_defaults.ami_id), null)
  cluster_version = try(coalesce(each.value.cluster_version, var.self_managed_node_group_defaults.cluster_version), time_sleep.this.triggers["cluster_version"])
  instance_type   = try(coalesce(each.value.instance_type, var.self_managed_node_group_defaults.instance_type), "m6i.large")
  key_name        = try(coalesce(each.value.key_name, var.self_managed_node_group_defaults.key_name), null)

  disable_api_termination              = try(coalesce(each.value.disable_api_termination, var.self_managed_node_group_defaults.disable_api_termination), null)
  instance_initiated_shutdown_behavior = try(coalesce(each.value.instance_initiated_shutdown_behavior, var.self_managed_node_group_defaults.instance_initiated_shutdown_behavior), null)
  kernel_id                            = try(coalesce(each.value.kernel_id, var.self_managed_node_group_defaults.kernel_id), null)
  ram_disk_id                          = try(coalesce(each.value.ram_disk_id, var.self_managed_node_group_defaults.ram_disk_id), null)

  block_device_mappings              = try(coalesce(each.value.block_device_mappings, var.self_managed_node_group_defaults.block_device_mappings), {})
  capacity_reservation_specification = try(coalesce(each.value.capacity_reservation_specification, var.self_managed_node_group_defaults.capacity_reservation_specification), null)
  cpu_options                        = try(coalesce(each.value.cpu_options, var.self_managed_node_group_defaults.cpu_options), null)
  credit_specification               = try(coalesce(each.value.credit_specification, var.self_managed_node_group_defaults.credit_specification), null)
  enclave_options                    = try(coalesce(each.value.enclave_options, var.self_managed_node_group_defaults.enclave_options), null)
  hibernation_options                = try(coalesce(each.value.hibernation_options, var.self_managed_node_group_defaults.hibernation_options), null)
  instance_requirements              = try(coalesce(each.value.instance_requirements, var.self_managed_node_group_defaults.instance_requirements), null)
  instance_market_options            = try(coalesce(each.value.instance_market_options, var.self_managed_node_group_defaults.instance_market_options), null)
  license_specifications             = try(coalesce(each.value.license_specifications, var.self_managed_node_group_defaults.license_specifications), {})
  metadata_options                   = try(coalesce(each.value.metadata_options, var.self_managed_node_group_defaults.metadata_options), local.metadata_options)
  enable_monitoring                  = try(coalesce(each.value.enable_monitoring, var.self_managed_node_group_defaults.enable_monitoring), true)
  enable_efa_support                 = try(coalesce(each.value.enable_efa_support, var.self_managed_node_group_defaults.enable_efa_support), false)
  enable_efa_only                    = try(coalesce(each.value.enable_efa_only, var.self_managed_node_group_defaults.enable_efa_only), true)
  efa_indices                        = try(coalesce(each.value.efa_indices, var.self_managed_node_group_defaults.efa_indices), [0])
  network_interfaces                 = try(coalesce(each.value.network_interfaces, var.self_managed_node_group_defaults.network_interfaces), [])
  placement                          = try(coalesce(each.value.placement, var.self_managed_node_group_defaults.placement), null)
  maintenance_options                = try(coalesce(each.value.maintenance_options, var.self_managed_node_group_defaults.maintenance_options), null)
  private_dns_name_options           = try(coalesce(each.value.private_dns_name_options, var.self_managed_node_group_defaults.private_dns_name_options), null)

  # IAM role
  create_iam_instance_profile   = try(coalesce(each.value.create_iam_instance_profile, var.self_managed_node_group_defaults.create_iam_instance_profile), true)
  iam_instance_profile_arn      = try(coalesce(each.value.iam_instance_profile_arn, var.self_managed_node_group_defaults.iam_instance_profile_arn), null)
  iam_role_name                 = try(coalesce(each.value.iam_role_name, var.self_managed_node_group_defaults.iam_role_name), null)
  iam_role_use_name_prefix      = try(coalesce(each.value.iam_role_use_name_prefix, var.self_managed_node_group_defaults.iam_role_use_name_prefix), true)
  iam_role_path                 = try(coalesce(each.value.iam_role_path, var.self_managed_node_group_defaults.iam_role_path), null)
  iam_role_description          = try(coalesce(each.value.iam_role_description, var.self_managed_node_group_defaults.iam_role_description), "Self managed node group IAM role")
  iam_role_permissions_boundary = try(coalesce(each.value.iam_role_permissions_boundary, var.self_managed_node_group_defaults.iam_role_permissions_boundary), null)
  iam_role_tags                 = try(coalesce(each.value.iam_role_tags, var.self_managed_node_group_defaults.iam_role_tags), {})
  iam_role_attach_cni_policy    = try(coalesce(each.value.iam_role_attach_cni_policy, var.self_managed_node_group_defaults.iam_role_attach_cni_policy), true)
  iam_role_additional_policies  = try(coalesce(each.value.iam_role_additional_policies, var.self_managed_node_group_defaults.iam_role_additional_policies), {})
  create_iam_role_policy        = try(coalesce(each.value.create_iam_role_policy, var.self_managed_node_group_defaults.create_iam_role_policy), true)
  iam_role_policy_statements    = try(coalesce(each.value.iam_role_policy_statements, var.self_managed_node_group_defaults.iam_role_policy_statements), [])

  # Access entry
  create_access_entry = try(coalesce(each.value.create_access_entry, var.self_managed_node_group_defaults.create_access_entry), true)
  iam_role_arn        = try(coalesce(each.value.iam_role_arn, var.self_managed_node_group_defaults.iam_role_arn), null)

  # Autoscaling group schedule
  create_schedule = try(coalesce(each.value.create_schedule, var.self_managed_node_group_defaults.create_schedule), true)
  schedules       = try(coalesce(each.value.schedules, var.self_managed_node_group_defaults.schedules), {})

  # Security group
  vpc_security_group_ids            = compact(concat([local.node_security_group_id], try(coalesce(each.value.vpc_security_group_ids, var.self_managed_node_group_defaults.vpc_security_group_ids), [])))
  cluster_primary_security_group_id = try(coalesce(each.value.attach_cluster_primary_security_group, var.self_managed_node_group_defaults.attach_cluster_primary_security_group), false) ? aws_eks_cluster.this.vpc_config[0].cluster_security_group_id : null

  tags = merge(var.tags, try(coalesce(each.value.tags, var.self_managed_node_group_defaults.tags), {}))
}
