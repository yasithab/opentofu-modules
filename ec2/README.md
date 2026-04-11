# Amazon EC2

OpenTofu module for provisioning Amazon EC2 instances with support for spot instances, IAM instance profiles, Elastic IPs, and AMI resolution via SSM parameters.

## Features

- **Instance Types** - Supports on-demand instances, spot instance requests, and instances with ignore-AMI-changes lifecycle for immutable deployments
- **AMI Resolution** - Automatic AMI lookup via SSM parameter store or explicit AMI ID specification
- **IAM Instance Profile** - Optional creation of IAM role and instance profile with customizable policies and permissions boundaries
- **Elastic IP** - Optional EIP allocation and association with configurable BYOIP and IPAM pool support
- **Block Devices** - Full configuration of root, EBS, and ephemeral block devices with encryption support
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

  instance_name = "my-instance"
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
  instance_name = "bastion-prod"
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
  instance_name = "app-server-prod"
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
  instance_name = "worker-prod"
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
  instance_name = "spot-worker"
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
