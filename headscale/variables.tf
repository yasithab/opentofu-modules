variable "enabled" {
  description = "Controls if Headscale resources should be created."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name for all Headscale resources."
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# Networking
################################################################################

variable "vpc_id" {
  description = "VPC ID to deploy Headscale into."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the Headscale instance. Use a public subnet for direct client connectivity."
  type        = string
}

variable "additional_security_group_ids" {
  description = "Additional security group IDs to attach to the Headscale instance."
  type        = list(string)
  default     = []
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with the instance."
  type        = bool
  default     = true
}

################################################################################
# Instance
################################################################################

variable "instance_type" {
  description = "EC2 instance type. Graviton (t4g) recommended for cost savings."
  type        = string
  default     = "t4g.nano"
}

variable "ami_id" {
  description = "Custom AMI ID. When null, the latest Amazon Linux 2023 ARM64 AMI is auto-detected."
  type        = string
  default     = null
}

variable "ebs_root_volume_size" {
  description = "Root EBS volume size in GB."
  type        = number
  default     = 8
}

variable "ebs_data_volume_size" {
  description = "Data EBS volume size in GB for Headscale database and state. Set to 0 to disable."
  type        = number
  default     = 10
}

variable "encryption" {
  description = "Whether to encrypt EBS volumes."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for EBS volume encryption. Uses the default EBS key when null."
  type        = string
  default     = null
}

variable "snapshot_enabled" {
  description = "Enable daily EBS snapshots of the data volume via Amazon Data Lifecycle Manager."
  type        = bool
  default     = true
}

variable "snapshot_retention_days" {
  description = "Number of days to retain daily EBS snapshots."
  type        = number
  default     = 7
}

variable "snapshot_time" {
  description = "UTC time to take daily snapshots in HH:MM format (e.g., '03:00')."
  type        = string
  default     = "03:00"
}

################################################################################
# Headscale Configuration
################################################################################

variable "headscale_version" {
  description = "Headscale version to install (e.g., '0.25.1')."
  type        = string
  default     = "0.28.0"
}

variable "server_url" {
  description = "Public URL for Headscale (e.g., 'https://headscale.example.com'). Clients use this to connect."
  type        = string
}

variable "base_domain" {
  description = "Base domain for MagicDNS (e.g., 'tailnet.example.com'). Devices get <hostname>.<base_domain>."
  type        = string
  default     = ""
}

variable "ip_prefixes" {
  description = "IP prefixes to allocate to Tailscale nodes."
  type        = list(string)
  default     = ["100.64.0.0/10", "fd7a:115c:a1e0::/48"]
}

variable "derp_enabled" {
  description = "Enable the built-in DERP relay server for NAT traversal."
  type        = bool
  default     = true
}

variable "derp_stun_port" {
  description = "STUN port for the built-in DERP server."
  type        = number
  default     = 3478
}

variable "oidc" {
  description = "OIDC configuration for user authentication. Set to null to disable. For client_secret, provide the raw value directly or use secrets_manager_arn + secrets_manager_oidc_key to fetch from Secrets Manager at boot."
  type = object({
    issuer        = string
    client_id     = string
    client_secret = optional(string, "")
    allowed_users = optional(list(string), [])
    expiry        = optional(string, "24h")
  })
  default = null
}

################################################################################
# Secrets Manager (single secret with multiple JSON keys)
################################################################################

variable "secrets_manager_arn" {
  description = "ARN of a Secrets Manager secret containing a JSON object with sensitive values. The module reads specific keys at boot. Leave empty to use inline values instead."
  type        = string
  default     = ""
}

variable "secrets_manager_oidc_key" {
  description = "JSON key in the Secrets Manager secret that holds the OIDC client_secret (e.g., 'oidc_client_secret'). Only used when secrets_manager_arn is set and OIDC is enabled."
  type        = string
  default     = "oidc_client_secret"
}

variable "acl_policy" {
  description = "Headscale ACL policy JSON. When empty, a default allow-all policy is used."
  type        = string
  default     = ""
}

################################################################################
# Elastic IP (stable address across instance replacements)
################################################################################

variable "create_eip" {
  description = "Create an Elastic IP for the Headscale instance. Recommended for production  - keeps the IP stable across instance replacements."
  type        = bool
  default     = false
}

variable "eip_allocation_id" {
  description = "Existing EIP allocation ID to associate. When set, create_eip is ignored."
  type        = string
  default     = ""
}

################################################################################
# DNS (Route53)
################################################################################

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for creating a DNS record. Leave empty to skip."
  type        = string
  default     = ""
}

variable "route53_record_name" {
  description = "DNS record name (e.g., 'headscale'). Combined with the zone to form the FQDN."
  type        = string
  default     = "headscale"
}

variable "route53_private_zone" {
  description = "Whether the Route53 zone is a private hosted zone. When true, the A record uses the instance's private IP."
  type        = bool
  default     = false
}

variable "route53_record_ttl" {
  description = "TTL in seconds for the Route53 DNS record."
  type        = number
  default     = 300
}

################################################################################
# TLS
################################################################################

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS. When empty, Headscale uses built-in Let's Encrypt (requires port 80 open)."
  type        = string
  default     = ""
}

variable "letsencrypt_email" {
  description = "Email for Let's Encrypt certificate registration. Only used when acm_certificate_arn is empty."
  type        = string
  default     = ""
}

################################################################################
# Access Control
################################################################################

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to reach the Headscale HTTPS/gRPC port (443)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

################################################################################
# SSM
################################################################################

variable "attach_ssm_policy" {
  description = "Attach SSM Session Manager permissions to the IAM role for remote access."
  type        = bool
  default     = true
}

################################################################################
# External Subnet Router Key (auto-generate and publish to Secrets Manager)
################################################################################

variable "publish_auth_key" {
  description = "Generate a tagged ephemeral pre-auth key at boot and publish it to Secrets Manager. Used for cross-account subnet router automation."
  type        = bool
  default     = false
}

################################################################################
# Spot Instances
################################################################################

variable "use_spot_instances" {
  description = "Use spot instances for cost savings (~70% cheaper). Safe because ASG replaces terminated instances and EBS data volume persists."
  type        = bool
  default     = false
}

################################################################################
# CloudWatch Alarm
################################################################################

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms (ASG health). Leave empty to create a new topic."
  type        = string
  default     = ""
}

variable "alarm_enabled" {
  description = "Create a CloudWatch alarm that fires when the Headscale instance is unhealthy."
  type        = bool
  default     = true
}

################################################################################
# CloudWatch Logs
################################################################################

variable "cloudwatch_logs_enabled" {
  description = "Export Headscale and cloud-init logs to CloudWatch Logs via the unified CloudWatch agent."
  type        = bool
  default     = true
}

variable "cloudwatch_logs_retention_days" {
  description = "Number of days to retain CloudWatch logs."
  type        = number
  default     = 30
}

################################################################################
# Metrics
################################################################################

variable "metrics_port" {
  description = "Port for Headscale Prometheus metrics endpoint (bound to 127.0.0.1)."
  type        = number
  default     = 9090
}

################################################################################
# Exit Node
################################################################################

variable "exit_node_enabled" {
  description = "Advertise this node as a Tailscale exit node. Routes ALL client traffic through this instance (not just subnet routes). Only used when subnet_router_enabled is true."
  type        = bool
  default     = false
}

################################################################################
# Built-in Subnet Router
################################################################################

variable "subnet_router_enabled" {
  description = "Install Tailscale on the Headscale instance and register it as a subnet router. Exposes the VPC CIDR to all tailnet clients."
  type        = bool
  default     = false
}

variable "subnet_router_advertise_routes" {
  description = "CIDR ranges to advertise via the built-in subnet router (e.g., ['10.0.0.0/16']). Required when subnet_router_enabled is true."
  type        = list(string)
  default     = []
}

variable "subnet_router_user" {
  description = "Headscale user for the built-in subnet router node."
  type        = string
  default     = "subnet-routers"
}

variable "tailscale_version" {
  description = "Tailscale client version to install for the built-in subnet router."
  type        = string
  default     = "1.96.4"
}

################################################################################
# Extensibility
################################################################################

variable "cloud_init_parts" {
  description = "Additional cloud-init parts to append after the Headscale setup script."
  type = list(object({
    content      = string
    content_type = string
  }))
  default = []
}
