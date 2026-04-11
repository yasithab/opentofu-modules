# Firewall Manager

AWS Firewall Manager (FMS) module for centrally managing WAFv2 security policies across an AWS Organization. Designates an FMS administrator account and deploys WAFv2 policies to targeted accounts and organizational units.

## Features

- **FMS Admin Account Association** - Optionally designate an AWS account as the Firewall Manager administrator
- **WAFv2 Policy Management** - Define multiple WAFv2 policies with pre-process and post-process rule groups, default actions, and custom request/response handling
- **Organization Scoping** - Target policies to specific accounts or OUs, with support for both include and exclude lists
- **Resource Filtering** - Protect resources by type (ALB, API Gateway, CloudFront, etc.) with optional tag-based inclusion or exclusion
- **WAF Logging** - Integrate WAF logging via Kinesis Firehose with configurable redacted fields
- **Auto-Remediation** - Optionally remediate non-compliant resources automatically

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
