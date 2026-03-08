# WAF Module Examples

## Example 1 - Basic CloudFront WAF (CLOUDFRONT scope)

Protect a CloudFront distribution with AWS managed rules and geo restriction.
CloudFront-scope Web ACLs must be created in `us-east-1`.

```hcl
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

module "waf_cloudfront" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//waf?depth=1&ref=v1.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//waf?depth=1&ref=v1.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//waf?depth=1&ref=v1.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//waf?depth=1&ref=v1.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//waf?depth=1&ref=v1.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//waf?depth=1&ref=v1.0.0"

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
