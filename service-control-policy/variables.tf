variable "name" {
  description = "Name to use for resource naming and tagging."
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "description" {
  default     = null
  description = "Description of the tag policy"
  type        = string
}

variable "attach_ous" {
  type        = list(string)
  description = "List of OU IDs to attach the tag policies to"
  default     = []

  validation {
    condition     = var.attach_to_org || length(var.attach_ous) > 0
    error_message = "attach_ous must have at least one OU if attach_to_org is false."
  }

  validation {
    condition     = var.attach_to_org || length([for ou in var.attach_ous : ou if can(regex("^ou-[0-9a-z]+-[0-9a-z]+$", ou))]) == length(var.attach_ous)
    error_message = "Each OU ID must match the pattern 'ou-' followed by alphanumeric characters with an optional hyphen."
  }
}

variable "attach_to_org" {
  default     = false
  description = "Whether to attach the tag policy to the organization (set to false if you want to attach to OUs)"
  type        = bool
}

variable "deny_all" {
  description = "If false, create a combined policy. If true, deny all access"
  default     = false
  type        = bool
}

variable "skip_destroy" {
  description = "If set to true, the policy will not be deleted when the resource is destroyed. This is useful to prevent accidental deletion of SCPs that are attached to the organization."
  type        = bool
  default     = false
}

# Policy Statement Variables
variable "deny_leaving_orgs" {
  description = "Deny leaving AWS Organizations"
  default     = false
  type        = bool
}

variable "deny_creating_iam_users" {
  description = "Deny creating IAM users"
  default     = false
  type        = bool
}

variable "deny_deleting_kms_keys" {
  description = "Deny deleting KMS keys"
  default     = false
  type        = bool
}

variable "deny_deleting_route53_zones" {
  description = "Deny deleting Route53 zones"
  default     = false
  type        = bool
}

variable "deny_deleting_cloudwatch_logs" {
  description = "Deny deleting CloudWatch logs"
  default     = false
  type        = bool
}

variable "deny_root_account" {
  description = "Deny root account access"
  default     = false
  type        = bool
}

variable "protect_s3_buckets" {
  description = "Protect S3 buckets from deletion"
  default     = false
  type        = bool
}

variable "deny_s3_buckets_public_access" {
  description = "Deny S3 buckets public access"
  default     = false
  type        = bool
}

variable "protect_iam_roles" {
  description = "Protect IAM roles from modification"
  default     = false
  type        = bool
}

variable "limit_ec2_instance_types" {
  description = "Limit allowed EC2 instance types"
  default     = false
  type        = bool
}

variable "limit_regions" {
  description = "Limit allowed AWS regions"
  default     = false
  type        = bool
}

variable "require_s3_encryption" {
  description = "Require S3 bucket encryption"
  default     = false
  type        = bool
}

variable "deny_network_modifications" {
  description = "Deny modifications to network ACLs and security groups"
  default     = false
  type        = bool
}

variable "deny_vpc_modifications" {
  description = "Deny modifications to VPC configurations"
  default     = false
  type        = bool
}

variable "require_mfa" {
  description = "Require Multi-Factor Authentication for sensitive actions"
  default     = false
  type        = bool
}

variable "enforce_cloudtrail_logging" {
  description = "Enforce continuous CloudTrail logging"
  default     = false
  type        = bool
}

variable "enforce_resource_tagging" {
  description = "Enforce tagging on resource creation"
  default     = false
  type        = bool
}

variable "required_tag_keys" {
  description = "List of tags to enforce on resources"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.required_tag_keys) > 0 == var.enforce_resource_tagging
    error_message = "When enforce_resource_tagging is true, required_tag_keys must not be empty."
  }
}

variable "tag_enforcement_actions" {
  description = "List of actions to enforce tagging on"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.tag_enforcement_actions) > 0 == var.enforce_resource_tagging
    error_message = "When enforce_tag_resource_tagging is true, tag_enforcement_actions must not be empty."
  }
}

# Resource-specific variables
variable "protect_s3_bucket_resources" {
  description = "S3 bucket resource ARNs to protect"
  type        = list(string)
  default     = []
}

variable "deny_s3_bucket_public_access_resources" {
  description = "S3 bucket resource ARNs to block public access"
  type        = list(string)
  default     = []
}

variable "protect_iam_role_resources" {
  description = "IAM role resource ARNs to protect"
  type        = list(string)
  default     = []
}

variable "allowed_regions" {
  description = "AWS Regions allowed for use"
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.allowed_regions) > 0 == var.limit_regions
    error_message = "When limit_regions is true, at least one region must be specified."
  }
}

variable "allowed_ec2_instance_types" {
  description = "EC2 instance types allowed for use"
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.allowed_ec2_instance_types) > 0 == var.limit_ec2_instance_types
    error_message = "When limit_ec2_instance_types is true, at least one EC2 instance type must be specified."
  }
}
