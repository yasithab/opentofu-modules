###################################################
# Locals
###################################################
locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

###################################################
# IP Sets
###################################################
resource "aws_wafv2_ip_set" "this" {
  for_each = local.enabled ? var.ip_sets : {}

  name               = each.key
  scope              = var.scope
  ip_address_version = each.value.ip_address_version
  addresses          = each.value.addresses
  description        = try(each.value.description, null)

  tags = local.tags
}

###################################################
# Regex Pattern Sets
###################################################
resource "aws_wafv2_regex_pattern_set" "this" {
  for_each = local.enabled ? var.regex_pattern_sets : {}

  name        = each.key
  scope       = var.scope
  description = try(each.value.description, null)

  dynamic "regular_expression" {
    for_each = each.value.regular_expressions
    content {
      regex_string = regular_expression.value
    }
  }

  tags = local.tags
}

###################################################
# Rule Groups
###################################################
resource "aws_wafv2_rule_group" "this" {
  for_each = local.enabled ? var.rule_groups : {}

  name        = each.key
  scope       = var.scope
  capacity    = each.value.capacity
  description = try(each.value.description, null)

  # JSON escape hatch - takes precedence over structured rules
  rules_json = try(each.value.rules_json, null)

  # Structured rules (only when rules_json is null)
  dynamic "rule" {
    for_each = try(each.value.rules_json, null) == null ? try(each.value.rules, []) : []
    content {
      name     = rule.value.name
      priority = rule.value.priority

      dynamic "action" {
        for_each = try(rule.value.action, null) != null ? [rule.value.action] : []
        content {
          dynamic "allow" {
            for_each = (try(action.value, "") == "allow") || try(action.value.allow, null) != null ? [1] : []
            content {}
          }
          dynamic "block" {
            for_each = (try(action.value, "") == "block") || try(action.value.block, null) != null ? [1] : []
            content {}
          }
          dynamic "count" {
            for_each = (try(action.value, "") == "count") || try(action.value.count, null) != null ? [1] : []
            content {}
          }
          dynamic "captcha" {
            for_each = (try(action.value, "") == "captcha") || try(action.value.captcha, null) != null ? [1] : []
            content {}
          }
          dynamic "challenge" {
            for_each = (try(action.value, "") == "challenge") || try(action.value.challenge, null) != null ? [1] : []
            content {}
          }
        }
      }

      dynamic "statement" {
        for_each = [rule.value.statement]
        content {
          dynamic "ip_set_reference_statement" {
            for_each = try(statement.value.ip_set_reference_statement, null) != null ? [statement.value.ip_set_reference_statement] : []
            content {
              arn = try(
                aws_wafv2_ip_set.this[ip_set_reference_statement.value.name].arn,
                ip_set_reference_statement.value.arn
              )
              dynamic "ip_set_forwarded_ip_config" {
                for_each = try(ip_set_reference_statement.value.ip_set_forwarded_ip_config, null) != null ? [ip_set_reference_statement.value.ip_set_forwarded_ip_config] : []
                content {
                  fallback_behavior = ip_set_forwarded_ip_config.value.fallback_behavior
                  header_name       = ip_set_forwarded_ip_config.value.header_name
                  position          = ip_set_forwarded_ip_config.value.position
                }
              }
            }
          }

          dynamic "geo_match_statement" {
            for_each = try(statement.value.geo_match_statement, null) != null ? [statement.value.geo_match_statement] : []
            content {
              country_codes = geo_match_statement.value.country_codes
            }
          }

          dynamic "byte_match_statement" {
            for_each = try(statement.value.byte_match_statement, null) != null ? [statement.value.byte_match_statement] : []
            content {
              positional_constraint = byte_match_statement.value.positional_constraint
              search_string         = byte_match_statement.value.search_string
              dynamic "field_to_match" {
                for_each = [try(byte_match_statement.value.field_to_match, {})]
                content {
                  dynamic "uri_path" {
                    for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "query_string" {
                    for_each = try(field_to_match.value.query_string, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "method" {
                    for_each = try(field_to_match.value.method, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "all_query_arguments" {
                    for_each = try(field_to_match.value.all_query_arguments, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "body" {
                    for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                    content { oversize_handling = try(body.value.oversize_handling, "CONTINUE") }
                  }
                  dynamic "single_header" {
                    for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
                    content { name = lower(single_header.value.name) }
                  }
                  dynamic "single_query_argument" {
                    for_each = try(field_to_match.value.single_query_argument, null) != null ? [field_to_match.value.single_query_argument] : []
                    content { name = lower(single_query_argument.value.name) }
                  }
                }
              }
              dynamic "text_transformation" {
                for_each = try(byte_match_statement.value.text_transformations, [])
                content {
                  priority = text_transformation.value.priority
                  type     = text_transformation.value.type
                }
              }
            }
          }

          dynamic "regex_match_statement" {
            for_each = try(statement.value.regex_match_statement, null) != null ? [statement.value.regex_match_statement] : []
            content {
              regex_string = regex_match_statement.value.regex_string
              dynamic "field_to_match" {
                for_each = [try(regex_match_statement.value.field_to_match, {})]
                content {
                  dynamic "uri_path" {
                    for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "query_string" {
                    for_each = try(field_to_match.value.query_string, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "single_header" {
                    for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
                    content { name = lower(single_header.value.name) }
                  }
                }
              }
              dynamic "text_transformation" {
                for_each = try(regex_match_statement.value.text_transformations, [])
                content {
                  priority = text_transformation.value.priority
                  type     = text_transformation.value.type
                }
              }
            }
          }

          dynamic "sqli_match_statement" {
            for_each = try(statement.value.sqli_match_statement, null) != null ? [statement.value.sqli_match_statement] : []
            content {
              sensitivity_level = try(sqli_match_statement.value.sensitivity_level, null)
              dynamic "field_to_match" {
                for_each = [try(sqli_match_statement.value.field_to_match, {})]
                content {
                  dynamic "uri_path" {
                    for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "query_string" {
                    for_each = try(field_to_match.value.query_string, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "body" {
                    for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                    content { oversize_handling = try(body.value.oversize_handling, "CONTINUE") }
                  }
                  dynamic "single_header" {
                    for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
                    content { name = lower(single_header.value.name) }
                  }
                }
              }
              dynamic "text_transformation" {
                for_each = try(sqli_match_statement.value.text_transformations, [])
                content {
                  priority = text_transformation.value.priority
                  type     = text_transformation.value.type
                }
              }
            }
          }

          dynamic "xss_match_statement" {
            for_each = try(statement.value.xss_match_statement, null) != null ? [statement.value.xss_match_statement] : []
            content {
              dynamic "field_to_match" {
                for_each = [try(xss_match_statement.value.field_to_match, {})]
                content {
                  dynamic "uri_path" {
                    for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "query_string" {
                    for_each = try(field_to_match.value.query_string, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "body" {
                    for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                    content { oversize_handling = try(body.value.oversize_handling, "CONTINUE") }
                  }
                  dynamic "single_header" {
                    for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
                    content { name = lower(single_header.value.name) }
                  }
                }
              }
              dynamic "text_transformation" {
                for_each = try(xss_match_statement.value.text_transformations, [])
                content {
                  priority = text_transformation.value.priority
                  type     = text_transformation.value.type
                }
              }
            }
          }

          dynamic "size_constraint_statement" {
            for_each = try(statement.value.size_constraint_statement, null) != null ? [statement.value.size_constraint_statement] : []
            content {
              comparison_operator = size_constraint_statement.value.comparison_operator
              size                = size_constraint_statement.value.size
              dynamic "field_to_match" {
                for_each = [try(size_constraint_statement.value.field_to_match, {})]
                content {
                  dynamic "uri_path" {
                    for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "query_string" {
                    for_each = try(field_to_match.value.query_string, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "body" {
                    for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                    content { oversize_handling = try(body.value.oversize_handling, "CONTINUE") }
                  }
                  dynamic "single_header" {
                    for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
                    content { name = lower(single_header.value.name) }
                  }
                }
              }
              dynamic "text_transformation" {
                for_each = try(size_constraint_statement.value.text_transformations, [])
                content {
                  priority = text_transformation.value.priority
                  type     = text_transformation.value.type
                }
              }
            }
          }

          dynamic "label_match_statement" {
            for_each = try(statement.value.label_match_statement, null) != null ? [statement.value.label_match_statement] : []
            content {
              scope = upper(label_match_statement.value.scope)
              key   = label_match_statement.value.key
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = try(rule.value.visibility_config.cloudwatch_metrics_enabled, try(each.value.cloudwatch_metrics_enabled, true))
        metric_name                = try(rule.value.visibility_config.metric_name, "${each.key}-${rule.value.name}")
        sampled_requests_enabled   = try(rule.value.visibility_config.sampled_requests_enabled, try(each.value.sampled_requests_enabled, true))
      }
    }
  }

  dynamic "custom_response_body" {
    for_each = try(each.value.custom_response_bodies, [])
    content {
      key          = custom_response_body.value.key
      content      = custom_response_body.value.content
      content_type = custom_response_body.value.content_type
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = try(each.value.cloudwatch_metrics_enabled, true)
    metric_name                = try(each.value.metric_name, each.key)
    sampled_requests_enabled   = try(each.value.sampled_requests_enabled, true)
  }

  tags = local.tags
}

###################################################
# API Keys
###################################################
resource "aws_wafv2_api_key" "this" {
  for_each = local.enabled ? var.api_keys : {}

  scope         = var.scope
  token_domains = each.value.token_domains
}

###################################################
# Web ACL
###################################################
resource "aws_wafv2_web_acl" "this" {
  name        = var.name
  scope       = var.scope
  description = var.description

  token_domains = length(var.token_domains) > 0 ? var.token_domains : null

  # --------------------------------------------------
  # Default Action
  # --------------------------------------------------
  default_action {
    dynamic "allow" {
      for_each = upper(var.default_action) == "ALLOW" ? [try(var.default_action_config.allow, {})] : []
      content {
        dynamic "custom_request_handling" {
          for_each = length(try(allow.value.insert_headers, [])) > 0 ? [allow.value] : []
          content {
            dynamic "insert_header" {
              for_each = custom_request_handling.value.insert_headers
              content {
                name  = insert_header.value.name
                value = insert_header.value.value
              }
            }
          }
        }
      }
    }

    dynamic "block" {
      for_each = upper(var.default_action) == "BLOCK" ? [try(var.default_action_config.block, {})] : []
      content {
        dynamic "custom_response" {
          for_each = try(block.value.response_code, null) != null ? [block.value] : []
          content {
            response_code            = custom_response.value.response_code
            custom_response_body_key = try(custom_response.value.custom_response_body_key, null)
          }
        }
      }
    }
  }

  # --------------------------------------------------
  # Custom Response Bodies
  # --------------------------------------------------
  dynamic "custom_response_body" {
    for_each = var.custom_response_bodies
    content {
      key          = custom_response_body.value.key
      content      = custom_response_body.value.content
      content_type = custom_response_body.value.content_type
    }
  }

  # --------------------------------------------------
  # JSON Escape Hatch (takes precedence over structured rules)
  # --------------------------------------------------
  rule_json = var.rule_json

  # --------------------------------------------------
  # Structured Rules (only used when rule_json is null)
  # --------------------------------------------------
  dynamic "rule" {
    for_each = var.rule_json != null ? [] : var.rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      # ------------------------------------------------
      # Action block (for non-group rules)
      # ------------------------------------------------
      dynamic "action" {
        for_each = try(rule.value.action, null) != null ? [rule.value.action] : []
        content {
          dynamic "allow" {
            for_each = (try(action.value, "") == "allow") || try(action.value.allow, null) != null ? [try(action.value.allow, {})] : []
            content {
              dynamic "custom_request_handling" {
                for_each = length(try(allow.value.insert_headers, [])) > 0 ? [allow.value] : []
                content {
                  dynamic "insert_header" {
                    for_each = custom_request_handling.value.insert_headers
                    content {
                      name  = insert_header.value.name
                      value = insert_header.value.value
                    }
                  }
                }
              }
            }
          }

          dynamic "block" {
            for_each = (try(action.value, "") == "block") || try(action.value.block, null) != null ? [try(action.value.block, {})] : []
            content {
              dynamic "custom_response" {
                for_each = try(block.value.response_code, null) != null ? [block.value] : []
                content {
                  response_code            = custom_response.value.response_code
                  custom_response_body_key = try(custom_response.value.custom_response_body_key, null)
                }
              }
            }
          }

          dynamic "count" {
            for_each = (try(action.value, "") == "count") || try(action.value.count, null) != null ? [try(action.value.count, {})] : []
            content {
              dynamic "custom_request_handling" {
                for_each = length(try(count.value.insert_headers, [])) > 0 ? [count.value] : []
                content {
                  dynamic "insert_header" {
                    for_each = custom_request_handling.value.insert_headers
                    content {
                      name  = insert_header.value.name
                      value = insert_header.value.value
                    }
                  }
                }
              }
            }
          }

          dynamic "captcha" {
            for_each = (try(action.value, "") == "captcha") || try(action.value.captcha, null) != null ? [try(action.value.captcha, {})] : []
            content {
              dynamic "custom_request_handling" {
                for_each = length(try(captcha.value.insert_headers, [])) > 0 ? [captcha.value] : []
                content {
                  dynamic "insert_header" {
                    for_each = custom_request_handling.value.insert_headers
                    content {
                      name  = insert_header.value.name
                      value = insert_header.value.value
                    }
                  }
                }
              }
            }
          }

          dynamic "challenge" {
            for_each = (try(action.value, "") == "challenge") || try(action.value.challenge, null) != null ? [try(action.value.challenge, {})] : []
            content {
              dynamic "custom_request_handling" {
                for_each = length(try(challenge.value.insert_headers, [])) > 0 ? [challenge.value] : []
                content {
                  dynamic "insert_header" {
                    for_each = custom_request_handling.value.insert_headers
                    content {
                      name  = insert_header.value.name
                      value = insert_header.value.value
                    }
                  }
                }
              }
            }
          }
        }
      }

      # ------------------------------------------------
      # Override action (for managed/rule-group rules)
      # ------------------------------------------------
      dynamic "override_action" {
        for_each = try(rule.value.override_action, null) != null ? [rule.value.override_action] : []
        content {
          dynamic "none" {
            for_each = try(override_action.value, "") == "none" ? [1] : []
            content {}
          }
          dynamic "count" {
            for_each = try(override_action.value, "") == "count" ? [1] : []
            content {}
          }
        }
      }

      # ------------------------------------------------
      # Statement
      # ------------------------------------------------
      dynamic "statement" {
        for_each = [rule.value.statement]
        content {

          # Managed Rule Group Statement
          dynamic "managed_rule_group_statement" {
            for_each = try(statement.value.managed_rule_group_statement, null) != null ? [statement.value.managed_rule_group_statement] : []
            content {
              name        = managed_rule_group_statement.value.name
              vendor_name = try(managed_rule_group_statement.value.vendor_name, "AWS")
              version     = try(managed_rule_group_statement.value.version, null)

              dynamic "rule_action_override" {
                for_each = try(managed_rule_group_statement.value.rule_action_overrides, [])
                content {
                  name = rule_action_override.value.name
                  action_to_use {
                    dynamic "allow" {
                      for_each = rule_action_override.value.action_to_use == "allow" ? [1] : []
                      content {}
                    }
                    dynamic "block" {
                      for_each = rule_action_override.value.action_to_use == "block" ? [1] : []
                      content {}
                    }
                    dynamic "count" {
                      for_each = rule_action_override.value.action_to_use == "count" ? [1] : []
                      content {}
                    }
                    dynamic "captcha" {
                      for_each = rule_action_override.value.action_to_use == "captcha" ? [1] : []
                      content {}
                    }
                    dynamic "challenge" {
                      for_each = rule_action_override.value.action_to_use == "challenge" ? [1] : []
                      content {}
                    }
                  }
                }
              }

              dynamic "managed_rule_group_configs" {
                for_each = try(managed_rule_group_statement.value.managed_rule_group_configs, null) != null ? [managed_rule_group_statement.value.managed_rule_group_configs] : []
                content {
                  dynamic "aws_managed_rules_bot_control_rule_set" {
                    for_each = try(managed_rule_group_configs.value.aws_managed_rules_bot_control_rule_set, null) != null ? [managed_rule_group_configs.value.aws_managed_rules_bot_control_rule_set] : []
                    content {
                      inspection_level        = aws_managed_rules_bot_control_rule_set.value.inspection_level
                      enable_machine_learning = try(aws_managed_rules_bot_control_rule_set.value.enable_machine_learning, true)
                    }
                  }

                  dynamic "aws_managed_rules_atp_rule_set" {
                    for_each = try(managed_rule_group_configs.value.aws_managed_rules_atp_rule_set, null) != null ? [managed_rule_group_configs.value.aws_managed_rules_atp_rule_set] : []
                    content {
                      login_path = aws_managed_rules_atp_rule_set.value.login_path

                      dynamic "request_inspection" {
                        for_each = try(aws_managed_rules_atp_rule_set.value.request_inspection, null) != null ? [aws_managed_rules_atp_rule_set.value.request_inspection] : []
                        content {
                          payload_type = try(request_inspection.value.payload_type, "JSON")
                          dynamic "username_field" {
                            for_each = try(request_inspection.value.username_field, null) != null ? [request_inspection.value.username_field] : []
                            content { identifier = username_field.value.identifier }
                          }
                          dynamic "password_field" {
                            for_each = try(request_inspection.value.password_field, null) != null ? [request_inspection.value.password_field] : []
                            content { identifier = password_field.value.identifier }
                          }
                        }
                      }

                      dynamic "response_inspection" {
                        for_each = try(aws_managed_rules_atp_rule_set.value.response_inspection, null) != null ? [aws_managed_rules_atp_rule_set.value.response_inspection] : []
                        content {
                          dynamic "status_code" {
                            for_each = try(response_inspection.value.status_code, null) != null ? [response_inspection.value.status_code] : []
                            content {
                              success_codes = status_code.value.success_codes
                              failure_codes = status_code.value.failure_codes
                            }
                          }
                          dynamic "header" {
                            for_each = try(response_inspection.value.header, null) != null ? [response_inspection.value.header] : []
                            content {
                              name           = header.value.name
                              success_values = header.value.success_values
                              failure_values = header.value.failure_values
                            }
                          }
                        }
                      }
                    }
                  }

                  dynamic "aws_managed_rules_acfp_rule_set" {
                    for_each = try(managed_rule_group_configs.value.aws_managed_rules_acfp_rule_set, null) != null ? [managed_rule_group_configs.value.aws_managed_rules_acfp_rule_set] : []
                    content {
                      creation_path          = aws_managed_rules_acfp_rule_set.value.creation_path
                      registration_page_path = aws_managed_rules_acfp_rule_set.value.registration_page_path
                      enable_regex_in_path   = try(aws_managed_rules_acfp_rule_set.value.enable_regex_in_path, null)

                      dynamic "request_inspection" {
                        for_each = try(aws_managed_rules_acfp_rule_set.value.request_inspection, null) != null ? [aws_managed_rules_acfp_rule_set.value.request_inspection] : []
                        content {
                          payload_type = try(request_inspection.value.payload_type, "JSON")
                          dynamic "username_field" {
                            for_each = try(request_inspection.value.username_field, null) != null ? [request_inspection.value.username_field] : []
                            content { identifier = username_field.value.identifier }
                          }
                          dynamic "password_field" {
                            for_each = try(request_inspection.value.password_field, null) != null ? [request_inspection.value.password_field] : []
                            content { identifier = password_field.value.identifier }
                          }
                          dynamic "email_field" {
                            for_each = try(request_inspection.value.email_field, null) != null ? [request_inspection.value.email_field] : []
                            content { identifier = email_field.value.identifier }
                          }
                        }
                      }

                      dynamic "response_inspection" {
                        for_each = try(aws_managed_rules_acfp_rule_set.value.response_inspection, null) != null ? [aws_managed_rules_acfp_rule_set.value.response_inspection] : []
                        content {
                          dynamic "status_code" {
                            for_each = try(response_inspection.value.status_code, null) != null ? [response_inspection.value.status_code] : []
                            content {
                              success_codes = status_code.value.success_codes
                              failure_codes = status_code.value.failure_codes
                            }
                          }
                        }
                      }
                    }
                  }

                  dynamic "aws_managed_rules_anti_ddos_rule_set" {
                    for_each = try(managed_rule_group_configs.value.aws_managed_rules_anti_ddos_rule_set, null) != null ? [managed_rule_group_configs.value.aws_managed_rules_anti_ddos_rule_set] : []
                    content {
                      sensitivity_to_block = try(aws_managed_rules_anti_ddos_rule_set.value.sensitivity_to_block, null)

                      client_side_action_config {
                        challenge {
                          usage_of_action = try(aws_managed_rules_anti_ddos_rule_set.value.client_side_action_usage_of_action, "ACTIVE_UNDER_DDOS")
                          sensitivity     = try(aws_managed_rules_anti_ddos_rule_set.value.client_side_action_sensitivity, null)
                        }
                      }
                    }
                  }
                }
              }

              # Scope-down statement for managed rule group
              dynamic "scope_down_statement" {
                for_each = try(managed_rule_group_statement.value.scope_down_statement, null) != null ? [managed_rule_group_statement.value.scope_down_statement] : []
                content {
                  dynamic "ip_set_reference_statement" {
                    for_each = try(scope_down_statement.value.ip_set_reference_statement, null) != null ? [scope_down_statement.value.ip_set_reference_statement] : []
                    content {
                      arn = try(
                        aws_wafv2_ip_set.this[ip_set_reference_statement.value.name].arn,
                        ip_set_reference_statement.value.arn
                      )
                    }
                  }
                  dynamic "geo_match_statement" {
                    for_each = try(scope_down_statement.value.geo_match_statement, null) != null ? [scope_down_statement.value.geo_match_statement] : []
                    content {
                      country_codes = geo_match_statement.value.country_codes
                    }
                  }
                  dynamic "byte_match_statement" {
                    for_each = try(scope_down_statement.value.byte_match_statement, null) != null ? [scope_down_statement.value.byte_match_statement] : []
                    content {
                      positional_constraint = byte_match_statement.value.positional_constraint
                      search_string         = byte_match_statement.value.search_string
                      dynamic "field_to_match" {
                        for_each = [try(byte_match_statement.value.field_to_match, {})]
                        content {
                          dynamic "uri_path" {
                            for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                            content {}
                          }
                          dynamic "query_string" {
                            for_each = try(field_to_match.value.query_string, null) != null ? [1] : []
                            content {}
                          }
                          dynamic "single_header" {
                            for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
                            content { name = lower(single_header.value.name) }
                          }
                          dynamic "body" {
                            for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                            content { oversize_handling = try(body.value.oversize_handling, "CONTINUE") }
                          }
                        }
                      }
                      dynamic "text_transformation" {
                        for_each = try(byte_match_statement.value.text_transformations, [])
                        content {
                          priority = text_transformation.value.priority
                          type     = text_transformation.value.type
                        }
                      }
                    }
                  }
                  dynamic "not_statement" {
                    for_each = try(scope_down_statement.value.not_statement, null) != null ? [scope_down_statement.value.not_statement] : []
                    content {
                      statement {
                        dynamic "geo_match_statement" {
                          for_each = try(not_statement.value.statement.geo_match_statement, null) != null ? [not_statement.value.statement.geo_match_statement] : []
                          content { country_codes = geo_match_statement.value.country_codes }
                        }
                        dynamic "ip_set_reference_statement" {
                          for_each = try(not_statement.value.statement.ip_set_reference_statement, null) != null ? [not_statement.value.statement.ip_set_reference_statement] : []
                          content {
                            arn = try(
                              aws_wafv2_ip_set.this[ip_set_reference_statement.value.name].arn,
                              ip_set_reference_statement.value.arn
                            )
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }

          # Rule Group Reference Statement
          dynamic "rule_group_reference_statement" {
            for_each = try(statement.value.rule_group_reference_statement, null) != null ? [statement.value.rule_group_reference_statement] : []
            content {
              arn = try(
                aws_wafv2_rule_group.this[rule_group_reference_statement.value.name].arn,
                rule_group_reference_statement.value.arn
              )
              dynamic "rule_action_override" {
                for_each = try(rule_group_reference_statement.value.rule_action_overrides, [])
                content {
                  name = rule_action_override.value.name
                  action_to_use {
                    dynamic "allow" {
                      for_each = rule_action_override.value.action_to_use == "allow" ? [1] : []
                      content {}
                    }
                    dynamic "block" {
                      for_each = rule_action_override.value.action_to_use == "block" ? [1] : []
                      content {}
                    }
                    dynamic "count" {
                      for_each = rule_action_override.value.action_to_use == "count" ? [1] : []
                      content {}
                    }
                    dynamic "captcha" {
                      for_each = rule_action_override.value.action_to_use == "captcha" ? [1] : []
                      content {}
                    }
                    dynamic "challenge" {
                      for_each = rule_action_override.value.action_to_use == "challenge" ? [1] : []
                      content {}
                    }
                  }
                }
              }
            }
          }

          # IP Set Reference Statement
          dynamic "ip_set_reference_statement" {
            for_each = try(statement.value.ip_set_reference_statement, null) != null ? [statement.value.ip_set_reference_statement] : []
            content {
              arn = try(
                aws_wafv2_ip_set.this[ip_set_reference_statement.value.name].arn,
                ip_set_reference_statement.value.arn
              )
              dynamic "ip_set_forwarded_ip_config" {
                for_each = try(ip_set_reference_statement.value.ip_set_forwarded_ip_config, null) != null ? [ip_set_reference_statement.value.ip_set_forwarded_ip_config] : []
                content {
                  fallback_behavior = ip_set_forwarded_ip_config.value.fallback_behavior
                  header_name       = ip_set_forwarded_ip_config.value.header_name
                  position          = ip_set_forwarded_ip_config.value.position
                }
              }
            }
          }

          # Rate-Based Statement
          dynamic "rate_based_statement" {
            for_each = try(statement.value.rate_based_statement, null) != null ? [statement.value.rate_based_statement] : []
            content {
              limit                 = rate_based_statement.value.limit
              aggregate_key_type    = try(rate_based_statement.value.aggregate_key_type, "IP")
              evaluation_window_sec = try(rate_based_statement.value.evaluation_window_sec, null)

              dynamic "forwarded_ip_config" {
                for_each = try(rate_based_statement.value.forwarded_ip_config, null) != null ? [rate_based_statement.value.forwarded_ip_config] : []
                content {
                  fallback_behavior = forwarded_ip_config.value.fallback_behavior
                  header_name       = forwarded_ip_config.value.header_name
                }
              }

              dynamic "custom_key" {
                for_each = try(rate_based_statement.value.custom_keys, [])
                content {
                  dynamic "header" {
                    for_each = try(custom_key.value.header, null) != null ? [custom_key.value.header] : []
                    content {
                      name = lower(header.value.name)
                      dynamic "text_transformation" {
                        for_each = try(header.value.text_transformations, [])
                        content {
                          priority = text_transformation.value.priority
                          type     = text_transformation.value.type
                        }
                      }
                    }
                  }
                  dynamic "ip" {
                    for_each = try(custom_key.value.ip, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "forwarded_ip" {
                    for_each = try(custom_key.value.forwarded_ip, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "query_string" {
                    for_each = try(custom_key.value.query_string, null) != null ? [custom_key.value.query_string] : []
                    content {
                      dynamic "text_transformation" {
                        for_each = try(query_string.value.text_transformations, [])
                        content {
                          priority = text_transformation.value.priority
                          type     = text_transformation.value.type
                        }
                      }
                    }
                  }
                  dynamic "uri_path" {
                    for_each = try(custom_key.value.uri_path, null) != null ? [custom_key.value.uri_path] : []
                    content {
                      dynamic "text_transformation" {
                        for_each = try(uri_path.value.text_transformations, [])
                        content {
                          priority = text_transformation.value.priority
                          type     = text_transformation.value.type
                        }
                      }
                    }
                  }
                  dynamic "label_namespace" {
                    for_each = try(custom_key.value.label_namespace, null) != null ? [custom_key.value.label_namespace] : []
                    content { namespace = label_namespace.value.namespace }
                  }
                }
              }

              # Scope-down statement for rate-based
              dynamic "scope_down_statement" {
                for_each = try(rate_based_statement.value.scope_down_statement, null) != null ? [rate_based_statement.value.scope_down_statement] : []
                content {
                  dynamic "ip_set_reference_statement" {
                    for_each = try(scope_down_statement.value.ip_set_reference_statement, null) != null ? [scope_down_statement.value.ip_set_reference_statement] : []
                    content {
                      arn = try(
                        aws_wafv2_ip_set.this[ip_set_reference_statement.value.name].arn,
                        ip_set_reference_statement.value.arn
                      )
                    }
                  }
                  dynamic "geo_match_statement" {
                    for_each = try(scope_down_statement.value.geo_match_statement, null) != null ? [scope_down_statement.value.geo_match_statement] : []
                    content {
                      country_codes = geo_match_statement.value.country_codes
                    }
                  }
                  dynamic "byte_match_statement" {
                    for_each = try(scope_down_statement.value.byte_match_statement, null) != null ? [scope_down_statement.value.byte_match_statement] : []
                    content {
                      positional_constraint = byte_match_statement.value.positional_constraint
                      search_string         = byte_match_statement.value.search_string
                      dynamic "field_to_match" {
                        for_each = [try(byte_match_statement.value.field_to_match, {})]
                        content {
                          dynamic "uri_path" {
                            for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                            content {}
                          }
                          dynamic "query_string" {
                            for_each = try(field_to_match.value.query_string, null) != null ? [1] : []
                            content {}
                          }
                          dynamic "single_header" {
                            for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
                            content { name = lower(single_header.value.name) }
                          }
                          dynamic "body" {
                            for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                            content { oversize_handling = try(body.value.oversize_handling, "CONTINUE") }
                          }
                        }
                      }
                      dynamic "text_transformation" {
                        for_each = try(byte_match_statement.value.text_transformations, [])
                        content {
                          priority = text_transformation.value.priority
                          type     = text_transformation.value.type
                        }
                      }
                    }
                  }
                  dynamic "not_statement" {
                    for_each = try(scope_down_statement.value.not_statement, null) != null ? [scope_down_statement.value.not_statement] : []
                    content {
                      statement {
                        dynamic "geo_match_statement" {
                          for_each = try(not_statement.value.statement.geo_match_statement, null) != null ? [not_statement.value.statement.geo_match_statement] : []
                          content { country_codes = geo_match_statement.value.country_codes }
                        }
                        dynamic "ip_set_reference_statement" {
                          for_each = try(not_statement.value.statement.ip_set_reference_statement, null) != null ? [not_statement.value.statement.ip_set_reference_statement] : []
                          content {
                            arn = try(
                              aws_wafv2_ip_set.this[ip_set_reference_statement.value.name].arn,
                              ip_set_reference_statement.value.arn
                            )
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }

          # Geo Match Statement
          dynamic "geo_match_statement" {
            for_each = try(statement.value.geo_match_statement, null) != null ? [statement.value.geo_match_statement] : []
            content {
              country_codes = geo_match_statement.value.country_codes
              dynamic "forwarded_ip_config" {
                for_each = try(geo_match_statement.value.forwarded_ip_config, null) != null ? [geo_match_statement.value.forwarded_ip_config] : []
                content {
                  fallback_behavior = forwarded_ip_config.value.fallback_behavior
                  header_name       = forwarded_ip_config.value.header_name
                }
              }
            }
          }

          # Byte Match Statement
          dynamic "byte_match_statement" {
            for_each = try(statement.value.byte_match_statement, null) != null ? [statement.value.byte_match_statement] : []
            content {
              positional_constraint = byte_match_statement.value.positional_constraint
              search_string         = byte_match_statement.value.search_string
              dynamic "field_to_match" {
                for_each = [try(byte_match_statement.value.field_to_match, {})]
                content {
                  dynamic "uri_path" {
                    for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "query_string" {
                    for_each = try(field_to_match.value.query_string, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "method" {
                    for_each = try(field_to_match.value.method, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "all_query_arguments" {
                    for_each = try(field_to_match.value.all_query_arguments, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "body" {
                    for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                    content { oversize_handling = try(body.value.oversize_handling, "CONTINUE") }
                  }
                  dynamic "single_header" {
                    for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
                    content { name = lower(single_header.value.name) }
                  }
                  dynamic "single_query_argument" {
                    for_each = try(field_to_match.value.single_query_argument, null) != null ? [field_to_match.value.single_query_argument] : []
                    content { name = lower(single_query_argument.value.name) }
                  }
                  dynamic "uri_fragment" {
                    for_each = try(field_to_match.value.uri_fragment, null) != null ? [field_to_match.value.uri_fragment] : []
                    content { fallback_behavior = try(uri_fragment.value.fallback_behavior, null) }
                  }
                  dynamic "header_order" {
                    for_each = try(field_to_match.value.header_order, null) != null ? [field_to_match.value.header_order] : []
                    content { oversize_handling = try(header_order.value.oversize_handling, "CONTINUE") }
                  }
                  dynamic "ja3_fingerprint" {
                    for_each = try(field_to_match.value.ja3_fingerprint, null) != null ? [field_to_match.value.ja3_fingerprint] : []
                    content { fallback_behavior = try(ja3_fingerprint.value.fallback_behavior, "MATCH") }
                  }
                  dynamic "ja4_fingerprint" {
                    for_each = try(field_to_match.value.ja4_fingerprint, null) != null ? [field_to_match.value.ja4_fingerprint] : []
                    content { fallback_behavior = try(ja4_fingerprint.value.fallback_behavior, "MATCH") }
                  }
                  dynamic "cookies" {
                    for_each = try(field_to_match.value.cookies, null) != null ? [field_to_match.value.cookies] : []
                    content {
                      match_scope       = upper(cookies.value.match_scope)
                      oversize_handling = try(cookies.value.oversize_handling, "CONTINUE")
                      match_pattern {
                        dynamic "all" {
                          for_each = try(cookies.value.match_pattern.all, null) != null ? [1] : []
                          content {}
                        }
                        included_cookies = try(cookies.value.match_pattern.included_cookies, null)
                        excluded_cookies = try(cookies.value.match_pattern.excluded_cookies, null)
                      }
                    }
                  }
                  dynamic "headers" {
                    for_each = try(field_to_match.value.headers, null) != null ? [field_to_match.value.headers] : []
                    content {
                      match_scope       = upper(headers.value.match_scope)
                      oversize_handling = try(headers.value.oversize_handling, "CONTINUE")
                      match_pattern {
                        dynamic "all" {
                          for_each = try(headers.value.match_pattern.all, null) != null ? [1] : []
                          content {}
                        }
                        included_headers = try(headers.value.match_pattern.included_headers, null)
                        excluded_headers = try(headers.value.match_pattern.excluded_headers, null)
                      }
                    }
                  }
                  dynamic "json_body" {
                    for_each = try(field_to_match.value.json_body, null) != null ? [field_to_match.value.json_body] : []
                    content {
                      match_scope               = upper(json_body.value.match_scope)
                      oversize_handling         = try(json_body.value.oversize_handling, "CONTINUE")
                      invalid_fallback_behavior = try(json_body.value.invalid_fallback_behavior, null)
                      match_pattern {
                        dynamic "all" {
                          for_each = try(json_body.value.match_pattern.all, null) != null ? [1] : []
                          content {}
                        }
                        included_paths = try(json_body.value.match_pattern.included_paths, null)
                      }
                    }
                  }
                }
              }
              dynamic "text_transformation" {
                for_each = try(byte_match_statement.value.text_transformations, [])
                content {
                  priority = text_transformation.value.priority
                  type     = text_transformation.value.type
                }
              }
            }
          }

          # Regex Match Statement
          dynamic "regex_match_statement" {
            for_each = try(statement.value.regex_match_statement, null) != null ? [statement.value.regex_match_statement] : []
            content {
              regex_string = regex_match_statement.value.regex_string
              dynamic "field_to_match" {
                for_each = [try(regex_match_statement.value.field_to_match, {})]
                content {
                  dynamic "uri_path" {
                    for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "query_string" {
                    for_each = try(field_to_match.value.query_string, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "method" {
                    for_each = try(field_to_match.value.method, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "all_query_arguments" {
                    for_each = try(field_to_match.value.all_query_arguments, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "body" {
                    for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                    content { oversize_handling = try(body.value.oversize_handling, "CONTINUE") }
                  }
                  dynamic "single_header" {
                    for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
                    content { name = lower(single_header.value.name) }
                  }
                  dynamic "single_query_argument" {
                    for_each = try(field_to_match.value.single_query_argument, null) != null ? [field_to_match.value.single_query_argument] : []
                    content { name = lower(single_query_argument.value.name) }
                  }
                  dynamic "json_body" {
                    for_each = try(field_to_match.value.json_body, null) != null ? [field_to_match.value.json_body] : []
                    content {
                      match_scope               = upper(json_body.value.match_scope)
                      oversize_handling         = try(json_body.value.oversize_handling, "CONTINUE")
                      invalid_fallback_behavior = try(json_body.value.invalid_fallback_behavior, null)
                      match_pattern {
                        dynamic "all" {
                          for_each = try(json_body.value.match_pattern.all, null) != null ? [1] : []
                          content {}
                        }
                        included_paths = try(json_body.value.match_pattern.included_paths, null)
                      }
                    }
                  }
                }
              }
              dynamic "text_transformation" {
                for_each = try(regex_match_statement.value.text_transformations, [])
                content {
                  priority = text_transformation.value.priority
                  type     = text_transformation.value.type
                }
              }
            }
          }

          # Regex Pattern Set Reference Statement
          dynamic "regex_pattern_set_reference_statement" {
            for_each = try(statement.value.regex_pattern_set_reference_statement, null) != null ? [statement.value.regex_pattern_set_reference_statement] : []
            content {
              arn = try(
                aws_wafv2_regex_pattern_set.this[regex_pattern_set_reference_statement.value.name].arn,
                regex_pattern_set_reference_statement.value.arn
              )
              dynamic "field_to_match" {
                for_each = [try(regex_pattern_set_reference_statement.value.field_to_match, {})]
                content {
                  dynamic "uri_path" {
                    for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "query_string" {
                    for_each = try(field_to_match.value.query_string, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "method" {
                    for_each = try(field_to_match.value.method, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "body" {
                    for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                    content { oversize_handling = try(body.value.oversize_handling, "CONTINUE") }
                  }
                  dynamic "single_header" {
                    for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
                    content { name = lower(single_header.value.name) }
                  }
                  dynamic "single_query_argument" {
                    for_each = try(field_to_match.value.single_query_argument, null) != null ? [field_to_match.value.single_query_argument] : []
                    content { name = lower(single_query_argument.value.name) }
                  }
                }
              }
              dynamic "text_transformation" {
                for_each = try(regex_pattern_set_reference_statement.value.text_transformations, [])
                content {
                  priority = text_transformation.value.priority
                  type     = text_transformation.value.type
                }
              }
            }
          }

          # SQL Injection Match Statement
          dynamic "sqli_match_statement" {
            for_each = try(statement.value.sqli_match_statement, null) != null ? [statement.value.sqli_match_statement] : []
            content {
              sensitivity_level = try(sqli_match_statement.value.sensitivity_level, null)
              dynamic "field_to_match" {
                for_each = [try(sqli_match_statement.value.field_to_match, {})]
                content {
                  dynamic "uri_path" {
                    for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "query_string" {
                    for_each = try(field_to_match.value.query_string, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "method" {
                    for_each = try(field_to_match.value.method, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "all_query_arguments" {
                    for_each = try(field_to_match.value.all_query_arguments, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "body" {
                    for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                    content { oversize_handling = try(body.value.oversize_handling, "CONTINUE") }
                  }
                  dynamic "single_header" {
                    for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
                    content { name = lower(single_header.value.name) }
                  }
                  dynamic "single_query_argument" {
                    for_each = try(field_to_match.value.single_query_argument, null) != null ? [field_to_match.value.single_query_argument] : []
                    content { name = lower(single_query_argument.value.name) }
                  }
                  dynamic "json_body" {
                    for_each = try(field_to_match.value.json_body, null) != null ? [field_to_match.value.json_body] : []
                    content {
                      match_scope               = upper(json_body.value.match_scope)
                      oversize_handling         = try(json_body.value.oversize_handling, "CONTINUE")
                      invalid_fallback_behavior = try(json_body.value.invalid_fallback_behavior, null)
                      match_pattern {
                        dynamic "all" {
                          for_each = try(json_body.value.match_pattern.all, null) != null ? [1] : []
                          content {}
                        }
                        included_paths = try(json_body.value.match_pattern.included_paths, null)
                      }
                    }
                  }
                }
              }
              dynamic "text_transformation" {
                for_each = try(sqli_match_statement.value.text_transformations, [])
                content {
                  priority = text_transformation.value.priority
                  type     = text_transformation.value.type
                }
              }
            }
          }

          # XSS Match Statement
          dynamic "xss_match_statement" {
            for_each = try(statement.value.xss_match_statement, null) != null ? [statement.value.xss_match_statement] : []
            content {
              dynamic "field_to_match" {
                for_each = [try(xss_match_statement.value.field_to_match, {})]
                content {
                  dynamic "uri_path" {
                    for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "query_string" {
                    for_each = try(field_to_match.value.query_string, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "method" {
                    for_each = try(field_to_match.value.method, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "all_query_arguments" {
                    for_each = try(field_to_match.value.all_query_arguments, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "body" {
                    for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                    content { oversize_handling = try(body.value.oversize_handling, "CONTINUE") }
                  }
                  dynamic "single_header" {
                    for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
                    content { name = lower(single_header.value.name) }
                  }
                  dynamic "single_query_argument" {
                    for_each = try(field_to_match.value.single_query_argument, null) != null ? [field_to_match.value.single_query_argument] : []
                    content { name = lower(single_query_argument.value.name) }
                  }
                  dynamic "json_body" {
                    for_each = try(field_to_match.value.json_body, null) != null ? [field_to_match.value.json_body] : []
                    content {
                      match_scope               = upper(json_body.value.match_scope)
                      oversize_handling         = try(json_body.value.oversize_handling, "CONTINUE")
                      invalid_fallback_behavior = try(json_body.value.invalid_fallback_behavior, null)
                      match_pattern {
                        dynamic "all" {
                          for_each = try(json_body.value.match_pattern.all, null) != null ? [1] : []
                          content {}
                        }
                        included_paths = try(json_body.value.match_pattern.included_paths, null)
                      }
                    }
                  }
                }
              }
              dynamic "text_transformation" {
                for_each = try(xss_match_statement.value.text_transformations, [])
                content {
                  priority = text_transformation.value.priority
                  type     = text_transformation.value.type
                }
              }
            }
          }

          # Size Constraint Statement
          dynamic "size_constraint_statement" {
            for_each = try(statement.value.size_constraint_statement, null) != null ? [statement.value.size_constraint_statement] : []
            content {
              comparison_operator = size_constraint_statement.value.comparison_operator
              size                = size_constraint_statement.value.size
              dynamic "field_to_match" {
                for_each = [try(size_constraint_statement.value.field_to_match, {})]
                content {
                  dynamic "uri_path" {
                    for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "query_string" {
                    for_each = try(field_to_match.value.query_string, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "method" {
                    for_each = try(field_to_match.value.method, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "all_query_arguments" {
                    for_each = try(field_to_match.value.all_query_arguments, null) != null ? [1] : []
                    content {}
                  }
                  dynamic "body" {
                    for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                    content { oversize_handling = try(body.value.oversize_handling, "CONTINUE") }
                  }
                  dynamic "single_header" {
                    for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
                    content { name = lower(single_header.value.name) }
                  }
                  dynamic "single_query_argument" {
                    for_each = try(field_to_match.value.single_query_argument, null) != null ? [field_to_match.value.single_query_argument] : []
                    content { name = lower(single_query_argument.value.name) }
                  }
                  dynamic "json_body" {
                    for_each = try(field_to_match.value.json_body, null) != null ? [field_to_match.value.json_body] : []
                    content {
                      match_scope               = upper(json_body.value.match_scope)
                      oversize_handling         = try(json_body.value.oversize_handling, "CONTINUE")
                      invalid_fallback_behavior = try(json_body.value.invalid_fallback_behavior, null)
                      match_pattern {
                        dynamic "all" {
                          for_each = try(json_body.value.match_pattern.all, null) != null ? [1] : []
                          content {}
                        }
                        included_paths = try(json_body.value.match_pattern.included_paths, null)
                      }
                    }
                  }
                }
              }
              dynamic "text_transformation" {
                for_each = try(size_constraint_statement.value.text_transformations, [])
                content {
                  priority = text_transformation.value.priority
                  type     = text_transformation.value.type
                }
              }
            }
          }

          # Label Match Statement
          dynamic "label_match_statement" {
            for_each = try(statement.value.label_match_statement, null) != null ? [statement.value.label_match_statement] : []
            content {
              scope = upper(label_match_statement.value.scope)
              key   = label_match_statement.value.key
            }
          }

          # ASN Match Statement
          dynamic "asn_match_statement" {
            for_each = try(statement.value.asn_match_statement, null) != null ? [statement.value.asn_match_statement] : []
            content {
              asn_list = asn_match_statement.value.asn_list
              dynamic "forwarded_ip_config" {
                for_each = try(asn_match_statement.value.forwarded_ip_config, null) != null ? [asn_match_statement.value.forwarded_ip_config] : []
                content {
                  fallback_behavior = forwarded_ip_config.value.fallback_behavior
                  header_name       = forwarded_ip_config.value.header_name
                }
              }
            }
          }

          # AND Statement (1 level deep inner statements)
          dynamic "and_statement" {
            for_each = try(statement.value.and_statement, null) != null ? [statement.value.and_statement] : []
            content {
              dynamic "statement" {
                for_each = and_statement.value.statements
                content {
                  dynamic "ip_set_reference_statement" {
                    for_each = try(statement.value.ip_set_reference_statement, null) != null ? [statement.value.ip_set_reference_statement] : []
                    content {
                      arn = try(
                        aws_wafv2_ip_set.this[ip_set_reference_statement.value.name].arn,
                        ip_set_reference_statement.value.arn
                      )
                    }
                  }
                  dynamic "geo_match_statement" {
                    for_each = try(statement.value.geo_match_statement, null) != null ? [statement.value.geo_match_statement] : []
                    content { country_codes = geo_match_statement.value.country_codes }
                  }
                  dynamic "byte_match_statement" {
                    for_each = try(statement.value.byte_match_statement, null) != null ? [statement.value.byte_match_statement] : []
                    content {
                      positional_constraint = byte_match_statement.value.positional_constraint
                      search_string         = byte_match_statement.value.search_string
                      dynamic "field_to_match" {
                        for_each = [try(byte_match_statement.value.field_to_match, {})]
                        content {
                          dynamic "uri_path" {
                            for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                            content {}
                          }
                          dynamic "query_string" {
                            for_each = try(field_to_match.value.query_string, null) != null ? [1] : []
                            content {}
                          }
                          dynamic "single_header" {
                            for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
                            content { name = lower(single_header.value.name) }
                          }
                          dynamic "body" {
                            for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                            content { oversize_handling = try(body.value.oversize_handling, "CONTINUE") }
                          }
                        }
                      }
                      dynamic "text_transformation" {
                        for_each = try(byte_match_statement.value.text_transformations, [])
                        content {
                          priority = text_transformation.value.priority
                          type     = text_transformation.value.type
                        }
                      }
                    }
                  }
                  dynamic "regex_match_statement" {
                    for_each = try(statement.value.regex_match_statement, null) != null ? [statement.value.regex_match_statement] : []
                    content {
                      regex_string = regex_match_statement.value.regex_string
                      dynamic "field_to_match" {
                        for_each = [try(regex_match_statement.value.field_to_match, {})]
                        content {
                          dynamic "uri_path" {
                            for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                            content {}
                          }
                          dynamic "single_header" {
                            for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
                            content { name = lower(single_header.value.name) }
                          }
                        }
                      }
                      dynamic "text_transformation" {
                        for_each = try(regex_match_statement.value.text_transformations, [])
                        content {
                          priority = text_transformation.value.priority
                          type     = text_transformation.value.type
                        }
                      }
                    }
                  }
                  dynamic "regex_pattern_set_reference_statement" {
                    for_each = try(statement.value.regex_pattern_set_reference_statement, null) != null ? [statement.value.regex_pattern_set_reference_statement] : []
                    content {
                      arn = try(
                        aws_wafv2_regex_pattern_set.this[regex_pattern_set_reference_statement.value.name].arn,
                        regex_pattern_set_reference_statement.value.arn
                      )
                      dynamic "field_to_match" {
                        for_each = [try(regex_pattern_set_reference_statement.value.field_to_match, {})]
                        content {
                          dynamic "uri_path" {
                            for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                            content {}
                          }
                          dynamic "single_header" {
                            for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
                            content { name = lower(single_header.value.name) }
                          }
                        }
                      }
                      dynamic "text_transformation" {
                        for_each = try(regex_pattern_set_reference_statement.value.text_transformations, [])
                        content {
                          priority = text_transformation.value.priority
                          type     = text_transformation.value.type
                        }
                      }
                    }
                  }
                  dynamic "sqli_match_statement" {
                    for_each = try(statement.value.sqli_match_statement, null) != null ? [statement.value.sqli_match_statement] : []
                    content {
                      sensitivity_level = try(sqli_match_statement.value.sensitivity_level, null)
                      dynamic "field_to_match" {
                        for_each = [try(sqli_match_statement.value.field_to_match, {})]
                        content {
                          dynamic "uri_path" {
                            for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                            content {}
                          }
                          dynamic "query_string" {
                            for_each = try(field_to_match.value.query_string, null) != null ? [1] : []
                            content {}
                          }
                          dynamic "body" {
                            for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                            content { oversize_handling = try(body.value.oversize_handling, "CONTINUE") }
                          }
                        }
                      }
                      dynamic "text_transformation" {
                        for_each = try(sqli_match_statement.value.text_transformations, [])
                        content {
                          priority = text_transformation.value.priority
                          type     = text_transformation.value.type
                        }
                      }
                    }
                  }
                  dynamic "xss_match_statement" {
                    for_each = try(statement.value.xss_match_statement, null) != null ? [statement.value.xss_match_statement] : []
                    content {
                      dynamic "field_to_match" {
                        for_each = [try(xss_match_statement.value.field_to_match, {})]
                        content {
                          dynamic "uri_path" {
                            for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                            content {}
                          }
                          dynamic "query_string" {
                            for_each = try(field_to_match.value.query_string, null) != null ? [1] : []
                            content {}
                          }
                          dynamic "body" {
                            for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                            content { oversize_handling = try(body.value.oversize_handling, "CONTINUE") }
                          }
                        }
                      }
                      dynamic "text_transformation" {
                        for_each = try(xss_match_statement.value.text_transformations, [])
                        content {
                          priority = text_transformation.value.priority
                          type     = text_transformation.value.type
                        }
                      }
                    }
                  }
                  dynamic "size_constraint_statement" {
                    for_each = try(statement.value.size_constraint_statement, null) != null ? [statement.value.size_constraint_statement] : []
                    content {
                      comparison_operator = size_constraint_statement.value.comparison_operator
                      size                = size_constraint_statement.value.size
                      dynamic "field_to_match" {
                        for_each = [try(size_constraint_statement.value.field_to_match, {})]
                        content {
                          dynamic "uri_path" {
                            for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                            content {}
                          }
                          dynamic "body" {
                            for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                            content { oversize_handling = try(body.value.oversize_handling, "CONTINUE") }
                          }
                        }
                      }
                      dynamic "text_transformation" {
                        for_each = try(size_constraint_statement.value.text_transformations, [])
                        content {
                          priority = text_transformation.value.priority
                          type     = text_transformation.value.type
                        }
                      }
                    }
                  }
                  dynamic "label_match_statement" {
                    for_each = try(statement.value.label_match_statement, null) != null ? [statement.value.label_match_statement] : []
                    content {
                      scope = upper(label_match_statement.value.scope)
                      key   = label_match_statement.value.key
                    }
                  }
                  dynamic "asn_match_statement" {
                    for_each = try(statement.value.asn_match_statement, null) != null ? [statement.value.asn_match_statement] : []
                    content { asn_list = asn_match_statement.value.asn_list }
                  }
                }
              }
            }
          }

          # OR Statement (1 level deep inner statements)
          dynamic "or_statement" {
            for_each = try(statement.value.or_statement, null) != null ? [statement.value.or_statement] : []
            content {
              dynamic "statement" {
                for_each = or_statement.value.statements
                content {
                  dynamic "ip_set_reference_statement" {
                    for_each = try(statement.value.ip_set_reference_statement, null) != null ? [statement.value.ip_set_reference_statement] : []
                    content {
                      arn = try(
                        aws_wafv2_ip_set.this[ip_set_reference_statement.value.name].arn,
                        ip_set_reference_statement.value.arn
                      )
                    }
                  }
                  dynamic "geo_match_statement" {
                    for_each = try(statement.value.geo_match_statement, null) != null ? [statement.value.geo_match_statement] : []
                    content { country_codes = geo_match_statement.value.country_codes }
                  }
                  dynamic "byte_match_statement" {
                    for_each = try(statement.value.byte_match_statement, null) != null ? [statement.value.byte_match_statement] : []
                    content {
                      positional_constraint = byte_match_statement.value.positional_constraint
                      search_string         = byte_match_statement.value.search_string
                      dynamic "field_to_match" {
                        for_each = [try(byte_match_statement.value.field_to_match, {})]
                        content {
                          dynamic "uri_path" {
                            for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                            content {}
                          }
                          dynamic "query_string" {
                            for_each = try(field_to_match.value.query_string, null) != null ? [1] : []
                            content {}
                          }
                          dynamic "single_header" {
                            for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
                            content { name = lower(single_header.value.name) }
                          }
                          dynamic "body" {
                            for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                            content { oversize_handling = try(body.value.oversize_handling, "CONTINUE") }
                          }
                        }
                      }
                      dynamic "text_transformation" {
                        for_each = try(byte_match_statement.value.text_transformations, [])
                        content {
                          priority = text_transformation.value.priority
                          type     = text_transformation.value.type
                        }
                      }
                    }
                  }
                  dynamic "regex_match_statement" {
                    for_each = try(statement.value.regex_match_statement, null) != null ? [statement.value.regex_match_statement] : []
                    content {
                      regex_string = regex_match_statement.value.regex_string
                      dynamic "field_to_match" {
                        for_each = [try(regex_match_statement.value.field_to_match, {})]
                        content {
                          dynamic "uri_path" {
                            for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                            content {}
                          }
                          dynamic "single_header" {
                            for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
                            content { name = lower(single_header.value.name) }
                          }
                        }
                      }
                      dynamic "text_transformation" {
                        for_each = try(regex_match_statement.value.text_transformations, [])
                        content {
                          priority = text_transformation.value.priority
                          type     = text_transformation.value.type
                        }
                      }
                    }
                  }
                  dynamic "regex_pattern_set_reference_statement" {
                    for_each = try(statement.value.regex_pattern_set_reference_statement, null) != null ? [statement.value.regex_pattern_set_reference_statement] : []
                    content {
                      arn = try(
                        aws_wafv2_regex_pattern_set.this[regex_pattern_set_reference_statement.value.name].arn,
                        regex_pattern_set_reference_statement.value.arn
                      )
                      dynamic "field_to_match" {
                        for_each = [try(regex_pattern_set_reference_statement.value.field_to_match, {})]
                        content {
                          dynamic "uri_path" {
                            for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                            content {}
                          }
                          dynamic "single_header" {
                            for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
                            content { name = lower(single_header.value.name) }
                          }
                        }
                      }
                      dynamic "text_transformation" {
                        for_each = try(regex_pattern_set_reference_statement.value.text_transformations, [])
                        content {
                          priority = text_transformation.value.priority
                          type     = text_transformation.value.type
                        }
                      }
                    }
                  }
                  dynamic "sqli_match_statement" {
                    for_each = try(statement.value.sqli_match_statement, null) != null ? [statement.value.sqli_match_statement] : []
                    content {
                      sensitivity_level = try(sqli_match_statement.value.sensitivity_level, null)
                      dynamic "field_to_match" {
                        for_each = [try(sqli_match_statement.value.field_to_match, {})]
                        content {
                          dynamic "uri_path" {
                            for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                            content {}
                          }
                          dynamic "query_string" {
                            for_each = try(field_to_match.value.query_string, null) != null ? [1] : []
                            content {}
                          }
                          dynamic "body" {
                            for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                            content { oversize_handling = try(body.value.oversize_handling, "CONTINUE") }
                          }
                        }
                      }
                      dynamic "text_transformation" {
                        for_each = try(sqli_match_statement.value.text_transformations, [])
                        content {
                          priority = text_transformation.value.priority
                          type     = text_transformation.value.type
                        }
                      }
                    }
                  }
                  dynamic "xss_match_statement" {
                    for_each = try(statement.value.xss_match_statement, null) != null ? [statement.value.xss_match_statement] : []
                    content {
                      dynamic "field_to_match" {
                        for_each = [try(xss_match_statement.value.field_to_match, {})]
                        content {
                          dynamic "uri_path" {
                            for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                            content {}
                          }
                          dynamic "query_string" {
                            for_each = try(field_to_match.value.query_string, null) != null ? [1] : []
                            content {}
                          }
                          dynamic "body" {
                            for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                            content { oversize_handling = try(body.value.oversize_handling, "CONTINUE") }
                          }
                        }
                      }
                      dynamic "text_transformation" {
                        for_each = try(xss_match_statement.value.text_transformations, [])
                        content {
                          priority = text_transformation.value.priority
                          type     = text_transformation.value.type
                        }
                      }
                    }
                  }
                  dynamic "size_constraint_statement" {
                    for_each = try(statement.value.size_constraint_statement, null) != null ? [statement.value.size_constraint_statement] : []
                    content {
                      comparison_operator = size_constraint_statement.value.comparison_operator
                      size                = size_constraint_statement.value.size
                      dynamic "field_to_match" {
                        for_each = [try(size_constraint_statement.value.field_to_match, {})]
                        content {
                          dynamic "uri_path" {
                            for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                            content {}
                          }
                          dynamic "body" {
                            for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                            content { oversize_handling = try(body.value.oversize_handling, "CONTINUE") }
                          }
                        }
                      }
                      dynamic "text_transformation" {
                        for_each = try(size_constraint_statement.value.text_transformations, [])
                        content {
                          priority = text_transformation.value.priority
                          type     = text_transformation.value.type
                        }
                      }
                    }
                  }
                  dynamic "label_match_statement" {
                    for_each = try(statement.value.label_match_statement, null) != null ? [statement.value.label_match_statement] : []
                    content {
                      scope = upper(label_match_statement.value.scope)
                      key   = label_match_statement.value.key
                    }
                  }
                  dynamic "asn_match_statement" {
                    for_each = try(statement.value.asn_match_statement, null) != null ? [statement.value.asn_match_statement] : []
                    content { asn_list = asn_match_statement.value.asn_list }
                  }
                }
              }
            }
          }

          # NOT Statement (1 level deep inner statement)
          dynamic "not_statement" {
            for_each = try(statement.value.not_statement, null) != null ? [statement.value.not_statement] : []
            content {
              statement {
                dynamic "ip_set_reference_statement" {
                  for_each = try(not_statement.value.statement.ip_set_reference_statement, null) != null ? [not_statement.value.statement.ip_set_reference_statement] : []
                  content {
                    arn = try(
                      aws_wafv2_ip_set.this[ip_set_reference_statement.value.name].arn,
                      ip_set_reference_statement.value.arn
                    )
                  }
                }
                dynamic "geo_match_statement" {
                  for_each = try(not_statement.value.statement.geo_match_statement, null) != null ? [not_statement.value.statement.geo_match_statement] : []
                  content { country_codes = geo_match_statement.value.country_codes }
                }
                dynamic "byte_match_statement" {
                  for_each = try(not_statement.value.statement.byte_match_statement, null) != null ? [not_statement.value.statement.byte_match_statement] : []
                  content {
                    positional_constraint = byte_match_statement.value.positional_constraint
                    search_string         = byte_match_statement.value.search_string
                    dynamic "field_to_match" {
                      for_each = [try(byte_match_statement.value.field_to_match, {})]
                      content {
                        dynamic "uri_path" {
                          for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                          content {}
                        }
                        dynamic "query_string" {
                          for_each = try(field_to_match.value.query_string, null) != null ? [1] : []
                          content {}
                        }
                        dynamic "single_header" {
                          for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
                          content { name = lower(single_header.value.name) }
                        }
                        dynamic "body" {
                          for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                          content { oversize_handling = try(body.value.oversize_handling, "CONTINUE") }
                        }
                      }
                    }
                    dynamic "text_transformation" {
                      for_each = try(byte_match_statement.value.text_transformations, [])
                      content {
                        priority = text_transformation.value.priority
                        type     = text_transformation.value.type
                      }
                    }
                  }
                }
                dynamic "regex_match_statement" {
                  for_each = try(not_statement.value.statement.regex_match_statement, null) != null ? [not_statement.value.statement.regex_match_statement] : []
                  content {
                    regex_string = regex_match_statement.value.regex_string
                    dynamic "field_to_match" {
                      for_each = [try(regex_match_statement.value.field_to_match, {})]
                      content {
                        dynamic "uri_path" {
                          for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                          content {}
                        }
                        dynamic "single_header" {
                          for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
                          content { name = lower(single_header.value.name) }
                        }
                      }
                    }
                    dynamic "text_transformation" {
                      for_each = try(regex_match_statement.value.text_transformations, [])
                      content {
                        priority = text_transformation.value.priority
                        type     = text_transformation.value.type
                      }
                    }
                  }
                }
                dynamic "regex_pattern_set_reference_statement" {
                  for_each = try(not_statement.value.statement.regex_pattern_set_reference_statement, null) != null ? [not_statement.value.statement.regex_pattern_set_reference_statement] : []
                  content {
                    arn = try(
                      aws_wafv2_regex_pattern_set.this[regex_pattern_set_reference_statement.value.name].arn,
                      regex_pattern_set_reference_statement.value.arn
                    )
                    dynamic "field_to_match" {
                      for_each = [try(regex_pattern_set_reference_statement.value.field_to_match, {})]
                      content {
                        dynamic "uri_path" {
                          for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                          content {}
                        }
                        dynamic "single_header" {
                          for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
                          content { name = lower(single_header.value.name) }
                        }
                      }
                    }
                    dynamic "text_transformation" {
                      for_each = try(regex_pattern_set_reference_statement.value.text_transformations, [])
                      content {
                        priority = text_transformation.value.priority
                        type     = text_transformation.value.type
                      }
                    }
                  }
                }
                dynamic "sqli_match_statement" {
                  for_each = try(not_statement.value.statement.sqli_match_statement, null) != null ? [not_statement.value.statement.sqli_match_statement] : []
                  content {
                    sensitivity_level = try(sqli_match_statement.value.sensitivity_level, null)
                    dynamic "field_to_match" {
                      for_each = [try(sqli_match_statement.value.field_to_match, {})]
                      content {
                        dynamic "uri_path" {
                          for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                          content {}
                        }
                        dynamic "query_string" {
                          for_each = try(field_to_match.value.query_string, null) != null ? [1] : []
                          content {}
                        }
                        dynamic "body" {
                          for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                          content { oversize_handling = try(body.value.oversize_handling, "CONTINUE") }
                        }
                      }
                    }
                    dynamic "text_transformation" {
                      for_each = try(sqli_match_statement.value.text_transformations, [])
                      content {
                        priority = text_transformation.value.priority
                        type     = text_transformation.value.type
                      }
                    }
                  }
                }
                dynamic "xss_match_statement" {
                  for_each = try(not_statement.value.statement.xss_match_statement, null) != null ? [not_statement.value.statement.xss_match_statement] : []
                  content {
                    dynamic "field_to_match" {
                      for_each = [try(xss_match_statement.value.field_to_match, {})]
                      content {
                        dynamic "uri_path" {
                          for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                          content {}
                        }
                        dynamic "query_string" {
                          for_each = try(field_to_match.value.query_string, null) != null ? [1] : []
                          content {}
                        }
                        dynamic "body" {
                          for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                          content { oversize_handling = try(body.value.oversize_handling, "CONTINUE") }
                        }
                      }
                    }
                    dynamic "text_transformation" {
                      for_each = try(xss_match_statement.value.text_transformations, [])
                      content {
                        priority = text_transformation.value.priority
                        type     = text_transformation.value.type
                      }
                    }
                  }
                }
                dynamic "size_constraint_statement" {
                  for_each = try(not_statement.value.statement.size_constraint_statement, null) != null ? [not_statement.value.statement.size_constraint_statement] : []
                  content {
                    comparison_operator = size_constraint_statement.value.comparison_operator
                    size                = size_constraint_statement.value.size
                    dynamic "field_to_match" {
                      for_each = [try(size_constraint_statement.value.field_to_match, {})]
                      content {
                        dynamic "uri_path" {
                          for_each = try(field_to_match.value.uri_path, null) != null ? [1] : []
                          content {}
                        }
                        dynamic "body" {
                          for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                          content { oversize_handling = try(body.value.oversize_handling, "CONTINUE") }
                        }
                      }
                    }
                    dynamic "text_transformation" {
                      for_each = try(size_constraint_statement.value.text_transformations, [])
                      content {
                        priority = text_transformation.value.priority
                        type     = text_transformation.value.type
                      }
                    }
                  }
                }
                dynamic "label_match_statement" {
                  for_each = try(not_statement.value.statement.label_match_statement, null) != null ? [not_statement.value.statement.label_match_statement] : []
                  content {
                    scope = upper(label_match_statement.value.scope)
                    key   = label_match_statement.value.key
                  }
                }
                dynamic "asn_match_statement" {
                  for_each = try(not_statement.value.statement.asn_match_statement, null) != null ? [not_statement.value.statement.asn_match_statement] : []
                  content { asn_list = asn_match_statement.value.asn_list }
                }
              }
            }
          }

        } # end statement content
      }   # end statement dynamic

      # Rule labels
      dynamic "rule_label" {
        for_each = try(rule.value.rule_labels, [])
        content {
          name = rule_label.value
        }
      }

      # Per-rule captcha config
      dynamic "captcha_config" {
        for_each = try(rule.value.captcha_config, null) != null ? [rule.value.captcha_config] : []
        content {
          immunity_time_property {
            immunity_time = captcha_config.value.immunity_time
          }
        }
      }

      # Per-rule challenge config
      dynamic "challenge_config" {
        for_each = try(rule.value.challenge_config, null) != null ? [rule.value.challenge_config] : []
        content {
          immunity_time_property {
            immunity_time = challenge_config.value.immunity_time
          }
        }
      }

      # Per-rule visibility config (falls back to web ACL visibility config)
      visibility_config {
        cloudwatch_metrics_enabled = try(rule.value.visibility_config.cloudwatch_metrics_enabled, var.visibility_config.cloudwatch_metrics_enabled)
        metric_name                = try(rule.value.visibility_config.metric_name, "${var.name}-${rule.value.name}")
        sampled_requests_enabled   = try(rule.value.visibility_config.sampled_requests_enabled, var.visibility_config.sampled_requests_enabled)
      }

    } # end rule content
  }   # end rule dynamic

  # --------------------------------------------------
  # Web ACL Visibility Config
  # --------------------------------------------------
  visibility_config {
    cloudwatch_metrics_enabled = try(var.visibility_config.cloudwatch_metrics_enabled, true)
    metric_name                = try(var.visibility_config.metric_name, var.name)
    sampled_requests_enabled   = try(var.visibility_config.sampled_requests_enabled, true)
  }

  # --------------------------------------------------
  # Association Config (request body size per resource type)
  # --------------------------------------------------
  dynamic "association_config" {
    for_each = var.association_config != null ? [var.association_config] : []
    content {
      dynamic "request_body" {
        for_each = try(association_config.value.request_body, null) != null ? [association_config.value.request_body] : []
        content {
          dynamic "api_gateway" {
            for_each = try(request_body.value.api_gateway, null) != null ? [request_body.value.api_gateway] : []
            content {
              default_size_inspection_limit = api_gateway.value.default_size_inspection_limit
            }
          }
          dynamic "app_runner_service" {
            for_each = try(request_body.value.app_runner_service, null) != null ? [request_body.value.app_runner_service] : []
            content {
              default_size_inspection_limit = app_runner_service.value.default_size_inspection_limit
            }
          }
          dynamic "cloudfront" {
            for_each = try(request_body.value.cloudfront, null) != null ? [request_body.value.cloudfront] : []
            content {
              default_size_inspection_limit = cloudfront.value.default_size_inspection_limit
            }
          }
          dynamic "cognito_user_pool" {
            for_each = try(request_body.value.cognito_user_pool, null) != null ? [request_body.value.cognito_user_pool] : []
            content {
              default_size_inspection_limit = cognito_user_pool.value.default_size_inspection_limit
            }
          }
          dynamic "verified_access_instance" {
            for_each = try(request_body.value.verified_access_instance, null) != null ? [request_body.value.verified_access_instance] : []
            content {
              default_size_inspection_limit = verified_access_instance.value.default_size_inspection_limit
            }
          }
        }
      }
    }
  }

  # --------------------------------------------------
  # Captcha Config (web ACL level immunity time)
  # --------------------------------------------------
  dynamic "captcha_config" {
    for_each = var.captcha_config != null ? [var.captcha_config] : []
    content {
      immunity_time_property {
        immunity_time = captcha_config.value.immunity_time
      }
    }
  }

  # --------------------------------------------------
  # Challenge Config (web ACL level immunity time)
  # --------------------------------------------------
  dynamic "challenge_config" {
    for_each = var.challenge_config != null ? [var.challenge_config] : []
    content {
      immunity_time_property {
        immunity_time = challenge_config.value.immunity_time
      }
    }
  }

  # --------------------------------------------------
  # Data Protection Config
  # --------------------------------------------------
  dynamic "data_protection_config" {
    for_each = var.data_protection_config != null ? [var.data_protection_config] : []
    content {
      dynamic "data_protection" {
        for_each = try(data_protection_config.value.data_protection, [])
        content {
          action                     = upper(data_protection.value.action)
          exclude_rate_based_details = try(data_protection.value.exclude_rate_based_details, null)
          exclude_rule_match_details = try(data_protection.value.exclude_rule_match_details, null)

          dynamic "field" {
            for_each = try(data_protection.value.fields, [])
            content {
              field_type = upper(field.value.field_type)
              field_keys = try(field.value.field_keys, null)
            }
          }
        }
      }
    }
  }

  tags = local.tags

  lifecycle {
    enabled = local.enabled
    # When rule_group_associations is used, rules are managed via
    # aws_wafv2_web_acl_rule_group_association and must be ignored here
    # to prevent Terraform from overwriting externally-managed rule entries.
    ignore_changes = [rule]
  }
}

###################################################
# Web ACL Associations
###################################################
resource "aws_wafv2_web_acl_association" "this" {
  for_each = local.enabled ? var.associations : {}

  resource_arn = each.value
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}

###################################################
# Web ACL Rule Group Associations
###################################################
resource "aws_wafv2_web_acl_rule_group_association" "this" {
  for_each = local.enabled ? var.rule_group_associations : {}

  web_acl_arn     = aws_wafv2_web_acl.this.arn
  priority        = each.value.priority
  rule_name       = each.key
  override_action = try(each.value.override_action, "none")

  # Rule group reference (inline rule group or external ARN)
  dynamic "rule_group_reference" {
    for_each = try(each.value.rule_group_reference, null) != null ? [each.value.rule_group_reference] : []
    content {
      arn = try(
        aws_wafv2_rule_group.this[rule_group_reference.value.name].arn,
        rule_group_reference.value.arn
      )
      dynamic "rule_action_override" {
        for_each = try(rule_group_reference.value.rule_action_overrides, [])
        content {
          name = rule_action_override.value.name
          action_to_use {
            dynamic "allow" {
              for_each = rule_action_override.value.action_to_use == "allow" ? [1] : []
              content {}
            }
            dynamic "block" {
              for_each = rule_action_override.value.action_to_use == "block" ? [1] : []
              content {}
            }
            dynamic "count" {
              for_each = rule_action_override.value.action_to_use == "count" ? [1] : []
              content {}
            }
          }
        }
      }
    }
  }

  # Managed rule group
  dynamic "managed_rule_group" {
    for_each = try(each.value.managed_rule_group, null) != null ? [each.value.managed_rule_group] : []
    content {
      name        = managed_rule_group.value.name
      vendor_name = try(managed_rule_group.value.vendor_name, "AWS")
      version     = try(managed_rule_group.value.version, null)

      dynamic "rule_action_override" {
        for_each = try(managed_rule_group.value.rule_action_overrides, [])
        content {
          name = rule_action_override.value.name
          action_to_use {
            dynamic "allow" {
              for_each = rule_action_override.value.action_to_use == "allow" ? [1] : []
              content {}
            }
            dynamic "block" {
              for_each = rule_action_override.value.action_to_use == "block" ? [1] : []
              content {}
            }
            dynamic "count" {
              for_each = rule_action_override.value.action_to_use == "count" ? [1] : []
              content {}
            }
          }
        }
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = try(each.value.visibility_config.cloudwatch_metrics_enabled, var.visibility_config.cloudwatch_metrics_enabled)
    metric_name                = try(each.value.visibility_config.metric_name, "${var.name}-${each.key}")
    sampled_requests_enabled   = try(each.value.visibility_config.sampled_requests_enabled, var.visibility_config.sampled_requests_enabled)
  }
}

###################################################
# Web ACL Logging Configuration
###################################################
resource "aws_wafv2_web_acl_logging_configuration" "this" {
  log_destination_configs = var.logging_destination_arns
  resource_arn            = aws_wafv2_web_acl.this.arn

  dynamic "logging_filter" {
    for_each = var.logging_filter != null ? [var.logging_filter] : []
    content {
      default_behavior = upper(logging_filter.value.default_behavior)

      dynamic "filter" {
        for_each = try(logging_filter.value.filters, [])
        content {
          behavior    = upper(filter.value.behavior)
          requirement = upper(try(filter.value.requirement, "MEETS_ANY"))

          dynamic "condition" {
            for_each = try(filter.value.conditions, [])
            content {
              dynamic "action_condition" {
                for_each = try(condition.value.action_condition, null) != null ? [condition.value.action_condition] : []
                content {
                  action = upper(action_condition.value.action)
                }
              }
              dynamic "label_name_condition" {
                for_each = try(condition.value.label_name_condition, null) != null ? [condition.value.label_name_condition] : []
                content {
                  label_name = label_name_condition.value.label_name
                }
              }
            }
          }
        }
      }
    }
  }

  dynamic "redacted_fields" {
    for_each = var.logging_redacted_fields
    content {
      dynamic "uri_path" {
        for_each = try(redacted_fields.value.uri_path, null) != null ? [1] : []
        content {}
      }
      dynamic "query_string" {
        for_each = try(redacted_fields.value.query_string, null) != null ? [1] : []
        content {}
      }
      dynamic "method" {
        for_each = try(redacted_fields.value.method, null) != null ? [1] : []
        content {}
      }
      dynamic "single_header" {
        for_each = try(redacted_fields.value.single_header, null) != null ? [redacted_fields.value.single_header] : []
        content {
          name = lower(single_header.value.name)
        }
      }
    }
  }

  lifecycle {
    enabled = local.enabled && length(var.logging_destination_arns) > 0
  }
}
