variable "enabled" {
  description = "Set to false to disable all resources in this module."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name for the conformance pack."
  type        = string
}

# -- Template -----------------------------------------------------------------

variable "template_body" {
  description = <<-EOT
    Inline YAML or JSON template body for the conformance pack.
    Exactly one of template_body or template_s3_uri must be provided.
  EOT
  type        = string
  default     = null
}

variable "template_s3_uri" {
  description = <<-EOT
    S3 URI (s3://bucket/key) of the conformance pack template.
    Exactly one of template_body or template_s3_uri must be provided.
  EOT
  type        = string
  default     = null
}

# -- Parameters ---------------------------------------------------------------

variable "input_parameters" {
  description = "Map of parameter name to value passed to the conformance pack template."
  type        = map(string)
  default     = {}
}

# -- Account-level pack -------------------------------------------------------

variable "delivery_s3_bucket" {
  description = "S3 bucket for conformance pack results. Required for organization conformance packs."
  type        = string
  default     = null
}

variable "delivery_s3_key_prefix" {
  description = "S3 key prefix for conformance pack delivery."
  type        = string
  default     = null
}

# -- Organization conformance pack --------------------------------------------

variable "create_organization_conformance_pack" {
  description = <<-EOT
    Set to true to create an aws_config_organization_conformance_pack instead of
    an account-level aws_config_conformance_pack. Requires AWS Organizations and
    that AWS Config is enabled in all member accounts.
  EOT
  type        = bool
  default     = false
}

variable "excluded_account_ids" {
  description = "List of AWS account IDs to exclude from the organization conformance pack."
  type        = list(string)
  default     = []
}
