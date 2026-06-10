# Headscale Subnet Router

Standalone Tailscale subnet router that connects to a Headscale coordination server and advertises local VPC routes to the tailnet.

Deploy this in any VPC/account to give all tailnet clients access to that VPC's resources - without VPC peering, Transit Gateway, or VPN.

## Features

- **Self-healing** - ASG (min=1, max=1) automatically replaces failed instances
- **Stateless** - no persistent data, re-registers with Headscale on every boot
- **Spot instances** - optional, ~70% cheaper (safe because stateless)
- **Private subnet** - no public IP needed, connects outbound to Headscale via NAT
- **Exit node** - optionally route ALL client traffic through this instance
- **CloudWatch alarm** - alerts when instance is unhealthy
- **CloudWatch Logs** - setup logs exported automatically
- **SSM access** - no SSH keys needed

## Usage

> **WARNING:** an inline `headscale_auth_key` is rendered into the instance **user_data**
> and stored in **OpenTofu state** (the variable is marked `sensitive`, which hides it from
> CLI output but does not encrypt it). For production, leave `headscale_auth_key` empty and
> use `secrets_manager_arn` (+ `secrets_manager_auth_key_field`) so the key is fetched at
> boot and never touches user_data or state.

> **NOTE:** logs are now written to `/headscale/subnet-router/<name>` (previously
> `/headscale/<name>`, which collided with the main Headscale module's log group). The old
> log group is left behind on upgrade and can be deleted manually.

```hcl
module "subnet_router" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//headscale/subnet-router?depth=1&ref=master"

  name      = "staging-subnet-router"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.private_subnets[0]

  headscale_server_url = "https://headscale.example.com"
  advertise_routes     = ["10.20.0.0/16"]
  secrets_manager_arn  = aws_secretsmanager_secret.headscale.arn
  use_spot_instances   = true

  tags = { Environment = "staging" }
}
```

After deployment, approve the routes on the Headscale server:

```bash
headscale routes list
headscale routes enable --route <id>
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
| accept\_dns | Whether this node accepts DNS configuration from the tailnet. | `bool` | `false` | no |
| additional\_security\_group\_ids | Additional security group IDs to attach to the instance. | `list(string)` | `[]` | no |
| advertise\_routes | CIDR ranges to advertise to the tailnet (e.g., ['10.0.0.0/16', '172.16.0.0/12']). | `list(string)` | n/a | yes |
| alarm\_enabled | Create a CloudWatch alarm that fires when the subnet router instance is unhealthy. | `bool` | `true` | no |
| alarm\_sns\_topic\_arn | SNS topic ARN for CloudWatch alarms. Leave empty to create a new topic. | `string` | `""` | no |
| ami\_id | Custom AMI ID. When null, the latest Amazon Linux 2023 AMI is auto-detected. | `string` | `null` | no |
| attach\_ssm\_policy | Attach SSM Session Manager permissions to the IAM role for remote access. | `bool` | `true` | no |
| cloud\_init\_parts | Additional cloud-init parts to append after the Tailscale setup script. | <pre>list(object({<br/>    content      = string<br/>    content_type = string<br/>  }))</pre> | `[]` | no |
| cloudwatch\_logs\_enabled | Export Tailscale and cloud-init logs to CloudWatch Logs. | `bool` | `true` | no |
| cloudwatch\_logs\_retention\_days | Number of days to retain CloudWatch logs. | `number` | `30` | no |
| ebs\_root\_volume\_size | Root EBS volume size in GB. | `number` | `8` | no |
| enable\_instance\_refresh | Enable ASG instance refresh (rolling, 90% min healthy) so launch template changes roll out automatically. | `bool` | `true` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| encryption | Whether to encrypt the root EBS volume. | `bool` | `true` | no |
| exit\_node\_enabled | Advertise this node as a Tailscale exit node. Routes ALL client traffic through this instance (not just subnet routes). | `bool` | `false` | no |
| headscale\_auth\_key | Pre-auth key from Headscale for automatic registration. Leave empty when using secrets\_manager\_arn. Generate with: headscale preauthkeys create --user <user> --reusable --expiration 87600h | `string` | `""` | no |
| headscale\_server\_url | Headscale server URL (e.g., 'https://headscale.example.com'). | `string` | n/a | yes |
| hostname | Tailscale hostname for this subnet router node. Defaults to the instance name. | `string` | `""` | no |
| instance\_type | EC2 instance type. Graviton (t4g) recommended for cost savings. | `string` | `"t4g.nano"` | no |
| kms\_key\_arn | ARN of the customer-managed KMS key encrypting the Secrets Manager secret. When set, the instance's kms:Decrypt permission is scoped to this key instead of all keys (the kms:ViaService=secretsmanager condition applies either way). Required to be set explicitly for cross-account secrets encrypted with a CMK. | `string` | `null` | no |
| kms\_key\_id | KMS key ID for EBS volume encryption. Uses the default EBS key when null. | `string` | `null` | no |
| name | Name for all subnet router resources. | `string` | n/a | yes |
| secrets\_manager\_arn | ARN of a Secrets Manager secret containing a JSON object with sensitive values. The module reads the auth key from the key specified by secrets\_manager\_auth\_key\_field. | `string` | `""` | no |
| secrets\_manager\_auth\_key\_field | JSON key in the Secrets Manager secret that holds the Headscale pre-auth key. | `string` | `"headscale_auth_key"` | no |
| subnet\_id | Private subnet ID for the subnet router instance. | `string` | n/a | yes |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| tailscale\_version | Tailscale client version to install. | `string` | `"1.96.4"` | no |
| use\_spot\_instances | Use spot instances for cost savings (~70% cheaper). Safe because the subnet router is stateless - ASG replaces terminated instances and Tailscale re-registers automatically. | `bool` | `false` | no |
| vpc\_id | VPC ID to deploy the subnet router into. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| alarm\_arn | CloudWatch alarm ARN (null when alarm is disabled) |
| ami\_id | Resolved AMI ID |
| autoscaling\_group\_arn | ASG ARN |
| autoscaling\_group\_name | ASG name |
| iam\_role\_arn | IAM role ARN |
| iam\_role\_name | IAM role name |
| instance\_profile\_arn | Instance profile ARN |
| launch\_template\_id | Launch template ID |
| log\_group\_name | CloudWatch log group name (null when logs are disabled) |
| security\_group\_id | Security group ID |
| sns\_topic\_arn | SNS topic ARN for alarm notifications (null when using existing topic or alarm is disabled) |
<!-- END_TF_DOCS -->

## Examples

## Basic  - route a VPC to the tailnet

```hcl
module "subnet_router" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//headscale/subnet-router?depth=1&ref=master"

  name      = "staging-subnet-router"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.private_subnets[0]

  headscale_server_url = "https://headscale.example.com"
  headscale_auth_key   = var.headscale_auth_key
  advertise_routes     = ["10.20.0.0/16"]

  tags = { Environment = "staging" }
}
```

## Multiple CIDRs

```hcl
module "subnet_router" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//headscale/subnet-router?depth=1&ref=master"

  name      = "prod-subnet-router"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.private_subnets[0]

  headscale_server_url = "https://headscale.example.com"
  headscale_auth_key   = var.headscale_auth_key
  advertise_routes     = ["10.30.0.0/16", "172.16.0.0/12"]
  hostname             = "prod-vpc-router"

  tags = { Environment = "production" }
}
```

## Cross-account deployment

```hcl
# Deploy in a different AWS account using a provider alias
module "dr_subnet_router" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//headscale/subnet-router?depth=1&ref=master"
  providers = { aws = aws.dr_account }

  name      = "dr-subnet-router"
  vpc_id    = module.dr_vpc.vpc_id
  subnet_id = module.dr_vpc.private_subnets[0]

  headscale_server_url = "https://headscale.example.com"
  headscale_auth_key   = var.dr_headscale_auth_key
  advertise_routes     = ["10.254.0.0/16"]
  hostname             = "dr-vpc-router"

  tags = { Environment = "dr" }
}
```

## After deployment

Routes must be approved on the Headscale server:

```bash
# List pending routes
headscale routes list

# Enable a route
headscale routes enable --route <id>

# Verify from a client
tailscale status
tailscale ping <subnet-router-hostname>
```
