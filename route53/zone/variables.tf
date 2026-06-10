variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}


variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "zones" {
  description = <<-EOT
    Map of Route53 zone parameters. Set `dnssec` to enable DNSSEC signing for a public zone
    (the KMS key must be an asymmetric ECC_NIST_P256 customer-managed key in us-east-1).
    Set `query_logging` to enable DNS query logging - either supply an existing log group ARN
    or let the module create one (log groups for Route 53 query logging must be in us-east-1).
  EOT
  type = map(object({
    domain_name                 = optional(string)
    comment                     = optional(string)
    force_destroy               = optional(bool, false)
    enable_accelerated_recovery = optional(bool)
    delegation_set_id           = optional(string)
    vpc = optional(list(object({
      vpc_id     = string
      vpc_region = optional(string)
    })), [])
    dnssec = optional(object({
      kms_key_arn            = string
      key_signing_key_name   = optional(string)
      key_signing_key_status = optional(string, "ACTIVE")
      signing_status         = optional(string, "SIGNING")
    }))
    query_logging = optional(object({
      cloudwatch_log_group_arn    = optional(string)
      log_group_retention_in_days = optional(number, 30)
      log_group_kms_key_id        = optional(string)
    }))
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for v in values(var.zones) : v.dnssec == null || can(regex("^arn:", try(v.dnssec.kms_key_arn, "")))])
    error_message = "dnssec.kms_key_arn must be a valid KMS key ARN starting with 'arn:'."
  }

  validation {
    condition     = alltrue([for v in values(var.zones) : v.dnssec == null || contains(["ACTIVE", "INACTIVE"], try(v.dnssec.key_signing_key_status, ""))])
    error_message = "dnssec.key_signing_key_status must be one of: ACTIVE, INACTIVE."
  }

  validation {
    condition     = alltrue([for v in values(var.zones) : v.dnssec == null || contains(["SIGNING", "NOT_SIGNING"], try(v.dnssec.signing_status, ""))])
    error_message = "dnssec.signing_status must be one of: SIGNING, NOT_SIGNING."
  }

  validation {
    condition = alltrue([
      for v in values(var.zones) : v.query_logging == null || contains(
        [0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653],
        try(v.query_logging.log_group_retention_in_days, 30)
      )
    ])
    error_message = "query_logging.log_group_retention_in_days must be one of the allowed CloudWatch Logs retention values."
  }

  validation {
    condition     = alltrue([for v in values(var.zones) : v.dnssec == null || length(v.vpc) == 0])
    error_message = "DNSSEC signing is only supported on public hosted zones (zones without VPC associations)."
  }
}

variable "create_query_log_resource_policy" {
  description = "Whether to create the account-wide CloudWatch Logs resource policy that allows Route 53 to deliver query logs to /aws/route53/* log groups. Required once per account - leave false if it is already managed elsewhere."
  type        = bool
  default     = false
}

variable "query_log_resource_policy_name" {
  description = "Name of the CloudWatch Logs resource policy created when create_query_log_resource_policy is true."
  type        = string
  default     = "route53-query-logging"
}
