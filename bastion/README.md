# Bastion Module

Combined bastion host module supporting two operational modes:

- **HA mode** (default): Auto Scaling Group with weekly AMI replacement, SSH host key persistence (ED25519, RSA, ECDSA), and self-healing
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

## Supported SSH Key Types for Tunnel Users

| Key Type | Example Prefix |
|----------|---------------|
| ED25519 (recommended) | `ssh-ed25519 AAAA...` |
| RSA | `ssh-rsa AAAA...` |
| ECDSA | `ecdsa-sha2-nistp256 AAAA...` |
| FIDO2 ED25519 | `sk-ssh-ed25519@openssh.com AAAA...` |
| FIDO2 ECDSA | `sk-ecdsa-sha2-nistp256@openssh.com AAAA...` |

All key types can be mixed in the same module. The `ssh_public_key` value is validated against these prefixes.

## SSH Host Key Persistence

Applies to `ha_mode = true` and `public = true` only. Enabled by default. Generates ED25519, RSA (4096-bit), and ECDSA (P-256) host keys, stored in a single SSM SecureString parameter at `/bastion/{name}/ssh-host-keys`. All 3 key types are installed on boot - clients negotiate the strongest available.

The SSM parameter value is written via the **write-only** `value_wo` attribute, so the
private host keys are never stored in OpenTofu state. The generated `tls_private_key`
resources still hold key material in state, however - protect your state backend accordingly.

**To rotate host keys:**

```bash
tofu taint tls_private_key.ssh_host_ed25519
tofu taint tls_private_key.ssh_host_rsa
tofu taint tls_private_key.ssh_host_ecdsa
tofu apply
```

After rotating, also increment `ssh_host_keys_wo_version` so the write-only SSM parameter
value is rewritten.

Set `kms_key_arn` to the ARN of the customer-managed KMS key encrypting the parameter to
scope the bastion's `kms:Decrypt` permission to that single key (instead of all keys in the
account, still gated by `kms:ViaService = ssm`).

## Security

| Feature | Default |
|---------|---------|
| IMDSv2 required | Yes |
| Root volume encrypted | Yes (gp3) |
| SSM Session Manager | Always enabled |
| Session logging | CloudWatch, 7-day retention, optional KMS encryption |
| IAM AssociateEIP | Scoped to specific EIP ARN + same account/region |
| IAM SSM GetParameter | Scoped to exact parameter ARN |
| IAM KMS Decrypt | Conditioned on kms:ViaService=ssm (only usable via SSM API) |
| SSM prefix validation | Path format enforced (path traversal blocked) |
| SSH public key validation | Key type prefix + single-quote injection blocked |
| Tunnel user access | Port-forwarding only, no shell |
| Tunnel user shell | `/usr/sbin/nologin` (defense-in-depth) |


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

## Reference

<details>
<summary>Requirements, providers, inputs and outputs (generated by terraform-docs)</summary>

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11.0 |
| aws | >= 6.49, < 7.0 |
| cloudinit | >= 2.0, < 3.0 |
| tls | >= 4.0, < 5.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.49, < 7.0 |
| cloudinit | >= 2.0, < 3.0 |
| tls | >= 4.0, < 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| additional\_iam\_policies | Map of additional IAM policy ARNs to attach to the bastion role | `map(string)` | `{}` | no |
| allowed\_ssh\_cidrs | List of CIDR blocks allowed to SSH to the bastion. Only used when public = true and the module creates its own security group (vpc\_security\_group\_ids is empty). | `list(string)` | `[]` | no |
| cpu\_architecture | CPU architecture: x86\_64 or arm64. Must match the instance type (e.g. t3 = x86\_64, t4g = arm64). | `string` | `"arm64"` | no |
| ebs\_encrypted | Whether to encrypt the root EBS volume | `bool` | `true` | no |
| ebs\_root\_volume\_size | Root EBS volume size in GB | `number` | `8` | no |
| eip\_tags | Additional tags for the Elastic IP | `map(string)` | `{}` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| ha\_mode | Use an Auto Scaling Group for automatic instance recovery and weekly AMI replacement. | `bool` | `true` | no |
| iam\_role\_permissions\_boundary | ARN of the permissions boundary policy for the IAM role | `string` | `null` | no |
| instance\_type | EC2 instance type for the bastion host | `string` | `"t4g.nano"` | no |
| key\_name | Key pair name for SSH access. Optional when using SSM Session Manager only. | `string` | `null` | no |
| kms\_key\_arn | ARN of the customer-managed KMS key used to encrypt the SSH host key SSM parameter. When set, the bastion's kms:Decrypt permission is scoped to this key instead of all keys in the account (the kms:ViaService=ssm condition applies either way). | `string` | `null` | no |
| kms\_key\_id | KMS key ID for EBS volume encryption. Uses default EBS key when null. | `string` | `null` | no |
| maintenance\_window\_cutoff | Hours before the end of the maintenance window that new tasks stop being scheduled. Only used when ha\_mode = false. | `number` | `1` | no |
| maintenance\_window\_duration | Duration of the maintenance window in hours. Only used when ha\_mode = false. | `number` | `2` | no |
| monitoring | Enable detailed monitoring on launched instances | `bool` | `false` | no |
| name | Name for the bastion instance and related resources | `string` | `null` | no |
| patch\_baseline\_approval\_days | Number of days after a patch is released before it is auto-approved. Only used when ha\_mode = false. | `number` | `7` | no |
| patch\_operation | Patch operation to perform: Scan or Install. Only used when ha\_mode = false. | `string` | `"Install"` | no |
| patch\_schedule | Cron expression for the SSM maintenance window schedule (UTC). Only used when ha\_mode = false. | `string` | `"cron(0 0 ? * SAT *)"` | no |
| persist\_ssh\_host\_keys | Persist SSH host keys in SSM Parameter Store so they survive instance replacement. Only used when ha\_mode = true and public = true. | `bool` | `true` | no |
| public | Whether the bastion is public. When true, an Elastic IP is created. In ha\_mode, EIP is self-associated on boot via user data. | `bool` | `false` | no |
| reboot\_option | Reboot behavior after patching: RebootIfNeeded or NoReboot. Only used when ha\_mode = false. | `string` | `"RebootIfNeeded"` | no |
| replacement\_scale\_down\_schedule | Cron expression (UTC) for weekly scale-down. Default: Saturday 00:00 UTC (4 AM GST). Only used when ha\_mode = true. | `string` | `"0 0 * * 6"` | no |
| replacement\_scale\_up\_schedule | Cron expression (UTC) for weekly scale-up after replacement. Default: Saturday 00:05 UTC (4:05 AM GST). Only used when ha\_mode = true. | `string` | `"5 0 * * 6"` | no |
| session\_idle\_timeout\_minutes | Idle timeout in minutes for SSM sessions | `number` | `20` | no |
| session\_log\_kms\_key\_id | KMS key ARN for encrypting SSM session logs in CloudWatch. Uses default CloudWatch encryption when null. | `string` | `null` | no |
| session\_log\_retention\_days | Number of days to retain SSM session logs in CloudWatch | `number` | `7` | no |
| ssh\_host\_key\_ssm\_prefix | SSM Parameter Store prefix for SSH host keys. Keys stored as SecureString under this path. Only used when ha\_mode = true and public = true. | `string` | `null` | no |
| ssh\_host\_keys\_wo\_version | Version counter for the write-only SSH host keys SSM parameter value. The host keys are written via the `value_wo` write-only attribute and never stored in state; increment this number to force the parameter value to be rewritten (e.g. after rotating the TLS keys). | `number` | `1` | no |
| subnet\_id | VPC subnet ID to launch the bastion in | `string` | n/a | yes |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| tunnel\_users | Map of restricted SSH tunnel users. Only used when public = true. Each user can only create SSH tunnels to allowed\_tunnels destinations. Empty allowed\_tunnels permits tunneling to any destination. | <pre>map(object({<br/>    ssh_public_key  = string<br/>    allowed_tunnels = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| user\_data\_parts | Additional cloud-init parts appended after the bastion bootstrap script | <pre>list(object({<br/>    content      = string<br/>    content_type = string<br/>  }))</pre> | `[]` | no |
| vpc\_security\_group\_ids | List of security group IDs to associate with the bastion | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| auto\_recovery\_alarm\_arn | ARN of the auto-recovery CloudWatch alarm (null in ha\_mode) |
| autoscaling\_group\_arn | ARN of the bastion Auto Scaling Group (null when ha\_mode = false) |
| autoscaling\_group\_name | Name of the bastion Auto Scaling Group (null when ha\_mode = false) |
| eip\_id | Allocation ID of the Elastic IP (null if not public) |
| eip\_public\_ip | Elastic IP address (null if not public) |
| iam\_instance\_profile\_arn | ARN of the bastion instance profile |
| iam\_role\_arn | ARN of the bastion IAM role |
| iam\_role\_name | Name of the bastion IAM role |
| instance\_arn | The ARN of the bastion instance (null in ha\_mode) |
| instance\_id | The ID of the bastion instance (null in ha\_mode) |
| instance\_state | The state of the bastion instance (null in ha\_mode) |
| launch\_template\_id | ID of the bastion launch template (null when ha\_mode = false) |
| maintenance\_window\_id | ID of the SSM maintenance window (null in ha\_mode) |
| patch\_baseline\_id | ID of the SSM patch baseline (null in ha\_mode) |
| private\_ip | Private IP address of the bastion instance (null in ha\_mode) |
| security\_group\_id | ID of the bastion security group (null if using external security groups) |
| session\_log\_group\_arn | CloudWatch log group ARN for SSM session logs |
| session\_log\_group\_name | CloudWatch log group name for SSM session logs |
<!-- END_TF_DOCS -->

</details>
