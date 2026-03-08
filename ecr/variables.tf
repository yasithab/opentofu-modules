
variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "enabled" {
  description = "Determines whether resources will be created (affects all resources)"
  type        = bool
  default     = true
}

variable "repository_type" {
  description = "The type of repository to create. Either `public` or `private`"
  type        = string
  default     = "private"
}

################################################################################
# Repository
################################################################################

variable "create_repository" {
  description = "Determines whether a repository will be created"
  type        = bool
  default     = true
}

variable "repository_name" {
  description = "The name of the repository"
  type        = string
  default     = null
}

variable "repository_image_tag_mutability" {
  description = "The tag mutability setting for the repository. Must be one of: `MUTABLE`, `IMMUTABLE`, `IMMUTABLE_WITH_EXCLUSION`, or `MUTABLE_WITH_EXCLUSION`. Defaults to `IMMUTABLE`"
  type        = string
  default     = "IMMUTABLE"
}

variable "repository_image_tag_mutability_exclusion_filters" {
  description = "List of image tag mutability exclusion filter blocks. Each block requires `filter` (pattern string) and optionally `filter_type` (default: WILDCARD). Only applicable when `repository_image_tag_mutability` is `IMMUTABLE_WITH_EXCLUSION` or `MUTABLE_WITH_EXCLUSION`."
  type        = any
  default     = []
}

variable "repository_encryption_type" {
  description = "The encryption type for the repository. Must be one of: `KMS` or `AES256`. Defaults to `AES256`"
  type        = string
  default     = null
}

variable "repository_kms_key" {
  description = "The ARN of the KMS key to use when encryption_type is `KMS`. If not specified, uses the default AWS managed key for ECR"
  type        = string
  default     = null
}

variable "repository_image_scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository (`true`) or not scanned (`false`)"
  type        = bool
  default     = true
}

variable "repository_policy" {
  description = "The JSON policy to apply to the repository. If not specified, uses the default policy"
  type        = string
  default     = null
}

variable "repository_force_delete" {
  description = "If `true`, will delete the repository even if it contains images. Defaults to `false`"
  type        = bool
  default     = null
}

################################################################################
# Repository Policy
################################################################################

variable "attach_repository_policy" {
  description = "Determines whether a repository policy will be attached to the repository"
  type        = bool
  default     = true
}

variable "create_repository_policy" {
  description = "Determines whether a repository policy will be created"
  type        = bool
  default     = true
}

variable "repository_read_access_arns" {
  description = "The ARNs of the IAM users/roles that have read access to the repository"
  type        = list(string)
  default     = []
}

variable "repository_lambda_read_access_arns" {
  description = "The ARNs of the Lambda service roles that have read access to the repository"
  type        = list(string)
  default     = []
}

variable "repository_read_write_access_arns" {
  description = "The ARNs of the IAM users/roles that have read/write access to the repository"
  type        = list(string)
  default     = []
}

variable "repository_policy_statements" {
  description = "A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage"
  type        = any
  default     = {}
}

################################################################################
# Lifecycle Policy
################################################################################

variable "create_lifecycle_policy" {
  description = "Determines whether a lifecycle policy will be created"
  type        = bool
  default     = true
}

variable "repository_lifecycle_policy" {
  description = "The policy document. This is a JSON formatted string. See more details about [Policy Parameters](http://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html#lifecycle_policy_parameters) in the official AWS docs"
  type        = string
  default     = null
}

################################################################################
# Public Repository
################################################################################

variable "public_repository_catalog_data" {
  description = "Catalog data configuration for the repository"
  type        = any
  default     = {}
}

################################################################################
# Registry Policy
################################################################################

variable "create_registry_policy" {
  description = "Determines whether a registry policy will be created"
  type        = bool
  default     = false
}

variable "registry_policy" {
  description = "The policy document. This is a JSON formatted string"
  type        = string
  default     = null
}

################################################################################
# Registry Pull Through Cache Rule
################################################################################

variable "registry_pull_through_cache_rules" {
  description = "Map of pull through cache rules to create. Each key is a unique identifier. Supports: ecr_repository_prefix (required), upstream_registry_url (required), credential_arn (optional), custom_role_arn (optional), upstream_repository_prefix (optional)."
  type        = any
  default     = {}
}

################################################################################
# Registry Scanning Configuration
################################################################################

variable "manage_registry_scanning_configuration" {
  description = "Determines whether the registry scanning configuration will be managed"
  type        = bool
  default     = false
}

variable "registry_scan_type" {
  description = "the scanning type to set for the registry. Can be either `ENHANCED` or `BASIC`"
  type        = string
  default     = "ENHANCED"
}

variable "registry_scan_rules" {
  description = "One or multiple blocks specifying scanning rules to determine which repository filters are used and at what frequency scanning will occur"
  type        = any
  default     = []
}

################################################################################
# Registry Replication Configuration
################################################################################

variable "create_registry_replication_configuration" {
  description = "Determines whether a registry replication configuration will be created"
  type        = bool
  default     = false
}

variable "registry_replication_rules" {
  description = "The replication rules for a replication configuration. A maximum of 10 are allowed"
  type        = any
  default     = []
}
