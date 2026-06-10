# CloudFront Module

Creates and manages AWS CloudFront resources: distributions, policies, functions, signing keys,
real-time log configs, VPC origins, and continuous deployment policies - all from a single module call.

## Resources Created

| Resource | Controlled by |
|----------|--------------|
| `aws_cloudfront_distribution` | `enabled` |
| `aws_cloudfront_cache_policy` | `cache_policies` map |
| `aws_cloudfront_origin_request_policy` | `origin_request_policies` map |
| `aws_cloudfront_response_headers_policy` | `response_headers_policies` map |
| `aws_cloudfront_key_value_store` | `key_value_stores` map |
| `aws_cloudfront_function` | `functions` map |
| `aws_cloudfront_public_key` | `public_keys` map |
| `aws_cloudfront_key_group` | `key_groups` map |
| `aws_cloudfront_realtime_log_config` | `realtime_log_configs` map |
| `aws_cloudfront_continuous_deployment_policy` | `continuous_deployment_policies` map |
| `aws_cloudfront_origin_access_control` | `create_origin_access_control` + `origin_access_control` map |
| `aws_cloudfront_origin_access_identity` | `create_origin_access_identity` + `origin_access_identities` map |
| `aws_cloudfront_vpc_origin` | `create_vpc_origin` + `vpc_origin` map |
| `aws_cloudfront_monitoring_subscription` | `create_monitoring_subscription` |

> [!IMPORTANT]
> - **Every cache behavior must reference a cache policy** via `cache_policy_id` or `cache_policy_name` (enforced by variable validation). Use an AWS managed policy (e.g. `CachingOptimized`, ID `658327ea-f89d-4fab-a63d-7e88639e58f6`; `CachingDisabled`, ID `4135ea2d-6df8-44a3-9df3-4b5a84be39ad`) or define your own under `cache_policies`. Forwarding headers/cookies/query strings to the origin is configured with `origin_request_policy_id`/`origin_request_policy_name` (e.g. AWS managed `AllViewer`, ID `216adef6-5c7f-47e4-b989-5492eafa07d3`). Legacy `forwarded_values` is not supported (deprecated by AWS); TTLs belong to the cache policy.
> - `origin`, `origin_group`, `default_cache_behavior`, and `ordered_cache_behavior` are fully typed `optional()` object schemas — unknown attributes are rejected at plan time. Origin custom headers are `custom_headers` (`map(string)`); `function_association`/`lambda_function_association` are lists of objects with an explicit `event_type`.
> - `default_cache_behavior` is required. `viewer_protocol_policy` defaults to `redirect-to-https` and `compress` defaults to `true` on all behaviors.
> - `distribution_enabled` controls the distribution's own `enabled` argument (whether it serves traffic), decoupled from `enabled` (whether the resource exists).
> - `viewer_certificate.minimum_protocol_version` defaults to `TLSv1.2_2021`; override only if you must support legacy TLS clients. With `cloudfront_default_certificate = true` CloudFront ignores this setting and uses TLSv1.
> - `web_acl_id` is fully managed: if a WAF web ACL is attached out-of-band (e.g. by AWS Firewall Manager), the next plan will detach it unless `web_acl_id` matches.
> - `logging_config` is a typed object defaulting to `null` (omit to disable logging). `custom_error_response` is a typed list. `viewer_certificate` is a typed object.

> [!NOTE]
> Enable `logging_config` (access logs) for production distributions — logs are the primary forensic trail for CDN traffic.

## Policy Name Resolution

Policies can be referenced in cache behaviors in three ways (tried in order):

1. **Direct ID** - pass `cache_policy_id`, `origin_request_policy_id`, or `response_headers_policy_id`
2. **Inline name** - pass `cache_policy_name` matching a key in `cache_policies` (created in this module call)
3. **AWS-managed name** - pass `cache_policy_name` not found in `cache_policies` (looked up via data source)

The same resolution applies to `realtime_log_config_arn`/`realtime_log_config_name`
and `function_association.function_arn`/`function_association.function_name`.

A cache policy is **mandatory** on every behavior (legacy `forwarded_values` is gone). If you
don't need custom caching rules, reference an AWS managed policy either by name
(`cache_policy_name = "CachingOptimized"`, resolved via data source — requires AWS credentials
at plan time) or directly by its well-known ID (no lookup needed), e.g.:

| AWS managed cache policy | ID |
|--------------------------|----|
| `CachingOptimized` | `658327ea-f89d-4fab-a63d-7e88639e58f6` |
| `CachingDisabled` | `4135ea2d-6df8-44a3-9df3-4b5a84be39ad` |
| `CachingOptimizedForUncompressedObjects` | `b2884449-e4de-46a7-ac36-70bc7f1ddd6d` |

## Usage

```hcl
module "cloudfront" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudfront?depth=1&ref=master"

  enabled             = true
  comment             = "My distribution"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  aliases             = ["www.example.com"]

  create_origin_access_control = true
  origin_access_control = {
    s3_oac = {
      description      = ""
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  origin = {
    s3 = {
      domain_name           = "my-bucket.s3.us-east-1.amazonaws.com"
      origin_access_control = "s3_oac"
    }
  }

  default_cache_behavior = {
    target_origin_id       = "s3"
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_name      = "CachingOptimized"
    compress               = true
  }

  viewer_certificate = {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:123456789012:certificate/..."
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = { Environment = "production" }
}
```


---

## Requirements

| Name | Version |
|------|---------|
| OpenTofu | `>= 1.11.0` |
| AWS provider | `~> 6.34` |

---

## Inputs

### Distribution

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `enabled` | Create the module resources | `bool` | `true` |
| `distribution_enabled` | Whether the distribution accepts end user requests (decoupled from `enabled`) | `bool` | `true` |
| `comment` | Distribution comment | `string` | `null` |
| `aliases` | Alternate domain names (CNAMEs) | `list(string)` | `null` |
| `default_root_object` | Default root object (e.g. `index.html`) | `string` | `null` |
| `price_class` | `PriceClass_All`, `PriceClass_200`, or `PriceClass_100` | `string` | `null` |
| `http_version` | `http2`, `http2and3`, `http3`, `http1.1` | `string` | `"http2"` |
| `is_ipv6_enabled` | Enable IPv6 | `bool` | `null` |
| `web_acl_id` | WAFv2 web ACL ARN. Changes are managed by this module (no longer ignored via `ignore_changes`) | `string` | `null` |
| `staging` | Mark as a staging distribution | `bool` | `false` |
| `continuous_deployment_policy_id` | Continuous deployment policy ID (production only) | `string` | `null` |
| `anycast_ip_list_id` | Anycast static IP list ID | `string` | `null` |
| `retain_on_delete` | Disable instead of delete on destroy | `bool` | `false` |
| `wait_for_deployment` | Wait for `Deployed` status after changes | `bool` | `true` |
| `tags` | Tags applied to all taggable resources | `map(string)` | `{}` |

### Origins

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `origin` | Map of origins (typed schema). Key is used as `origin_id` unless overridden. Each entry supports: `domain_name` (required), `origin_id`, `origin_path`, `connection_attempts`, `connection_timeout`, `response_completion_timeout`, `origin_access_control_id` (or `origin_access_control` — name of an inline OAC), `custom_headers` (`map(string)` name => value), `custom_origin_config` (object: `http_port` default `80`, `https_port` default `443`, `origin_protocol_policy` default `"https-only"`, `origin_ssl_protocols` default `["TLSv1.2"]`, `origin_keepalive_timeout`, `origin_read_timeout`, `ip_address_type`), `s3_origin_config` (object: `cloudfront_access_identity_path` or `origin_access_identity` — name of an inline OAI), `origin_shield` (object: `enabled` default `true`, `origin_shield_region`), `vpc_origin_config` (object: `vpc_origin_id` or `vpc_origin` — name of an inline VPC origin, `origin_keepalive_timeout`, `origin_read_timeout`, `owner_account_id`) | `map(object)` | `{}` |
| `origin_group` | Map of origin groups (typed schema). Key is used as `origin_id` unless overridden. Each entry: `origin_id`, `failover_status_codes` (required), `primary_member_origin_id` (required), `secondary_member_origin_id` (required) | `map(object)` | `{}` |

### Cache Behaviors

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `default_cache_behavior` | Default cache behavior (**required**, typed schema). Attributes: `target_origin_id` (required), `viewer_protocol_policy` (default `"redirect-to-https"`), `allowed_methods` (default `["GET", "HEAD", "OPTIONS"]`), `cached_methods` (default `["GET", "HEAD"]`), `compress` (default `true`), `cache_policy_id`/`cache_policy_name` (**one required** — see [Policy Name Resolution](#policy-name-resolution)), `origin_request_policy_id`/`origin_request_policy_name`, `response_headers_policy_id`/`response_headers_policy_name`, `realtime_log_config_arn`/`realtime_log_config_name`, `function_association` (list of objects: `event_type` required, `function_arn` or `function_name`), `lambda_function_association` (list of objects: `event_type` and `lambda_arn` required, `include_body`), `trusted_key_groups`, `trusted_signers`, `field_level_encryption_id`, `smooth_streaming`, `grpc_config` (object: `enabled`). Legacy `forwarded_values` and behavior-level TTLs are **not supported** | `object` | n/a |
| `ordered_cache_behavior` | List of ordered cache behaviors (typed schema), same attributes as `default_cache_behavior` plus the required `path_pattern`. Evaluated top to bottom (topmost = precedence 0) | `list(object)` | `[]` |

### Policies (inline creation)

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `cache_policies` | Map of cache policies to create. Key = policy name. Supports: `comment`, `default_ttl`, `max_ttl`, `min_ttl`, `cookie_behavior`, `cookies_items`, `header_behavior`, `headers_items`, `query_string_behavior`, `query_strings_items`, `enable_accept_encoding_brotli`, `enable_accept_encoding_gzip` | `any` | `{}` |
| `origin_request_policies` | Map of origin request policies to create. Key = policy name. Supports: `comment`, `cookie_behavior`, `cookies_items`, `header_behavior`, `headers_items`, `query_string_behavior`, `query_strings_items` | `any` | `{}` |
| `response_headers_policies` | Map of response headers policies to create. Key = policy name. Supports: `comment`, `cors` (object), `custom_headers` (list), `remove_headers` (set), `content_security_policy_header`, `content_type_options_header`, `frame_options_header`, `referrer_policy_header`, `strict_transport_security_header`, `xss_protection_header`, `server_timing_header` | `any` | `{}` |

### Functions and Edge Computing

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `key_value_stores` | Map of CloudFront Key-Value Stores. Key = store name. Supports: `comment` | `any` | `{}` |
| `functions` | Map of CloudFront Functions. Key = function name. Required: `runtime` (e.g. `cloudfront-js-2.0`), `code` (JS source). Optional: `comment`, `publish` (default `true`), `key_value_store_associations` (list of inline KVS names or ARNs) | `any` | `{}` |

### Signed URLs / Cookies

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `public_keys` | Map of CloudFront Public Keys. Key = key name. Required: `encoded_key` (PEM-encoded RSA public key). Optional: `comment` | `any` | `{}` |
| `key_groups` | Map of CloudFront Key Groups. Key = group name. Required: `items` (list of inline public key names or explicit IDs). Optional: `comment` | `any` | `{}` |

### Real-time Logging

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `realtime_log_configs` | Map of real-time log configs. Key = config name. Required: `sampling_rate` (1-100), `fields` (list), `kinesis_stream_config` (object with `role_arn` + `stream_arn`). Optional: `stream_type` (default `"Kinesis"`) | `any` | `{}` |

### Continuous Deployment

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `continuous_deployment_policies` | Map of continuous deployment policies. Key = identifier. Required: `policy_enabled` (bool). Optional: `staging_distribution_dns_names` (object with `items` + `quantity`), `traffic_config` (object with `type` and one of `single_weight_config` or `single_header_config`) | `any` | `{}` |

### Origin Access

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `create_origin_access_control` | Create OAC resources | `bool` | `false` |
| `origin_access_control` | Map of OAC configs. Each entry requires: `description`, `origin_type`, `signing_behavior`, `signing_protocol` | `map(object)` | S3 default |
| `create_origin_access_identity` | Create legacy OAI resources | `bool` | `false` |
| `origin_access_identities` | Map of OAIs (value = comment) | `map(string)` | `{}` |

### VPC Origins

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `create_vpc_origin` | Create VPC origin resources | `bool` | `false` |
| `vpc_origin` | Map of VPC origins. Each entry requires: `name`, `arn`, `http_port`, `https_port`, `origin_protocol_policy`, `origin_ssl_protocols` (object with `items` + `quantity`) | `map(object)` | `{}` |

### SSL / Viewer Certificate

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `viewer_certificate` | SSL configuration. Supports: `cloudfront_default_certificate`, `acm_certificate_arn`, `iam_certificate_id`, `ssl_support_method`, `minimum_protocol_version` (default `TLSv1.2_2021`) | `object` | CloudFront default cert, `TLSv1.2_2021` |
| `viewer_mtls_config` | mTLS configuration. Supports: `mode`, `trust_store_config` (object with `trust_store_id`, `advertise_trust_store_ca_names`, `ignore_certificate_expiry`) | `any` | `null` |

### Other Distribution Settings

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `geo_restriction` | Geo restriction config. Supports: `restriction_type` (`whitelist`/`blacklist`/`none`), `locations` (list of ISO 3166-1 alpha-2 codes) | `any` | `{}` |
| `custom_error_response` | List of custom error response objects. Each supports: `error_code` (required), `response_code`, `response_page_path`, `error_caching_min_ttl` | `list(object)` | `[]` |
| `logging_config` | Access log config. Supports: `bucket` (required), `prefix`, `include_cookies`. Strongly recommended for production | `object` | `null` |
| `connection_function_association_id` | ID of a connection-level CloudFront Function (v6.28+) | `string` | `null` |
| `create_monitoring_subscription` | Enable extended CloudWatch metrics | `bool` | `false` |
| `realtime_metrics_subscription_status` | `Enabled` or `Disabled` | `string` | `"Enabled"` |

---

## Outputs

### Distribution

| Output | Description |
|--------|-------------|
| `cloudfront_distribution_id` | Distribution ID |
| `cloudfront_distribution_arn` | Distribution ARN |
| `cloudfront_distribution_domain_name` | CloudFront domain name (e.g. `d1234.cloudfront.net`) |
| `cloudfront_distribution_hosted_zone_id` | Route 53 hosted zone ID for alias records |
| `cloudfront_distribution_etag` | Current distribution version (ETag) |
| `cloudfront_distribution_status` | `Deployed` or `InProgress` |
| `cloudfront_distribution_last_modified_time` | Last modification timestamp |
| `cloudfront_distribution_caller_reference` | Internal CloudFront reference |
| `cloudfront_distribution_in_progress_validation_batches` | Number of in-progress invalidation batches |
| `cloudfront_distribution_trusted_signers` | Active trusted signers |
| `cloudfront_distribution_tags` | Distribution tags |
| `cloudfront_monitoring_subscription_id` | Monitoring subscription ID |

### Policies

| Output | Description |
|--------|-------------|
| `cloudfront_cache_policy_ids` | Map of inline cache policy name to ID |
| `cloudfront_origin_request_policy_ids` | Map of inline origin request policy name to ID |
| `cloudfront_response_headers_policy_ids` | Map of inline response headers policy name to ID |

### Functions and Edge Computing

| Output | Description |
|--------|-------------|
| `cloudfront_key_value_store_arns` | Map of KVS name to ARN |
| `cloudfront_key_value_store_ids` | Map of KVS name to ID |
| `cloudfront_function_arns` | Map of function name to ARN |
| `cloudfront_function_statuses` | Map of function name to status |

### Signing

| Output | Description |
|--------|-------------|
| `cloudfront_public_key_ids` | Map of public key name to ID |
| `cloudfront_public_key_etags` | Map of public key name to ETag |
| `cloudfront_key_group_ids` | Map of key group name to ID |
| `cloudfront_key_group_etags` | Map of key group name to ETag |

### Real-time Logging

| Output | Description |
|--------|-------------|
| `cloudfront_realtime_log_config_arns` | Map of log config name to ARN |

### Continuous Deployment

| Output | Description |
|--------|-------------|
| `cloudfront_continuous_deployment_policy_ids` | Map of policy key to ID |
| `cloudfront_continuous_deployment_policy_arns` | Map of policy key to ARN |

### Origin Access

| Output | Description |
|--------|-------------|
| `cloudfront_origin_access_controls` | Full OAC resource map |
| `cloudfront_origin_access_controls_ids` | Map of OAC name to ID |
| `cloudfront_origin_access_identities` | Full OAI resource map |
| `cloudfront_origin_access_identity_ids` | Map of OAI name to ID |
| `cloudfront_origin_access_identity_iam_arns` | Map of OAI name to IAM ARN |
| `cloudfront_vpc_origin_ids` | Map of VPC origin name to ID |


## Examples

> **Note on CloudFront policies:** AWS CloudFront has three policy types that can be defined
> directly in this module via `cache_policies`, `origin_request_policies`, and
> `response_headers_policies`. Each policy is created as a standalone reusable AWS resource
> and referenced in cache behaviors by name. You can also reference externally managed or
> AWS-managed policies by name (looked up via data source) or by passing a direct ID.
>
> There is no "request headers policy" as a distinct AWS resource type. Controlling which
> headers flow to the origin is handled by `origin_request_policies`.

## Basic Usage - S3 Static Website

Creates a CloudFront distribution backed by an S3 bucket with Origin Access Control, using
the AWS-managed caching-optimised cache policy referenced by name.

```hcl
module "cloudfront" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudfront?depth=1&ref=master"

  enabled = true

  comment             = "Static website"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  create_origin_access_control = true
  origin_access_control = {
    s3_oac = {
      description      = "OAC for S3 static website"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  origin = {
    s3 = {
      domain_name           = "my-website-bucket.s3.us-east-1.amazonaws.com"
      origin_access_control = "s3_oac"
    }
  }

  default_cache_behavior = {
    target_origin_id       = "s3"
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_name      = "CachingOptimized" # AWS-managed policy looked up by name
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
  }

  viewer_certificate = {
    cloudfront_default_certificate = true
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## With Custom Policies Defined Inline

Defines a custom cache policy, origin request policy, and response headers policy directly
in this module call - no separate modules needed.

```hcl
module "cloudfront" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudfront?depth=1&ref=master"

  enabled = true

  comment     = "API CDN"
  price_class = "PriceClass_100"
  aliases     = ["api.example.com"]

  # Cache policy created inline
  cache_policies = {
    "api-cache-policy" = {
      comment               = "Short TTL for API responses"
      default_ttl           = 30
      max_ttl               = 60
      min_ttl               = 0
      header_behavior       = "whitelist"
      headers_items         = ["Authorization"]
      query_string_behavior = "whitelist"
      query_strings_items   = ["version", "locale"]
    }
  }

  # Origin request policy - controls what headers/cookies flow to origin
  origin_request_policies = {
    "api-origin-policy" = {
      comment         = "Forward auth and accept headers to origin"
      header_behavior = "whitelist"
      headers_items   = ["Authorization", "Accept", "Accept-Language"]
    }
  }

  # Response headers policy - adds security headers to responses
  response_headers_policies = {
    "api-security-headers" = {
      comment = "Security headers for the API"
      strict_transport_security_header = {
        enabled            = true
        max_age            = 63072000
        include_subdomains = true
        preload            = true
      }
      content_type_options_header = { enabled = true }
      frame_options_header        = { enabled = true, value = "DENY" }
      referrer_policy_header      = { enabled = true, value = "strict-origin-when-cross-origin" }
    }
  }

  origin = {
    alb = {
      domain_name = "internal-alb.us-east-1.elb.amazonaws.com"
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  # Reference the inline policies by their map key (= policy name)
  default_cache_behavior = {
    target_origin_id             = "alb"
    viewer_protocol_policy       = "redirect-to-https"
    cache_policy_name            = "api-cache-policy"
    origin_request_policy_name   = "api-origin-policy"
    response_headers_policy_name = "api-security-headers"
    allowed_methods              = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods               = ["GET", "HEAD"]
  }

  viewer_certificate = {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:123456789012:certificate/abc12345-1234-1234-1234-abcdef123456"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## SPA + API - Multi-Origin with CORS

Two origins (S3 for the SPA, ALB for the API) with ordered cache behaviors,
CORS response headers, and a no-cache policy for the API path.

```hcl
module "cloudfront" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudfront?depth=1&ref=master"

  enabled = true

  comment     = "SPA + API distribution"
  price_class = "PriceClass_200"
  aliases     = ["app.example.com"]

  cache_policies = {
    "spa-static-cache" = {
      default_ttl = 86400
      max_ttl     = 604800
      min_ttl     = 0
    }
    "api-no-cache" = {
      default_ttl           = 0
      max_ttl               = 0
      min_ttl               = 0
      query_string_behavior = "all"
    }
  }

  response_headers_policies = {
    "spa-cors" = {
      comment = "CORS for SPA"
      cors = {
        enabled                          = true
        override                         = true
        access_control_allow_credentials = false
        access_control_allow_headers     = ["*"]
        access_control_allow_methods     = ["GET", "HEAD", "OPTIONS"]
        access_control_allow_origins     = ["https://app.example.com"]
        access_control_max_age           = 86400
      }
      strict_transport_security_header = { enabled = true, max_age = 63072000 }
      content_type_options_header      = { enabled = true }
    }
  }

  create_origin_access_control = true
  origin_access_control = {
    s3_oac = {
      description      = ""
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  origin = {
    s3-spa = {
      domain_name           = "my-spa-bucket.s3.us-east-1.amazonaws.com"
      origin_access_control = "s3_oac"
    }
    api = {
      domain_name = "api.internal.example.com"
      custom_origin_config = {
        http_port              = 443
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  default_cache_behavior = {
    target_origin_id             = "s3-spa"
    viewer_protocol_policy       = "redirect-to-https"
    cache_policy_name            = "spa-static-cache"
    response_headers_policy_name = "spa-cors"
    compress                     = true
  }

  ordered_cache_behavior = [
    {
      path_pattern                 = "/api/*"
      target_origin_id             = "api"
      viewer_protocol_policy       = "https-only"
      cache_policy_name            = "api-no-cache"
      response_headers_policy_name = "spa-cors"
      allowed_methods              = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods               = ["GET", "HEAD"]
    }
  ]

  viewer_certificate = {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:123456789012:certificate/abc12345-1234-1234-1234-abcdef123456"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Environment = "production"
    Team        = "frontend"
  }
}
```

## Advanced - WAF, Geo Restriction, Custom Error Pages, Monitoring

```hcl
module "cloudfront" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudfront?depth=1&ref=master"

  enabled = true

  comment     = "Production distribution with full hardening"
  price_class = "PriceClass_All"
  aliases     = ["www.example.com", "example.com"]

  web_acl_id = "arn:aws:wafv2:us-east-1:123456789012:global/webacl/production-waf/abc12345"

  response_headers_policies = {
    "production-security" = {
      strict_transport_security_header = {
        enabled            = true
        max_age            = 63072000
        include_subdomains = true
        preload            = true
      }
      content_type_options_header = { enabled = true }
      frame_options_header        = { enabled = true, value = "SAMEORIGIN" }
      referrer_policy_header      = { enabled = true, value = "strict-origin-when-cross-origin" }
      content_security_policy_header = {
        enabled = true
        value   = "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'"
      }
      server_timing_header = { enabled = true, sampling_rate = 10 }
    }
  }

  create_origin_access_control = true
  origin_access_control = {
    s3_oac = {
      description      = ""
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  origin = {
    s3 = {
      domain_name           = "my-production-bucket.s3.us-east-1.amazonaws.com"
      origin_access_control = "s3_oac"
    }
  }

  default_cache_behavior = {
    target_origin_id             = "s3"
    viewer_protocol_policy       = "redirect-to-https"
    cache_policy_name            = "CachingOptimized"
    response_headers_policy_name = "production-security"
    compress                     = true
  }

  geo_restriction = {
    restriction_type = "whitelist"
    locations        = ["US", "GB", "DE", "AE", "SA"]
  }

  custom_error_response = [
    {
      error_code            = 403
      response_code         = 200
      response_page_path    = "/index.html"
      error_caching_min_ttl = 10
    },
    {
      error_code            = 404
      response_code         = 200
      response_page_path    = "/index.html"
      error_caching_min_ttl = 10
    }
  ]

  logging_config = {
    bucket          = "my-cf-logs.s3.amazonaws.com"
    prefix          = "cloudfront/"
    include_cookies = false
  }

  create_monitoring_subscription        = true
  realtime_metrics_subscription_status = "Enabled"

  viewer_certificate = {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:123456789012:certificate/abc12345-1234-1234-1234-abcdef123456"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## CloudFront Functions with Key-Value Store

Creates a CloudFront Function for URL rewriting backed by a Key-Value Store for dynamic
redirect rules. The function is associated with the default cache behavior.

```hcl
module "cloudfront" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudfront?depth=1&ref=master"

  enabled = true

  comment     = "Distribution with edge functions"
  price_class = "PriceClass_100"

  # Key-Value Store used by the function for redirect lookups
  key_value_stores = {
    "redirect-rules" = {
      comment = "URL redirect rules for edge rewriting"
    }
  }

  # CloudFront Function that references the KVS by inline name
  functions = {
    "url-rewriter" = {
      runtime = "cloudfront-js-2.0"
      comment = "Rewrites incoming URLs using KVS redirect rules"
      publish = true
      key_value_store_associations = ["redirect-rules"] # inline KVS name or explicit ARN
      code = <<-JS
        import cf from 'cloudfront';
        const kvsId = cf.kvs.id;
        async function handler(event) {
          const request = event.request;
          const kvs = cf.kvs();
          try {
            const redirect = await kvs.get(request.uri);
            if (redirect) {
              return { statusCode: 301, headers: { location: { value: redirect } } };
            }
          } catch (e) {}
          return request;
        }
      JS
    }
  }

  create_origin_access_control = true
  origin_access_control = {
    s3_oac = {
      description      = ""
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  origin = {
    s3 = {
      domain_name           = "my-bucket.s3.us-east-1.amazonaws.com"
      origin_access_control = "s3_oac"
    }
  }

  default_cache_behavior = {
    target_origin_id       = "s3"
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_name      = "CachingOptimized"
    compress               = true
    # Associate the inline function by name
    function_association = [
      {
        event_type    = "viewer-request"
        function_name = "url-rewriter"
      }
    ]
  }

  viewer_certificate = {
    cloudfront_default_certificate = true
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}

# Access the KVS ARN to populate redirect rules via a separate resource
output "redirect_kvs_arn" {
  value = module.cloudfront.cloudfront_key_value_store_arns["redirect-rules"]
}
```

## Signed URLs / Cookies - Public Key and Key Group

Creates a public key and key group for serving private content with signed
URLs or signed cookies. The key group is created outside the module call
because the distribution needs the key group ID at plan time (every module
sub-resource is gated by `enabled`, so a "signing-only" module call is not
possible).

```hcl
# Step 1: Create the public key and key group as standalone resources
resource "aws_cloudfront_public_key" "signing" {
  name        = "signing-key-2024"
  comment     = "RSA-2048 signing key - rotated annually"
  encoded_key = file("${path.module}/keys/cloudfront-public-key.pem")
}

resource "aws_cloudfront_key_group" "signing" {
  name    = "content-signing-group"
  comment = "Key group for signed URL enforcement"
  items   = [aws_cloudfront_public_key.signing.id]
}

# Step 2: Create the distribution, referencing the key group from step 1
module "cloudfront" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudfront?depth=1&ref=master"

  enabled = true

  comment     = "Private content distribution"
  price_class = "PriceClass_100"

  create_origin_access_control = true
  origin_access_control = {
    s3_oac = {
      description      = ""
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  origin = {
    s3-private = {
      domain_name           = "my-private-content-bucket.s3.us-east-1.amazonaws.com"
      origin_access_control = "s3_oac"
    }
  }

  default_cache_behavior = {
    target_origin_id       = "s3-private"
    viewer_protocol_policy = "https-only"
    cache_policy_name      = "CachingOptimized"
    compress               = true
    # Reference the key group created in step 1
    trusted_key_groups = [aws_cloudfront_key_group.signing.id]
  }

  viewer_certificate = {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:123456789012:certificate/abc12345-1234-1234-1234-abcdef123456"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Real-time Logging with Kinesis

Streams CloudFront access logs in real time to a Kinesis Data Stream for
immediate processing (e.g., fraud detection, live dashboards).

```hcl
module "cloudfront" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudfront?depth=1&ref=master"

  enabled = true

  comment     = "Distribution with real-time logging"
  price_class = "PriceClass_100"

  realtime_log_configs = {
    "access-logs" = {
      sampling_rate = 100 # 1-100 percent of requests
      fields = [
        "timestamp",
        "c-ip",
        "cs-method",
        "cs-uri-stem",
        "sc-status",
        "cs(User-Agent)",
        "x-edge-location",
        "time-taken",
      ]
      kinesis_stream_config = {
        role_arn   = "arn:aws:iam::123456789012:role/cloudfront-realtime-log-role"
        stream_arn = "arn:aws:kinesis:us-east-1:123456789012:stream/cloudfront-access-logs"
      }
    }
  }

  create_origin_access_control = true
  origin_access_control = {
    s3_oac = {
      description      = ""
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  origin = {
    s3 = {
      domain_name           = "my-bucket.s3.us-east-1.amazonaws.com"
      origin_access_control = "s3_oac"
    }
  }

  default_cache_behavior = {
    target_origin_id         = "s3"
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_name        = "CachingOptimized"
    compress                 = true
    # Reference the inline real-time log config by name
    realtime_log_config_name = "access-logs"
  }

  viewer_certificate = {
    cloudfront_default_certificate = true
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Continuous Deployment - Blue/Green Canary Release

Gradually shifts a percentage of traffic to a staging distribution before
promoting. Uses a weight-based traffic split with session stickiness.

```hcl
# Step 1: Staging distribution (deployed first)
module "cloudfront_staging" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudfront?depth=1&ref=master"

  enabled = true
  staging = true # marks this as a staging distribution

  comment     = "Staging distribution - v2 candidate"
  price_class = "PriceClass_100"

  create_origin_access_control = true
  origin_access_control = {
    s3_oac = {
      description      = ""
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  origin = {
    s3 = {
      domain_name           = "my-website-v2-bucket.s3.us-east-1.amazonaws.com"
      origin_access_control = "s3_oac"
    }
  }

  default_cache_behavior = {
    target_origin_id       = "s3"
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_name      = "CachingOptimized"
    compress               = true
  }

  viewer_certificate = {
    cloudfront_default_certificate = true
  }
}

# Step 2: Create the continuous deployment policy linking staging to production.
# The policy is a standalone resource (a "policy-only" module call is not
# possible because every module sub-resource is gated by `enabled`).
resource "aws_cloudfront_continuous_deployment_policy" "v2_canary" {
  enabled = true

  staging_distribution_dns_names {
    items    = [module.cloudfront_staging.cloudfront_distribution_domain_name]
    quantity = 1
  }

  traffic_config {
    type = "SingleWeight"

    single_weight_config {
      weight = 0.15 # send 15% of traffic to staging

      session_stickiness_config {
        idle_ttl    = 300
        maximum_ttl = 600
      }
    }
  }
}

# Step 3: Production distribution referencing the continuous deployment policy
module "cloudfront_production" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudfront?depth=1&ref=master"

  enabled = true

  comment     = "Production distribution"
  price_class = "PriceClass_100"

  # Reference the policy created in step 2
  continuous_deployment_policy_id = aws_cloudfront_continuous_deployment_policy.v2_canary.id

  create_origin_access_control = true
  origin_access_control = {
    s3_oac = {
      description      = ""
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  origin = {
    s3 = {
      domain_name           = "my-website-bucket.s3.us-east-1.amazonaws.com"
      origin_access_control = "s3_oac"
    }
  }

  default_cache_behavior = {
    target_origin_id       = "s3"
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_name      = "CachingOptimized"
    compress               = true
  }

  viewer_certificate = {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:123456789012:certificate/abc12345-1234-1234-1234-abcdef123456"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```
