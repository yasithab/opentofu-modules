# Firewall Manager

AWS Firewall Manager (FMS) module for centrally managing WAFv2 security policies across an AWS Organization. Designates an FMS administrator account and deploys WAFv2 policies to targeted accounts and organizational units.

## Scope

This module manages **WAFv2 policies only** (`security_service_policy_data.type = "WAFV2"`).
Other FMS policy types (Shield Advanced, security groups, Network Firewall, DNS Firewall,
WAF Classic) are not supported.

## Features

- **FMS Admin Account Association** - Optionally designate an AWS account as the Firewall Manager administrator
- **WAFv2 Policy Management** - Define multiple WAFv2 policies with pre-process and post-process rule groups, default actions, and custom request/response handling
- **Organization Scoping** - Target policies to specific accounts or OUs, with support for both include and exclude lists
- **Resource Filtering** - Protect resources by type (ALB, API Gateway, CloudFront, etc.) with optional tag-based inclusion or exclusion
- **WAF Logging** - Integrate WAF logging via Kinesis Firehose with configurable redacted fields
- **Auto-Remediation** - Optionally remediate non-compliant resources automatically

## Notes

- **BREAKING**: the `firehose_kinesis_id` and `firehose_enabled` variables were removed.
  Use `firehose_arn` (a full Kinesis Firehose delivery stream ARN) as the single logging
  destination input. `firehose_arn` is required when `logging_configuration_enabled = true`.
- `redacted_fields` controls which fields are redacted from WAF logs when the module-level
  logging configuration is used. It defaults to the previous hard-coded behaviour
  (`SingleHeader` value `Cookies`, and `Method`).
- `waf_v2_policies` is now a typed `list(object)` with `optional()` attributes instead of
  `list(any)`. Existing inputs keep working; unknown attributes are now rejected at plan time.

## Usage

```hcl
module "firewall_manager" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//firewall-manager?depth=1&ref=master"

  associate_admin_account = true
  admin_account_id        = "123456789012"

  waf_v2_policies = [
    {
      name                = "org-alb-waf-policy"
      resource_type_list  = ["AWS::ElasticLoadBalancingV2::LoadBalancer"]
      remediation_enabled = true

      policy_data = {
        default_action = "ALLOW"
        pre_process_rule_groups = [
          {
            managedRuleGroupIdentifier = {
              vendorName         = "AWS"
              managedRuleGroupName = "AWSManagedRulesCommonRuleSet"
            }
            overrideAction = { type = "NONE" }
            ruleGroupType  = "ManagedRuleGroup"
          }
        ]
        post_process_rule_groups = []
      }
    }
  ]

  tags = {
    Environment = "production"
  }
}
```


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11.0 |
| aws | >= 6.49, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.49, < 7.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| admin\_account\_id | AWS account ID to associate as the FMS administrator. Defaults to the current account when null. | `string` | `null` | no |
| associate\_admin\_account | Whether to associate an AWS account as the FMS administrator account. | `bool` | `false` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| firehose\_arn | ARN of the Kinesis Firehose delivery stream used as the WAF logging destination. Required when logging\_configuration\_enabled is true. | `string` | `null` | no |
| logging\_configuration\_enabled | Whether to enable WAF logging configuration in the managed\_service\_data. | `bool` | `false` | no |
| redacted\_fields | List of fields to redact from WAF logs when the module-level logging configuration is used. Each entry supports redacted\_field\_type (e.g. SingleHeader, Method, UriPath, QueryString) and an optional redacted\_field\_value (e.g. the header name for SingleHeader). | <pre>list(object({<br/>    redacted_field_type  = string<br/>    redacted_field_value = optional(string)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "redacted_field_type": "SingleHeader",<br/>    "redacted_field_value": "Cookies"<br/>  },<br/>  {<br/>    "redacted_field_type": "Method"<br/>  }<br/>]</pre> | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| waf\_v2\_policies | List of WAFv2 FMS policy configurations. Each entry supports:<br/><br/>name:<br/>  The friendly name of the AWS Firewall Manager Policy.<br/>description:<br/>  Optional description for the policy.<br/>delete\_all\_policy\_resources:<br/>  Whether to perform a clean-up process when the policy is deleted.<br/>  Defaults to true.<br/>delete\_unused\_fm\_managed\_resources:<br/>  Whether to delete unused FM managed resources.<br/>  Defaults to false.<br/>exclude\_resource\_tags:<br/>  If true, resources with the specified resource\_tags are NOT protected.<br/>  If false, resources WITH the tags are protected.<br/>  Defaults to false.<br/>remediation\_enabled:<br/>  Whether the policy should automatically apply to resources that already exist.<br/>  Defaults to false.<br/>resource\_type\_list:<br/>  List of resource types to protect. Conflicts with resource\_type.<br/>resource\_type:<br/>  A single resource type to protect. Conflicts with resource\_type\_list.<br/>resource\_tags:<br/>  Map of resource tags used to filter protected resources based on exclude\_resource\_tags.<br/>include\_account\_ids:<br/>  List of AWS Organization member account IDs to include for this policy.<br/>include\_orgunit\_ids:<br/>  List of AWS Organizational Unit IDs to include for this policy.<br/>exclude\_account\_ids:<br/>  List of AWS Organization member account IDs to exclude from this policy.<br/>exclude\_orgunit\_ids:<br/>  List of AWS Organizational Unit IDs to exclude from this policy.<br/>tags:<br/>  Map of additional tags to apply to this specific policy.<br/>policy\_data:<br/>  default\_action:<br/>    The action AWS WAF should take. Values: ALLOW, BLOCK, or COUNT.<br/>  override\_customer\_web\_acl\_association:<br/>    Whether to override customer Web ACL association. Defaults to false.<br/>  logging\_configuration:<br/>    WAFv2 Web ACL logging configuration JSON. Overrides module-level logging config.<br/>  pre\_process\_rule\_groups:<br/>    List of pre-process rule groups.<br/>  post\_process\_rule\_groups:<br/>    List of post-process rule groups.<br/>  custom\_request\_handling:<br/>    Custom header for custom request handling. Defaults to null.<br/>  custom\_response:<br/>    Custom response for the web request. Defaults to null.<br/>  sampled\_requests\_enabled\_for\_default\_actions:<br/>    Whether WAF should store a sampling of web requests that match rules.<br/>  token\_domains:<br/>    List of token domains for the Web ACL.<br/>  web\_acl\_source:<br/>    Source of the Web ACL configuration.<br/>  optimize\_unassociated\_web\_acl:<br/>    Whether to optimize unassociated Web ACLs. Defaults to false. | <pre>list(object({<br/>    name                               = string<br/>    description                        = optional(string)<br/>    delete_all_policy_resources        = optional(bool, true)<br/>    delete_unused_fm_managed_resources = optional(bool, false)<br/>    exclude_resource_tags              = optional(bool, false)<br/>    remediation_enabled                = optional(bool, false)<br/>    resource_type_list                 = optional(list(string))<br/>    resource_type                      = optional(string)<br/>    resource_tags                      = optional(map(string))<br/>    include_account_ids                = optional(list(string), [])<br/>    include_orgunit_ids                = optional(list(string), [])<br/>    exclude_account_ids                = optional(list(string), [])<br/>    exclude_orgunit_ids                = optional(list(string), [])<br/>    tags                               = optional(map(string), {})<br/>    policy_data = object({<br/>      default_action                               = string<br/>      override_customer_web_acl_association        = optional(bool, false)<br/>      logging_configuration                        = optional(string)<br/>      pre_process_rule_groups                      = optional(any, [])<br/>      post_process_rule_groups                     = optional(any, [])<br/>      custom_request_handling                      = optional(any)<br/>      custom_response                              = optional(any)<br/>      sampled_requests_enabled_for_default_actions = optional(bool, false)<br/>      token_domains                                = optional(list(string), [])<br/>      web_acl_source                               = optional(string)<br/>      optimize_unassociated_web_acl                = optional(bool, false)<br/>    })<br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| admin\_account\_id | AWS account ID of the FMS administrator account. |
| waf\_v2\_policy\_arns | Map of WAFv2 policy names to their ARNs. |
| waf\_v2\_policy\_ids | Map of WAFv2 policy names to their IDs. |
<!-- END_TF_DOCS -->

## Examples

## Basic Usage

Enforce a single WAFv2 policy across all ALBs in the organization with no logging.

```hcl
module "firewall_manager" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//firewall-manager?depth=1&ref=master"

  enabled = true

  waf_v2_policies = [
    {
      name              = "org-waf-policy-alb"
      resource_type     = "AWS::ElasticLoadBalancingV2::LoadBalancer"
      remediation_enabled = false

      policy_data = {
        default_action = "ALLOW"
        override_customer_web_acl_association        = false
        sampled_requests_enabled_for_default_actions = true
        pre_process_rule_groups                      = []
        post_process_rule_groups                     = []
      }
    }
  ]
}
```

## With Specific Account Inclusion

Apply a WAFv2 policy only to selected AWS Organization member accounts.

```hcl
module "firewall_manager_scoped" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//firewall-manager?depth=1&ref=master"

  enabled = true

  waf_v2_policies = [
    {
      name                = "prod-waf-policy-cloudfront"
      resource_type       = "AWS::CloudFront::Distribution"
      remediation_enabled = true
      include_account_ids = ["123456789012", "234567890123"]

      policy_data = {
        default_action = "ALLOW"
        override_customer_web_acl_association        = true
        sampled_requests_enabled_for_default_actions = true
        pre_process_rule_groups                      = []
        post_process_rule_groups                     = []
      }
    }
  ]
}
```

## With Logging to Kinesis Firehose

Enable WAFv2 logging to a Kinesis Firehose ARN and exclude specific accounts.

```hcl
module "firewall_manager_with_logging" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//firewall-manager?depth=1&ref=master"

  enabled = true

  firehose_arn                  = "arn:aws:firehose:us-east-1:123456789012:deliverystream/aws-waf-logs-prod"
  logging_configuration_enabled = true

  waf_v2_policies = [
    {
      name                = "prod-waf-policy-multi"
      exclude_account_ids = ["999999999999"]
      resource_type_list  = ["AWS::ElasticLoadBalancingV2::LoadBalancer", "AWS::CloudFront::Distribution"]
      remediation_enabled = true

      policy_data = {
        default_action = "ALLOW"
        override_customer_web_acl_association        = false
        sampled_requests_enabled_for_default_actions = true
        pre_process_rule_groups                      = []
        post_process_rule_groups                     = []
      }
    }
  ]
}
```

## Multiple Policies with Resource Tags

Define two policies - one that protects tagged resources and one that excludes them.

```hcl
module "firewall_manager_multi_policy" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//firewall-manager?depth=1&ref=master"

  enabled = true

  waf_v2_policies = [
    {
      name                   = "protected-alb-policy"
      resource_type          = "AWS::ElasticLoadBalancingV2::LoadBalancer"
      exclude_resource_tags  = false
      resource_tags          = { "waf-protected" = "true" }
      remediation_enabled    = true

      policy_data = {
        default_action = "BLOCK"
        override_customer_web_acl_association        = true
        sampled_requests_enabled_for_default_actions = true
        pre_process_rule_groups                      = []
        post_process_rule_groups                     = []
      }
    },
    {
      name                   = "excluded-internal-policy"
      resource_type          = "AWS::ElasticLoadBalancingV2::LoadBalancer"
      exclude_resource_tags  = true
      resource_tags          = { "internal" = "true" }
      remediation_enabled    = false

      policy_data = {
        default_action = "ALLOW"
        override_customer_web_acl_association        = false
        sampled_requests_enabled_for_default_actions = false
        pre_process_rule_groups                      = []
        post_process_rule_groups                     = []
      }
    }
  ]
}
```
