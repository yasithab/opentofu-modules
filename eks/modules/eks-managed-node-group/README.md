# EKS Managed Node Group Module

Configuration in this directory creates an EKS Managed Node Group along with an IAM role, security group, and launch template

## Usage

```hcl
module "eks_managed_node_group" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/eks-managed-node-group?depth=1&ref=master"

  name            = "separate-eks-mng"
  cluster_name    = "my-cluster"
  cluster_version = "1.31"

  subnet_ids = ["subnet-abcde012", "subnet-bcde012a", "subnet-fghi345a"]

  // The following variables are necessary if you decide to use the module outside of the parent EKS module context.
  // Without it, the security groups of the nodes are empty and thus won't join the cluster.
  cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
  vpc_security_group_ids            = [module.eks.node_security_group_id]

  // Note: `disk_size`, and `remote_access` can only be set when using the EKS managed node group default launch template
  // This module defaults to providing a custom launch template to allow for custom security groups, tag propagation, etc.
  // use_custom_launch_template = false
  // disk_size = 50
  //
  //  # Remote access cannot be specified with a launch template
  //  remote_access = {
  //    ec2_ssh_key               = module.key_pair.key_pair_name
  //    source_security_group_ids = [aws_security_group.remote_access.id]
  //  }

  min_size     = 1
  max_size     = 10
  desired_size = 1

  instance_types = ["t3.large"]
  capacity_type  = "SPOT"

  labels = {
    Environment = "test"
    GithubRepo  = "terraform-aws-eks"
    GithubOrg   = "terraform-aws-modules"
  }

  taints = {
    dedicated = {
      key    = "dedicated"
      value  = "gpuGroup"
      effect = "NO_SCHEDULE"
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
```

## Examples

## Basic Usage

Single EKS managed node group with AL2023 and on-demand instances.

```hcl
module "node_group" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/eks-managed-node-group?depth=1&ref=master"

  enabled      = true
  name         = "general"
  cluster_name = "my-cluster"

  subnet_ids    = ["subnet-0aaa111", "subnet-0bbb222", "subnet-0ccc333"]
  instance_types = ["m6i.large"]
  ami_type      = "AL2023_x86_64_STANDARD"

  min_size     = 2
  max_size     = 6
  desired_size = 2

  tags = {
    Environment = "production"
    NodeRole    = "general"
  }
}
```

## With Custom Launch Template and Labels/Taints

Node group with custom launch template settings, Kubernetes labels, and a taint for dedicated workloads.

```hcl
module "node_group" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/eks-managed-node-group?depth=1&ref=master"

  enabled      = true
  name         = "app-workers"
  cluster_name = "prod-cluster"

  subnet_ids     = ["subnet-0aaa111", "subnet-0bbb222"]
  instance_types = ["m6i.xlarge", "m6a.xlarge"]
  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"

  min_size     = 3
  max_size     = 15
  desired_size = 3

  labels = {
    role        = "app"
    environment = "production"
  }

  taints = {
    dedicated = {
      key    = "dedicated"
      value  = "app"
      effect = "NO_SCHEDULE"
    }
  }

  block_device_mappings = {
    xvda = {
      device_name = "/dev/xvda"
      ebs = {
        volume_size           = 100
        volume_type           = "gp3"
        iops                  = 3000
        throughput            = 125
        encrypted             = true
        delete_on_termination = true
      }
    }
  }

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tags = {
    Environment = "production"
    NodeRole    = "app"
  }
}
```

## Spot Node Group with Mixed Instance Types

Cost-optimised spot capacity for fault-tolerant batch workloads.

```hcl
module "node_group_spot" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/eks-managed-node-group?depth=1&ref=master"

  enabled      = true
  name         = "spot-workers"
  cluster_name = "prod-cluster"

  subnet_ids     = ["subnet-0aaa111", "subnet-0bbb222", "subnet-0ccc333"]
  instance_types = ["m6i.large", "m5.large", "m5a.large", "m4.large"]
  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "SPOT"

  min_size     = 0
  max_size     = 20
  desired_size = 2

  labels = {
    role          = "spot"
    "spot-worker" = "true"
  }

  taints = {
    spot = {
      key    = "spot"
      value  = "true"
      effect = "NO_SCHEDULE"
    }
  }

  update_config = {
    max_unavailable_percentage = 50
  }

  tags = {
    Environment = "production"
    NodeRole    = "spot"
  }
}
```

## Advanced - Node Auto Repair and Scaling Schedules

Production node group with auto repair, scaling schedules for business hours, and additional IAM policies.

```hcl
module "node_group" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/eks-managed-node-group?depth=1&ref=master"

  enabled      = true
  name         = "prod-general"
  cluster_name = "prod-cluster"

  subnet_ids     = ["subnet-0aaa111", "subnet-0bbb222", "subnet-0ccc333"]
  instance_types = ["m6i.xlarge"]
  ami_type       = "AL2023_x86_64_STANDARD"

  min_size     = 3
  max_size     = 30
  desired_size = 6

  node_repair_config = {
    enabled = true
    max_parallel_nodes_repaired_count = 2
  }

  iam_role_additional_policies = {
    ssm      = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    readonly = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  }

  schedules = {
    scale_up = {
      min_size     = 3
      max_size     = 30
      desired_size = 6
      recurrence   = "0 8 * * MON-FRI"
      time_zone    = "Asia/Dubai"
    }
    scale_down = {
      min_size     = 1
      max_size     = 6
      desired_size = 2
      recurrence   = "0 20 * * MON-FRI"
      time_zone    = "Asia/Dubai"
    }
  }

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    NodeRole    = "general"
  }
}
```

## Reference

<details>
<summary>Requirements, providers, inputs and outputs (generated by terraform-docs)</summary>

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11.0 |
| aws | >= 6.49, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.49, < 7.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| ami\_id | The AMI from which to launch the instance. If not supplied, EKS will use its own default image | `string` | `null` | no |
| ami\_release\_version | The AMI version. Defaults to latest AMI release version for the given Kubernetes version and AMI type | `string` | `null` | no |
| ami\_type | Type of Amazon Machine Image (AMI) associated with the EKS Node Group. See the [AWS documentation](https://docs.aws.amazon.com/eks/latest/APIReference/API_Nodegroup.html#AmazonEKS-Type-Nodegroup-amiType) for valid values | `string` | `null` | no |
| block\_device\_mappings | Specify volumes to attach to the instance besides the volumes specified by the AMI | <pre>map(object({<br/>    device_name = optional(string)<br/>    ebs = optional(object({<br/>      delete_on_termination      = optional(bool)<br/>      encrypted                  = optional(bool)<br/>      iops                       = optional(number)<br/>      kms_key_id                 = optional(string)<br/>      snapshot_id                = optional(string)<br/>      throughput                 = optional(number)<br/>      volume_initialization_rate = optional(number)<br/>      volume_size                = optional(number)<br/>      volume_type                = optional(string)<br/>    }))<br/>    no_device    = optional(string)<br/>    virtual_name = optional(string)<br/>  }))</pre> | `{}` | no |
| bootstrap\_extra\_args | Additional arguments passed to the bootstrap script. When `ami_type` = `BOTTLEROCKET_*`; these are additional [settings](https://github.com/bottlerocket-os/bottlerocket#settings) that are provided to the Bottlerocket user data | `string` | `null` | no |
| capacity\_reservation\_specification | Targeting for EC2 capacity reservations | <pre>object({<br/>    capacity_reservation_preference = optional(string)<br/>    capacity_reservation_target = optional(object({<br/>      capacity_reservation_id                 = optional(string)<br/>      capacity_reservation_resource_group_arn = optional(string)<br/>    }))<br/>  })</pre> | `null` | no |
| capacity\_type | Type of capacity associated with the EKS Node Group. Valid values: `ON_DEMAND`, `SPOT` | `string` | `"ON_DEMAND"` | no |
| cloudinit\_post\_nodeadm | Array of cloud-init document parts that are created after the nodeadm document part | <pre>list(object({<br/>    content      = string<br/>    content_type = optional(string)<br/>    filename     = optional(string)<br/>    merge_type   = optional(string)<br/>  }))</pre> | `[]` | no |
| cloudinit\_pre\_nodeadm | Array of cloud-init document parts that are created before the nodeadm document part | <pre>list(object({<br/>    content      = string<br/>    content_type = optional(string)<br/>    filename     = optional(string)<br/>    merge_type   = optional(string)<br/>  }))</pre> | `[]` | no |
| cluster\_auth\_base64 | Base64 encoded CA of associated EKS cluster | `string` | `null` | no |
| cluster\_endpoint | Endpoint of associated EKS cluster | `string` | `null` | no |
| cluster\_ip\_family | The IP family used to assign Kubernetes pod and service addresses. Valid values are `ipv4` (default) and `ipv6` | `string` | `"ipv4"` | no |
| cluster\_name | Name of associated EKS cluster | `string` | `null` | no |
| cluster\_primary\_security\_group\_id | The ID of the EKS cluster primary security group to associate with the instance(s). This is the security group that is automatically created by the EKS service | `string` | `null` | no |
| cluster\_service\_cidr | The CIDR block (IPv4 or IPv6) used by the cluster to assign Kubernetes service IP addresses. This is derived from the cluster itself | `string` | `null` | no |
| cluster\_version | Kubernetes version. Defaults to EKS Cluster Kubernetes version | `string` | `null` | no |
| cpu\_options | The CPU options for the instance | <pre>object({<br/>    amd_sev_snp           = optional(string)<br/>    core_count            = optional(number)<br/>    nested_virtualization = optional(bool)<br/>    threads_per_core      = optional(number)<br/>  })</pre> | `null` | no |
| create\_iam\_role | Determines whether an IAM role is created or to use an existing IAM role | `bool` | `true` | no |
| create\_iam\_role\_policy | Determines whether an IAM role policy is created or not | `bool` | `true` | no |
| create\_launch\_template | Determines whether to create a launch template or not. If set to `false`, EKS will use its own default launch template | `bool` | `true` | no |
| create\_placement\_group | Determines whether a placement group is created & used by the node group | `bool` | `false` | no |
| create\_schedule | Determines whether to create autoscaling group schedule or not | `bool` | `true` | no |
| credit\_specification | Customize the credit specification of the instance | <pre>object({<br/>    cpu_credits = optional(string)<br/>  })</pre> | `null` | no |
| desired\_size | Desired number of instances/nodes | `number` | `1` | no |
| disable\_api\_stop | If true, enables EC2 instance stop protection | `bool` | `null` | no |
| disable\_api\_termination | If true, enables EC2 instance termination protection | `bool` | `null` | no |
| disk\_size | Disk size in GiB for nodes. Defaults to `20`. Only valid when `use_custom_launch_template` = `false` | `number` | `null` | no |
| ebs\_optimized | If true, the launched EC2 instance(s) will be EBS-optimized | `bool` | `null` | no |
| efa\_indices | The indices of the network interfaces that should be EFA-enabled. Only valid when `enable_efa_support` = `true` | `list(number)` | <pre>[<br/>  0<br/>]</pre> | no |
| enable\_bootstrap\_user\_data | Determines whether the bootstrap configurations are populated within the user data template. Only valid when using a custom AMI via `ami_id` | `bool` | `false` | no |
| enable\_efa\_only | Determines whether to enable EFA only (`true`) or EFA + standard (`false`) network interfaces. Note: requires vpc-cni version `v1.18.4` or later | `bool` | `true` | no |
| enable\_efa\_support | Determines whether to enable Elastic Fabric Adapter (EFA) support | `bool` | `false` | no |
| enable\_monitoring | Enables/disables detailed monitoring | `bool` | `false` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| enclave\_options | Enable Nitro Enclaves on launched instances | <pre>object({<br/>    enabled = bool<br/>  })</pre> | `null` | no |
| force\_update\_version | Force version update if existing pods are unable to be drained due to a pod disruption budget issue | `bool` | `null` | no |
| iam\_role\_additional\_policies | Additional policies to be added to the IAM role | `map(string)` | `{}` | no |
| iam\_role\_arn | Existing IAM role ARN for the node group. Required if `create_iam_role` is set to `false` | `string` | `null` | no |
| iam\_role\_attach\_cni\_policy | Whether to attach the `AmazonEKS_CNI_Policy`/`AmazonEKS_CNI_IPv6_Policy` IAM policy to the IAM IAM role. WARNING: If set `false` the permissions must be assigned to the `aws-node` DaemonSet pods via another method or nodes will not be able to join the cluster | `bool` | `true` | no |
| iam\_role\_description | Description of the role | `string` | `null` | no |
| iam\_role\_name | Name to use on IAM role created | `string` | `null` | no |
| iam\_role\_path | IAM role path | `string` | `null` | no |
| iam\_role\_permissions\_boundary | ARN of the policy that is used to set the permissions boundary for the IAM role | `string` | `null` | no |
| iam\_role\_policy\_statements | A list of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) - used for adding specific IAM permissions as needed | <pre>list(object({<br/>    sid           = optional(string)<br/>    actions       = optional(list(string))<br/>    not_actions   = optional(list(string))<br/>    effect        = optional(string)<br/>    resources     = optional(list(string))<br/>    not_resources = optional(list(string))<br/>    principals = optional(list(object({<br/>      type        = string<br/>      identifiers = list(string)<br/>    })), [])<br/>    not_principals = optional(list(object({<br/>      type        = string<br/>      identifiers = list(string)<br/>    })), [])<br/>    conditions = optional(list(object({<br/>      test     = string<br/>      values   = list(string)<br/>      variable = string<br/>    })), [])<br/>  }))</pre> | `[]` | no |
| iam\_role\_tags | A map of additional tags to add to the IAM role created | `map(string)` | `{}` | no |
| iam\_role\_use\_name\_prefix | Determines whether the IAM role name (`iam_role_name`) is used as a prefix | `bool` | `true` | no |
| instance\_market\_options | The market (purchasing) option for the instance | <pre>object({<br/>    market_type = optional(string)<br/>    spot_options = optional(object({<br/>      block_duration_minutes         = optional(number)<br/>      instance_interruption_behavior = optional(string)<br/>      max_price                      = optional(string)<br/>      spot_instance_type             = optional(string)<br/>      valid_until                    = optional(string)<br/>    }))<br/>  })</pre> | `null` | no |
| instance\_types | Set of instance types associated with the EKS Node Group. Defaults to `["t3.medium"]` | `list(string)` | `null` | no |
| kernel\_id | The kernel ID | `string` | `null` | no |
| key\_name | The key name that should be used for the instance(s) | `string` | `null` | no |
| labels | Key-value map of Kubernetes labels. Only labels that are applied with the EKS API are managed by this argument. Other Kubernetes labels applied to the EKS Node Group will not be managed | `map(string)` | `null` | no |
| launch\_template\_default\_version | Default version of the launch template | `string` | `null` | no |
| launch\_template\_description | Description of the launch template | `string` | `null` | no |
| launch\_template\_id | The ID of an existing launch template to use. Required when `create_launch_template` = `false` and `use_custom_launch_template` = `true` | `string` | `null` | no |
| launch\_template\_name | Name of launch template to be created | `string` | `null` | no |
| launch\_template\_tags | A map of additional tags to add to the tag\_specifications of launch template created | `map(string)` | `{}` | no |
| launch\_template\_use\_name\_prefix | Determines whether to use `launch_template_name` as is or create a unique name beginning with the `launch_template_name` as the prefix | `bool` | `true` | no |
| launch\_template\_version | Launch template version number. The default is `$Default` | `string` | `null` | no |
| license\_specifications | A map of license specifications to associate with | <pre>map(object({<br/>    license_configuration_arn = string<br/>  }))</pre> | `{}` | no |
| maintenance\_options | The maintenance options for the instance | <pre>object({<br/>    auto_recovery = optional(string)<br/>  })</pre> | `null` | no |
| max\_size | Maximum number of instances/nodes | `number` | `3` | no |
| metadata\_options | Customize the metadata options for the instance | <pre>object({<br/>    http_endpoint               = optional(string, "enabled")<br/>    http_protocol_ipv6          = optional(string)<br/>    http_put_response_hop_limit = optional(number, 1)<br/>    http_tokens                 = optional(string, "required")<br/>    instance_metadata_tags      = optional(string)<br/>  })</pre> | `{}` | no |
| min\_size | Minimum number of instances/nodes | `number` | `0` | no |
| name | Name of the EKS managed node group | `string` | `null` | no |
| network\_interfaces | Customize network interfaces to be attached at instance boot time | <pre>list(object({<br/>    associate_carrier_ip_address = optional(bool)<br/>    associate_public_ip_address  = optional(bool)<br/>    connection_tracking_specification = optional(object({<br/>      tcp_established_timeout = optional(number)<br/>      udp_stream_timeout      = optional(number)<br/>      udp_timeout             = optional(number)<br/>    }))<br/>    delete_on_termination = optional(bool)<br/>    description           = optional(string)<br/>    device_index          = optional(number)<br/>    ena_srd_specification = optional(object({<br/>      ena_srd_enabled = optional(bool)<br/>      ena_srd_udp_specification = optional(object({<br/>        ena_srd_udp_enabled = optional(bool)<br/>      }))<br/>    }))<br/>    interface_type       = optional(string)<br/>    ipv4_address_count   = optional(number)<br/>    ipv4_addresses       = optional(list(string), [])<br/>    ipv4_prefix_count    = optional(number)<br/>    ipv4_prefixes        = optional(list(string))<br/>    ipv6_address_count   = optional(number)<br/>    ipv6_addresses       = optional(list(string), [])<br/>    ipv6_prefix_count    = optional(number)<br/>    ipv6_prefixes        = optional(list(string), [])<br/>    network_card_index   = optional(number)<br/>    network_interface_id = optional(string)<br/>    primary_ipv6         = optional(bool)<br/>    private_ip_address   = optional(string)<br/>    security_groups      = optional(list(string), [])<br/>  }))</pre> | `[]` | no |
| network\_performance\_options | The network performance options for the instance. Valid keys are `bandwidth_weighting` (valid values: `default`, `vpc-1`, `ebs-1`) | `map(string)` | `{}` | no |
| node\_repair\_config | The node auto repair configuration for the node group | <pre>object({<br/>    enabled                                 = optional(bool, true)<br/>    max_parallel_nodes_repaired_count       = optional(number)<br/>    max_parallel_nodes_repaired_percentage  = optional(number)<br/>    max_unhealthy_node_threshold_count      = optional(number)<br/>    max_unhealthy_node_threshold_percentage = optional(number)<br/>    node_repair_config_overrides = optional(list(object({<br/>      min_repair_wait_time_mins = number<br/>      node_monitoring_condition = string<br/>      node_unhealthy_reason     = string<br/>      repair_action             = string<br/>    })), [])<br/>  })</pre> | `null` | no |
| placement | The placement of the instance | <pre>object({<br/>    affinity                = optional(string)<br/>    availability_zone       = optional(string)<br/>    group_id                = optional(string)<br/>    group_name              = optional(string)<br/>    host_id                 = optional(string)<br/>    host_resource_group_arn = optional(string)<br/>    partition_number        = optional(number)<br/>    spread_domain           = optional(string)<br/>    tenancy                 = optional(string)<br/>  })</pre> | `null` | no |
| placement\_group\_az | Availability zone where placement group is created (ex. `eu-west-1c`) | `string` | `null` | no |
| post\_bootstrap\_user\_data | User data that is appended to the user data script after of the EKS bootstrap script. Not used when `ami_type` = `BOTTLEROCKET_*` | `string` | `null` | no |
| pre\_bootstrap\_user\_data | User data that is injected into the user data script ahead of the EKS bootstrap script. Not used when `ami_type` = `BOTTLEROCKET_*` | `string` | `null` | no |
| private\_dns\_name\_options | The options for the instance hostname. The default values are inherited from the subnet | <pre>object({<br/>    enable_resource_name_dns_aaaa_record = optional(bool)<br/>    enable_resource_name_dns_a_record    = optional(bool)<br/>    hostname_type                        = optional(string)<br/>  })</pre> | `null` | no |
| ram\_disk\_id | The ID of the ram disk | `string` | `null` | no |
| remote\_access | Configuration block with remote access settings. Only valid when `use_custom_launch_template` = `false` | <pre>object({<br/>    ec2_ssh_key               = optional(string)<br/>    source_security_group_ids = optional(list(string), [])<br/>  })</pre> | `null` | no |
| schedules | Map of autoscaling group schedule to create | <pre>map(object({<br/>    min_size     = optional(number)<br/>    max_size     = optional(number)<br/>    desired_size = optional(number)<br/>    start_time   = optional(string)<br/>    end_time     = optional(string)<br/>    time_zone    = optional(string)<br/>    recurrence   = optional(string)<br/>  }))</pre> | `{}` | no |
| secondary\_interfaces | Configuration for secondary network interfaces on the launch template | <pre>list(object({<br/>    delete_on_termination    = optional(bool)<br/>    device_index             = optional(number)<br/>    interface_type           = optional(string)<br/>    network_card_index       = optional(number)<br/>    private_ip_address_count = optional(number)<br/>    private_ip_addresses     = optional(list(string))<br/>    secondary_subnet_id      = optional(string)<br/>  }))</pre> | `[]` | no |
| security\_group\_names | A list of security group names to associate with. (EC2-Classic only) | `list(string)` | `null` | no |
| subnet\_ids | Identifiers of EC2 Subnets to associate with the EKS Node Group. These subnets must have the following resource tag: `kubernetes.io/cluster/CLUSTER_NAME` | `list(string)` | `null` | no |
| tag\_specifications | The tags to apply to the resources during launch | `list(string)` | <pre>[<br/>  "instance",<br/>  "volume",<br/>  "network-interface"<br/>]</pre> | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| taints | The Kubernetes taints to be applied to the nodes in the node group. Maximum of 50 taints per node group | <pre>map(object({<br/>    key    = string<br/>    value  = optional(string)<br/>    effect = string<br/>  }))</pre> | `{}` | no |
| timeouts | Create, update, and delete timeout configurations for the node group | `map(string)` | `{}` | no |
| update\_config | Configuration block of settings for max unavailable resources during node group updates. Supports max\_unavailable, max\_unavailable\_percentage, and update\_strategy (MINIMAL or DEFAULT) | <pre>object({<br/>    max_unavailable            = optional(number)<br/>    max_unavailable_percentage = optional(number)<br/>    update_strategy            = optional(string)<br/>  })</pre> | <pre>{<br/>  "max_unavailable_percentage": 33<br/>}</pre> | no |
| update\_launch\_template\_default\_version | Whether to update the launch templates default version on each update. Conflicts with `launch_template_default_version` | `bool` | `true` | no |
| use\_custom\_launch\_template | Determines whether to use a custom launch template or not. If set to `false`, EKS will use its own default launch template | `bool` | `true` | no |
| use\_latest\_ami\_release\_version | Determines whether to use the latest AMI release version for the given `ami_type` (except for `CUSTOM`). Note: `ami_type` and `cluster_version` must be supplied in order to enable this feature | `bool` | `false` | no |
| use\_name\_prefix | Determines whether to use `name` as is or create a unique name beginning with the `name` as the prefix | `bool` | `true` | no |
| user\_data\_template\_path | Path to a local, custom user data template file to use when rendering user data | `string` | `null` | no |
| vpc\_security\_group\_ids | A list of security group IDs to associate | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| autoscaling\_group\_schedule\_arns | ARNs of autoscaling group schedules |
| iam\_role\_arn | The Amazon Resource Name (ARN) specifying the IAM role |
| iam\_role\_name | The name of the IAM role |
| iam\_role\_unique\_id | Stable and unique string identifying the IAM role |
| launch\_template\_arn | The ARN of the launch template |
| launch\_template\_id | The ID of the launch template |
| launch\_template\_latest\_version | The latest version of the launch template |
| launch\_template\_name | The name of the launch template |
| node\_group\_arn | Amazon Resource Name (ARN) of the EKS Node Group |
| node\_group\_autoscaling\_group\_names | List of the autoscaling group names |
| node\_group\_id | EKS Cluster name and EKS Node Group name separated by a colon (`:`) |
| node\_group\_labels | Map of labels applied to the node group |
| node\_group\_resources | List of objects containing information about underlying resources |
| node\_group\_status | Status of the EKS Node Group |
| node\_group\_taints | List of objects containing information about taints applied to the node group |
| platform | [DEPRECATED - Will be removed in `v21.0`] Identifies the OS platform as `bottlerocket`, `linux` (AL2), `al2023`, or `windows` |
<!-- END_TF_DOCS -->

</details>
