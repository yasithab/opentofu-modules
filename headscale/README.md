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
