# EKS Managed Node Group Module - Examples

## Basic Usage

Single EKS managed node group with AL2023 and on-demand instances.

```hcl
module "node_group" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/eks-managed-node-group?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/eks-managed-node-group?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/eks-managed-node-group?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//eks/modules/eks-managed-node-group?depth=1&ref=v2.0.0"

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
