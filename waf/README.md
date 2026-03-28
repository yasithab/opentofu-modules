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
  source = "git::https://github.com/yasithab/opentofu-modules.git//waf?depth=1&ref=v1.0.0"

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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.11.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.38.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.38.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | Name of the Web ACL and prefix for related resources. Required. | `string` | n/a | yes |
| <a name="input_api_keys"></a> [api\_keys](#input\_api\_keys) | Map of API keys to create for application integration (CAPTCHA/Challenge JavaScript API).<br/>Map key is a descriptive name. Each value: { token\_domains = list(string) } | <pre>map(object({<br/>    token_domains = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_association_config"></a> [association\_config](#input\_association\_config) | Configuration for resource type-specific request body inspection size limits.<br/>Structure:<br/>  {<br/>    request\_body = {<br/>      api\_gateway              = { default\_size\_inspection\_limit = "KB\_16" }<br/>      app\_runner\_service       = { default\_size\_inspection\_limit = "KB\_16" }<br/>      cloudfront               = { default\_size\_inspection\_limit = "KB\_16" }<br/>      cognito\_user\_pool        = { default\_size\_inspection\_limit = "KB\_16" }<br/>      verified\_access\_instance = { default\_size\_inspection\_limit = "KB\_16" }<br/>    }<br/>  }<br/>Valid values for default\_size\_inspection\_limit: KB\_16, KB\_32, KB\_48, KB\_64 | `any` | `null` | no |
| <a name="input_associations"></a> [associations](#input\_associations) | Map of resources to associate with the Web ACL. Map key is a descriptive name,<br/>map value is the resource ARN.<br/>Supported resource types: ALB, API Gateway Stage, AppSync GraphQL API,<br/>App Runner Service, Cognito User Pool, Verified Access Instance.<br/>Note: CloudFront distributions are associated via the distribution's web\_acl\_id attribute. | `map(string)` | `{}` | no |
| <a name="input_captcha_config"></a> [captcha\_config](#input\_captcha\_config) | Specifies how AWS WAF should handle CAPTCHA evaluations at the Web ACL level. Sets the immunity time in seconds. | <pre>object({<br/>    immunity_time = number<br/>  })</pre> | `null` | no |
| <a name="input_challenge_config"></a> [challenge\_config](#input\_challenge\_config) | Specifies how AWS WAF should handle challenge evaluations at the Web ACL level. Sets the immunity time in seconds. | <pre>object({<br/>    immunity_time = number<br/>  })</pre> | `null` | no |
| <a name="input_custom_response_bodies"></a> [custom\_response\_bodies](#input\_custom\_response\_bodies) | List of custom response body definitions that can be referenced by name in block rules.<br/>Each entry: { key = string, content = string, content\_type = string }<br/>content\_type: TEXT\_PLAIN, TEXT\_HTML, or APPLICATION\_JSON | <pre>list(object({<br/>    key          = string<br/>    content      = string<br/>    content_type = string<br/>  }))</pre> | `[]` | no |
| <a name="input_data_protection_config"></a> [data\_protection\_config](#input\_data\_protection\_config) | Configuration for data protection applied before logging WAF request data.<br/>Structure:<br/>  {<br/>    data\_protection = [<br/>      {<br/>        action                     = "HASH"   # HASH or SUBSTITUTION<br/>        exclude\_rate\_based\_details = optional(bool)<br/>        exclude\_rule\_match\_details = optional(bool)<br/>        fields = [<br/>          {<br/>            field\_type = "QUERY\_STRING"  # QUERY\_STRING, SINGLE\_HEADER, URI\_PATH, etc.<br/>            field\_keys = optional(list(string))  # For SINGLE\_HEADER: list of header names<br/>          }<br/>        ]<br/>      }<br/>    ]<br/>  } | `any` | `null` | no |
| <a name="input_default_action"></a> [default\_action](#input\_default\_action) | Action to take on requests that don't match any rules. ALLOW or BLOCK. | `string` | `"ALLOW"` | no |
| <a name="input_default_action_config"></a> [default\_action\_config](#input\_default\_action\_config) | Optional configuration for the default action. Use when you want custom headers on<br/>ALLOW or custom response on BLOCK.<br/><br/>For ALLOW with custom headers:<br/>  { allow = { insert\_headers = [{ name = "x-allowed", value = "true" }] } }<br/><br/>For BLOCK with custom response:<br/>  { block = { response\_code = 403, custom\_response\_body\_key = "restricted" } } | `any` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | A friendly description of the Web ACL. | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_ip_sets"></a> [ip\_sets](#input\_ip\_sets) | Map of IP sets to create. Map key becomes the IP set name.<br/>Each value: {<br/>  addresses          = list(string)   # CIDR notation<br/>  ip\_address\_version = string         # IPV4 or IPV6<br/>  description        = optional(string)<br/>}<br/>Created IP sets can be referenced by name in rules using ip\_set\_reference\_statement.name. | <pre>map(object({<br/>    addresses          = list(string)<br/>    ip_address_version = string<br/>    description        = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_logging_destination_arns"></a> [logging\_destination\_arns](#input\_logging\_destination\_arns) | List of ARNs of logging destinations. Supported: CloudWatch Logs log group,<br/>Kinesis Data Firehose delivery stream, S3 bucket.<br/>Names must start with aws-waf-logs-.<br/>When empty, no logging configuration is created. | `list(string)` | `[]` | no |
| <a name="input_logging_filter"></a> [logging\_filter](#input\_logging\_filter) | Logging filter configuration to selectively log requests. When null, all requests are logged.<br/>Structure:<br/>  {<br/>    default\_behavior = "KEEP" or "DROP"<br/>    filters = [<br/>      {<br/>        behavior    = "KEEP" or "DROP"<br/>        requirement = "MEETS\_ANY" or "MEETS\_ALL"  # default MEETS\_ANY<br/>        conditions  = [<br/>          {<br/>            action\_condition     = { action = "ALLOW" \| "BLOCK" \| "COUNT" \| "CAPTCHA" \| "CHALLENGE" \| "EXCLUDED\_AS\_COUNT" }<br/>            label\_name\_condition = { label\_name = "..." }<br/>          }<br/>        ]<br/>      }<br/>    ]<br/>  } | `any` | `null` | no |
| <a name="input_logging_redacted_fields"></a> [logging\_redacted\_fields](#input\_logging\_redacted\_fields) | List of fields to redact from logs. Each entry specifies which field to redact:<br/>  { uri\_path = {} }<br/>  { query\_string = {} }<br/>  { method = {} }<br/>  { single\_header = { name = "authorization" } } | `any` | `[]` | no |
| <a name="input_regex_pattern_sets"></a> [regex\_pattern\_sets](#input\_regex\_pattern\_sets) | Map of regex pattern sets to create. Map key becomes the regex pattern set name.<br/>Each value: {<br/>  regular\_expressions = list(string)<br/>  description         = optional(string)<br/>}<br/>Created sets can be referenced by name in rules using regex\_pattern\_set\_reference\_statement.name. | <pre>map(object({<br/>    regular_expressions = list(string)<br/>    description         = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_rule_group_associations"></a> [rule\_group\_associations](#input\_rule\_group\_associations) | Map of rule group associations to the Web ACL. Map key is a descriptive name.<br/>When this is non-empty, the rule attribute of the Web ACL is added to lifecycle<br/>ignore\_changes to avoid conflicts between inline rules and associated groups.<br/>Each value: {<br/>  priority = number<br/>  rule\_group\_reference = optional({<br/>    arn  = optional(string)   # Use ARN for external rule groups<br/>    name = optional(string)   # Use name for rule groups created by this module<br/>    rule\_action\_overrides = optional(list({ name=string, action\_to\_use=string }))<br/>  })<br/>  managed\_rule\_group = optional({<br/>    name        = string<br/>    vendor\_name = string   # Defaults to "AWS"<br/>    version     = optional(string)<br/>    rule\_action\_overrides = optional(list({ name=string, action\_to\_use=string }))<br/>  })<br/>  override\_action   = optional(string)   # "none" or "count"<br/>  visibility\_config = optional({<br/>    cloudwatch\_metrics\_enabled = bool<br/>    metric\_name                = string<br/>    sampled\_requests\_enabled   = bool<br/>  })<br/>} | `any` | `{}` | no |
| <a name="input_rule_groups"></a> [rule\_groups](#input\_rule\_groups) | Map of rule groups to create. Map key becomes the rule group name.<br/>Each value: {<br/>  capacity    = number              # WCU capacity<br/>  description = optional(string)<br/>  rules\_json  = optional(string)    # Raw JSON; takes precedence over rules<br/>  rules       = optional(any)       # Structured rules list (common statement types)<br/>  cloudwatch\_metrics\_enabled = optional(bool)<br/>  metric\_name                = optional(string)<br/>  sampled\_requests\_enabled   = optional(bool)<br/>  custom\_response\_bodies     = optional(list({ key=string, content=string, content\_type=string }))<br/>}<br/>Created rule groups can be referenced by name in rules using rule\_group\_reference\_statement.name. | <pre>map(object({<br/>    capacity                   = number<br/>    description                = optional(string)<br/>    rules_json                 = optional(string)<br/>    rules                      = optional(any)<br/>    cloudwatch_metrics_enabled = optional(bool)<br/>    metric_name                = optional(string)<br/>    sampled_requests_enabled   = optional(bool)<br/>    custom_response_bodies = optional(list(object({<br/>      key          = string<br/>      content      = string<br/>      content_type = string<br/>    })))<br/>  }))</pre> | `{}` | no |
| <a name="input_rule_json"></a> [rule\_json](#input\_rule\_json) | Raw JSON string of WAFv2 rules to apply to the Web ACL. When set, takes precedence<br/>over the structured rules variable and rule\_json is passed directly to the provider.<br/>Use this for complex rules that exceed the structured variable schema (e.g., deeply<br/>nested and/or/not statements). | `string` | `null` | no |
| <a name="input_rules"></a> [rules](#input\_rules) | List of WAFv2 rule objects. Only used when rule\_json is null.<br/>Each rule requires: name, priority, statement, and either action or override\_action.<br/>See README for full rule structure reference. | `any` | `[]` | no |
| <a name="input_scope"></a> [scope](#input\_scope) | Specifies whether the Web ACL is for an AWS CloudFront distribution (CLOUDFRONT) or for a regional application (REGIONAL). CLOUDFRONT scope must be created in us-east-1. | `string` | `"REGIONAL"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to all resources. | `map(string)` | `{}` | no |
| <a name="input_token_domains"></a> [token\_domains](#input\_token\_domains) | List of domains to accept in web requests that contain a CAPTCHA or challenge token. | `list(string)` | `[]` | no |
| <a name="input_visibility_config"></a> [visibility\_config](#input\_visibility\_config) | Visibility configuration for the Web ACL. Also used as the default for rules that<br/>do not specify their own visibility\_config.<br/>Defaults: cloudwatch\_metrics\_enabled=true, metric\_name=var.name, sampled\_requests\_enabled=true. | <pre>object({<br/>    cloudwatch_metrics_enabled = bool<br/>    metric_name                = string<br/>    sampled_requests_enabled   = bool<br/>  })</pre> | <pre>{<br/>  "cloudwatch_metrics_enabled": true,<br/>  "metric_name": null,<br/>  "sampled_requests_enabled": true<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_keys"></a> [api\_keys](#output\_api\_keys) | Map of API key name to api\_key value for all API keys created by this module. |
| <a name="output_association_ids"></a> [association\_ids](#output\_association\_ids) | Map of association name to resource ID for all Web ACL associations created by this module. |
| <a name="output_ip_set_arns"></a> [ip\_set\_arns](#output\_ip\_set\_arns) | Map of IP set name to ARN for all IP sets created by this module. |
| <a name="output_ip_set_ids"></a> [ip\_set\_ids](#output\_ip\_set\_ids) | Map of IP set name to ID for all IP sets created by this module. |
| <a name="output_regex_pattern_set_arns"></a> [regex\_pattern\_set\_arns](#output\_regex\_pattern\_set\_arns) | Map of regex pattern set name to ARN for all sets created by this module. |
| <a name="output_regex_pattern_set_ids"></a> [regex\_pattern\_set\_ids](#output\_regex\_pattern\_set\_ids) | Map of regex pattern set name to ID for all sets created by this module. |
| <a name="output_rule_group_arns"></a> [rule\_group\_arns](#output\_rule\_group\_arns) | Map of rule group name to ARN for all rule groups created by this module. |
| <a name="output_rule_group_association_ids"></a> [rule\_group\_association\_ids](#output\_rule\_group\_association\_ids) | Map of rule group association name to resource ID for all rule group associations created by this module. |
| <a name="output_rule_group_ids"></a> [rule\_group\_ids](#output\_rule\_group\_ids) | Map of rule group name to ID for all rule groups created by this module. |
| <a name="output_web_acl_application_integration_url"></a> [web\_acl\_application\_integration\_url](#output\_web\_acl\_application\_integration\_url) | The URL to use in SDK integrations with managed rule groups (for CAPTCHA and challenge actions). |
| <a name="output_web_acl_arn"></a> [web\_acl\_arn](#output\_web\_acl\_arn) | The ARN of the Web ACL. Use this ARN to associate the Web ACL with a CloudFront distribution, ALB, or API Gateway stage. |
| <a name="output_web_acl_capacity"></a> [web\_acl\_capacity](#output\_web\_acl\_capacity) | The web ACL capacity units (WCUs) currently used by this web ACL. |
| <a name="output_web_acl_id"></a> [web\_acl\_id](#output\_web\_acl\_id) | The unique identifier of the Web ACL. |
| <a name="output_web_acl_name"></a> [web\_acl\_name](#output\_web\_acl\_name) | The name of the Web ACL. |
<!-- END_TF_DOCS -->
