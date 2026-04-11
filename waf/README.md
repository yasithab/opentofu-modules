# WAFv2 Module

Terraform module for AWS WAFv2 Web ACLs. Supports both REGIONAL (ALB, API Gateway,
AppSync, App Runner, Cognito, Verified Access) and CLOUDFRONT scopes. Provides a
complete solution for creating IP sets, regex pattern sets, rule groups, API keys,
the Web ACL itself, resource associations, and logging configuration - all in a single
module invocation.

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_wafv2_ip_set` | One per entry in `var.ip_sets`. Referenced by name in rules. |
| `aws_wafv2_regex_pattern_set` | One per entry in `var.regex_pattern_sets`. Referenced by name in rules. |
| `aws_wafv2_rule_group` | One per entry in `var.rule_groups`. Referenced by name in rules. |
| `aws_wafv2_api_key` | One per entry in `var.api_keys`. For CAPTCHA/Challenge JavaScript SDK integration. |
| `aws_wafv2_web_acl` | The main Web ACL resource. |
| `aws_wafv2_web_acl_association` | One per entry in `var.associations`. Attaches the Web ACL to a resource ARN. |
| `aws_wafv2_web_acl_rule_group_association` | One per entry in `var.rule_group_associations`. |
| `aws_wafv2_web_acl_logging_configuration` | Created when `var.logging_destination_arns` is non-empty. |

## Design Notes

### Structured Rules vs. rule_json

The module supports two mutually exclusive approaches to rules:

**Structured rules** (`var.rules`): Use HCL objects to define rules. Supports all
common statement types and 1 level of AND/OR/NOT nesting. The module uses `dynamic`
blocks to render only the statement types present in each rule.

**JSON escape hatch** (`var.rule_json`): Pass a raw JSON string directly to the
provider. Use this for rules that require more than 1 level of AND/OR/NOT nesting,
which cannot be expressed in the structured schema. When `rule_json` is set, `var.rules`
is ignored entirely.

### Inline Name Resolution

IP sets, regex pattern sets, and rule groups created by this module can be referenced
by name in rules using their map key. The module resolves the name to the ARN using
`try()`:

```hcl
# In ip_set_reference_statement:
arn = try(aws_wafv2_ip_set.this[stmt.name].arn, stmt.arn)

# In regex_pattern_set_reference_statement:
arn = try(aws_wafv2_regex_pattern_set.this[stmt.name].arn, stmt.arn)

# In rule_group_reference_statement:
arn = try(aws_wafv2_rule_group.this[stmt.name].arn, stmt.arn)
```

If the name does not match any inline resource, the literal `arn` value is used.
You may provide either `name` (for inline resources) or `arn` (for external resources).

### Rule Group Associations and lifecycle ignore_changes

When `var.rule_group_associations` is non-empty, the Web ACL's `rule` attribute is
automatically placed in `lifecycle { ignore_changes = [rule] }`. This prevents
Terraform from overwriting rules that were added by `aws_wafv2_web_acl_rule_group_association`
out-of-band from the Web ACL's inline `rule` blocks.

### Action String vs. Structured Object

Rules support both a simple string and a structured object for `action`:

```hcl
# Simple string
action = "block"

# Structured object with custom response
action = {
  block = {
    response_code            = 403
    custom_response_body_key = "my-error-page"
  }
}
```

## Quick Start

```hcl
module "waf" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//waf?depth=1&ref=master"

  name  = "my-service-waf"
  scope = "REGIONAL"

  rules = [
    {
      name            = "AWSManagedRulesCommonRuleSet"
      priority        = 10
      override_action = "none"
      statement = {
        managed_rule_group_statement = {
          name        = "AWSManagedRulesCommonRuleSet"
          vendor_name = "AWS"
        }
      }
    },
  ]

  associations = {
    my-alb = aws_lb.this.arn
  }

  tags = var.tags
}
```

## Input Variables

### Standard Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `enabled` | `bool` | `true` | Set to false to prevent the module from creating any resources. |
| `name` | `string` | required | Name of the Web ACL. Used as a prefix for related resources. |
| `tags` | `map(string)` | `{}` | Tags to assign to all resources. |

### Core Settings

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `description` | `string` | `null` | Friendly description of the Web ACL. |
| `scope` | `string` | `"REGIONAL"` | `REGIONAL` or `CLOUDFRONT`. CloudFront WACs must be created in us-east-1. |
| `token_domains` | `list(string)` | `[]` | Domains to accept CAPTCHA/challenge tokens from. |

### Default Action

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `default_action` | `string` | `"ALLOW"` | `ALLOW` or `BLOCK`. Action for requests that match no rules. |
| `default_action_config` | `any` | `null` | Custom headers for ALLOW or custom response for BLOCK. |

### Custom Response Bodies

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `custom_response_bodies` | `list(object)` | `[]` | Reusable response body definitions. Each: `{key, content, content_type}`. |

### Visibility Config

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `visibility_config` | `object` | see description | CloudWatch metrics and sampling config. Default: metrics enabled, metric_name=var.name, sampling enabled. |

### Rules

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `rules` | `any` | `[]` | List of structured rule objects. Used when `rule_json` is null. |
| `rule_json` | `string` | `null` | Raw JSON rules string. Takes precedence over `rules` when set. |

### Advanced Web ACL Settings

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `association_config` | `any` | `null` | Request body inspection size limits per resource type (api_gateway, cloudfront, etc.). |
| `captcha_config` | `object({immunity_time=number})` | `null` | Web ACL-level CAPTCHA immunity time in seconds. |
| `challenge_config` | `object({immunity_time=number})` | `null` | Web ACL-level challenge immunity time in seconds. |
| `data_protection_config` | `any` | `null` | Field-level data protection (hashing/substitution) before logging. |

### Helper Resources

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `ip_sets` | `map(object)` | `{}` | IP sets to create. Map key = name. Referenced by name in rules. |
| `regex_pattern_sets` | `map(object)` | `{}` | Regex pattern sets to create. Map key = name. Referenced by name in rules. |
| `rule_groups` | `map(object)` | `{}` | Rule groups to create. Map key = name. Support `rules_json` or structured `rules`. |
| `api_keys` | `map(object)` | `{}` | API keys for CAPTCHA/Challenge JavaScript SDK. Map key = descriptive name. |

### Associations

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `associations` | `map(string)` | `{}` | Map of name to resource ARN. Associates the Web ACL with ALBs, API stages, etc. |
| `rule_group_associations` | `any` | `{}` | Map of rule group associations. Triggers `lifecycle ignore_changes = [rule]` on the Web ACL. |

### Logging

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `logging_destination_arns` | `list(string)` | `[]` | ARNs of CloudWatch log groups, Firehose streams, or S3 buckets. Names must start with `aws-waf-logs-`. |
| `logging_filter` | `any` | `null` | Selective logging filter. `null` = log all requests. |
| `logging_redacted_fields` | `any` | `[]` | Fields to redact from logs (e.g., `authorization` header). |

## Rule Structure Reference

Each rule in `var.rules`:

```hcl
{
  name     = string   # required
  priority = number   # required

  # Use action for ip_set/rate/geo/byte/regex/sqli/xss/size/label/asn rules
  action = "allow" | "block" | "count" | "captcha" | "challenge"
  # OR structured form with custom response/headers:
  action = { block = { response_code = 403, custom_response_body_key = "key" } }

  # Use override_action for managed_rule_group and rule_group_reference rules
  override_action = "none" | "count"

  statement = {
    # Exactly one statement type key:

    managed_rule_group_statement = {
      name        = string          # AWS managed rule group name
      vendor_name = string          # default "AWS"
      version     = string          # optional; pin a specific version
      rule_action_overrides = [     # optional
        { name = "RuleName", action_to_use = "count" }
      ]
      managed_rule_group_configs = {
        aws_managed_rules_bot_control_rule_set = { inspection_level = "TARGETED", enable_machine_learning = true }
        aws_managed_rules_atp_rule_set         = { login_path = "/login", ... }
        aws_managed_rules_acfp_rule_set        = { creation_path = "/signup", registration_page_path = "/register" }
        aws_managed_rules_anti_ddos_rule_set   = { sensitivity_to_block = "LOW" }
      }
      scope_down_statement = { ... }  # optional; restrict which requests this group inspects
    }

    rule_group_reference_statement = {
      arn  = string   # explicit ARN for external rule groups
      name = string   # map key of an inline rule group (resolved to ARN)
      rule_action_overrides = [...]
    }

    ip_set_reference_statement = {
      arn  = string   # explicit ARN
      name = string   # map key of an inline ip_set (resolved to ARN)
      ip_set_forwarded_ip_config = { fallback_behavior = "MATCH", header_name = "X-Forwarded-For", position = "FIRST" }
    }

    rate_based_statement = {
      limit                 = number   # 100–2000000000
      aggregate_key_type    = string   # IP, CONSTANT, CUSTOM_KEYS, FORWARDED_IP
      evaluation_window_sec = number   # 60, 120, 300, 600
      forwarded_ip_config   = { fallback_behavior = "MATCH", header_name = "X-Forwarded-For" }
      custom_keys           = [...]    # for CUSTOM_KEYS aggregate
      scope_down_statement  = { ... }
    }

    geo_match_statement = {
      country_codes       = list(string)
      forwarded_ip_config = { fallback_behavior = "MATCH", header_name = "X-Forwarded-For" }
    }

    byte_match_statement = {
      positional_constraint = string   # EXACTLY, STARTS_WITH, ENDS_WITH, CONTAINS, CONTAINS_WORD
      search_string         = string
      field_to_match        = { ... }
      text_transformations  = [{ priority = number, type = string }]
    }

    regex_match_statement = {
      regex_string         = string
      field_to_match       = { ... }
      text_transformations = [...]
    }

    regex_pattern_set_reference_statement = {
      arn  = string   # explicit ARN
      name = string   # map key of an inline regex_pattern_set (resolved to ARN)
      field_to_match       = { ... }
      text_transformations = [...]
    }

    sqli_match_statement = {
      sensitivity_level    = string   # LOW or HIGH
      field_to_match       = { ... }
      text_transformations = [...]
    }

    xss_match_statement = {
      field_to_match       = { ... }
      text_transformations = [...]
    }

    size_constraint_statement = {
      comparison_operator  = string   # EQ, NE, LE, LT, GE, GT
      size                 = number
      field_to_match       = { ... }
      text_transformations = [...]
    }

    label_match_statement = {
      scope = string   # LABEL or NAMESPACE
      key   = string
    }

    asn_match_statement = {
      asn_list            = list(number)
      forwarded_ip_config = { fallback_behavior = "MATCH", header_name = "X-Forwarded-For" }
    }

    and_statement = {
      statements = [
        { ip_set_reference_statement = { ... } },
        { geo_match_statement = { ... } },
        # any inner statement type - 1 level deep
      ]
    }

    or_statement = {
      statements = [...]
    }

    not_statement = {
      statement = { ... }   # single inner statement - 1 level deep
    }
  }

  rule_labels      = ["awswaf:custom:label-name"]   # optional
  captcha_config   = { immunity_time = 300 }         # optional
  challenge_config = { immunity_time = 300 }         # optional
  visibility_config = {
    cloudwatch_metrics_enabled = bool
    metric_name                = string
    sampled_requests_enabled   = bool
  }
}
```

## field_to_match Reference

Specify exactly one field type inside `field_to_match`:

```hcl
field_to_match = {
  uri_path             = {}
  query_string         = {}
  method               = {}
  all_query_arguments  = {}

  body = { oversize_handling = "CONTINUE" }   # CONTINUE, MATCH, or NO_MATCH

  single_header        = { name = "content-type" }
  single_query_argument = { name = "search" }

  uri_fragment  = { fallback_behavior = "MATCH" }
  header_order  = { oversize_handling = "CONTINUE" }
  ja3_fingerprint = { fallback_behavior = "MATCH" }
  ja4_fingerprint = { fallback_behavior = "MATCH" }

  cookies = {
    match_scope       = "ALL"
    oversize_handling = "CONTINUE"
    match_pattern     = { all = {} }
    # OR: match_pattern = { included_cookies = ["session"] }
  }

  headers = {
    match_scope       = "ALL"
    oversize_handling = "CONTINUE"
    match_pattern     = { all = {} }
    # OR: match_pattern = { included_headers = ["x-custom-header"] }
  }

  json_body = {
    match_scope               = "ALL"
    oversize_handling         = "CONTINUE"
    invalid_fallback_behavior = "EVALUATE_AS_STRING"   # optional
    match_pattern             = { all = {} }
    # OR: match_pattern = { included_paths = ["/userId", "/email"] }
  }
}
```

## Outputs

| Name | Description |
|------|-------------|
| `web_acl_id` | The unique identifier of the Web ACL. |
| `web_acl_arn` | The ARN of the Web ACL. Use this to associate with CloudFront. |
| `web_acl_name` | The name of the Web ACL. |
| `web_acl_capacity` | WCU capacity currently used by this Web ACL. |
| `web_acl_application_integration_url` | URL for SDK integration (CAPTCHA/Challenge). |
| `ip_set_arns` | Map of IP set name to ARN. |
| `ip_set_ids` | Map of IP set name to ID. |
| `regex_pattern_set_arns` | Map of regex pattern set name to ARN. |
| `regex_pattern_set_ids` | Map of regex pattern set name to ID. |
| `rule_group_arns` | Map of rule group name to ARN. |
| `rule_group_ids` | Map of rule group name to ID. |
| `api_keys` | Map of API key name to api_key value. Sensitive. |
| `association_ids` | Map of association name to resource ID. |
| `rule_group_association_ids` | Map of rule group association name to resource ID. |

## Requirements

| Name | Version |
|------|---------|
| OpenTofu | >= 1.11.0 |
| AWS provider | ~> 6.34 |


## Examples

## Example 1 - Basic CloudFront WAF (CLOUDFRONT scope)

Protect a CloudFront distribution with AWS managed rules and geo restriction.
CloudFront-scope Web ACLs must be created in `us-east-1`.

```hcl
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

module "waf_cloudfront" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//waf?depth=1&ref=master"

  providers = {
    aws = aws.us-east-1
  }

  name  = "my-cloudfront-waf"
  scope = "CLOUDFRONT"

  default_action = "ALLOW"

  rules = [
    # AWS Core Rule Set - block common exploits
    {
      name            = "AWSManagedRulesCommonRuleSet"
      priority        = 10
      override_action = "none"
      statement = {
        managed_rule_group_statement = {
          name        = "AWSManagedRulesCommonRuleSet"
          vendor_name = "AWS"
        }
      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesCommonRuleSet"
        sampled_requests_enabled   = true
      }
    },

    # Block traffic from sanctioned countries
    {
      name     = "GeoBlockRule"
      priority = 20
      action   = "block"
      statement = {
        geo_match_statement = {
          country_codes = ["KP", "IR", "CU", "SY"]
        }
      }
    },

    # AWS Known Bad Inputs Rule Set
    {
      name            = "AWSManagedRulesKnownBadInputsRuleSet"
      priority        = 30
      override_action = "none"
      statement = {
        managed_rule_group_statement = {
          name        = "AWSManagedRulesKnownBadInputsRuleSet"
          vendor_name = "AWS"
        }
      }
    },
  ]

  visibility_config = {
    cloudwatch_metrics_enabled = true
    metric_name                = "my-cloudfront-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

---

## Example 2 - ALB WAF (REGIONAL scope)

Protect an Application Load Balancer with rate limiting, an inline IP blocklist,
and a custom block response page.

```hcl
module "waf_alb" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//waf?depth=1&ref=master"

  name  = "my-alb-waf"
  scope = "REGIONAL"

  default_action = "ALLOW"

  # Inline IP set - referenced by name in rules below
  ip_sets = {
    blocked-ips = {
      ip_address_version = "IPV4"
      addresses = [
        "192.0.2.0/24",
        "198.51.100.44/32",
        "203.0.113.0/25",
      ]
      description = "Known bad actor IPs"
    }
  }

  custom_response_bodies = [
    {
      key          = "access-denied"
      content      = "{\"error\": \"Access Denied\", \"code\": 403}"
      content_type = "APPLICATION_JSON"
    }
  ]

  rules = [
    # Block IPs from inline ip_set by name
    {
      name     = "BlockBadIPs"
      priority = 5
      action = {
        block = {
          response_code            = 403
          custom_response_body_key = "access-denied"
        }
      }
      statement = {
        ip_set_reference_statement = {
          name = "blocked-ips"   # references the inline ip_set above
        }
      }
    },

    # Rate limit: max 1000 requests per 5 minutes per IP
    {
      name     = "RateLimitPerIP"
      priority = 10
      action   = "block"
      statement = {
        rate_based_statement = {
          limit                 = 1000
          aggregate_key_type    = "IP"
          evaluation_window_sec = 300
        }
      }
    },

    # AWS Managed Rules - Amazon IP reputation list
    {
      name            = "AWSManagedRulesAmazonIpReputationList"
      priority        = 20
      override_action = "none"
      statement = {
        managed_rule_group_statement = {
          name        = "AWSManagedRulesAmazonIpReputationList"
          vendor_name = "AWS"
        }
      }
    },
  ]

  # Associate with an ALB
  associations = {
    my-alb = "arn:aws:elasticloadbalancing:ap-southeast-1:123456789012:loadbalancer/app/my-alb/abc123"
  }

  logging_destination_arns = [
    "arn:aws:logs:ap-southeast-1:123456789012:log-group:aws-waf-logs-alb"
  ]

  tags = {
    Environment = "production"
  }
}
```

---

## Example 3 - API Gateway WAF

Protect an API Gateway stage with SQL injection protection, XSS protection,
and body size constraints.

```hcl
module "waf_apigw" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//waf?depth=1&ref=master"

  name        = "my-api-waf"
  scope       = "REGIONAL"
  description = "WAF for REST API Gateway"

  default_action = "ALLOW"

  rules = [
    # Reject oversized request bodies (> 8 KB)
    {
      name     = "BlockLargeBody"
      priority = 5
      action   = "block"
      statement = {
        size_constraint_statement = {
          comparison_operator = "GT"
          size                = 8192
          field_to_match = {
            body = { oversize_handling = "MATCH" }
          }
          text_transformations = [{ priority = 0, type = "NONE" }]
        }
      }
    },

    # SQL injection protection on body and query string
    {
      name     = "SQLiProtection"
      priority = 10
      action   = "block"
      statement = {
        or_statement = {
          statements = [
            {
              sqli_match_statement = {
                sensitivity_level = "HIGH"
                field_to_match    = { body = { oversize_handling = "CONTINUE" } }
                text_transformations = [
                  { priority = 0, type = "URL_DECODE" },
                  { priority = 1, type = "HTML_ENTITY_DECODE" },
                ]
              }
            },
            {
              sqli_match_statement = {
                sensitivity_level = "HIGH"
                field_to_match    = { query_string = {} }
                text_transformations = [{ priority = 0, type = "URL_DECODE" }]
              }
            },
          ]
        }
      }
    },

    # XSS protection
    {
      name     = "XSSProtection"
      priority = 20
      action   = "block"
      statement = {
        xss_match_statement = {
          field_to_match = { body = { oversize_handling = "CONTINUE" } }
          text_transformations = [
            { priority = 0, type = "URL_DECODE" },
            { priority = 1, type = "HTML_ENTITY_DECODE" },
          ]
        }
      }
    },

    # AWS Core Rule Set (count mode for visibility)
    {
      name            = "AWSManagedRulesCommonRuleSet"
      priority        = 50
      override_action = "count"
      statement = {
        managed_rule_group_statement = {
          name        = "AWSManagedRulesCommonRuleSet"
          vendor_name = "AWS"
          rule_action_overrides = [
            { name = "SizeRestrictions_BODY", action_to_use = "count" },
          ]
        }
      }
    },
  ]

  # Increase body inspection limit for API payloads
  association_config = {
    request_body = {
      api_gateway = {
        default_size_inspection_limit = "KB_64"
      }
    }
  }

  associations = {
    my-api-stage = "arn:aws:apigateway:ap-southeast-1::/restapis/abc123xyz/stages/prod"
  }

  tags = {
    Environment = "production"
    Service     = "api"
  }
}
```

---

## Example 4 - Advanced WAF with Bot Control, ATP, Labels, and Logical Statements

Full-featured WAF demonstrating inline IP sets, regex pattern sets, Bot Control managed
rule group with machine learning, Account Takeover Protection (ATP), label matching,
and/or/not logical statements, and logging to Kinesis Firehose with filtering.

```hcl
module "waf_advanced" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//waf?depth=1&ref=master"

  name        = "my-advanced-waf"
  scope       = "REGIONAL"
  description = "Advanced WAF with bot control and ATP"

  default_action = "ALLOW"

  # Inline IP sets
  ip_sets = {
    office-allowlist = {
      ip_address_version = "IPV4"
      addresses          = ["203.0.113.0/24"]
      description        = "Office egress IPs - always allowed"
    }
    scraper-blocklist = {
      ip_address_version = "IPV4"
      addresses          = ["198.51.100.0/28"]
      description        = "Known scraper subnets"
    }
  }

  # Inline regex pattern sets
  regex_pattern_sets = {
    bad-user-agents = {
      regular_expressions = [
        "(?i)curl/",
        "(?i)python-requests/",
        "(?i)go-http-client/",
      ]
      description = "Non-browser user agents to challenge"
    }
  }

  custom_response_bodies = [
    {
      key          = "bot-blocked"
      content      = "Automated request detected."
      content_type = "TEXT_PLAIN"
    }
  ]

  captcha_config = {
    immunity_time = 300
  }

  rules = [
    # Always allow office IPs - highest priority
    {
      name     = "AllowOfficeIPs"
      priority = 1
      action   = "allow"
      statement = {
        ip_set_reference_statement = {
          name = "office-allowlist"
        }
      }
    },

    # Block known scrapers
    {
      name     = "BlockScrapers"
      priority = 5
      action   = "block"
      statement = {
        ip_set_reference_statement = {
          name = "scraper-blocklist"
        }
      }
    },

    # Challenge suspicious user agents using an inline regex pattern set
    {
      name     = "ChallengeSuspiciousUA"
      priority = 10
      action   = "captcha"
      statement = {
        and_statement = {
          statements = [
            {
              regex_pattern_set_reference_statement = {
                name           = "bad-user-agents"
                field_to_match = { single_header = { name = "user-agent" } }
                text_transformations = [{ priority = 0, type = "LOWERCASE" }]
              }
            },
            {
              not_statement = {
                statement = {
                  ip_set_reference_statement = {
                    name = "office-allowlist"
                  }
                }
              }
            },
          ]
        }
      }
    },

    # Bot Control - targeted inspection with machine learning
    {
      name            = "AWSManagedRulesBotControlRuleSet"
      priority        = 20
      override_action = "none"
      statement = {
        managed_rule_group_statement = {
          name        = "AWSManagedRulesBotControlRuleSet"
          vendor_name = "AWS"
          managed_rule_group_configs = {
            aws_managed_rules_bot_control_rule_set = {
              inspection_level        = "TARGETED"
              enable_machine_learning = true
            }
          }
          rule_action_overrides = [
            { name = "TGT_VolumetricIpTokenAbsent", action_to_use = "captcha" },
          ]
        }
      }
    },

    # Account Takeover Prevention on /auth/login endpoint
    {
      name            = "AWSManagedRulesATPRuleSet"
      priority        = 30
      override_action = "none"
      statement = {
        managed_rule_group_statement = {
          name        = "AWSManagedRulesATPRuleSet"
          vendor_name = "AWS"
          managed_rule_group_configs = {
            aws_managed_rules_atp_rule_set = {
              login_path = "/auth/login"
              request_inspection = {
                payload_type   = "JSON"
                username_field = { identifier = "/email" }
                password_field = { identifier = "/password" }
              }
              response_inspection = {
                status_code = {
                  success_codes = [200]
                  failure_codes = [401, 403]
                }
              }
            }
          }
        }
      }
    },

    # Block requests with a bot label set by Bot Control
    {
      name     = "BlockDetectedBots"
      priority = 40
      action   = "block"
      statement = {
        label_match_statement = {
          scope = "LABEL"
          key   = "awswaf:managed:aws:bot-control:bot:category:scraper"
        }
      }
    },

    # Rate limit login endpoint by IP + URI path
    {
      name     = "RateLimitLogin"
      priority = 50
      action   = "block"
      statement = {
        rate_based_statement = {
          limit                 = 100
          aggregate_key_type    = "CUSTOM_KEYS"
          evaluation_window_sec = 300
          custom_keys = [
            { ip = {} },
            {
              uri_path = {
                text_transformations = [{ priority = 0, type = "LOWERCASE" }]
              }
            },
          ]
          scope_down_statement = {
            byte_match_statement = {
              positional_constraint = "STARTS_WITH"
              search_string         = "/auth/"
              field_to_match        = { uri_path = {} }
              text_transformations  = [{ priority = 0, type = "LOWERCASE" }]
            }
          }
        }
      }
    },

    # Core Rule Set - always on, block mode
    {
      name            = "AWSManagedRulesCommonRuleSet"
      priority        = 60
      override_action = "none"
      statement = {
        managed_rule_group_statement = {
          name        = "AWSManagedRulesCommonRuleSet"
          vendor_name = "AWS"
        }
      }
    },
  ]

  # Logging to Kinesis Firehose - drop ALLOW, keep BLOCK/CAPTCHA/CHALLENGE/COUNT
  logging_destination_arns = [
    "arn:aws:firehose:ap-southeast-1:123456789012:deliverystream/aws-waf-logs-advanced"
  ]

  logging_filter = {
    default_behavior = "DROP"
    filters = [
      {
        behavior    = "KEEP"
        requirement = "MEETS_ANY"
        conditions = [
          { action_condition = { action = "BLOCK" } },
          { action_condition = { action = "CAPTCHA" } },
          { action_condition = { action = "CHALLENGE" } },
          { action_condition = { action = "COUNT" } },
        ]
      }
    ]
  }

  logging_redacted_fields = [
    { single_header = { name = "authorization" } },
    { single_header = { name = "cookie" } },
  ]

  tags = {
    Environment = "production"
    Compliance  = "PCI-DSS"
  }
}
```

---

## Example 5 - Rule JSON Escape Hatch

Use `rule_json` for rules that require more than 1 level of AND/OR/NOT nesting, which
exceeds what the structured `rules` variable can express. The JSON is passed directly
to the AWS provider.

```hcl
module "waf_json_rules" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//waf?depth=1&ref=master"

  name  = "my-complex-waf"
  scope = "REGIONAL"

  default_action = "ALLOW"

  # When rule_json is set, the structured rules variable is ignored entirely.
  rule_json = jsonencode([
    {
      Name     = "ComplexNestedRule"
      Priority = 10
      Action = {
        Block = {}
      }
      Statement = {
        AndStatement = {
          Statements = [
            {
              GeoMatchStatement = {
                CountryCodes = ["CN", "RU"]
              }
            },
            {
              NotStatement = {
                Statement = {
                  IPSetReferenceStatement = {
                    ARN = "arn:aws:wafv2:ap-southeast-1:123456789012:regional/ipset/allowlist/abc123"
                  }
                }
              }
            },
            {
              OrStatement = {
                Statements = [
                  {
                    ByteMatchStatement = {
                      SearchString         = "/api/v1/sensitive"
                      PositionalConstraint = "STARTS_WITH"
                      FieldToMatch         = { UriPath = {} }
                      TextTransformations  = [{ Priority = 0, Type = "LOWERCASE" }]
                    }
                  },
                  {
                    SizeConstraintStatement = {
                      ComparisonOperator = "GT"
                      Size               = 65536
                      FieldToMatch       = { Body = { OversizeHandling = "MATCH" } }
                      TextTransformations = [{ Priority = 0, Type = "NONE" }]
                    }
                  }
                ]
              }
            }
          ]
        }
      }
      VisibilityConfig = {
        CloudWatchMetricsEnabled = true
        MetricName               = "ComplexNestedRule"
        SampledRequestsEnabled   = true
      }
    }
  ])

  visibility_config = {
    cloudwatch_metrics_enabled = true
    metric_name                = "my-complex-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Environment = "production"
  }
}
```

---

## Example 6 - Continuous Deployment / Staging with Rule Group Associations

Use `rule_group_associations` to attach pre-built managed rule groups and inline rule
groups to the Web ACL independently of the inline `rules`. When `rule_group_associations`
is non-empty, the Web ACL's `rule` attribute is automatically added to `lifecycle
ignore_changes` to avoid conflicts.

```hcl
module "waf_app" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//waf?depth=1&ref=master"

  name  = "my-app-waf"
  scope = "REGIONAL"

  # Core inline rules that are always active
  rules = [
    {
      name     = "AllowHealthCheck"
      priority = 1
      action   = "allow"
      statement = {
        byte_match_statement = {
          positional_constraint = "EXACTLY"
          search_string         = "/health"
          field_to_match        = { uri_path = {} }
          text_transformations  = [{ priority = 0, type = "NONE" }]
        }
      }
    },
  ]

  # Inline rule group created by this module invocation
  rule_groups = {
    custom-rules = {
      capacity    = 100
      description = "Custom business logic rules"
      rules = [
        {
          name     = "BlockAdminPath"
          priority = 1
          action   = "block"
          statement = {
            byte_match_statement = {
              positional_constraint = "STARTS_WITH"
              search_string         = "/wp-admin"
              field_to_match        = { uri_path = {} }
              text_transformations  = [{ priority = 0, type = "LOWERCASE" }]
            }
          }
        },
      ]
    }
  }

  # Attach managed rule groups and the inline rule group via associations.
  # The Web ACL's rule attribute is added to lifecycle ignore_changes automatically.
  rule_group_associations = {
    core-managed = {
      priority = 100
      managed_rule_group = {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
        rule_action_overrides = [
          { name = "SizeRestrictions_BODY", action_to_use = "count" },
        ]
      }
      override_action = "none"
    }

    ip-reputation = {
      priority = 110
      managed_rule_group = {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
      override_action = "none"
    }

    custom-inline = {
      priority = 200
      rule_group_reference = {
        # Reference the inline rule group created above by name
        name = "custom-rules"
      }
      override_action = "none"
    }
  }

  associations = {
    production-alb = "arn:aws:elasticloadbalancing:ap-southeast-1:123456789012:loadbalancer/app/prod-alb/def456"
  }

  logging_destination_arns = [
    "arn:aws:logs:ap-southeast-1:123456789012:log-group:aws-waf-logs-app"
  ]

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```
