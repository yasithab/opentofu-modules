# Headscale

Self-hosted [Headscale](https://github.com/juanfont/headscale) coordination server on AWS EC2  - an open-source, self-hosted implementation of the Tailscale control server.

Headscale lets you use standard **Tailscale clients** (macOS, Windows, Linux, iOS, Android) with your own infrastructure instead of Tailscale's SaaS. No user/device limits, full control over your data.

## Features

- **Self-healing** - ASG (min=1, max=1) automatically replaces failed instances
- **Persistent state** - EBS data volume survives instance replacements (SQLite DB, noise keys, Let's Encrypt certs)
- **Daily snapshots** - DLM lifecycle policy with configurable retention (default 7 days)
- **Stable IP** - Elastic IP self-associates at boot, DNS stays stable across replacements
- **Spot instances** - optional, ~70% cheaper than on-demand (safe with ASG + persistent EBS)
- **Secrets Manager** - sensitive values (OIDC secret, auth keys) fetched at boot, never in user_data or Terraform state

- **Built-in subnet router** - optionally expose the local VPC to all tailnet clients (auto-registered, auto-approved)
- **Exit node** - optionally route ALL client traffic through this instance (not just subnets)
- **Standalone subnet-router sub-module** - deploy in any VPC/account to route its traffic through the tailnet

- **Let's Encrypt TLS** or bring your own ACM certificate
- **OIDC authentication** - Google, Okta, Azure AD, etc.
- **DERP relay** - built-in NAT traversal for clients behind restrictive firewalls
- **MagicDNS** - devices get `<hostname>.<base_domain>` names
- **SSM access** - no SSH keys, connect via `aws ssm start-session`
- **CloudWatch Logs** - setup and headscale logs exported automatically
- **CloudWatch alarm** - alerts when instance is unhealthy via SNS
- **Prometheus metrics** - exposed on configurable port (127.0.0.1 only)
- **Route53 + external DNS** - public zones or `dns_ip` output for Cloudflare, etc.

## Architecture

```
                    ┌──────────────────────────┐
  Tailscale         │  ASG (min=1, max=1)      │
  Clients ──443──▶  │  ┌────────────────────┐  │
  (any OS)          │  │  Headscale (EC2)    │  │
                    │  │  + Tailscale client │  │  ◄── Elastic IP (stable)
                    │  │    (subnet router)  │  │
                    │  └────────┬───────────┘  │
                    └───────────┼──────────────┘
                                │
                    ┌───────────┼──────────────┐
                    │  /opt/headscale (EBS)    │  ◄── Persistent data volume
                    │  ├── headscale.db        │      (survives replacements)
                    │  ├── noise_private.key   │
                    │  └── cache/ (LE certs)   │
                    └──────────────────────────┘
```

### Recovery flow (instance failure)

```
Instance dies
  → ASG launches replacement (~2-3 min)
  → New instance runs cloud-init:
      1. Self-associates Elastic IP (public IP restored)
      2. Waits for old volume to detach, self-attaches EBS data volume
      3. Mounts existing filesystem (DB + keys + certs preserved)
      4. Starts Headscale (picks up existing state)
      5. Re-registers subnet router (if enabled)
  → Clients reconnect automatically via DERP
```

## Prerequisites

### 1. Secrets Manager secret (recommended for production)

Create a single Secrets Manager secret containing a JSON object with all sensitive values. The module reads specific keys at boot time.

**Secret format:**

```json
{
  "oidc_client_secret": "your-oidc-client-secret-here",
  "headscale_auth_key": "your-pre-auth-key-here"
}
```

**Key names** (configurable via variables):

| Key | Default field name | Used by | Purpose |
|-----|-------------------|---------|---------|
| OIDC client secret | `oidc_client_secret` | Main module (`secrets_manager_oidc_key`) | OIDC authentication |
| Pre-auth key | `headscale_auth_key` | Subnet-router sub-module (`secrets_manager_auth_key_field`) | Auto-registration |

**Terraform example:**

```hcl
resource "aws_secretsmanager_secret" "headscale" {
  name = "headscale/config"
}

resource "aws_secretsmanager_secret_version" "headscale" {
  secret_id = aws_secretsmanager_secret.headscale.id
  secret_string = jsonencode({
    oidc_client_secret = var.oidc_client_secret
    headscale_auth_key = var.headscale_auth_key
  })
}
```

Pass `secrets_manager_arn = aws_secretsmanager_secret.headscale.arn` to the module. The module grants itself `secretsmanager:GetSecretValue` on this specific ARN only.

### 2. Elastic IP (recommended for production)

Set `create_eip = true` to create a new EIP, or pass `eip_allocation_id` for an existing one. Without an EIP, the public IP changes on every instance replacement, breaking DNS and client connectivity.

### 3. DNS

Three options - pick one:

**Option A - Route53 (public zone):**

```hcl
route53_zone_id     = "Z1234567890"
route53_record_name = "headscale"
```

The module creates an A record pointing to the EIP.

**Option B - Route53 (private zone):**

Not supported with ASG-based deployment (no static private IP). Use a separate ALB/NLB in front of the ASG for private deployments.

**Option C - External DNS (Cloudflare, GoDaddy, Namecheap, etc.):**

Skip `route53_zone_id` entirely. Use the `dns_ip` output to configure your DNS provider:

```hcl
module "headscale" {
  # ...
  create_eip = true  # Stable IP for external DNS
  # No route53_zone_id - manage DNS externally
}

# Cloudflare
resource "cloudflare_record" "headscale" {
  zone_id = var.cloudflare_zone_id
  name    = "headscale"
  content = module.headscale.dns_ip
  type    = "A"
  ttl     = 300
}

# Or any other provider - just use module.headscale.dns_ip
# GoDaddy, Namecheap, DigitalOcean, etc.

# Or output for manual DNS setup
output "headscale_ip" {
  value = module.headscale.dns_ip
}
```

### 4. TLS

**Let's Encrypt (default):** Set `letsencrypt_email`. Requires port 80 open (automatically configured) and a public IP. Certs persist on the EBS data volume.

**ACM:** Set `acm_certificate_arn`. Use when Headscale is behind a load balancer that terminates TLS.

### 5. Pre-auth key for standalone subnet routers

Generate on the Headscale server after first deployment:

```bash
aws ssm start-session --target <instance-id>
sudo headscale users create subnet-routers
sudo headscale preauthkeys create --user subnet-routers --reusable --expiration 87600h
```

Store the key in the Secrets Manager secret under the `headscale_auth_key` field.

## Usage

### Upgrade notes (BREAKING)

- **`allowed_cidr_blocks` now defaults to `[]`** (was `["0.0.0.0/0"]`). You must explicitly
  allow client networks to reach port 443; set `allowed_cidr_blocks = ["0.0.0.0/0"]` to keep
  the previous public behaviour.
- **HTTPS ingress rules are now keyed by CIDR value** instead of list index. Existing
  `aws_vpc_security_group_ingress_rule.https` entries are re-created on the next apply, or
  move them explicitly:

  ```hcl
  moved {
    from = module.headscale.aws_vpc_security_group_ingress_rule.https["0"]
    to   = module.headscale.aws_vpc_security_group_ingress_rule.https["203.0.113.0/24"]
  }
  ```

### Minimal (development)

```hcl
module "headscale" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//headscale?depth=1&ref=master"

  name              = "dev-headscale"
  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.public_subnets[0]
  server_url        = "https://headscale.dev.example.com"
  letsencrypt_email = "admin@example.com"
}
```

### Production (all features)

```hcl
module "headscale" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//headscale?depth=1&ref=master"

  name      = "headscale"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnets[0]

  # Core
  server_url        = "https://headscale.example.com"
  base_domain       = "tailnet.example.com"
  letsencrypt_email = "admin@example.com"
  create_eip        = true
  use_spot_instances = true  # ~70% cheaper

  # DNS
  route53_zone_id     = module.dns.zone_id
  route53_record_name = "headscale"

  # OIDC
  oidc = {
    issuer    = "https://accounts.google.com"
    client_id = "xxxx.apps.googleusercontent.com"
  }

  # Secrets Manager
  secrets_manager_arn = aws_secretsmanager_secret.headscale.arn

  # Subnet router + exit node
  subnet_router_enabled          = true
  subnet_router_advertise_routes = ["10.0.0.0/16"]
  exit_node_enabled              = true

  # Snapshots
  snapshot_retention_days = 30

  # Alarm
  alarm_sns_topic_arn = aws_sns_topic.infra_alerts.arn

  tags = { Environment = "production" }
}
```

### Standalone subnet router (different VPC/account)

```hcl
module "subnet_router" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//headscale/subnet-router?depth=1&ref=master"

  name                 = "staging-router"
  vpc_id               = module.vpc.vpc_id
  subnet_id            = module.vpc.private_subnets[0]
  headscale_server_url = "https://headscale.example.com"
  advertise_routes     = ["10.20.0.0/16"]
  secrets_manager_arn  = aws_secretsmanager_secret.headscale.arn
}
```

## Connecting Tailscale clients

```bash
# Install Tailscale from https://tailscale.com/download
# Connect to your Headscale server
tailscale up --login-server https://headscale.example.com --authkey <pre-auth-key>
```

Works with all Tailscale apps  - macOS, Windows, Linux, iOS, Android.

## Sub-modules

| Module | Purpose |
|--------|---------|
| `headscale/` | Coordination server (this module) |
| `headscale/subnet-router/` | Standalone Tailscale subnet router for remote VPCs/accounts |


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
| acl\_policy | Headscale ACL policy JSON. When empty, a default allow-all policy is used. | `string` | `""` | no |
| acm\_certificate\_arn | ACM certificate ARN for HTTPS. When empty, Headscale uses built-in Let's Encrypt (requires port 80 open). | `string` | `""` | no |
| additional\_security\_group\_ids | Additional security group IDs to attach to the Headscale instance. | `list(string)` | `[]` | no |
| alarm\_enabled | Create a CloudWatch alarm that fires when the Headscale instance is unhealthy. | `bool` | `true` | no |
| alarm\_sns\_topic\_arn | SNS topic ARN for CloudWatch alarms (ASG health). Leave empty to create a new topic. | `string` | `""` | no |
| allowed\_cidr\_blocks | CIDR blocks allowed to reach the Headscale HTTPS/gRPC port (443). Empty by default - you must explicitly allow client networks (use ["0.0.0.0/0"] for a public coordination server). | `list(string)` | `[]` | no |
| ami\_id | Custom AMI ID. When null, the latest Amazon Linux 2023 ARM64 AMI is auto-detected. | `string` | `null` | no |
| associate\_public\_ip\_address | Whether to associate a public IP address with the instance. | `bool` | `true` | no |
| attach\_ssm\_policy | Attach SSM Session Manager permissions to the IAM role for remote access. | `bool` | `true` | no |
| base\_domain | Base domain for MagicDNS (e.g., 'tailnet.example.com'). Devices get <hostname>.<base\_domain>. | `string` | `""` | no |
| cloud\_init\_parts | Additional cloud-init parts to append after the Headscale setup script. | <pre>list(object({<br/>    content      = string<br/>    content_type = string<br/>  }))</pre> | `[]` | no |
| cloudwatch\_logs\_enabled | Export Headscale and cloud-init logs to CloudWatch Logs via the unified CloudWatch agent. | `bool` | `true` | no |
| cloudwatch\_logs\_kms\_key\_id | KMS key ARN for encrypting the Headscale CloudWatch log group. Uses default CloudWatch encryption when null. | `string` | `null` | no |
| cloudwatch\_logs\_retention\_days | Number of days to retain CloudWatch logs. | `number` | `30` | no |
| create\_eip | Create an Elastic IP for the Headscale instance. Recommended for production  - keeps the IP stable across instance replacements. | `bool` | `false` | no |
| derp\_enabled | Enable the built-in DERP relay server for NAT traversal. | `bool` | `true` | no |
| derp\_stun\_port | STUN port for the built-in DERP server. | `number` | `3478` | no |
| ebs\_data\_volume\_size | Data EBS volume size in GB for Headscale database and state. Set to 0 to disable. | `number` | `10` | no |
| ebs\_root\_volume\_size | Root EBS volume size in GB. | `number` | `8` | no |
| eip\_allocation\_id | Existing EIP allocation ID to associate. When set, create\_eip is ignored. | `string` | `""` | no |
| enable\_instance\_refresh | Enable ASG instance refresh (rolling, 90% min healthy) so launch template changes roll out automatically. | `bool` | `true` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| encryption | Whether to encrypt EBS volumes. | `bool` | `true` | no |
| exit\_node\_enabled | Advertise this node as a Tailscale exit node. Routes ALL client traffic through this instance (not just subnet routes). Only used when subnet\_router\_enabled is true. | `bool` | `false` | no |
| headscale\_version | Headscale version to install (e.g., '0.25.1'). | `string` | `"0.28.0"` | no |
| instance\_type | EC2 instance type. Graviton (t4g) recommended for cost savings. | `string` | `"t4g.nano"` | no |
| ip\_prefixes | IP prefixes to allocate to Tailscale nodes. | `list(string)` | <pre>[<br/>  "100.64.0.0/10",<br/>  "fd7a:115c:a1e0::/48"<br/>]</pre> | no |
| kms\_key\_id | KMS key ID for EBS volume encryption. Uses the default EBS key when null. | `string` | `null` | no |
| letsencrypt\_email | Email for Let's Encrypt certificate registration. Only used when acm\_certificate\_arn is empty. | `string` | `""` | no |
| metrics\_port | Port for Headscale Prometheus metrics endpoint (bound to 127.0.0.1). | `number` | `9090` | no |
| name | Name for all Headscale resources. | `string` | n/a | yes |
| oidc | OIDC configuration for user authentication. Set to null to disable. WARNING: an inline client\_secret is rendered into the instance user\_data and stored in OpenTofu state; prefer secrets\_manager\_arn + secrets\_manager\_oidc\_key to fetch it from Secrets Manager at boot. | <pre>object({<br/>    issuer        = string<br/>    client_id     = string<br/>    client_secret = optional(string, "")<br/>    allowed_users = optional(list(string), [])<br/>    expiry        = optional(string, "24h")<br/>  })</pre> | `null` | no |
| publish\_auth\_key | Generate a tagged ephemeral pre-auth key at boot and publish it to Secrets Manager. Used for cross-account subnet router automation. | `bool` | `false` | no |
| route53\_private\_zone | Whether the Route53 zone is a private hosted zone. When true, the A record uses the instance's private IP. | `bool` | `false` | no |
| route53\_record\_name | DNS record name (e.g., 'headscale'). Combined with the zone to form the FQDN. | `string` | `"headscale"` | no |
| route53\_record\_ttl | TTL in seconds for the Route53 DNS record. | `number` | `300` | no |
| route53\_zone\_id | Route53 hosted zone ID for creating a DNS record. Leave empty to skip. | `string` | `""` | no |
| secrets\_manager\_arn | ARN of a Secrets Manager secret containing a JSON object with sensitive values. The module reads specific keys at boot. Leave empty to use inline values instead. | `string` | `""` | no |
| secrets\_manager\_oidc\_key | JSON key in the Secrets Manager secret that holds the OIDC client\_secret (e.g., 'oidc\_client\_secret'). Only used when secrets\_manager\_arn is set and OIDC is enabled. | `string` | `"oidc_client_secret"` | no |
| server\_url | Public URL for Headscale (e.g., 'https://headscale.example.com'). Clients use this to connect. | `string` | n/a | yes |
| snapshot\_enabled | Enable daily EBS snapshots of the data volume via Amazon Data Lifecycle Manager. | `bool` | `true` | no |
| snapshot\_retention\_days | Number of days to retain daily EBS snapshots. | `number` | `7` | no |
| snapshot\_time | UTC time to take daily snapshots in HH:MM format (e.g., '03:00'). | `string` | `"03:00"` | no |
| subnet\_id | Subnet ID for the Headscale instance. Use a public subnet for direct client connectivity. | `string` | n/a | yes |
| subnet\_router\_advertise\_routes | CIDR ranges to advertise via the built-in subnet router (e.g., ['10.0.0.0/16']). Required when subnet\_router\_enabled is true. | `list(string)` | `[]` | no |
| subnet\_router\_enabled | Install Tailscale on the Headscale instance and register it as a subnet router. Exposes the VPC CIDR to all tailnet clients. | `bool` | `false` | no |
| subnet\_router\_user | Headscale user for the built-in subnet router node. | `string` | `"subnet-routers"` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| tailscale\_version | Tailscale client version to install for the built-in subnet router. | `string` | `"1.96.4"` | no |
| use\_spot\_instances | Use spot instances for cost savings (~70% cheaper). Safe because ASG replaces terminated instances and EBS data volume persists. | `bool` | `false` | no |
| vpc\_id | VPC ID to deploy Headscale into. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| alarm\_arn | CloudWatch alarm ARN (null when alarm is disabled) |
| ami\_id | Resolved AMI ID |
| autoscaling\_group\_arn | ASG ARN |
| autoscaling\_group\_name | ASG name |
| data\_volume\_id | EBS data volume ID (null when data volume is disabled) |
| dns\_fqdn | Fully qualified domain name (when Route53 is configured) |
| dns\_ip | IP address used for DNS records. Use this to configure external DNS providers (Cloudflare, etc.). Returns EIP public IP. |
| eip\_allocation\_id | Elastic IP allocation ID (null when EIP is not used) |
| eip\_public\_ip | Elastic IP address (null when EIP is not used). Returns the IP for both created and existing EIPs. |
| iam\_role\_arn | IAM role ARN |
| iam\_role\_name | IAM role name |
| instance\_profile\_arn | Instance profile ARN |
| launch\_template\_id | Launch template ID |
| log\_group\_name | CloudWatch log group name (null when logs are disabled) |
| metrics\_url | Prometheus metrics endpoint URL (accessible only from the instance itself via SSM) |
| security\_group\_id | Security group ID |
| server\_url | Headscale server URL for client configuration |
| snapshot\_policy\_id | DLM lifecycle policy ID for data volume snapshots (null when snapshots are disabled) |
| sns\_topic\_arn | SNS topic ARN for alarm notifications (null when using existing topic or alarm is disabled) |
<!-- END_TF_DOCS -->

## Examples

## Basic  - Public instance with Let's Encrypt

```hcl
module "headscale" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//headscale?depth=1&ref=master"

  name      = "mycompany-headscale"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnets[0]

  server_url        = "https://headscale.example.com"
  base_domain       = "tailnet.example.com"
  letsencrypt_email = "admin@example.com"

  route53_zone_id     = module.dns.zone_id
  route53_record_name = "headscale"

  tags = { Environment = "production" }
}
```

## With OIDC (Google, Okta, etc.)

> **WARNING:** an inline `oidc.client_secret` is rendered into the instance **user_data**
> and stored in **OpenTofu state** (the variable is marked `sensitive`, which hides it from
> CLI output but does not encrypt it). For production, omit `client_secret` and use
> `secrets_manager_arn` + `secrets_manager_oidc_key` so the secret is fetched at boot and
> never touches user_data or state.

```hcl
module "headscale" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//headscale?depth=1&ref=master"

  name      = "mycompany-headscale"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnets[0]

  server_url        = "https://headscale.example.com"
  base_domain       = "tailnet.example.com"
  letsencrypt_email = "admin@example.com"

  oidc = {
    issuer        = "https://accounts.google.com"
    client_id     = "xxxx.apps.googleusercontent.com"
    client_secret = var.oidc_client_secret
    allowed_users = ["admin@example.com"]
  }

  tags = { Environment = "production" }
}
```

## Private subnet (no public IP)

```hcl
module "headscale" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//headscale?depth=1&ref=master"

  name      = "mycompany-headscale"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.private_subnets[0]

  associate_public_ip_address = false
  server_url                  = "https://headscale.example.com"

  # Use ACM + ALB for TLS termination instead of Let's Encrypt
  acm_certificate_arn = aws_acm_certificate.headscale.arn

  tags = { Environment = "production" }
}
```

## Production with Elastic IP + Route53

Elastic IP keeps the address stable across instance replacements  - critical for production DNS.

```hcl
module "headscale" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//headscale?depth=1&ref=master"

  name      = "mycompany-headscale"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnets[0]

  server_url        = "https://headscale.example.com"
  base_domain       = "tailnet.example.com"
  letsencrypt_email = "admin@example.com"

  # Stable IP  - survives instance replacement
  create_eip = true

  # Route53 public zone
  route53_zone_id     = module.dns.zone_id
  route53_record_name = "headscale"

  tags = { Environment = "production" }
}
```

## Private hosted zone (internal DNS)

```hcl
module "headscale" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//headscale?depth=1&ref=master"

  name      = "mycompany-headscale"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.private_subnets[0]

  associate_public_ip_address = false
  server_url                  = "https://headscale.internal.example.com"
  acm_certificate_arn         = aws_acm_certificate.headscale.arn

  # Route53 private zone  - uses private IP
  route53_zone_id      = module.dns.private_zone_id
  route53_record_name  = "headscale"
  route53_private_zone = true

  tags = { Environment = "production" }
}
```

## External DNS (Cloudflare, GoDaddy, etc.)

Skip Route53  - use the `dns_ip` output to configure your external provider.

```hcl
module "headscale" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//headscale?depth=1&ref=master"

  name      = "mycompany-headscale"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnets[0]

  server_url        = "https://headscale.example.com"
  letsencrypt_email = "admin@example.com"
  create_eip        = true  # Stable IP for external DNS

  # No route53_zone_id  - manage DNS externally
}

# Cloudflare example
resource "cloudflare_record" "headscale" {
  zone_id = var.cloudflare_zone_id
  name    = "headscale"
  content = module.headscale.dns_ip
  type    = "A"
  ttl     = 300
}

# Or output for manual DNS configuration
output "headscale_ip" {
  value = module.headscale.dns_ip
}
```

## Minimal (development)

```hcl
module "headscale" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//headscale?depth=1&ref=master"

  name               = "dev-headscale"
  vpc_id             = module.vpc.vpc_id
  subnet_id          = module.vpc.public_subnets[0]
  server_url         = "https://headscale.dev.example.com"
  letsencrypt_email  = "admin@example.com"
  ebs_data_volume_size = 0  # No separate data volume
}
```

## Built-in subnet router (same instance as Headscale)

Routes are automatically advertised and approved  - no manual steps needed.

```hcl
module "headscale" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//headscale?depth=1&ref=master"

  name      = "mycompany-headscale"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnets[0]

  server_url        = "https://headscale.example.com"
  base_domain       = "tailnet.example.com"
  letsencrypt_email = "admin@example.com"

  # Built-in subnet router  - exposes this VPC to all tailnet clients
  subnet_router_enabled          = true
  subnet_router_advertise_routes = ["10.0.0.0/16"]

  tags = { Environment = "production" }
}
```

## Standalone subnet router (different VPC or AWS account)

Deploy in any VPC to give tailnet clients access to that VPC's resources.
Requires a pre-auth key from the Headscale server.

```hcl
# Generate a pre-auth key on the Headscale server first:
#   headscale users create subnet-routers
#   headscale preauthkeys create --user subnet-routers --reusable --expiration 87600h

module "staging_router" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//headscale/subnet-router?depth=1&ref=master"

  name      = "staging-subnet-router"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.private_subnets[0]

  headscale_server_url = "https://headscale.example.com"
  headscale_auth_key   = var.headscale_auth_key  # Store in Secrets Manager or tfvars
  advertise_routes     = ["10.20.0.0/16"]

  tags = { Environment = "staging" }
}
```

After deployment, approve the routes on the Headscale server:
```bash
headscale routes list
headscale routes enable --route <id>
```

## Multi-account architecture

```
                  ┌─────────────────────┐
                  │  Management Account │
                  │                     │
                  │  Headscale server   │
                  │  + built-in router  │◄── Your laptop (Tailscale)
                  │  VPC: 10.0.0.0/16  │
                  └─────────────────────┘
                            │
              ┌─────────────┴──────────────┐
              │                            │
   ┌──────────▼──────────┐    ┌────────────▼────────────┐
   │  Staging Account    │    │  Production Account     │
   │                     │    │                         │
   │  subnet-router      │    │  subnet-router          │
   │  VPC: 10.20.0.0/16 │    │  VPC: 10.30.0.0/16     │
   │  → RDS, ECS, etc.  │    │  → RDS, ECS, etc.      │
   └─────────────────────┘    └─────────────────────────┘
```

```hcl
# Management account  - Headscale server with built-in router
module "headscale" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//headscale?depth=1&ref=master"

  name                           = "headscale"
  vpc_id                         = module.mgmt_vpc.vpc_id
  subnet_id                      = module.mgmt_vpc.public_subnets[0]
  server_url                     = "https://headscale.example.com"
  letsencrypt_email              = "admin@example.com"
  subnet_router_enabled          = true
  subnet_router_advertise_routes = ["10.0.0.0/16"]
}

# Staging account  - standalone subnet router
module "staging_router" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//headscale/subnet-router?depth=1&ref=master"
  providers = { aws = aws.staging }

  name                 = "staging-router"
  vpc_id               = module.staging_vpc.vpc_id
  subnet_id            = module.staging_vpc.private_subnets[0]
  headscale_server_url = "https://headscale.example.com"
  headscale_auth_key   = var.staging_auth_key
  advertise_routes     = ["10.20.0.0/16"]
}

# Production account  - standalone subnet router
module "prod_router" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//headscale/subnet-router?depth=1&ref=master"
  providers = { aws = aws.production }

  name                 = "prod-router"
  vpc_id               = module.prod_vpc.vpc_id
  subnet_id            = module.prod_vpc.private_subnets[0]
  headscale_server_url = "https://headscale.example.com"
  headscale_auth_key   = var.prod_auth_key
  advertise_routes     = ["10.30.0.0/16"]
}
```

---

## Connecting Tailscale clients to Headscale

### 1. Create a user on the server

```bash
# SSM into the instance
aws ssm start-session --target <instance-id>

# Create a user
sudo headscale users create myuser
```

### 2. Generate a pre-auth key

```bash
sudo headscale preauthkeys create --user myuser --reusable --expiration 24h
# Output: <pre-auth-key>
```

### 3. Connect clients

**macOS / Linux / Windows:**

```bash
# Install Tailscale client from https://tailscale.com/download

# Connect to your Headscale server
tailscale up --login-server https://headscale.example.com --authkey <pre-auth-key>
```

**iOS / Android:**

1. Install the Tailscale app from the App Store / Play Store
2. Open the app, tap the three dots menu → "Use custom coordination server"
3. Enter your Headscale URL: `https://headscale.example.com`
4. Authenticate (if OIDC is configured, it will redirect to your identity provider)

### 4. Verify connectivity

```bash
# Check status
tailscale status

# Ping another node
tailscale ping <other-node-name>

# Access a node by MagicDNS name (if base_domain is configured)
ssh user@myserver.tailnet.example.com
```

### 5. Subnet routing (expose VPC resources)

**Option A: Automatic (recommended)**  - use `subnet_router_enabled = true` on the Headscale module or deploy the `subnet-router` sub-module. Routes are advertised and approved automatically at boot.

**Option B: Manual**  - on any Tailscale node inside your VPC:

```bash
# Advertise VPC CIDR to the tailnet
tailscale up --login-server https://headscale.example.com \
  --authkey <key> \
  --advertise-routes=10.0.0.0/16

# Approve the route on the server
sudo headscale routes enable --route <route-id>
```

Once routes are active, all Tailscale clients can access VPC resources (RDS, ECS, internal ALBs, etc.) as if they were on the local network.
