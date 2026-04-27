################################################################################
# Module Control
################################################################################

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

################################################################################
# FMS Admin Account
################################################################################

variable "associate_admin_account" {
  description = "Whether to associate an AWS account as the FMS administrator account."
  type        = bool
  default     = false
}

variable "admin_account_id" {
  description = "AWS account ID to associate as the FMS administrator. Defaults to the current account when null."
  type        = string
  default     = null

  validation {
    condition     = var.admin_account_id == null || can(regex("^[0-9]{12}$", var.admin_account_id))
    error_message = "admin_account_id must be a 12-digit AWS account ID."
  }
}

################################################################################
# WAFv2 Policies
################################################################################

variable "firehose_arn" {
  description = "ARN of the Kinesis Firehose delivery stream for WAF logging (used when firehose_enabled is false)."
  type        = string
  default     = null

  validation {
    condition     = var.firehose_arn == null || can(regex("^arn:", var.firehose_arn))
    error_message = "firehose_arn must be a valid ARN starting with 'arn:'."
  }
}

variable "firehose_kinesis_id" {
  description = "Kinesis Firehose stream ID for WAF logging (used when firehose_enabled is true)."
  type        = string
  default     = null
}

variable "firehose_enabled" {
  description = "Whether to use firehose_kinesis_id instead of firehose_arn for WAF logging configuration."
  type        = bool
  default     = false
}

variable "logging_configuration_enabled" {
  description = "Whether to enable WAF logging configuration in the managed_service_data."
  type        = bool
  default     = false
}

variable "waf_v2_policies" {
  description = <<-DOC
    List of WAFv2 FMS policy configurations. Each entry supports:

    name:
      The friendly name of the AWS Firewall Manager Policy.
    description:
      Optional description for the policy.
    delete_all_policy_resources:
      Whether to perform a clean-up process when the policy is deleted.
      Defaults to true.
    delete_unused_fm_managed_resources:
      Whether to delete unused FM managed resources.
      Defaults to false.
    exclude_resource_tags:
      If true, resources with the specified resource_tags are NOT protected.
      If false, resources WITH the tags are protected.
      Defaults to false.
    remediation_enabled:
      Whether the policy should automatically apply to resources that already exist.
      Defaults to false.
    resource_type_list:
      List of resource types to protect. Conflicts with resource_type.
    resource_type:
      A single resource type to protect. Conflicts with resource_type_list.
    resource_tags:
      Map of resource tags used to filter protected resources based on exclude_resource_tags.
    include_account_ids:
      List of AWS Organization member account IDs to include for this policy.
    include_orgunit_ids:
      List of AWS Organizational Unit IDs to include for this policy.
    exclude_account_ids:
      List of AWS Organization member account IDs to exclude from this policy.
    exclude_orgunit_ids:
      List of AWS Organizational Unit IDs to exclude from this policy.
    tags:
      Map of additional tags to apply to this specific policy.
    policy_data:
      default_action:
        The action AWS WAF should take. Values: ALLOW, BLOCK, or COUNT.
      override_customer_web_acl_association:
        Whether to override customer Web ACL association. Defaults to false.
      logging_configuration:
        WAFv2 Web ACL logging configuration JSON. Overrides module-level logging config.
      pre_process_rule_groups:
        List of pre-process rule groups.
      post_process_rule_groups:
        List of post-process rule groups.
      custom_request_handling:
        Custom header for custom request handling. Defaults to null.
      custom_response:
        Custom response for the web request. Defaults to null.
      sampled_requests_enabled_for_default_actions:
        Whether WAF should store a sampling of web requests that match rules.
      token_domains:
        List of token domains for the Web ACL.
      web_acl_source:
        Source of the Web ACL configuration.
      optimize_unassociated_web_acl:
        Whether to optimize unassociated Web ACLs. Defaults to false.
  DOC
  type        = list(any)
  default     = []
}
