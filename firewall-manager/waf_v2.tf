resource "aws_fms_policy" "waf_v2" {
  for_each = local.waf_v2_policies

  name                               = each.value.name
  delete_all_policy_resources        = each.value.delete_all_policy_resources
  exclude_resource_tags              = each.value.exclude_resource_tags
  delete_unused_fm_managed_resources = each.value.delete_unused_fm_managed_resources
  remediation_enabled                = each.value.remediation_enabled
  resource_type_list                 = each.value.resource_type_list
  resource_type                      = each.value.resource_type
  resource_tags                      = each.value.resource_tags
  description                        = each.value.description

  dynamic "include_map" {
    for_each = length(each.value.include_account_ids) > 0 || length(each.value.include_orgunit_ids) > 0 ? [1] : []
    content {
      account = each.value.include_account_ids
      orgunit = each.value.include_orgunit_ids
    }
  }

  dynamic "exclude_map" {
    for_each = length(each.value.exclude_account_ids) > 0 || length(each.value.exclude_orgunit_ids) > 0 ? [1] : []
    content {
      account = each.value.exclude_account_ids
      orgunit = each.value.exclude_orgunit_ids
    }
  }

  security_service_policy_data {
    type = "WAFV2"

    managed_service_data = jsonencode({
      type                  = "WAFV2"
      preProcessRuleGroups  = each.value.policy_data.pre_process_rule_groups
      postProcessRuleGroups = each.value.policy_data.post_process_rule_groups

      defaultAction = {
        type = upper(each.value.policy_data.default_action)
      }

      overrideCustomerWebACLAssociation       = each.value.policy_data.override_customer_web_acl_association
      loggingConfiguration                    = each.value.policy_data.logging_configuration != null ? each.value.policy_data.logging_configuration : local.logging_configuration
      customRequestHandling                   = each.value.policy_data.custom_request_handling
      customResponse                          = each.value.policy_data.custom_response
      sampledRequestsEnabledForDefaultActions = each.value.policy_data.sampled_requests_enabled_for_default_actions
      tokenDomains                            = each.value.policy_data.token_domains
      webACLSource                            = each.value.policy_data.web_acl_source
      optimizeUnassociatedWebACL              = each.value.policy_data.optimize_unassociated_web_acl
    })
  }

  tags = merge(local.tags, each.value.tags)
}
