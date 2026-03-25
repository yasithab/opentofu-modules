# fck-nat Module - Examples

## Basic Usage

Deploy a fck-nat instance in HA mode with automatic recovery via an Auto Scaling Group.

```hcl
module "fck_nat" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//fck-nat?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//fck-nat?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//fck-nat?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//fck-nat?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//fck-nat?depth=1&ref=v2.0.0"

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

  attach_ssm_policy = true

  tags = {
    Environment = "production"
    Tier        = "high-throughput"
  }
}
```
