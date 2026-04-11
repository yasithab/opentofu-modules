# fck-nat

Cost-effective NAT instance module powered by the [fck-nat](https://fck-nat.dev/) AMI. Provides a drop-in replacement for AWS NAT Gateway at a fraction of the cost, with optional high-availability via an Auto Scaling Group.

## Features

- **High Availability Mode** - Automatic instance recovery using an ASG (min/max 1) with health checks and configurable grace periods
- **Static ENI** - Persistent network interface that survives instance replacements, keeping route table entries stable
- **Automatic AMI Selection** - Resolves the latest fck-nat AL2023 AMI for both x86_64 and ARM64 (Graviton) architectures
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
