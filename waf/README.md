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

### Why `rules` is `type = any`

`var.rules` is intentionally **not** declared as `list(object({...}))`. HCL/OpenTofu
requires every element of a typed list to convert to one concrete type; an `any`
attribute inside the element type (e.g. `statement = any`) is resolved by *unifying*
the statement values of **all** rules in the list. Real-world rule lists mix statement
shapes (a `managed_rule_group_statement` next to a `byte_match_statement` next to a
`rate_based_statement`), and unification then fails with
`cannot find a common base type for all elements` - or, when it happens to succeed,
silently degrades object types to maps and converts numbers (such as
`rate_based_statement.limit`) to strings. WAF statements are also recursive
(`and`/`or`/`not` nesting), which HCL object types cannot express at all.

Instead, the top-level rule schema (`name`, `priority`, `action`/`override_action`,
`rule_labels`, `visibility_config`, `captcha_config`, `challenge_config`, `statement`)
is enforced by `validation` blocks on the variable - unknown attributes, missing
required fields, invalid `action`/`override_action` values, and malformed
`rule_labels`/`captcha_config`/`challenge_config` are all rejected at plan time. The
full schema, including every supported statement type, is documented in the
[Rule Structure Reference](#rule-structure-reference) below.

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

OpenTofu cannot make `ignore_changes` conditional, so the module maintains two
otherwise-identical Web ACL resources (same pattern as the `dynamodb` module) and
enables exactly one of them:

- `aws_wafv2_web_acl.this` - used when `rule_group_associations` is empty. Inline
  `rule` blocks are fully managed; out-of-band rule drift is corrected on apply.
- `aws_wafv2_web_acl.rule_group_associated` - used when `rule_group_associations`
  is non-empty. The `rule` attribute is in `lifecycle { ignore_changes = [rule] }`
  so rules attached via `aws_wafv2_web_acl_rule_group_association` are not
  overwritten by the Web ACL's inline `rule` blocks.

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
      limit                 = number   # 100-2000000000
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

## Reference

<details>
<summary>Requirements, providers, inputs and outputs (generated by terraform-docs)</summary>

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
| api\_keys | Map of API keys to create for application integration (CAPTCHA/Challenge JavaScript API).<br/>Map key is a descriptive name. Each value: { token\_domains = list(string) } | <pre>map(object({<br/>    token_domains = list(string)<br/>  }))</pre> | `{}` | no |
| association\_config | Configuration for resource type-specific request body inspection size limits.<br/>Structure:<br/>  {<br/>    request\_body = {<br/>      api\_gateway              = { default\_size\_inspection\_limit = "KB\_16" }<br/>      app\_runner\_service       = { default\_size\_inspection\_limit = "KB\_16" }<br/>      cloudfront               = { default\_size\_inspection\_limit = "KB\_16" }<br/>      cognito\_user\_pool        = { default\_size\_inspection\_limit = "KB\_16" }<br/>      verified\_access\_instance = { default\_size\_inspection\_limit = "KB\_16" }<br/>    }<br/>  }<br/>Valid values for default\_size\_inspection\_limit: KB\_16, KB\_32, KB\_48, KB\_64 | <pre>object({<br/>    request_body = optional(object({<br/>      api_gateway              = optional(object({ default_size_inspection_limit = string }))<br/>      app_runner_service       = optional(object({ default_size_inspection_limit = string }))<br/>      cloudfront               = optional(object({ default_size_inspection_limit = string }))<br/>      cognito_user_pool        = optional(object({ default_size_inspection_limit = string }))<br/>      verified_access_instance = optional(object({ default_size_inspection_limit = string }))<br/>    }))<br/>  })</pre> | `null` | no |
| associations | Map of resources to associate with the Web ACL. Map key is a descriptive name,<br/>map value is the resource ARN.<br/>Supported resource types: ALB, API Gateway Stage, AppSync GraphQL API,<br/>App Runner Service, Cognito User Pool, Verified Access Instance.<br/>Note: CloudFront distributions are associated via the distribution's web\_acl\_id attribute. | `map(string)` | `{}` | no |
| captcha\_config | Specifies how AWS WAF should handle CAPTCHA evaluations at the Web ACL level. Sets the immunity time in seconds. | <pre>object({<br/>    immunity_time = number<br/>  })</pre> | `null` | no |
| challenge\_config | Specifies how AWS WAF should handle challenge evaluations at the Web ACL level. Sets the immunity time in seconds. | <pre>object({<br/>    immunity_time = number<br/>  })</pre> | `null` | no |
| custom\_response\_bodies | List of custom response body definitions that can be referenced by name in block rules.<br/>Each entry: { key = string, content = string, content\_type = string }<br/>content\_type: TEXT\_PLAIN, TEXT\_HTML, or APPLICATION\_JSON | <pre>list(object({<br/>    key          = string<br/>    content      = string<br/>    content_type = string<br/>  }))</pre> | `[]` | no |
| data\_protection\_config | Configuration for data protection applied before logging WAF request data.<br/>Structure:<br/>  {<br/>    data\_protection = [<br/>      {<br/>        action                     = "HASH"   # HASH or SUBSTITUTION<br/>        exclude\_rate\_based\_details = optional(bool)<br/>        exclude\_rule\_match\_details = optional(bool)<br/>        fields = [<br/>          {<br/>            field\_type = "QUERY\_STRING"  # QUERY\_STRING, SINGLE\_HEADER, URI\_PATH, etc.<br/>            field\_keys = optional(list(string))  # For SINGLE\_HEADER: list of header names<br/>          }<br/>        ]<br/>      }<br/>    ]<br/>  } | `any` | `null` | no |
| default\_action | Action to take on requests that don't match any rules. ALLOW or BLOCK. | `string` | `"ALLOW"` | no |
| default\_action\_config | Optional configuration for the default action. Use when you want custom headers on<br/>ALLOW or custom response on BLOCK.<br/><br/>For ALLOW with custom headers:<br/>  { allow = { insert\_headers = [{ name = "x-allowed", value = "true" }] } }<br/><br/>For BLOCK with custom response:<br/>  { block = { response\_code = 403, custom\_response\_body\_key = "restricted" } } | <pre>object({<br/>    allow = optional(object({<br/>      insert_headers = optional(list(object({<br/>        name  = string<br/>        value = string<br/>      })), [])<br/>    }))<br/>    block = optional(object({<br/>      response_code            = optional(number)<br/>      custom_response_body_key = optional(string)<br/>    }))<br/>  })</pre> | `null` | no |
| description | A friendly description of the Web ACL. | `string` | `null` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| ip\_sets | Map of IP sets to create. Map key becomes the IP set name.<br/>Each value: {<br/>  addresses          = list(string)   # CIDR notation<br/>  ip\_address\_version = string         # IPV4 or IPV6<br/>  description        = optional(string)<br/>}<br/>Created IP sets can be referenced by name in rules using ip\_set\_reference\_statement.name. | <pre>map(object({<br/>    addresses          = list(string)<br/>    ip_address_version = string<br/>    description        = optional(string)<br/>  }))</pre> | `{}` | no |
| logging\_destination\_arns | List of ARNs of logging destinations. Supported: CloudWatch Logs log group,<br/>Kinesis Data Firehose delivery stream, S3 bucket.<br/>Names must start with aws-waf-logs-.<br/>When empty, no logging configuration is created. | `list(string)` | `[]` | no |
| logging\_filter | Logging filter configuration to selectively log requests. When null, all requests are logged.<br/>Structure:<br/>  {<br/>    default\_behavior = "KEEP" or "DROP"<br/>    filters = [<br/>      {<br/>        behavior    = "KEEP" or "DROP"<br/>        requirement = "MEETS\_ANY" or "MEETS\_ALL"  # default MEETS\_ANY<br/>        conditions  = [<br/>          {<br/>            action\_condition     = { action = "ALLOW" \| "BLOCK" \| "COUNT" \| "CAPTCHA" \| "CHALLENGE" \| "EXCLUDED\_AS\_COUNT" }<br/>            label\_name\_condition = { label\_name = "..." }<br/>          }<br/>        ]<br/>      }<br/>    ]<br/>  } | <pre>object({<br/>    default_behavior = string<br/>    filters = optional(list(object({<br/>      behavior    = string<br/>      requirement = optional(string, "MEETS_ANY")<br/>      conditions = optional(list(object({<br/>        action_condition     = optional(object({ action = string }))<br/>        label_name_condition = optional(object({ label_name = string }))<br/>      })), [])<br/>    })), [])<br/>  })</pre> | `null` | no |
| logging\_redacted\_fields | List of fields to redact from logs. Each entry specifies which field to redact:<br/>  { uri\_path = {} }<br/>  { query\_string = {} }<br/>  { method = {} }<br/>  { single\_header = { name = "authorization" } } | <pre>list(object({<br/>    uri_path      = optional(object({}))<br/>    query_string  = optional(object({}))<br/>    method        = optional(object({}))<br/>    single_header = optional(object({ name = string }))<br/>  }))</pre> | `[]` | no |
| name | Name of the Web ACL and prefix for related resources. Required. | `string` | n/a | yes |
| regex\_pattern\_sets | Map of regex pattern sets to create. Map key becomes the regex pattern set name.<br/>Each value: {<br/>  regular\_expressions = list(string)<br/>  description         = optional(string)<br/>}<br/>Created sets can be referenced by name in rules using regex\_pattern\_set\_reference\_statement.name. | <pre>map(object({<br/>    regular_expressions = list(string)<br/>    description         = optional(string)<br/>  }))</pre> | `{}` | no |
| rule\_group\_associations | Map of rule group associations to the Web ACL. Map key is a descriptive name.<br/>When this is non-empty, the rule attribute of the Web ACL is added to lifecycle<br/>ignore\_changes to avoid conflicts between inline rules and associated groups.<br/>Each value: {<br/>  priority = number<br/>  rule\_group\_reference = optional({<br/>    arn  = optional(string)   # Use ARN for external rule groups<br/>    name = optional(string)   # Use name for rule groups created by this module<br/>    rule\_action\_overrides = optional(list({ name=string, action\_to\_use=string }))<br/>  })<br/>  managed\_rule\_group = optional({<br/>    name        = string<br/>    vendor\_name = string   # Defaults to "AWS"<br/>    version     = optional(string)<br/>    rule\_action\_overrides = optional(list({ name=string, action\_to\_use=string }))<br/>  })<br/>  override\_action   = optional(string)   # "none" or "count"<br/>  visibility\_config = optional({<br/>    cloudwatch\_metrics\_enabled = bool<br/>    metric\_name                = string<br/>    sampled\_requests\_enabled   = bool<br/>  })<br/>} | `any` | `{}` | no |
| rule\_groups | Map of rule groups to create. Map key becomes the rule group name.<br/>Each value: {<br/>  capacity    = number              # WCU capacity<br/>  description = optional(string)<br/>  rules\_json  = optional(string)    # Raw JSON; takes precedence over rules<br/>  rules       = optional(any)       # Structured rules list (common statement types)<br/>  cloudwatch\_metrics\_enabled = optional(bool)<br/>  metric\_name                = optional(string)<br/>  sampled\_requests\_enabled   = optional(bool)<br/>  custom\_response\_bodies     = optional(list({ key=string, content=string, content\_type=string }))<br/>}<br/>Created rule groups can be referenced by name in rules using rule\_group\_reference\_statement.name. | <pre>map(object({<br/>    capacity                   = number<br/>    description                = optional(string)<br/>    rules_json                 = optional(string)<br/>    rules                      = optional(any, [])<br/>    cloudwatch_metrics_enabled = optional(bool, true)<br/>    metric_name                = optional(string)<br/>    sampled_requests_enabled   = optional(bool, true)<br/>    custom_response_bodies = optional(list(object({<br/>      key          = string<br/>      content      = string<br/>      content_type = string<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| rule\_json | Raw JSON string of WAFv2 rules to apply to the Web ACL. When set, takes precedence<br/>over the structured rules variable and rule\_json is passed directly to the provider.<br/>Use this for complex rules that exceed the structured variable schema (e.g., deeply<br/>nested and/or/not statements). | `string` | `null` | no |
| rules | List of WAFv2 rule objects. Only used when rule\_json is null.<br/>Each rule is an object with the following top-level fields:<br/>  name              = string            (required)<br/>  priority          = number            (required)<br/>  statement         = object            (required - see README "Rule Structure Reference")<br/>  action            = string or object  (one of action/override\_action; "allow"\|"block"\|"count"\|"captcha"\|"challenge" or { allow\|block\|count\|captcha\|challenge = {...} })<br/>  override\_action   = string            ("none" or "count"; for managed/rule-group rules)<br/>  rule\_labels       = list(string)      (optional)<br/>  visibility\_config = object            (optional; { cloudwatch\_metrics\_enabled, metric\_name, sampled\_requests\_enabled }, falls back to var.visibility\_config)<br/>  captcha\_config    = object            (optional; { immunity\_time = number })<br/>  challenge\_config  = object            (optional; { immunity\_time = number })<br/>See README for the full rule structure reference including all statement types. | `any` | `[]` | no |
| scope | Specifies whether the Web ACL is for an AWS CloudFront distribution (CLOUDFRONT) or for a regional application (REGIONAL). CLOUDFRONT scope must be created in us-east-1. | `string` | `"REGIONAL"` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| token\_domains | List of domains to accept in web requests that contain a CAPTCHA or challenge token. | `list(string)` | `[]` | no |
| visibility\_config | Visibility configuration for the Web ACL. Also used as the default for rules that<br/>do not specify their own visibility\_config.<br/>Defaults: cloudwatch\_metrics\_enabled=true, metric\_name=var.name, sampled\_requests\_enabled=true. | <pre>object({<br/>    cloudwatch_metrics_enabled = optional(bool, true)<br/>    metric_name                = optional(string)<br/>    sampled_requests_enabled   = optional(bool, true)<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| api\_keys | Map of API key name to api\_key value for all API keys created by this module. |
| association\_ids | Map of association name to resource ID for all Web ACL associations created by this module. |
| ip\_set\_arns | Map of IP set name to ARN for all IP sets created by this module. |
| ip\_set\_ids | Map of IP set name to ID for all IP sets created by this module. |
| regex\_pattern\_set\_arns | Map of regex pattern set name to ARN for all sets created by this module. |
| regex\_pattern\_set\_ids | Map of regex pattern set name to ID for all sets created by this module. |
| rule\_group\_arns | Map of rule group name to ARN for all rule groups created by this module. |
| rule\_group\_association\_ids | Map of rule group association name to resource ID for all rule group associations created by this module. |
| rule\_group\_ids | Map of rule group name to ID for all rule groups created by this module. |
| web\_acl\_application\_integration\_url | The URL to use in SDK integrations with managed rule groups (for CAPTCHA and challenge actions). |
| web\_acl\_arn | The ARN of the Web ACL. Use this ARN to associate the Web ACL with a CloudFront distribution, ALB, or API Gateway stage. |
| web\_acl\_capacity | The web ACL capacity units (WCUs) currently used by this web ACL. |
| web\_acl\_id | The unique identifier of the Web ACL. |
| web\_acl\_name | The name of the Web ACL. |
<!-- END_TF_DOCS -->

</details>
