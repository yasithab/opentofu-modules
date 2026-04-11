variable "enabled" {
  description = "Controls if subnet router resources should be created."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name for all subnet router resources."
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
  description = "VPC ID to deploy the subnet router into."
  type        = string
}

variable "subnet_id" {
  description = "Private subnet ID for the subnet router instance."
  type        = string
}

variable "additional_security_group_ids" {
  description = "Additional security group IDs to attach to the instance."
  type        = list(string)
  default     = []
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
  description = "Custom AMI ID. When null, the latest Amazon Linux 2023 AMI is auto-detected."
  type        = string
  default     = null
}

variable "ebs_root_volume_size" {
  description = "Root EBS volume size in GB."
  type        = number
  default     = 8
}

variable "encryption" {
  description = "Whether to encrypt the root EBS volume."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for EBS volume encryption. Uses the default EBS key when null."
  type        = string
  default     = null
}

################################################################################
# Headscale / Tailscale
################################################################################

variable "headscale_server_url" {
  description = "Headscale server URL (e.g., 'https://headscale.example.com')."
  type        = string
}

variable "headscale_auth_key" {
  description = "Pre-auth key from Headscale for automatic registration. Leave empty when using secrets_manager_arn. Generate with: headscale preauthkeys create --user <user> --reusable --expiration 87600h"
  type        = string
  sensitive   = true
  default     = ""
}

variable "secrets_manager_arn" {
  description = "ARN of a Secrets Manager secret containing a JSON object with sensitive values. The module reads the auth key from the key specified by secrets_manager_auth_key_field."
  type        = string
  default     = ""
}

variable "secrets_manager_auth_key_field" {
  description = "JSON key in the Secrets Manager secret that holds the Headscale pre-auth key."
  type        = string
  default     = "headscale_auth_key"
}

variable "tailscale_version" {
  description = "Tailscale client version to install."
  type        = string
  default     = "1.96.4"
}

variable "advertise_routes" {
  description = "CIDR ranges to advertise to the tailnet (e.g., ['10.0.0.0/16', '172.16.0.0/12'])."
  type        = list(string)
}

variable "hostname" {
  description = "Tailscale hostname for this subnet router node. Defaults to the instance name."
  type        = string
  default     = ""
}

variable "accept_dns" {
  description = "Whether this node accepts DNS configuration from the tailnet."
  type        = bool
  default     = false
}

################################################################################
# Spot Instances
################################################################################

variable "use_spot_instances" {
  description = "Use spot instances for cost savings (~70% cheaper). Safe because the subnet router is stateless - ASG replaces terminated instances and Tailscale re-registers automatically."
  type        = bool
  default     = false
}

################################################################################
# Exit Node
################################################################################

variable "exit_node_enabled" {
  description = "Advertise this node as a Tailscale exit node. Routes ALL client traffic through this instance (not just subnet routes)."
  type        = bool
  default     = false
}

################################################################################
# CloudWatch Alarm
################################################################################

variable "alarm_enabled" {
  description = "Create a CloudWatch alarm that fires when the subnet router instance is unhealthy."
  type        = bool
  default     = true
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms. Leave empty to create a new topic."
  type        = string
  default     = ""
}

################################################################################
# CloudWatch Logs
################################################################################

variable "cloudwatch_logs_enabled" {
  description = "Export Tailscale and cloud-init logs to CloudWatch Logs."
  type        = bool
  default     = true
}

variable "cloudwatch_logs_retention_days" {
  description = "Number of days to retain CloudWatch logs."
  type        = number
  default     = 30
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
# Extensibility
################################################################################

variable "cloud_init_parts" {
  description = "Additional cloud-init parts to append after the Tailscale setup script."
  type = list(object({
    content      = string
    content_type = string
  }))
  default = []
}
