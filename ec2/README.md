# Amazon EC2

OpenTofu module for provisioning Amazon EC2 instances with support for spot instances, IAM instance profiles, Elastic IPs, and AMI resolution via SSM parameters.

## Features

- **Instance Types** - Supports on-demand instances, spot instance requests, and instances with ignore-AMI-changes lifecycle for immutable deployments
- **AMI Resolution** - Automatic AMI lookup via SSM parameter store or explicit AMI ID specification
- **IAM Instance Profile** - Optional creation of IAM role and instance profile with customizable policies and permissions boundaries. When `create_iam_instance_profile = true`, either `iam_role_name` or `name` must be set
- **Elastic IP** - Optional EIP allocation and association with configurable BYOIP and IPAM pool support
- **Block Devices** - Full configuration of root, EBS, and ephemeral block devices. Root and additional EBS volumes are **encrypted by default** (set `encrypted = false` per volume to opt out)
- **Networking** - Support for primary, secondary, and additional network interfaces with IPv6, placement groups, and private DNS options
- **Spot Instances** - Dedicated spot instance request support with configurable pricing, interruption behavior, and validity windows
- **Security** - IMDSv2 enforced by default, Nitro Enclave support, and termination/stop protection options
- **CPU Configuration** - Customizable CPU options including core count, threads per core, AMD SEV-SNP, and nested virtualization
- **Launch Template** - Optional launch template creation with full configuration support
- **Spot via Market Options** - Inline spot requests using `instance_market_options` as an alternative to dedicated spot instance resources
- **Capacity Reservation** - Target specific capacity reservations or open capacity reservation groups
- **Credit Specification** - Configure CPU credit option (`standard` or `unlimited`) for burstable instance types
- **Volume Tags** - Apply tags to all EBS volumes attached to the instance

## Usage

```hcl
module "ec2" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ec2?depth=1&ref=master"

  name          = "my-instance"
  instance_type = "t3.micro"
  subnet_id     = "subnet-0123456789abcdef0"

  vpc_security_group_ids = ["sg-0123456789abcdef0"]

  tags = {
    Environment = "production"
  }
}
```

## Examples

## Basic Usage

A minimal EC2 instance using the latest Amazon Linux 2 AMI resolved via SSM Parameter Store.

```hcl
module "bastion" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ec2?depth=1&ref=master"

  enabled       = true
  name          = "bastion-prod"
  instance_type = "t3.micro"

  subnet_id              = "subnet-0abc123def456789a"
  vpc_security_group_ids = ["sg-0abc123def456789a"]

  key_name = "my-keypair"

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## With Custom AMI and Encrypted Root Volume

An instance with a specific AMI and an encrypted root EBS volume backed by a customer-managed KMS key.

```hcl
module "app_server" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ec2?depth=1&ref=master"

  enabled       = true
  name          = "app-server-prod"
  instance_type = "m5.large"

  ami                  = "ami-0c55b159cbfafe1f0"
  ignore_ami_changes   = true

  subnet_id              = "subnet-0abc123def456789a"
  vpc_security_group_ids = ["sg-0abc123def456789a"]

  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = 50
      encrypted   = true
      kms_key_id  = "arn:aws:kms:ap-southeast-1:123456789012:key/mrk-abc123def456"
    }
  ]

  monitoring              = true
  disable_api_termination = true

  tags = {
    Environment = "production"
    Team        = "backend"
  }
}
```

## With IAM Instance Profile

An instance that has a managed IAM instance profile allowing it to access AWS services such as SSM and S3.

```hcl
module "worker" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ec2?depth=1&ref=master"

  enabled       = true
  name          = "worker-prod"
  instance_type = "c5.xlarge"

  subnet_id              = "subnet-0abc123def456789a"
  vpc_security_group_ids = ["sg-0abc123def456789a"]

  create_iam_instance_profile = true
  iam_role_name               = "worker-instance-role"
  iam_role_description        = "IAM role for worker EC2 instances"
  iam_role_policies = {
    SSMCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    S3Read  = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  }

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y amazon-ssm-agent
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
  EOF

  tags = {
    Environment = "production"
    Team        = "data"
  }
}
```

## Spot Instance with Elastic IP

A persistent spot instance with an Elastic IP for stable addressing.

```hcl
module "spot_worker" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ec2?depth=1&ref=master"

  enabled       = true
  name          = "spot-worker"
  instance_type = "r5.2xlarge"

  subnet_id              = "subnet-0abc123def456789a"
  vpc_security_group_ids = ["sg-0abc123def456789a"]

  create_spot_instance             = true
  spot_price                       = "0.25"
  spot_type                        = "persistent"
  spot_instance_interruption_behavior = "stop"

  create_eip = true

  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = 100
      encrypted   = true
    }
  ]

  tags = {
    Environment = "production"
    Team        = "ml"
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
| ami | ID of AMI to use for the instance | `string` | `null` | no |
| ami\_ssm\_parameter | SSM parameter name for the AMI ID. For Amazon Linux AMI SSM parameters see [reference](https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-store-public-parameters-ami.html) | `string` | `"/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"` | no |
| associate\_public\_ip\_address | Whether to associate a public IP address with an instance in a VPC | `bool` | `null` | no |
| availability\_zone | AZ to start the instance in | `string` | `null` | no |
| capacity\_reservation\_specification | Describes an instance's Capacity Reservation targeting option | <pre>object({<br/>    capacity_reservation_preference = optional(string)<br/>    capacity_reservation_target = optional(object({<br/>      capacity_reservation_id                 = optional(string)<br/>      capacity_reservation_resource_group_arn = optional(string)<br/>    }))<br/>  })</pre> | `null` | no |
| cpu\_credits | The credit option for CPU usage (unlimited or standard) | `string` | `null` | no |
| cpu\_options | Defines CPU options to apply to the instance at launch time. | <pre>object({<br/>    core_count            = optional(number)<br/>    threads_per_core      = optional(number)<br/>    amd_sev_snp           = optional(string)<br/>    nested_virtualization = optional(string)<br/>  })</pre> | `null` | no |
| create\_eip | Determines whether a public EIP will be created and associated with the instance. | `bool` | `false` | no |
| create\_iam\_instance\_profile | Determines whether an IAM instance profile is created or to use an existing IAM instance profile | `bool` | `false` | no |
| create\_spot\_instance | Depicts if the instance is a spot instance | `bool` | `false` | no |
| disable\_api\_stop | If true, enables EC2 Instance Stop Protection | `bool` | `null` | no |
| disable\_api\_termination | If true, enables EC2 Instance Termination Protection | `bool` | `null` | no |
| ebs\_block\_device | Additional EBS block devices to attach to the instance. Volumes are encrypted by default; set `encrypted = false` to opt out. | <pre>list(object({<br/>    device_name           = string<br/>    delete_on_termination = optional(bool)<br/>    encrypted             = optional(bool, true)<br/>    iops                  = optional(number)<br/>    kms_key_id            = optional(string)<br/>    snapshot_id           = optional(string)<br/>    volume_size           = optional(number)<br/>    volume_type           = optional(string)<br/>    throughput            = optional(number)<br/>    tags                  = optional(map(string), {})<br/>  }))</pre> | `[]` | no |
| ebs\_optimized | If true, the launched EC2 instance will be EBS-optimized | `bool` | `null` | no |
| eip\_address | IP address from an EC2 BYOIP pool. This option is only available for VPC EIPs | `string` | `null` | no |
| eip\_associate\_with\_private\_ip | User-specified primary or secondary private IP address to associate with the Elastic IP address. If no private IP address is specified, the Elastic IP address is associated with the primary private IP address | `string` | `null` | no |
| eip\_customer\_owned\_ipv4\_pool | ID of a customer-owned address pool. For more on customer owned IP addressed check out Customer-owned IP addresses guide | `string` | `null` | no |
| eip\_domain | Indicates if this EIP is for use in VPC | `string` | `"vpc"` | no |
| eip\_ipam\_pool\_id | The ID of an IPAM pool which has an Amazon-provided or BYOIP public IPv4 CIDR provisioned to it | `string` | `null` | no |
| eip\_network\_border\_group | The location from which the IP address is advertised. Use this parameter to limit the address to this location | `string` | `null` | no |
| eip\_network\_interface | Network interface ID to associate with. Conflicts with instance | `string` | `null` | no |
| eip\_public\_ipv4\_pool | EC2 IPv4 address pool identifier or amazon. This option is only available for VPC EIPs | `string` | `null` | no |
| eip\_tags | A map of additional tags to add to the eip | `map(string)` | `{}` | no |
| enable\_primary\_ipv6 | Whether to assign a primary IPv6 Global Unicast Address (GUA) to the instance when launched in a dual-stack or IPv6-only subnet. Requires ipv6\_address\_count or ipv6\_addresses to also be configured. | `bool` | `null` | no |
| enable\_volume\_tags | Whether to enable volume tags (if enabled it conflicts with root\_block\_device tags) | `bool` | `true` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| enclave\_options\_enabled | Whether Nitro Enclaves will be enabled on the instance. Defaults to `false` | `bool` | `null` | no |
| ephemeral\_block\_device | Customize Ephemeral (also known as Instance Store) volumes on the instance | `list(map(string))` | `[]` | no |
| force\_destroy | If true, all Elastic IPs and network interfaces associated with the instance will be deleted along with the instance | `bool` | `null` | no |
| get\_password\_data | If true, wait for password data to become available and retrieve it | `bool` | `null` | no |
| hibernation | If true, the launched EC2 instance will support hibernation | `bool` | `null` | no |
| host\_id | ID of a dedicated host that the instance will be assigned to. Use when an instance is to be launched on a specific dedicated host | `string` | `null` | no |
| host\_resource\_group\_arn | ARN of the host resource group in which to launch the instances. If you specify a Host Resource Group ARN, omit the Tenancy parameter or set it to host | `string` | `null` | no |
| iam\_instance\_profile | IAM Instance Profile to launch the instance with. Specified as the name of the Instance Profile | `string` | `null` | no |
| iam\_role\_description | Description of the role | `string` | `null` | no |
| iam\_role\_max\_session\_duration | Maximum session duration (in seconds) that you want to set for the specified role. Valid values are between 3600 and 43200 | `number` | `null` | no |
| iam\_role\_name | Name to use on IAM role created | `string` | `null` | no |
| iam\_role\_path | IAM role path | `string` | `null` | no |
| iam\_role\_permissions\_boundary | ARN of the policy that is used to set the permissions boundary for the IAM role | `string` | `null` | no |
| iam\_role\_policies | Policies attached to the IAM role | `map(string)` | `{}` | no |
| iam\_role\_tags | A map of additional tags to add to the IAM role/profile created | `map(string)` | `{}` | no |
| iam\_role\_use\_name\_prefix | Determines whether the IAM role name (`iam_role_name` or `name`) is used as a prefix | `bool` | `true` | no |
| ignore\_ami\_changes | Whether changes to the AMI ID changes should be ignored by Terraform. Note - changing this value will result in the replacement of the instance | `bool` | `false` | no |
| instance\_initiated\_shutdown\_behavior | Shutdown behavior for the instance. Amazon defaults this to stop for EBS-backed instances and terminate for instance-store instances. Cannot be set on instance-store instance | `string` | `null` | no |
| instance\_market\_options | Customize the market (purchasing) option for the instance. Used when launching instances as Spot via aws\_instance (not aws\_spot\_instance\_request) | <pre>object({<br/>    market_type = optional(string)<br/>    spot_options = optional(object({<br/>      instance_interruption_behavior = optional(string)<br/>      max_price                      = optional(string)<br/>      spot_instance_type             = optional(string)<br/>      valid_until                    = optional(string)<br/>    }))<br/>  })</pre> | `null` | no |
| instance\_tags | Additional tags for the instance | `map(string)` | `{}` | no |
| instance\_type | The type of instance to start | `string` | `"t3.micro"` | no |
| ipv6\_address\_count | A number of IPv6 addresses to associate with the primary network interface. Amazon EC2 chooses the IPv6 addresses from the range of your subnet | `number` | `null` | no |
| ipv6\_addresses | Specify one or more IPv6 addresses from the range of the subnet to associate with the primary network interface | `list(string)` | `null` | no |
| key\_name | Key name of the Key Pair to use for the instance; which can be managed using the `aws_key_pair` resource | `string` | `null` | no |
| launch\_template | Specifies a Launch Template to configure the instance. Parameters configured on this resource will override the corresponding parameters in the Launch Template | `map(string)` | `{}` | no |
| maintenance\_options | The maintenance options for the instance | <pre>object({<br/>    auto_recovery = optional(string)<br/>  })</pre> | `null` | no |
| metadata\_options | Customize the metadata options of the instance | `map(string)` | <pre>{<br/>  "http_endpoint": "enabled",<br/>  "http_put_response_hop_limit": 1,<br/>  "http_tokens": "required"<br/>}</pre> | no |
| monitoring | If true, the launched EC2 instance will have detailed monitoring enabled | `bool` | `null` | no |
| name | Name to be used on EC2 instance created | `string` | `null` | no |
| network\_interface | Customize network interfaces to be attached at instance boot time | `list(map(string))` | `[]` | no |
| placement\_group | The Placement Group to start the instance in | `string` | `null` | no |
| placement\_group\_id | The ID of the Placement Group to start the instance in, if applicable. Used for partition placement groups. | `string` | `null` | no |
| placement\_partition\_number | The number of the partition the instance is in. Valid only if the aws\_placement\_group resource's strategy argument is set to partition. | `number` | `null` | no |
| primary\_network\_interface | Configuration for the primary network interface. Specify network\_interface\_id to attach a pre-existing ENI as the primary network interface. | <pre>object({<br/>    network_interface_id = string<br/>  })</pre> | `null` | no |
| private\_dns\_name\_options | Customize the private DNS name options of the instance | `map(string)` | `{}` | no |
| private\_ip | Private IP address to associate with the instance in a VPC | `string` | `null` | no |
| root\_block\_device | Customize details about the root block device of the instance. Encrypted by default; set `encrypted = false` to opt out. | <pre>list(object({<br/>    delete_on_termination = optional(bool)<br/>    encrypted             = optional(bool, true)<br/>    iops                  = optional(number)<br/>    kms_key_id            = optional(string)<br/>    volume_size           = optional(number)<br/>    volume_type           = optional(string)<br/>    throughput            = optional(number)<br/>    tags                  = optional(map(string), {})<br/>  }))</pre> | `[]` | no |
| secondary\_network\_interface | List of secondary network interfaces to attach at instance boot time. Each object must include secondary\_subnet\_id (required) and network\_card\_index (required), plus optional delete\_on\_termination, device\_index, interface\_type, and private\_ip\_address\_count. | <pre>list(object({<br/>    secondary_subnet_id      = string<br/>    network_card_index       = number<br/>    delete_on_termination    = optional(bool)<br/>    device_index             = optional(number)<br/>    interface_type           = optional(string)<br/>    private_ip_address_count = optional(number)<br/>  }))</pre> | `[]` | no |
| secondary\_private\_ips | A list of secondary private IPv4 addresses to assign to the instance's primary network interface (eth0) in a VPC. Can only be assigned to the primary network interface (eth0) attached at instance creation, not a pre-existing network interface i.e. referenced in a `network_interface block` | `list(string)` | `null` | no |
| source\_dest\_check | Controls if traffic is routed to the instance when the destination address does not match the instance. Used for NAT or VPNs | `bool` | `null` | no |
| spot\_instance\_interruption\_behavior | Indicates Spot instance behavior when it is interrupted. Valid values are `terminate`, `stop`, or `hibernate` | `string` | `null` | no |
| spot\_launch\_group | A launch group is a group of spot instances that launch together and terminate together. If left empty instances are launched and terminated individually | `string` | `null` | no |
| spot\_price | The maximum price to request on the spot market. Defaults to on-demand price | `string` | `null` | no |
| spot\_type | If set to one-time, after the instance is terminated, the spot request will be closed. Default `persistent` | `string` | `null` | no |
| spot\_valid\_from | The start date and time of the request, in UTC RFC3339 format(for example, YYYY-MM-DDTHH:MM:SSZ) | `string` | `null` | no |
| spot\_valid\_until | The end date and time of the request, in UTC RFC3339 format(for example, YYYY-MM-DDTHH:MM:SSZ) | `string` | `null` | no |
| spot\_wait\_for\_fulfillment | If set, Terraform will wait for the Spot Request to be fulfilled, and will throw an error if the timeout of 10m is reached | `bool` | `null` | no |
| subnet\_id | The VPC Subnet ID to launch in | `string` | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| tenancy | The tenancy of the instance (if the instance is running in a VPC). Available values: default, dedicated, host | `string` | `null` | no |
| timeouts | Define maximum timeout for creating, updating, and deleting EC2 instance resources | <pre>object({<br/>    create = optional(string)<br/>    update = optional(string)<br/>    delete = optional(string)<br/>  })</pre> | `{}` | no |
| user\_data | The user data to provide when launching the instance. Do not pass gzip-compressed data via this argument; see user\_data\_base64 instead | `string` | `null` | no |
| user\_data\_base64 | Can be used instead of user\_data to pass base64-encoded binary data directly. Use this instead of user\_data whenever the value is not a valid UTF-8 string. For example, gzip-encoded user data must be base64-encoded and passed via this argument to avoid corruption | `string` | `null` | no |
| user\_data\_replace\_on\_change | When used in combination with user\_data or user\_data\_base64 will trigger a destroy and recreate when set to true. Defaults to false if not set | `bool` | `null` | no |
| volume\_tags | A mapping of tags to assign to the devices created by the instance at launch time | `map(string)` | `{}` | no |
| vpc\_security\_group\_ids | A list of security group IDs to associate with | `list(string)` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| ami | AMI ID that was used to create the instance |
| arn | The ARN of the instance |
| availability\_zone | The availability zone of the created instance |
| capacity\_reservation\_specification | Capacity reservation specification of the instance |
| ebs\_block\_device | EBS block device information |
| ephemeral\_block\_device | Ephemeral block device information |
| iam\_instance\_profile\_arn | ARN assigned by AWS to the instance profile |
| iam\_instance\_profile\_id | Instance profile's ID |
| iam\_instance\_profile\_unique | Stable and unique string identifying the IAM instance profile |
| iam\_role\_arn | The Amazon Resource Name (ARN) specifying the IAM role |
| iam\_role\_name | The name of the IAM role |
| iam\_role\_unique\_id | Stable and unique string identifying the IAM role |
| id | The ID of the instance |
| instance\_state | The state of the instance |
| ipv6\_addresses | The IPv6 address assigned to the instance, if applicable |
| outpost\_arn | The ARN of the Outpost the instance is assigned to |
| password\_data | Base-64 encoded encrypted password data for the instance. Useful for getting the administrator password for instances running Microsoft Windows. This attribute is only exported if `get_password_data` is true |
| primary\_network\_interface\_id | The ID of the instance's primary network interface |
| private\_dns | The private DNS name assigned to the instance. Can only be used inside the Amazon EC2, and only available if you've enabled DNS hostnames for your VPC |
| private\_ip | The private IP address assigned to the instance |
| public\_dns | The public DNS name assigned to the instance. For EC2-VPC, this is only available if you've enabled DNS hostnames for your VPC |
| public\_ip | The public IP address assigned to the instance, if applicable. |
| root\_block\_device | Root block device information |
| spot\_bid\_status | The current bid status of the Spot Instance Request |
| spot\_instance\_id | The Instance ID (if any) that is currently fulfilling the Spot Instance request |
| spot\_request\_state | The current request state of the Spot Instance Request |
| tags\_all | A map of tags assigned to the resource, including those inherited from the provider default\_tags configuration block |
<!-- END_TF_DOCS -->

</details>
