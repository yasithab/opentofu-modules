# Self Managed Node Group Module

Configuration in this directory creates a Self Managed Node Group (AutoScaling Group) along with an IAM role, security group, and launch template

## Usage

```hcl
module "self_managed_node_group" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/self-managed-node-group?depth=1&ref=master"

  name                = "separate-self-mng"
  cluster_name        = "my-cluster"
  cluster_version     = "1.31"
  cluster_endpoint    = "https://012345678903AB2BAE5D1E0BFE0E2B50.gr7.us-east-1.eks.amazonaws.com"
  cluster_auth_base64 = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM1ekNDQWMrZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKbXFqQ1VqNGdGR2w3ZW5PeWthWnZ2RjROOTVOUEZCM2o0cGhVZUsrWGFtN2ZSQnZya0d6OGxKZmZEZWF2b2plTwpQK2xOZFlqdHZncmxCUEpYdHZIZmFzTzYxVzdIZmdWQ2EvamdRM2w3RmkvL1dpQmxFOG9oWUZkdWpjc0s1SXM2CnNkbk5KTTNYUWN2TysrSitkV09NT2ZlNzlsSWdncmdQLzgvRU9CYkw3eUY1aU1hS3lsb1RHL1V3TlhPUWt3ZUcKblBNcjdiUmdkQ1NCZTlXYXowOGdGRmlxV2FOditsTDhsODBTdFZLcWVNVlUxbjQyejVwOVpQRTd4T2l6L0xTNQpYV2lXWkVkT3pMN0xBWGVCS2gzdkhnczFxMkI2d1BKZnZnS1NzWllQRGFpZTloT1NNOUJkNFNPY3JrZTRYSVBOCkVvcXVhMlYrUDRlTWJEQzhMUkVWRDdCdVZDdWdMTldWOTBoL3VJUy9WU2VOcEdUOGVScE5DakszSjc2aFlsWm8KWjNGRG5QWUY0MWpWTHhiOXF0U1ROdEp6amYwWXBEYnFWci9xZzNmQWlxbVorMzd3YWM1eHlqMDZ4cmlaRUgzZgpUM002d2lCUEVHYVlGeWN5TmNYTk5aYW9DWDJVL0N1d2JsUHAKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQ=="

  subnet_ids = ["subnet-abcde012", "subnet-bcde012a", "subnet-fghi345a"]

  // The following variables are necessary if you decide to use the module outside of the parent EKS module context.
  // Without it, the security groups of the nodes are empty and thus won't join the cluster.
  vpc_security_group_ids = [
    module.eks.cluster_primary_security_group_id,
    module.eks.cluster_security_group_id,
  ]

  min_size     = 1
  max_size     = 10
  desired_size = 1

  launch_template_name   = "separate-self-mng"
  instance_type          = "m5.large"

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
```


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
| access\_entry\_kubernetes\_groups | List of Kubernetes groups the access entry principal belongs to | `list(string)` | `null` | no |
| access\_entry\_user\_name | The Kubernetes username for the access entry principal | `string` | `null` | no |
| additional\_cluster\_dns\_ips | Additional DNS IP addresses to use for the cluster. Only used when `ami_type` = `BOTTLEROCKET_*` | `list(string)` | `[]` | no |
| ami\_id | The AMI from which to launch the instance | `string` | `null` | no |
| ami\_type | Type of Amazon Machine Image (AMI) associated with the node group. See the [AWS documentation](https://docs.aws.amazon.com/eks/latest/APIReference/API_Nodegroup.html#AmazonEKS-Type-Nodegroup-amiType) for valid values | `string` | `"AL2023_x86_64_STANDARD"` | no |
| asg\_capacity\_reservation\_specification | The capacity reservation specification for the Auto Scaling group | <pre>object({<br/>    capacity_reservation_preference = optional(string)<br/>    capacity_reservation_target = optional(object({<br/>      capacity_reservation_ids                 = optional(list(string))<br/>      capacity_reservation_resource_group_arns = optional(list(string))<br/>    }))<br/>  })</pre> | `null` | no |
| autoscaling\_group\_tags | A map of additional tags to add to the autoscaling group created. Tags are applied to the autoscaling group only and are NOT propagated to instances | `map(string)` | `{}` | no |
| availability\_zone\_distribution | The availability zone distribution settings for the Auto Scaling group | <pre>object({<br/>    capacity_distribution_strategy = optional(string)<br/>  })</pre> | `null` | no |
| availability\_zones | A list of one or more availability zones for the group. Used for EC2-Classic and default subnets when not specified with `subnet_ids` argument. Conflicts with `subnet_ids` | `list(string)` | `null` | no |
| block\_device\_mappings | Specify volumes to attach to the instance besides the volumes specified by the AMI | <pre>map(object({<br/>    device_name = optional(string)<br/>    ebs = optional(object({<br/>      delete_on_termination      = optional(bool)<br/>      encrypted                  = optional(bool)<br/>      iops                       = optional(number)<br/>      kms_key_id                 = optional(string)<br/>      snapshot_id                = optional(string)<br/>      throughput                 = optional(number)<br/>      volume_initialization_rate = optional(number)<br/>      volume_size                = optional(number)<br/>      volume_type                = optional(string)<br/>    }))<br/>    no_device    = optional(string)<br/>    virtual_name = optional(string)<br/>  }))</pre> | `{}` | no |
| bootstrap\_extra\_args | Additional arguments passed to the bootstrap script. When `ami_type` = `BOTTLEROCKET_*`; these are additional [settings](https://github.com/bottlerocket-os/bottlerocket#settings) that are provided to the Bottlerocket user data | `string` | `null` | no |
| capacity\_rebalance | Indicates whether capacity rebalance is enabled | `bool` | `null` | no |
| capacity\_reservation\_specification | Targeting for EC2 capacity reservations | <pre>object({<br/>    capacity_reservation_preference = optional(string)<br/>    capacity_reservation_target = optional(object({<br/>      capacity_reservation_id                 = optional(string)<br/>      capacity_reservation_resource_group_arn = optional(string)<br/>    }))<br/>  })</pre> | `null` | no |
| cloudinit\_post\_nodeadm | Array of cloud-init document parts that are created after the nodeadm document part | <pre>list(object({<br/>    content      = string<br/>    content_type = optional(string)<br/>    filename     = optional(string)<br/>    merge_type   = optional(string)<br/>  }))</pre> | `[]` | no |
| cloudinit\_pre\_nodeadm | Array of cloud-init document parts that are created before the nodeadm document part | <pre>list(object({<br/>    content      = string<br/>    content_type = optional(string)<br/>    filename     = optional(string)<br/>    merge_type   = optional(string)<br/>  }))</pre> | `[]` | no |
| cluster\_auth\_base64 | Base64 encoded CA of associated EKS cluster | `string` | `null` | no |
| cluster\_endpoint | Endpoint of associated EKS cluster | `string` | `null` | no |
| cluster\_ip\_family | The IP family used to assign Kubernetes pod and service addresses. Valid values are `ipv4` (default) and `ipv6` | `string` | `"ipv4"` | no |
| cluster\_name | Name of associated EKS cluster | `string` | `null` | no |
| cluster\_primary\_security\_group\_id | The ID of the EKS cluster primary security group to associate with the instance(s). This is the security group that is automatically created by the EKS service | `string` | `null` | no |
| cluster\_service\_cidr | The CIDR block (IPv4 or IPv6) used by the cluster to assign Kubernetes service IP addresses. This is derived from the cluster itself | `string` | `null` | no |
| cluster\_version | Kubernetes cluster version - used to lookup default AMI ID if one is not provided | `string` | `null` | no |
| context | Reserved | `string` | `null` | no |
| cpu\_options | The CPU options for the instance | <pre>object({<br/>    amd_sev_snp           = optional(string)<br/>    core_count            = optional(number)<br/>    nested_virtualization = optional(bool)<br/>    threads_per_core      = optional(number)<br/>  })</pre> | `null` | no |
| create\_access\_entry | Determines whether an access entry is created for the IAM role used by the node group | `bool` | `true` | no |
| create\_autoscaling\_group | Determines whether to create autoscaling group or not | `bool` | `true` | no |
| create\_iam\_instance\_profile | Determines whether an IAM instance profile is created or to use an existing IAM instance profile | `bool` | `true` | no |
| create\_iam\_role\_policy | Determines whether an IAM role policy is created or not | `bool` | `true` | no |
| create\_launch\_template | Determines whether to create launch template or not | `bool` | `true` | no |
| create\_placement\_group | Determines whether a placement group is created & used by the node group | `bool` | `false` | no |
| create\_schedule | Determines whether to create autoscaling group schedule or not | `bool` | `true` | no |
| credit\_specification | Customize the credit specification of the instance | <pre>object({<br/>    cpu_credits = optional(string)<br/>  })</pre> | `null` | no |
| default\_cooldown | The amount of time, in seconds, after a scaling activity completes before another scaling activity can start | `number` | `null` | no |
| default\_instance\_warmup | Amount of time, in seconds, until a newly launched instance can contribute to the Amazon CloudWatch metrics. This delay lets an instance finish initializing before Amazon EC2 Auto Scaling aggregates instance metrics, resulting in more reliable usage data | `number` | `null` | no |
| delete\_timeout | Delete timeout to wait for destroying autoscaling group | `string` | `null` | no |
| desired\_size | The number of Amazon EC2 instances that should be running in the autoscaling group | `number` | `1` | no |
| desired\_size\_type | The unit of measurement for the value specified for `desired_size`. Supported for attribute-based instance type selection only. Valid values: `units`, `vcpu`, `memory-mib` | `string` | `null` | no |
| disable\_api\_stop | If true, enables EC2 instance stop protection | `bool` | `null` | no |
| disable\_api\_termination | If true, enables EC2 instance termination protection | `bool` | `null` | no |
| ebs\_optimized | If true, the launched EC2 instance will be EBS-optimized | `bool` | `null` | no |
| efa\_indices | The indices of the network interfaces that should be EFA-enabled. Only valid when `enable_efa_support` = `true` | `list(number)` | <pre>[<br/>  0<br/>]</pre> | no |
| enable\_efa\_only | Determines whether to enable EFA only (`true`) or both EFA and EFA-only (`false`) network interfaces. Note: requires vpc-cni version `v1.18.4` or later | `bool` | `true` | no |
| enable\_efa\_support | Determines whether to enable Elastic Fabric Adapter (EFA) support | `bool` | `false` | no |
| enable\_monitoring | Enables/disables detailed monitoring | `bool` | `true` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| enabled\_metrics | A list of metrics to collect. The allowed values are `GroupDesiredCapacity`, `GroupInServiceCapacity`, `GroupPendingCapacity`, `GroupMinSize`, `GroupMaxSize`, `GroupInServiceInstances`, `GroupPendingInstances`, `GroupStandbyInstances`, `GroupStandbyCapacity`, `GroupTerminatingCapacity`, `GroupTerminatingInstances`, `GroupTotalCapacity`, `GroupTotalInstances` | `list(string)` | `[]` | no |
| enclave\_options | Enable Nitro Enclaves on launched instances | <pre>object({<br/>    enabled = bool<br/>  })</pre> | `null` | no |
| force\_delete | Allows deleting the Auto Scaling Group without waiting for all instances in the pool to terminate. You can force an Auto Scaling Group to delete even if it's in the process of scaling a resource. Normally, Terraform drains all the instances before deleting the group. This bypasses that behavior and potentially leaves resources dangling | `bool` | `null` | no |
| force\_delete\_warm\_pool | Allows deleting the Auto Scaling Group without waiting for all instances in the warm pool to terminate | `bool` | `null` | no |
| health\_check\_grace\_period | Time (in seconds) after instance comes into service before checking health | `number` | `null` | no |
| health\_check\_type | `EC2` or `ELB`. Controls how health checking is done | `string` | `null` | no |
| hibernation\_options | The hibernation options for the instance | <pre>object({<br/>    configured = bool<br/>  })</pre> | `null` | no |
| iam\_instance\_profile\_arn | Amazon Resource Name (ARN) of an existing IAM instance profile that provides permissions for the node group. Required if `create_iam_instance_profile` = `false` | `string` | `null` | no |
| iam\_role\_additional\_policies | Additional policies to be added to the IAM role | `map(string)` | `{}` | no |
| iam\_role\_arn | ARN of the IAM role used by the instance profile. Required when `create_access_entry = true` and `create_iam_instance_profile = false` | `string` | `null` | no |
| iam\_role\_attach\_cni\_policy | Whether to attach the `AmazonEKS_CNI_Policy`/`AmazonEKS_CNI_IPv6_Policy` IAM policy to the IAM IAM role. WARNING: If set `false` the permissions must be assigned to the `aws-node` DaemonSet pods via another method or nodes will not be able to join the cluster | `bool` | `true` | no |
| iam\_role\_description | Description of the role | `string` | `null` | no |
| iam\_role\_name | Name to use on IAM role created | `string` | `null` | no |
| iam\_role\_path | IAM role path | `string` | `null` | no |
| iam\_role\_permissions\_boundary | ARN of the policy that is used to set the permissions boundary for the IAM role | `string` | `null` | no |
| iam\_role\_policy\_statements | A list of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) - used for adding specific IAM permissions as needed | <pre>list(object({<br/>    sid           = optional(string)<br/>    actions       = optional(list(string))<br/>    not_actions   = optional(list(string))<br/>    effect        = optional(string)<br/>    resources     = optional(list(string))<br/>    not_resources = optional(list(string))<br/>    principals = optional(list(object({<br/>      type        = string<br/>      identifiers = list(string)<br/>    })), [])<br/>    not_principals = optional(list(object({<br/>      type        = string<br/>      identifiers = list(string)<br/>    })), [])<br/>    conditions = optional(list(object({<br/>      test     = string<br/>      values   = list(string)<br/>      variable = string<br/>    })), [])<br/>  }))</pre> | `[]` | no |
| iam\_role\_tags | A map of additional tags to add to the IAM role created | `map(string)` | `{}` | no |
| iam\_role\_use\_name\_prefix | Determines whether cluster IAM role name (`iam_role_name`) is used as a prefix | `bool` | `true` | no |
| ignore\_failed\_scaling\_activities | Whether to ignore failed Auto Scaling scaling activities while waiting for capacity. | `bool` | `null` | no |
| initial\_lifecycle\_hooks | One or more Lifecycle Hooks to attach to the Auto Scaling Group before instances are launched. The syntax is exactly the same as the separate `aws_autoscaling_lifecycle_hook` resource, without the `autoscaling_group_name` attribute. Please note that this will only work when creating a new Auto Scaling Group. For all other use-cases, please use `aws_autoscaling_lifecycle_hook` resource | `list(map(string))` | `[]` | no |
| instance\_initiated\_shutdown\_behavior | Shutdown behavior for the instance. Can be `stop` or `terminate`. (Default: `stop`) | `string` | `null` | no |
| instance\_maintenance\_policy | If this block is configured, add a instance maintenance policy to the specified Auto Scaling group | <pre>object({<br/>    min_healthy_percentage = number<br/>    max_healthy_percentage = number<br/>  })</pre> | `null` | no |
| instance\_market\_options | The market (purchasing) option for the instance | <pre>object({<br/>    market_type = optional(string)<br/>    spot_options = optional(object({<br/>      block_duration_minutes         = optional(number)<br/>      instance_interruption_behavior = optional(string)<br/>      max_price                      = optional(string)<br/>      spot_instance_type             = optional(string)<br/>      valid_until                    = optional(string)<br/>    }))<br/>  })</pre> | `null` | no |
| instance\_refresh | If this block is configured, start an Instance Refresh when this Auto Scaling Group is updated | <pre>object({<br/>    strategy = string<br/>    preferences = optional(object({<br/>      alarm_specification = optional(object({<br/>        alarms = optional(list(string))<br/>      }))<br/>      auto_rollback                = optional(bool)<br/>      checkpoint_delay             = optional(number)<br/>      checkpoint_percentages       = optional(list(number))<br/>      instance_warmup              = optional(number)<br/>      max_healthy_percentage       = optional(number)<br/>      min_healthy_percentage       = optional(number)<br/>      scale_in_protected_instances = optional(string)<br/>      skip_matching                = optional(bool)<br/>      standby_instances            = optional(string)<br/>    }))<br/>    triggers = optional(list(string))<br/>  })</pre> | <pre>{<br/>  "preferences": {<br/>    "min_healthy_percentage": 66<br/>  },<br/>  "strategy": "Rolling"<br/>}</pre> | no |
| instance\_requirements | The attribute requirements for the type of instance. If present then `instance_type` cannot be present | <pre>object({<br/>    accelerator_count = optional(object({<br/>      max = optional(number)<br/>      min = optional(number)<br/>    }))<br/>    accelerator_manufacturers = optional(list(string), [])<br/>    accelerator_names         = optional(list(string), [])<br/>    accelerator_total_memory_mib = optional(object({<br/>      max = optional(number)<br/>      min = optional(number)<br/>    }))<br/>    accelerator_types      = optional(list(string), [])<br/>    allowed_instance_types = optional(list(string))<br/>    bare_metal             = optional(string)<br/>    baseline_ebs_bandwidth_mbps = optional(object({<br/>      max = optional(number)<br/>      min = optional(number)<br/>    }))<br/>    burstable_performance                                   = optional(string)<br/>    cpu_manufacturers                                       = optional(list(string), [])<br/>    excluded_instance_types                                 = optional(list(string))<br/>    instance_generations                                    = optional(list(string), [])<br/>    local_storage                                           = optional(string)<br/>    local_storage_types                                     = optional(list(string), [])<br/>    max_spot_price_as_percentage_of_optimal_on_demand_price = optional(number)<br/>    memory_gib_per_vcpu = optional(object({<br/>      max = optional(number)<br/>      min = optional(number)<br/>    }))<br/>    memory_mib = object({<br/>      max = optional(number)<br/>      min = number<br/>    })<br/>    network_bandwidth_gbps = optional(object({<br/>      max = optional(number)<br/>      min = optional(number)<br/>    }))<br/>    network_interface_count = optional(object({<br/>      max = optional(number)<br/>      min = optional(number)<br/>    }))<br/>    on_demand_max_price_percentage_over_lowest_price = optional(number)<br/>    require_hibernate_support                        = optional(bool)<br/>    spot_max_price_percentage_over_lowest_price      = optional(number)<br/>    total_local_storage_gb = optional(object({<br/>      max = optional(number)<br/>      min = optional(number)<br/>    }))<br/>    vcpu_count = object({<br/>      max = optional(number)<br/>      min = number<br/>    })<br/>  })</pre> | `null` | no |
| instance\_type | The type of the instance to launch | `string` | `null` | no |
| kernel\_id | The kernel ID | `string` | `null` | no |
| key\_name | The key name that should be used for the instance | `string` | `null` | no |
| launch\_template\_default\_version | Default Version of the launch template | `string` | `null` | no |
| launch\_template\_description | Description of the launch template | `string` | `null` | no |
| launch\_template\_id | The ID of an existing launch template to use. Required when `create_launch_template` = `false` | `string` | `null` | no |
| launch\_template\_name | Name of launch template to be created | `string` | `null` | no |
| launch\_template\_tags | A map of additional tags to add to the tag\_specifications of launch template created | `map(string)` | `{}` | no |
| launch\_template\_use\_name\_prefix | Determines whether to use `launch_template_name` as is or create a unique name beginning with the `launch_template_name` as the prefix | `bool` | `true` | no |
| launch\_template\_version | Launch template version. Can be version number, `$Latest`, or `$Default` | `string` | `null` | no |
| license\_specifications | A map of license specifications to associate with | <pre>map(object({<br/>    license_configuration_arn = string<br/>  }))</pre> | `{}` | no |
| load\_balancers | A list of elastic load balancer names to add to the autoscaling group names. Only valid for classic load balancers | `list(string)` | `[]` | no |
| maintenance\_options | The maintenance options for the instance | <pre>object({<br/>    auto_recovery = optional(string)<br/>  })</pre> | `null` | no |
| max\_instance\_lifetime | The maximum amount of time, in seconds, that an instance can be in service, values must be either equal to 0 or between 604800 and 31536000 seconds | `number` | `null` | no |
| max\_size | The maximum size of the autoscaling group | `number` | `3` | no |
| metadata\_options | Customize the metadata options for the instance | <pre>object({<br/>    http_endpoint               = optional(string, "enabled")<br/>    http_protocol_ipv6          = optional(string)<br/>    http_put_response_hop_limit = optional(number, 2)<br/>    http_tokens                 = optional(string, "required")<br/>    instance_metadata_tags      = optional(string)<br/>  })</pre> | `{}` | no |
| metrics\_granularity | The granularity to associate with the metrics to collect. The only valid value is `1Minute` | `string` | `null` | no |
| min\_elb\_capacity | Setting this causes Terraform to wait for this number of instances to show up healthy in the ELB only on creation. Updates will not wait on ELB instance number changes | `number` | `null` | no |
| min\_size | The minimum size of the autoscaling group | `number` | `0` | no |
| mixed\_instances\_policy | Configuration block containing settings to define launch targets for Auto Scaling groups | <pre>object({<br/>    instances_distribution = optional(object({<br/>      on_demand_allocation_strategy            = optional(string)<br/>      on_demand_base_capacity                  = optional(number)<br/>      on_demand_percentage_above_base_capacity = optional(number)<br/>      spot_allocation_strategy                 = optional(string)<br/>      spot_instance_pools                      = optional(number)<br/>      spot_max_price                           = optional(string)<br/>    }))<br/>    override = optional(list(object({<br/>      instance_requirements = optional(object({<br/>        accelerator_count = optional(object({<br/>          max = optional(number)<br/>          min = optional(number)<br/>        }))<br/>        accelerator_manufacturers = optional(list(string), [])<br/>        accelerator_names         = optional(list(string), [])<br/>        accelerator_total_memory_mib = optional(object({<br/>          max = optional(number)<br/>          min = optional(number)<br/>        }))<br/>        accelerator_types      = optional(list(string), [])<br/>        allowed_instance_types = optional(list(string))<br/>        bare_metal             = optional(string)<br/>        baseline_ebs_bandwidth_mbps = optional(object({<br/>          max = optional(number)<br/>          min = optional(number)<br/>        }))<br/>        burstable_performance                                   = optional(string)<br/>        cpu_manufacturers                                       = optional(list(string), [])<br/>        excluded_instance_types                                 = optional(list(string), [])<br/>        instance_generations                                    = optional(list(string), [])<br/>        local_storage                                           = optional(string)<br/>        local_storage_types                                     = optional(list(string), [])<br/>        max_spot_price_as_percentage_of_optimal_on_demand_price = optional(number)<br/>        memory_gib_per_vcpu = optional(object({<br/>          max = optional(number)<br/>          min = optional(number)<br/>        }))<br/>        memory_mib = object({<br/>          max = optional(number)<br/>          min = number<br/>        })<br/>        network_bandwidth_gbps = optional(object({<br/>          max = optional(number)<br/>          min = optional(number)<br/>        }))<br/>        network_interface_count = optional(object({<br/>          max = optional(number)<br/>          min = optional(number)<br/>        }))<br/>        on_demand_max_price_percentage_over_lowest_price = optional(number)<br/>        require_hibernate_support                        = optional(bool)<br/>        spot_max_price_percentage_over_lowest_price      = optional(number)<br/>        total_local_storage_gb = optional(object({<br/>          max = optional(number)<br/>          min = optional(number)<br/>        }))<br/>        vcpu_count = object({<br/>          max = optional(number)<br/>          min = number<br/>        })<br/>      }))<br/>      instance_type = optional(string)<br/>      launch_template_specification = optional(object({<br/>        launch_template_id = optional(string)<br/>        version            = optional(string)<br/>      }))<br/>      weighted_capacity = optional(string)<br/>    })), [])<br/>  })</pre> | `null` | no |
| name | Name of the Self managed Node Group | `string` | `null` | no |
| network\_interfaces | Customize network interfaces to be attached at instance boot time | <pre>list(object({<br/>    associate_carrier_ip_address = optional(bool)<br/>    associate_public_ip_address  = optional(bool)<br/>    connection_tracking_specification = optional(object({<br/>      tcp_established_timeout = optional(number)<br/>      udp_stream_timeout      = optional(number)<br/>      udp_timeout             = optional(number)<br/>    }))<br/>    delete_on_termination = optional(bool)<br/>    description           = optional(string)<br/>    device_index          = optional(number)<br/>    ena_srd_specification = optional(object({<br/>      ena_srd_enabled = optional(bool)<br/>      ena_srd_udp_specification = optional(object({<br/>        ena_srd_udp_enabled = optional(bool)<br/>      }))<br/>    }))<br/>    interface_type       = optional(string)<br/>    ipv4_address_count   = optional(number)<br/>    ipv4_addresses       = optional(list(string), [])<br/>    ipv4_prefix_count    = optional(number)<br/>    ipv4_prefixes        = optional(list(string))<br/>    ipv6_address_count   = optional(number)<br/>    ipv6_addresses       = optional(list(string), [])<br/>    ipv6_prefix_count    = optional(number)<br/>    ipv6_prefixes        = optional(list(string), [])<br/>    network_card_index   = optional(number)<br/>    network_interface_id = optional(string)<br/>    primary_ipv6         = optional(bool)<br/>    private_ip_address   = optional(string)<br/>    security_groups      = optional(list(string), [])<br/>    subnet_id            = optional(string)<br/>  }))</pre> | `[]` | no |
| network\_performance\_options | The network performance options for the instance. Valid keys are `bandwidth_weighting` (valid values: `default`, `vpc-1`, `ebs-1`) | `map(string)` | `{}` | no |
| placement | The placement of the instance | <pre>object({<br/>    affinity                = optional(string)<br/>    availability_zone       = optional(string)<br/>    group_id                = optional(string)<br/>    group_name              = optional(string)<br/>    host_id                 = optional(string)<br/>    host_resource_group_arn = optional(string)<br/>    partition_number        = optional(number)<br/>    spread_domain           = optional(string)<br/>    tenancy                 = optional(string)<br/>  })</pre> | `null` | no |
| placement\_group | The name of the placement group into which you'll launch your instances, if any | `string` | `null` | no |
| placement\_group\_az | Availability zone where placement group is created (ex. `eu-west-1c`) | `string` | `null` | no |
| placement\_group\_partition\_count | The number of partitions to create in the placement group. Only valid when `placement_group_strategy` is `partition`. Must be between 1 and 7 | `number` | `null` | no |
| placement\_group\_spread\_level | Determines how placement groups spread instances. Can only be used when `placement_group_strategy` is `spread`. Can be `host` or `rack` | `string` | `null` | no |
| placement\_group\_strategy | The placement group strategy. Can be `cluster`, `partition`, or `spread` | `string` | `"cluster"` | no |
| post\_bootstrap\_user\_data | User data that is appended to the user data script after of the EKS bootstrap script. Not used when `ami_type` = `BOTTLEROCKET_*` | `string` | `null` | no |
| pre\_bootstrap\_user\_data | User data that is injected into the user data script ahead of the EKS bootstrap script. Not used when `ami_type` = `BOTTLEROCKET_*` | `string` | `null` | no |
| private\_dns\_name\_options | The options for the instance hostname. The default values are inherited from the subnet | <pre>object({<br/>    enable_resource_name_dns_aaaa_record = optional(bool)<br/>    enable_resource_name_dns_a_record    = optional(bool)<br/>    hostname_type                        = optional(string)<br/>  })</pre> | `null` | no |
| protect\_from\_scale\_in | Allows setting instance protection. The autoscaling group will not select instances with this setting for termination during scale in events. | `bool` | `false` | no |
| ram\_disk\_id | The ID of the ram disk | `string` | `null` | no |
| schedules | Map of autoscaling group schedule to create | <pre>map(object({<br/>    min_size     = optional(number)<br/>    max_size     = optional(number)<br/>    desired_size = optional(number)<br/>    start_time   = optional(string)<br/>    end_time     = optional(string)<br/>    time_zone    = optional(string)<br/>    recurrence   = optional(string)<br/>  }))</pre> | `{}` | no |
| secondary\_interfaces | Configuration for secondary network interfaces on the launch template | <pre>list(object({<br/>    delete_on_termination    = optional(bool)<br/>    device_index             = optional(number)<br/>    interface_type           = optional(string)<br/>    network_card_index       = optional(number)<br/>    private_ip_address_count = optional(number)<br/>    private_ip_addresses     = optional(list(string))<br/>    secondary_subnet_id      = optional(string)<br/>  }))</pre> | `[]` | no |
| security\_group\_names | A list of security group names to associate with. (EC2-Classic only) | `list(string)` | `null` | no |
| service\_linked\_role\_arn | The ARN of the service-linked role that the ASG will use to call other AWS services | `string` | `null` | no |
| subnet\_ids | A list of subnet IDs to launch resources in. Subnets automatically determine which availability zones the group will reside. Conflicts with `availability_zones` | `list(string)` | `null` | no |
| suspended\_processes | A list of processes to suspend for the Auto Scaling Group. The allowed values are `Launch`, `Terminate`, `HealthCheck`, `ReplaceUnhealthy`, `AZRebalance`, `AlarmNotification`, `ScheduledActions`, `AddToLoadBalancer`. Note that if you suspend either the `Launch` or `Terminate` process types, it can prevent your Auto Scaling Group from functioning properly | `list(string)` | `[]` | no |
| tag\_specifications | The tags to apply to the resources during launch | `list(string)` | <pre>[<br/>  "instance",<br/>  "volume",<br/>  "network-interface"<br/>]</pre> | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| target\_group\_arns | A set of `aws_alb_target_group` ARNs, for use with Application or Network Load Balancing | `list(string)` | `[]` | no |
| termination\_policies | A list of policies to decide how the instances in the Auto Scaling Group should be terminated. The allowed values are `OldestInstance`, `NewestInstance`, `OldestLaunchConfiguration`, `ClosestToNextInstanceHour`, `OldestLaunchTemplate`, `AllocationStrategy`, `Default` | `list(string)` | `[]` | no |
| traffic\_sources | Set of traffic sources to attach to the Auto Scaling Group. Each object has `identifier` and `type` attributes | <pre>list(object({<br/>    identifier = string<br/>    type       = string<br/>  }))</pre> | `[]` | no |
| update\_launch\_template\_default\_version | Whether to update Default Version each update. Conflicts with `launch_template_default_version` | `bool` | `true` | no |
| use\_mixed\_instances\_policy | Determines whether to use a mixed instances policy in the autoscaling group or not | `bool` | `false` | no |
| use\_name\_prefix | Determines whether to use `name` as is or create a unique name beginning with the `name` as the prefix | `bool` | `true` | no |
| user\_data\_template\_path | Path to a local, custom user data template file to use when rendering user data | `string` | `null` | no |
| vpc\_security\_group\_ids | A list of security group IDs to associate | `list(string)` | `[]` | no |
| wait\_for\_capacity\_timeout | A maximum duration that Terraform should wait for ASG instances to be healthy before timing out. (See also Waiting for Capacity below.) Setting this to '0' causes Terraform to skip all Capacity Waiting behavior. | `string` | `null` | no |
| wait\_for\_elb\_capacity | Setting this will cause Terraform to wait for exactly this number of healthy instances in all attached load balancers on both create and update operations. Takes precedence over `min_elb_capacity` behavior. | `number` | `null` | no |
| warm\_pool | If this block is configured, add a Warm Pool to the specified Auto Scaling group | <pre>object({<br/>    instance_reuse_policy = optional(object({<br/>      reuse_on_scale_in = optional(bool)<br/>    }))<br/>    max_group_prepared_capacity = optional(number)<br/>    min_size                    = optional(number)<br/>    pool_state                  = optional(string)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| access\_entry\_arn | Amazon Resource Name (ARN) of the Access Entry |
| autoscaling\_group\_arn | The ARN for this autoscaling group |
| autoscaling\_group\_availability\_zones | The availability zones of the autoscaling group |
| autoscaling\_group\_default\_cooldown | Time between a scaling activity and the succeeding scaling activity |
| autoscaling\_group\_desired\_capacity | The number of Amazon EC2 instances that should be running in the group |
| autoscaling\_group\_health\_check\_grace\_period | Time after instance comes into service before checking health |
| autoscaling\_group\_health\_check\_type | EC2 or ELB. Controls how health checking is done |
| autoscaling\_group\_id | The autoscaling group id |
| autoscaling\_group\_max\_size | The maximum size of the autoscaling group |
| autoscaling\_group\_min\_size | The minimum size of the autoscaling group |
| autoscaling\_group\_name | The autoscaling group name |
| autoscaling\_group\_schedule\_arns | ARNs of autoscaling group schedules |
| autoscaling\_group\_vpc\_zone\_identifier | The VPC zone identifier |
| iam\_instance\_profile\_arn | ARN assigned by AWS to the instance profile |
| iam\_instance\_profile\_id | Instance profile's ID |
| iam\_instance\_profile\_unique | Stable and unique string identifying the IAM instance profile |
| iam\_role\_arn | The Amazon Resource Name (ARN) specifying the IAM role |
| iam\_role\_name | The name of the IAM role |
| iam\_role\_unique\_id | Stable and unique string identifying the IAM role |
| image\_id | ID of the image |
| launch\_template\_arn | The ARN of the launch template |
| launch\_template\_id | The ID of the launch template |
| launch\_template\_latest\_version | The latest version of the launch template |
| launch\_template\_name | The name of the launch template |
| platform | [DEPRECATED - Will be removed in `v21.0`] Identifies the OS platform as `bottlerocket`, `linux` (AL2), `al2023`, or `windows` |
| user\_data | Base64 encoded user data |
<!-- END_TF_DOCS -->

## Examples

## Basic Usage

Self-managed node group with an Auto Scaling Group on AL2023.

```hcl
module "self_managed_ng" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/self-managed-node-group?depth=1&ref=master"

  enabled      = true
  name         = "general"
  cluster_name = "my-cluster"

  ami_type  = "AL2023_x86_64_STANDARD"
  ami_id    = "ami-0abcdef1234567890"

  instance_type = "m6i.large"
  subnet_ids    = ["subnet-0aaa111", "subnet-0bbb222", "subnet-0ccc333"]

  min_size     = 2
  max_size     = 6
  desired_size = 2

  cluster_endpoint    = "https://ABCDEF1234567890.gr7.ap-southeast-1.eks.amazonaws.com"
  cluster_auth_base64 = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t..."
  cluster_service_cidr = "172.20.0.0/16"

  tags = {
    Environment = "production"
  }
}
```

## With Custom Bootstrap and Block Device Mappings

Self-managed node group with pre-bootstrap user data and encrypted EBS volumes.

```hcl
module "self_managed_ng" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/self-managed-node-group?depth=1&ref=master"

  enabled      = true
  name         = "app-workers"
  cluster_name = "prod-cluster"

  ami_type  = "AL2023_x86_64_STANDARD"
  ami_id    = "ami-0abcdef1234567890"

  instance_type = "m6i.xlarge"
  subnet_ids    = ["subnet-0aaa111", "subnet-0bbb222"]

  min_size     = 3
  max_size     = 12
  desired_size = 3

  cluster_endpoint     = "https://ABCDEF1234567890.gr7.ap-southeast-1.eks.amazonaws.com"
  cluster_auth_base64  = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t..."
  cluster_service_cidr = "172.20.0.0/16"

  pre_bootstrap_user_data = <<-EOT
    #!/bin/bash
    yum install -y amazon-ssm-agent
    systemctl enable --now amazon-ssm-agent
  EOT

  block_device_mappings = {
    xvda = {
      device_name = "/dev/xvda"
      ebs = {
        volume_size           = 100
        volume_type           = "gp3"
        encrypted             = true
        kms_key_id            = "arn:aws:kms:ap-southeast-1:123456789012:key/mrk-abc123"
        delete_on_termination = true
      }
    }
  }

  iam_role_additional_policies = {
    ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = {
    Environment = "production"
    NodeRole    = "app"
  }
}
```

## With Mixed Instances Policy (Spot + On-Demand)

Cost-optimised node group using a mixed instances policy for spot and on-demand capacity.

```hcl
module "self_managed_ng_mixed" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/self-managed-node-group?depth=1&ref=master"

  enabled      = true
  name         = "mixed-workers"
  cluster_name = "prod-cluster"

  ami_type = "AL2023_x86_64_STANDARD"
  ami_id   = "ami-0abcdef1234567890"

  subnet_ids = ["subnet-0aaa111", "subnet-0bbb222", "subnet-0ccc333"]

  min_size     = 2
  max_size     = 20
  desired_size = 4

  cluster_endpoint     = "https://ABCDEF1234567890.gr7.ap-southeast-1.eks.amazonaws.com"
  cluster_auth_base64  = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t..."
  cluster_service_cidr = "172.20.0.0/16"

  use_mixed_instances_policy = true
  mixed_instances_policy = {
    instances_distribution = {
      on_demand_base_capacity                  = 2
      on_demand_percentage_above_base_capacity = 25
      spot_allocation_strategy                 = "price-capacity-optimized"
    }
    override = [
      { instance_type = "m6i.large" },
      { instance_type = "m5.large" },
      { instance_type = "m5a.large" },
      { instance_type = "m4.large" },
    ]
  }

  tags = {
    Environment = "production"
    NodeRole    = "mixed"
  }
}
```

## Advanced - With Placement Group and Instance Refresh

High-performance node group with cluster placement, rolling instance refresh, and scheduling.

```hcl
module "self_managed_ng_hpc" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/self-managed-node-group?depth=1&ref=master"

  enabled      = true
  name         = "hpc-workers"
  cluster_name = "prod-cluster"

  ami_type  = "AL2023_x86_64_STANDARD"
  ami_id    = "ami-0abcdef1234567890"

  instance_type = "c6i.8xlarge"
  subnet_ids    = ["subnet-0aaa111"]

  min_size     = 4
  max_size     = 20
  desired_size = 4

  cluster_endpoint     = "https://ABCDEF1234567890.gr7.ap-southeast-1.eks.amazonaws.com"
  cluster_auth_base64  = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t..."
  cluster_service_cidr = "172.20.0.0/16"

  create_placement_group      = true
  placement_group_strategy    = "cluster"
  placement_group_az          = "ap-southeast-1a"

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 75
      instance_warmup        = 120
    }
  }

  schedules = {
    scale_up = {
      min_size     = 4
      max_size     = 20
      desired_size = 4
      recurrence   = "0 7 * * MON-FRI"
      time_zone    = "Asia/Dubai"
    }
    scale_down = {
      min_size     = 0
      max_size     = 20
      desired_size = 0
      recurrence   = "0 21 * * MON-FRI"
      time_zone    = "Asia/Dubai"
    }
  }

  tags = {
    Environment = "production"
    NodeRole    = "hpc"
  }
}
```

## Notes

- **AMI type default**: `ami_type` defaults to `AL2023_x86_64_STANDARD` (previously `AL2_x86_64`). Set `ami_type = "AL2_x86_64"` explicitly to keep existing AL2-based groups unchanged; changing AMI type replaces instances on the next instance refresh.
