# Bastion Module

Combined bastion host module supporting two operational modes:

- **HA mode** (default): Auto Scaling Group with weekly AMI replacement, SSH host key persistence, and self-healing
- **Instance mode**: Standalone EC2 with SSM Patch Manager, auto-recovery alarm, and SSM agent auto-update

SSM Session Manager is always enabled. Public bastions add an Elastic IP and optional SSH tunnel user support.

## Usage

### HA Mode (default) - Private bastion with SSM only

```hcl
module "bastion" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//bastion?depth=1&ref=master"

  name      = "bastion-staging"
  subnet_id = "subnet-0abc123def456"

  tags = {
    Environment = "staging"
    Team        = "platform"
  }
}
```

### HA Mode - Public bastion with SSH tunnels

```hcl
module "bastion" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//bastion?depth=1&ref=master"

  name      = "bastion-production"
  subnet_id = "subnet-0abc123def456"
  public    = true

  instance_type = "t4g.small"

  allowed_ssh_cidrs = ["203.0.113.0/24"]

  tunnel_users = {
    analyst = {
      ssh_public_key  = "ssh-ed25519 AAAAC3... analyst@example.com"
      allowed_tunnels = ["db.internal:5432", "redis.internal:6379"]
    }
    developer = {
      ssh_public_key  = "ssh-ed25519 AAAAC3... dev@example.com"
      allowed_tunnels = []
    }
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

### Instance Mode - Single EC2 with patch management

```hcl
module "bastion" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//bastion?depth=1&ref=master"

  name      = "bastion-dev"
  subnet_id = "subnet-0abc123def456"
  ha_mode   = false

  patch_schedule               = "cron(0 4 ? * SAT *)"
  patch_operation              = "Install"
  patch_baseline_approval_days = 3

  tags = {
    Environment = "development"
    Team        = "platform"
  }
}
```

### Custom security groups and IAM policies

```hcl
module "bastion" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//bastion?depth=1&ref=master"

  name      = "bastion-custom"
  subnet_id = "subnet-0abc123def456"

  vpc_security_group_ids = ["sg-0abc123def456"]

  additional_iam_policies = {
    s3_read = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  }

  iam_role_permissions_boundary = "arn:aws:iam::123456789012:policy/BoundaryPolicy"

  user_data_parts = [
    {
      content_type = "text/x-shellscript"
      content      = "#!/bin/bash\necho 'custom setup'"
    }
  ]

  tags = {
    Environment = "staging"
    Team        = "platform"
  }
}
```
