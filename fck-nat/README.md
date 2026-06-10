# fck-nat

Cost-effective NAT instance module powered by the [fck-nat](https://fck-nat.dev/) AMI. Provides a drop-in replacement for AWS NAT Gateway at a fraction of the cost, with optional high-availability via an Auto Scaling Group.

## Features

- **High Availability Mode** - Automatic instance recovery using an ASG (min/max 1) with health checks and configurable grace periods
- **Static ENI** - Persistent network interface that survives instance replacements, keeping route table entries stable
- **Automatic AMI Selection** - Resolves the latest fck-nat AL2023 AMI for both x86_64 and ARM64 (Graviton) architectures. The AMI owner account is configurable via `ami_owner` (defaults to the upstream fck-nat account)
- **Spot Instance Support** - Optional spot instances for additional cost savings on top of the already low NAT instance pricing
- **Elastic IP Association** - Attach an existing EIP for a static outbound IP address
- **Route Table Management** - Optionally create 0.0.0.0/0 routes pointing to the NAT ENI in specified route tables
- **SSM Integration** - Built-in IAM policies for SSM Session Manager (interactive access) and SSM Patch Manager (automated patching)
- **Performance Tuning** - Configurable connection tracking limits and ephemeral port ranges for high-throughput workloads
- **EBS Encryption** - Encrypted root volume by default with optional custom KMS key
- **Extensible Cloud-Init** - Append custom cloud-init parts after the fck-nat bootstrap script

## Usage

```hcl
module "fck_nat" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//fck-nat?depth=1&ref=master"

  name      = "nat-az1"
  vpc_id    = "vpc-0abc123def456"
  subnet_id = "subnet-0abc123def456"

  ha_mode            = true
  update_route_tables = true
  route_tables_ids = {
    private-az1 = "rtb-0abc123def456"
  }

  tags = {
    Environment = "production"
  }
}
```


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11.0 |
| aws | >= 6.49, < 7.0 |
| cloudinit | >= 2.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.49, < 7.0 |
| cloudinit | >= 2.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| additional\_security\_group\_ids | Additional security group IDs to attach to the fck-nat ENIs. | `list(string)` | `[]` | no |
| ami\_id | Custom AMI ID. When null the latest fck-nat AL2023 AMI is auto-detected. | `string` | `null` | no |
| ami\_owner | AWS account ID that owns the fck-nat AMI. Defaults to the upstream fck-nat project account. | `string` | `"568608671756"` | no |
| attach\_ssm\_patch\_policy | Attach the AmazonSSMManagedInstanceCore managed policy to the IAM role (enables the SSM agent for inventory and automated patching). | `bool` | `true` | no |
| attach\_ssm\_session\_policy | Attach SSM Session Manager permissions to the IAM role (allows interactive shell access). | `bool` | `false` | no |
| cloud\_init\_parts | Additional cloud-init parts to append after the fck-nat configuration script. | <pre>list(object({<br/>    content      = string<br/>    content_type = string<br/>  }))</pre> | `[]` | no |
| conntrack\_max | Maximum number of concurrent tracked connections. Higher values use more memory. 0 uses the OS default. | `number` | `0` | no |
| create\_security\_group | Whether to create the default security group for fck-nat. | `bool` | `true` | no |
| credit\_specification | CPU credit option for burstable (T-type) instances: 'standard' or 'unlimited'. Null uses the instance default. | `string` | `null` | no |
| ebs\_root\_volume\_size | Root EBS volume size in GB. | `number` | `8` | no |
| eip\_allocation\_ids | Elastic IP allocation IDs to associate with fck-nat (max 1). Provides a static outbound IP. | `list(string)` | `[]` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| encryption | Whether to encrypt the root EBS volume. | `bool` | `true` | no |
| ha\_mode | Use an Auto Scaling Group for automatic instance recovery. | `bool` | `true` | no |
| instance\_type | EC2 instance type for fck-nat. Graviton (t4g, c6gn, c7gn) recommended. | `string` | `"t4g.nano"` | no |
| kms\_key\_id | KMS key ID for EBS volume encryption. Uses the default EBS key when null. | `string` | `null` | no |
| local\_port\_range | Ephemeral port range as 'min max' (e.g., '1024 65535'). Wider range reduces port exhaustion under high connection rates. Empty string uses the OS default. | `string` | `""` | no |
| name | Name for all fck-nat resources. | `string` | n/a | yes |
| route\_tables\_ids | Map of logical name to route table ID. A 0.0.0.0/0 route is created in each. | `map(string)` | `{}` | no |
| subnet\_id | Public subnet ID for the fck-nat instance. | `string` | n/a | yes |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| update\_route\_tables | Whether to create 0.0.0.0/0 routes pointing to the fck-nat ENI in the given route tables. | `bool` | `false` | no |
| use\_spot\_instances | Use spot instances for additional cost savings. | `bool` | `false` | no |
| vpc\_id | VPC ID to deploy fck-nat into. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| ami\_id | Resolved AMI ID |
| autoscaling\_group\_arn | ASG ARN (null in non-HA mode) |
| eni\_id | Static ENI ID |
| eni\_private\_ip | Private IP of the static ENI |
| iam\_role\_arn | IAM role ARN |
| iam\_role\_name | IAM role name |
| instance\_id | EC2 instance ID (null in HA mode) |
| instance\_profile\_arn | Instance profile ARN |
| launch\_template\_id | Launch template ID |
| security\_group\_id | Security group ID |
<!-- END_TF_DOCS -->

## Examples

## Basic Usage

Deploy a fck-nat instance in HA mode with automatic recovery via an Auto Scaling Group.

```hcl
module "fck_nat" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//fck-nat?depth=1&ref=master"

  name      = "fck-nat-main"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnet_ids[0]

  tags = {
    Environment = "production"
  }
}
```

## With Private Subnet Route Table Updates

Deploy fck-nat and automatically create 0.0.0.0/0 routes in private subnet route tables so that outbound traffic flows through the NAT instance.

```hcl
module "fck_nat" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//fck-nat?depth=1&ref=master"

  name      = "fck-nat-main"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnet_ids[0]

  update_route_tables = true
  route_tables_ids = {
    private-a = module.vpc.private_route_table_ids[0]
    private-b = module.vpc.private_route_table_ids[1]
    private-c = module.vpc.private_route_table_ids[2]
  }

  tags = {
    Environment = "production"
  }
}
```

## With Static Elastic IP

Attach an Elastic IP to provide a fixed outbound IP address, useful when external services require IP allowlisting.

```hcl
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "fck-nat-eip"
  }
}

module "fck_nat" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//fck-nat?depth=1&ref=master"

  name      = "fck-nat-main"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnet_ids[0]

  eip_allocation_ids = [aws_eip.nat.id]

  update_route_tables = true
  route_tables_ids = {
    private-a = module.vpc.private_route_table_ids[0]
    private-b = module.vpc.private_route_table_ids[1]
  }

  tags = {
    Environment = "production"
  }
}
```

## Cost-Optimized with Spot Instances

Use spot instances for non-critical environments to reduce costs. Combined with HA mode, the ASG automatically replaces interrupted spot instances.

```hcl
module "fck_nat" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//fck-nat?depth=1&ref=master"

  name      = "fck-nat-dev"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnet_ids[0]

  use_spot_instances = true
  instance_type      = "t4g.nano"

  update_route_tables = true
  route_tables_ids = {
    private-a = module.vpc.private_route_table_ids[0]
  }

  tags = {
    Environment = "development"
  }
}
```

## High-Throughput with Performance Tuning

Deploy a larger instance with tuned kernel parameters for high-throughput workloads that require many concurrent connections.

```hcl
module "fck_nat" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//fck-nat?depth=1&ref=master"

  name      = "fck-nat-high-throughput"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnet_ids[0]

  instance_type    = "c6gn.medium"
  conntrack_max    = 524288
  local_port_range = "1024 65535"

  eip_allocation_ids = [aws_eip.nat.id]

  update_route_tables = true
  route_tables_ids = {
    private-a = module.vpc.private_route_table_ids[0]
    private-b = module.vpc.private_route_table_ids[1]
    private-c = module.vpc.private_route_table_ids[2]
  }

  additional_security_group_ids = [aws_security_group.extra.id]

  attach_ssm_session_policy = true

  tags = {
    Environment = "production"
    Tier        = "high-throughput"
  }
}
```
