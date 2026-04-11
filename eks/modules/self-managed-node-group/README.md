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
