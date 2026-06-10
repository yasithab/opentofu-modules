variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# User Data
################################################################################

variable "enable_bootstrap_user_data" {
  description = "Determines whether the bootstrap configurations are populated within the user data template. Only valid when using a custom AMI via `ami_id`"
  type        = bool
  default     = false
}

variable "cluster_name" {
  description = "Name of associated EKS cluster"
  type        = string
  default     = null
}

variable "cluster_endpoint" {
  description = "Endpoint of associated EKS cluster"
  type        = string
  default     = null
}

variable "cluster_auth_base64" {
  description = "Base64 encoded CA of associated EKS cluster"
  type        = string
  default     = null
}

variable "cluster_service_cidr" {
  description = "The CIDR block (IPv4 or IPv6) used by the cluster to assign Kubernetes service IP addresses. This is derived from the cluster itself"
  type        = string
  default     = null
}

variable "pre_bootstrap_user_data" {
  description = "User data that is injected into the user data script ahead of the EKS bootstrap script. Not used when `ami_type` = `BOTTLEROCKET_*`"
  type        = string
  default     = null
}

variable "post_bootstrap_user_data" {
  description = "User data that is appended to the user data script after of the EKS bootstrap script. Not used when `ami_type` = `BOTTLEROCKET_*`"
  type        = string
  default     = null
}

variable "bootstrap_extra_args" {
  description = "Additional arguments passed to the bootstrap script. When `ami_type` = `BOTTLEROCKET_*`; these are additional [settings](https://github.com/bottlerocket-os/bottlerocket#settings) that are provided to the Bottlerocket user data"
  type        = string
  default     = null
}

variable "user_data_template_path" {
  description = "Path to a local, custom user data template file to use when rendering user data"
  type        = string
  default     = null
}

variable "cloudinit_pre_nodeadm" {
  description = "Array of cloud-init document parts that are created before the nodeadm document part"
  type = list(object({
    content      = string
    content_type = optional(string)
    filename     = optional(string)
    merge_type   = optional(string)
  }))
  default = []
}

variable "cloudinit_post_nodeadm" {
  description = "Array of cloud-init document parts that are created after the nodeadm document part"
  type = list(object({
    content      = string
    content_type = optional(string)
    filename     = optional(string)
    merge_type   = optional(string)
  }))
  default = []
}

################################################################################
# Launch template
################################################################################

variable "create_launch_template" {
  description = "Determines whether to create a launch template or not. If set to `false`, EKS will use its own default launch template"
  type        = bool
  default     = true
}

variable "use_custom_launch_template" {
  description = "Determines whether to use a custom launch template or not. If set to `false`, EKS will use its own default launch template"
  type        = bool
  default     = true
}

variable "launch_template_id" {
  description = "The ID of an existing launch template to use. Required when `create_launch_template` = `false` and `use_custom_launch_template` = `true`"
  type        = string
  default     = null
}

variable "launch_template_name" {
  description = "Name of launch template to be created"
  type        = string
  default     = null
}

variable "launch_template_use_name_prefix" {
  description = "Determines whether to use `launch_template_name` as is or create a unique name beginning with the `launch_template_name` as the prefix"
  type        = bool
  default     = true
}

variable "launch_template_description" {
  description = "Description of the launch template"
  type        = string
  default     = null
}

variable "ebs_optimized" {
  description = "If true, the launched EC2 instance(s) will be EBS-optimized"
  type        = bool
  default     = null
}

variable "ami_id" {
  description = "The AMI from which to launch the instance. If not supplied, EKS will use its own default image"
  type        = string
  default     = null
}

variable "key_name" {
  description = "The key name that should be used for the instance(s)"
  type        = string
  default     = null
}

variable "vpc_security_group_ids" {
  description = "A list of security group IDs to associate"
  type        = list(string)
  default     = []
}

variable "cluster_primary_security_group_id" {
  description = "The ID of the EKS cluster primary security group to associate with the instance(s). This is the security group that is automatically created by the EKS service"
  type        = string
  default     = null
}

variable "launch_template_default_version" {
  description = "Default version of the launch template"
  type        = string
  default     = null
}

variable "update_launch_template_default_version" {
  description = "Whether to update the launch templates default version on each update. Conflicts with `launch_template_default_version`"
  type        = bool
  default     = true
}

variable "disable_api_stop" {
  description = "If true, enables EC2 instance stop protection"
  type        = bool
  default     = null
}

variable "disable_api_termination" {
  description = "If true, enables EC2 instance termination protection"
  type        = bool
  default     = null
}

variable "kernel_id" {
  description = "The kernel ID"
  type        = string
  default     = null
}

variable "ram_disk_id" {
  description = "The ID of the ram disk"
  type        = string
  default     = null
}

variable "block_device_mappings" {
  description = "Specify volumes to attach to the instance besides the volumes specified by the AMI"
  type = map(object({
    device_name = optional(string)
    ebs = optional(object({
      delete_on_termination      = optional(bool)
      encrypted                  = optional(bool)
      iops                       = optional(number)
      kms_key_id                 = optional(string)
      snapshot_id                = optional(string)
      throughput                 = optional(number)
      volume_initialization_rate = optional(number)
      volume_size                = optional(number)
      volume_type                = optional(string)
    }))
    no_device    = optional(string)
    virtual_name = optional(string)
  }))
  default = {}
}

variable "capacity_reservation_specification" {
  description = "Targeting for EC2 capacity reservations"
  type = object({
    capacity_reservation_preference = optional(string)
    capacity_reservation_target = optional(object({
      capacity_reservation_id                 = optional(string)
      capacity_reservation_resource_group_arn = optional(string)
    }))
  })
  default = null
}

variable "cpu_options" {
  description = "The CPU options for the instance"
  type = object({
    amd_sev_snp           = optional(string)
    core_count            = optional(number)
    nested_virtualization = optional(bool)
    threads_per_core      = optional(number)
  })
  default = null
}

variable "network_performance_options" {
  description = "The network performance options for the instance. Valid keys are `bandwidth_weighting` (valid values: `default`, `vpc-1`, `ebs-1`)"
  type        = map(string)
  default     = {}
}

variable "credit_specification" {
  description = "Customize the credit specification of the instance"
  type = object({
    cpu_credits = optional(string)
  })
  default = null
}

variable "enclave_options" {
  description = "Enable Nitro Enclaves on launched instances"
  type = object({
    enabled = bool
  })
  default = null
}

variable "instance_market_options" {
  description = "The market (purchasing) option for the instance"
  type = object({
    market_type = optional(string)
    spot_options = optional(object({
      block_duration_minutes         = optional(number)
      instance_interruption_behavior = optional(string)
      max_price                      = optional(string)
      spot_instance_type             = optional(string)
      valid_until                    = optional(string)
    }))
  })
  default = null
}

variable "maintenance_options" {
  description = "The maintenance options for the instance"
  type = object({
    auto_recovery = optional(string)
  })
  default = null
}

variable "license_specifications" {
  description = "A map of license specifications to associate with"
  type = map(object({
    license_configuration_arn = string
  }))
  default = {}
}

variable "metadata_options" {
  description = "Customize the metadata options for the instance"
  type = object({
    http_endpoint               = optional(string, "enabled")
    http_protocol_ipv6          = optional(string)
    http_put_response_hop_limit = optional(number, 1)
    http_tokens                 = optional(string, "required")
    instance_metadata_tags      = optional(string)
  })
  default = {}
}

variable "enable_monitoring" {
  description = "Enables/disables detailed monitoring"
  type        = bool
  default     = false
}

variable "enable_efa_support" {
  description = "Determines whether to enable Elastic Fabric Adapter (EFA) support"
  type        = bool
  default     = false
}

variable "enable_efa_only" {
  description = "Determines whether to enable EFA only (`true`) or EFA + standard (`false`) network interfaces. Note: requires vpc-cni version `v1.18.4` or later"
  type        = bool
  default     = true
}

variable "efa_indices" {
  description = "The indices of the network interfaces that should be EFA-enabled. Only valid when `enable_efa_support` = `true`"
  type        = list(number)
  default     = [0]
}

variable "network_interfaces" {
  description = "Customize network interfaces to be attached at instance boot time"
  type = list(object({
    associate_carrier_ip_address = optional(bool)
    associate_public_ip_address  = optional(bool)
    connection_tracking_specification = optional(object({
      tcp_established_timeout = optional(number)
      udp_stream_timeout      = optional(number)
      udp_timeout             = optional(number)
    }))
    delete_on_termination = optional(bool)
    description           = optional(string)
    device_index          = optional(number)
    ena_srd_specification = optional(object({
      ena_srd_enabled = optional(bool)
      ena_srd_udp_specification = optional(object({
        ena_srd_udp_enabled = optional(bool)
      }))
    }))
    interface_type       = optional(string)
    ipv4_address_count   = optional(number)
    ipv4_addresses       = optional(list(string), [])
    ipv4_prefix_count    = optional(number)
    ipv4_prefixes        = optional(list(string))
    ipv6_address_count   = optional(number)
    ipv6_addresses       = optional(list(string), [])
    ipv6_prefix_count    = optional(number)
    ipv6_prefixes        = optional(list(string), [])
    network_card_index   = optional(number)
    network_interface_id = optional(string)
    primary_ipv6         = optional(bool)
    private_ip_address   = optional(string)
    security_groups      = optional(list(string), [])
  }))
  default = []
}

variable "placement" {
  description = "The placement of the instance"
  type = object({
    affinity                = optional(string)
    availability_zone       = optional(string)
    group_id                = optional(string)
    group_name              = optional(string)
    host_id                 = optional(string)
    host_resource_group_arn = optional(string)
    partition_number        = optional(number)
    spread_domain           = optional(string)
    tenancy                 = optional(string)
  })
  default = null
}

variable "create_placement_group" {
  description = "Determines whether a placement group is created & used by the node group"
  type        = bool
  default     = false
}

variable "private_dns_name_options" {
  description = "The options for the instance hostname. The default values are inherited from the subnet"
  type = object({
    enable_resource_name_dns_aaaa_record = optional(bool)
    enable_resource_name_dns_a_record    = optional(bool)
    hostname_type                        = optional(string)
  })
  default = null
}

variable "security_group_names" {
  description = "A list of security group names to associate with. (EC2-Classic only)"
  type        = list(string)
  default     = null
}

variable "secondary_interfaces" {
  description = "Configuration for secondary network interfaces on the launch template"
  type = list(object({
    delete_on_termination    = optional(bool)
    device_index             = optional(number)
    interface_type           = optional(string)
    network_card_index       = optional(number)
    private_ip_address_count = optional(number)
    private_ip_addresses     = optional(list(string))
    secondary_subnet_id      = optional(string)
  }))
  default = []
}

variable "launch_template_tags" {
  description = "A map of additional tags to add to the tag_specifications of launch template created"
  type        = map(string)
  default     = {}
}

variable "tag_specifications" {
  description = "The tags to apply to the resources during launch"
  type        = list(string)
  default     = ["instance", "volume", "network-interface"]
}

################################################################################
# EKS Managed Node Group
################################################################################

variable "subnet_ids" {
  description = "Identifiers of EC2 Subnets to associate with the EKS Node Group. These subnets must have the following resource tag: `kubernetes.io/cluster/CLUSTER_NAME`"
  type        = list(string)
  default     = null
}

variable "placement_group_az" {
  description = "Availability zone where placement group is created (ex. `eu-west-1c`)"
  type        = string
  default     = null
}

variable "min_size" {
  description = "Minimum number of instances/nodes"
  type        = number
  default     = 0

  validation {
    condition     = var.min_size >= 0
    error_message = "The min_size must be non-negative."
  }
}

variable "max_size" {
  description = "Maximum number of instances/nodes"
  type        = number
  default     = 3

  validation {
    condition     = var.max_size >= 0
    error_message = "The max_size must be non-negative."
  }
}

variable "desired_size" {
  description = "Desired number of instances/nodes"
  type        = number
  default     = 1

  validation {
    condition     = var.desired_size >= 0
    error_message = "The desired_size must be non-negative."
  }
}

variable "name" {
  description = "Name of the EKS managed node group"
  type        = string
  default     = null
}

variable "use_name_prefix" {
  description = "Determines whether to use `name` as is or create a unique name beginning with the `name` as the prefix"
  type        = bool
  default     = true
}

variable "ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS Node Group. See the [AWS documentation](https://docs.aws.amazon.com/eks/latest/APIReference/API_Nodegroup.html#AmazonEKS-Type-Nodegroup-amiType) for valid values"
  type        = string
  default     = null
}

variable "ami_release_version" {
  description = "The AMI version. Defaults to latest AMI release version for the given Kubernetes version and AMI type"
  type        = string
  default     = null
}

variable "use_latest_ami_release_version" {
  description = "Determines whether to use the latest AMI release version for the given `ami_type` (except for `CUSTOM`). Note: `ami_type` and `cluster_version` must be supplied in order to enable this feature"
  type        = bool
  default     = false
}

variable "capacity_type" {
  description = "Type of capacity associated with the EKS Node Group. Valid values: `ON_DEMAND`, `SPOT`"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "The capacity_type must be 'ON_DEMAND' or 'SPOT'."
  }
}

variable "disk_size" {
  description = "Disk size in GiB for nodes. Defaults to `20`. Only valid when `use_custom_launch_template` = `false`"
  type        = number
  default     = null
}

variable "force_update_version" {
  description = "Force version update if existing pods are unable to be drained due to a pod disruption budget issue"
  type        = bool
  default     = null
}

variable "instance_types" {
  description = "Set of instance types associated with the EKS Node Group. Defaults to `[\"t3.medium\"]`"
  type        = list(string)
  default     = null
}

variable "labels" {
  description = "Key-value map of Kubernetes labels. Only labels that are applied with the EKS API are managed by this argument. Other Kubernetes labels applied to the EKS Node Group will not be managed"
  type        = map(string)
  default     = null
}

variable "cluster_version" {
  description = "Kubernetes version. Defaults to EKS Cluster Kubernetes version"
  type        = string
  default     = null
}

variable "launch_template_version" {
  description = "Launch template version number. The default is `$Default`"
  type        = string
  default     = null
}

variable "remote_access" {
  description = "Configuration block with remote access settings. Only valid when `use_custom_launch_template` = `false`"
  type = object({
    ec2_ssh_key               = optional(string)
    source_security_group_ids = optional(list(string), [])
  })
  default = null
}

variable "taints" {
  description = "The Kubernetes taints to be applied to the nodes in the node group. Maximum of 50 taints per node group"
  type = map(object({
    key    = string
    value  = optional(string)
    effect = string
  }))
  default = {}
}

variable "update_config" {
  description = "Configuration block of settings for max unavailable resources during node group updates. Supports max_unavailable, max_unavailable_percentage, and update_strategy (MINIMAL or DEFAULT)"
  type = object({
    max_unavailable            = optional(number)
    max_unavailable_percentage = optional(number)
    update_strategy            = optional(string)
  })
  default = {
    max_unavailable_percentage = 33
  }
}

variable "node_repair_config" {
  description = "The node auto repair configuration for the node group"
  type = object({
    enabled                                 = optional(bool, true)
    max_parallel_nodes_repaired_count       = optional(number)
    max_parallel_nodes_repaired_percentage  = optional(number)
    max_unhealthy_node_threshold_count      = optional(number)
    max_unhealthy_node_threshold_percentage = optional(number)
    node_repair_config_overrides = optional(list(object({
      min_repair_wait_time_mins = number
      node_monitoring_condition = string
      node_unhealthy_reason     = string
      repair_action             = string
    })), [])
  })
  default = null
}

variable "timeouts" {
  description = "Create, update, and delete timeout configurations for the node group"
  type        = map(string)
  default     = {}
}

################################################################################
# IAM Role
################################################################################

variable "create_iam_role" {
  description = "Determines whether an IAM role is created or to use an existing IAM role"
  type        = bool
  default     = true
}

variable "cluster_ip_family" {
  description = "The IP family used to assign Kubernetes pod and service addresses. Valid values are `ipv4` (default) and `ipv6`"
  type        = string
  default     = "ipv4"

  validation {
    condition     = contains(["ipv4", "ipv6"], var.cluster_ip_family)
    error_message = "The cluster_ip_family must be 'ipv4' or 'ipv6'."
  }
}

variable "iam_role_arn" {
  description = "Existing IAM role ARN for the node group. Required if `create_iam_role` is set to `false`"
  type        = string
  default     = null

  validation {
    condition     = var.iam_role_arn == null || can(regex("^arn:", var.iam_role_arn))
    error_message = "The iam_role_arn must be null or a valid ARN starting with 'arn:'."
  }
}

variable "iam_role_name" {
  description = "Name to use on IAM role created"
  type        = string
  default     = null
}

variable "iam_role_use_name_prefix" {
  description = "Determines whether the IAM role name (`iam_role_name`) is used as a prefix"
  type        = bool
  default     = true
}

variable "iam_role_path" {
  description = "IAM role path"
  type        = string
  default     = null
}

variable "iam_role_description" {
  description = "Description of the role"
  type        = string
  default     = null
}

variable "iam_role_permissions_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the IAM role"
  type        = string
  default     = null

  validation {
    condition     = var.iam_role_permissions_boundary == null || can(regex("^arn:", var.iam_role_permissions_boundary))
    error_message = "The iam_role_permissions_boundary must be null or a valid ARN starting with 'arn:'."
  }
}

variable "iam_role_attach_cni_policy" {
  description = "Whether to attach the `AmazonEKS_CNI_Policy`/`AmazonEKS_CNI_IPv6_Policy` IAM policy to the IAM IAM role. WARNING: If set `false` the permissions must be assigned to the `aws-node` DaemonSet pods via another method or nodes will not be able to join the cluster"
  type        = bool
  default     = true
}

variable "iam_role_additional_policies" {
  description = "Additional policies to be added to the IAM role"
  type        = map(string)
  default     = {}
}

variable "iam_role_tags" {
  description = "A map of additional tags to add to the IAM role created"
  type        = map(string)
  default     = {}
}

################################################################################
# IAM Role Policy
################################################################################

variable "create_iam_role_policy" {
  description = "Determines whether an IAM role policy is created or not"
  type        = bool
  default     = true
}

variable "iam_role_policy_statements" {
  description = "A list of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) - used for adding specific IAM permissions as needed"
  type = list(object({
    sid           = optional(string)
    actions       = optional(list(string))
    not_actions   = optional(list(string))
    effect        = optional(string)
    resources     = optional(list(string))
    not_resources = optional(list(string))
    principals = optional(list(object({
      type        = string
      identifiers = list(string)
    })), [])
    not_principals = optional(list(object({
      type        = string
      identifiers = list(string)
    })), [])
    conditions = optional(list(object({
      test     = string
      values   = list(string)
      variable = string
    })), [])
  }))
  default = []
}

################################################################################
# Autoscaling Group Schedule
################################################################################

variable "create_schedule" {
  description = "Determines whether to create autoscaling group schedule or not"
  type        = bool
  default     = true
}

variable "schedules" {
  description = "Map of autoscaling group schedule to create"
  type = map(object({
    min_size     = optional(number)
    max_size     = optional(number)
    desired_size = optional(number)
    start_time   = optional(string)
    end_time     = optional(string)
    time_zone    = optional(string)
    recurrence   = optional(string)
  }))
  default = {}
}
