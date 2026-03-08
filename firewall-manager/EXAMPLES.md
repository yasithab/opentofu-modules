# Firewall Manager Module - Examples

## Basic Usage

Enforce a single WAFv2 policy across all ALBs in the organization with no logging.

```hcl
module "firewall_manager" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//firewall-manager?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//firewall-manager?depth=1&ref=v2.0.0"

  enabled = true

  waf_v2_policies = [
    {
      name                = "prod-waf-policy-cloudfront"
      resource_type       = "AWS::CloudFront::Distribution"
      remediation_enabled = true
      include_account_ids = [["123456789012", "234567890123"]]

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//firewall-manager?depth=1&ref=v2.0.0"

  enabled = true

  firehose_arn                  = "arn:aws:firehose:us-east-1:123456789012:deliverystream/aws-waf-logs-prod"
  logging_configuration_enabled = true

  waf_v2_policies = [
    {
      name                = "prod-waf-policy-multi"
      exclude_account_ids = [["999999999999"]]
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
  source = "git::https://github.com/yasithab/opentofu-modules.git//firewall-manager?depth=1&ref=v2.0.0"

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
