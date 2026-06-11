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
| aliases | Extra CNAMEs (alternate domain names), if any, for this distribution. | `list(string)` | `null` | no |
| anycast\_ip\_list\_id | ID of the Anycast static IP list to associate with the CloudFront distribution | `string` | `null` | no |
| cache\_policies | Map of CloudFront cache policies to create. Map key is used as the policy name. Supports: comment, default\_ttl, max\_ttl, min\_ttl, cookie\_behavior, cookies\_items, header\_behavior, headers\_items, query\_string\_behavior, query\_strings\_items, enable\_accept\_encoding\_brotli, enable\_accept\_encoding\_gzip. | `any` | `{}` | no |
| comment | Any comments you want to include about the distribution. | `string` | `null` | no |
| connection\_function\_association\_id | ID of the CloudFront connection-level function to associate with the distribution (v6.28+) | `string` | `null` | no |
| continuous\_deployment\_policies | Map of CloudFront Continuous Deployment Policies to create. Map key is used as the policy identifier. Required: policy\_enabled (bool). Optional: staging\_distribution\_dns\_names (object with items and quantity), traffic\_config (object with type and one of single\_weight\_config or single\_header\_config). | `any` | `{}` | no |
| continuous\_deployment\_policy\_id | Identifier of a continuous deployment policy. This argument should only be set on a production distribution. | `string` | `null` | no |
| create\_monitoring\_subscription | If enabled, the resource for monitoring subscription will created. | `bool` | `false` | no |
| create\_origin\_access\_control | Controls if CloudFront origin access control should be created | `bool` | `false` | no |
| create\_origin\_access\_identity | Controls if CloudFront origin access identity should be created | `bool` | `false` | no |
| create\_vpc\_origin | If enabled, the resource for VPC origin will be created. | `bool` | `false` | no |
| custom\_error\_response | List of custom error response elements | <pre>list(object({<br/>    error_code            = number<br/>    response_code         = optional(number)<br/>    response_page_path    = optional(string)<br/>    error_caching_min_ttl = optional(number)<br/>  }))</pre> | `[]` | no |
| default\_cache\_behavior | The default cache behavior for this distribution (required). A cache policy is mandatory: set `cache_policy_id` (e.g. an AWS managed policy ID) or `cache_policy_name` (inline policy from `cache_policies`, or an AWS/externally managed policy looked up by name). Legacy `forwarded_values` is not supported. The `*_name` variants of origin request, response headers and realtime log config follow the same resolution rules. | <pre>object({<br/>    target_origin_id          = string<br/>    viewer_protocol_policy    = optional(string, "redirect-to-https")<br/>    allowed_methods           = optional(list(string), ["GET", "HEAD", "OPTIONS"])<br/>    cached_methods            = optional(list(string), ["GET", "HEAD"])<br/>    compress                  = optional(bool, true)<br/>    field_level_encryption_id = optional(string)<br/>    smooth_streaming          = optional(bool)<br/>    trusted_signers           = optional(list(string))<br/>    trusted_key_groups        = optional(list(string))<br/><br/>    cache_policy_id              = optional(string)<br/>    cache_policy_name            = optional(string)<br/>    origin_request_policy_id     = optional(string)<br/>    origin_request_policy_name   = optional(string)<br/>    response_headers_policy_id   = optional(string)<br/>    response_headers_policy_name = optional(string)<br/><br/>    realtime_log_config_arn  = optional(string)<br/>    realtime_log_config_name = optional(string)<br/><br/>    function_association = optional(list(object({<br/>      event_type    = string<br/>      function_arn  = optional(string)<br/>      function_name = optional(string)<br/>    })), [])<br/><br/>    lambda_function_association = optional(list(object({<br/>      event_type   = string<br/>      lambda_arn   = string<br/>      include_body = optional(bool)<br/>    })), [])<br/><br/>    grpc_config = optional(object({<br/>      enabled = bool<br/>    }))<br/>  })</pre> | n/a | yes |
| default\_root\_object | The object that you want CloudFront to return (for example, index.html) when an end user requests the root URL. | `string` | `null` | no |
| distribution\_enabled | Whether the CloudFront distribution accepts end user requests for content. Decoupled from `enabled` (which controls resource creation), so a distribution can be kept in state but disabled | `bool` | `true` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| functions | Map of CloudFront Functions to create. Map key is used as the function name. Required: runtime (string, e.g. 'cloudfront-js-2.0'), code (string, JS source). Optional: comment (string), publish (bool, default true), key\_value\_store\_associations (list of KVS ARNs or inline KVS names). | `any` | `{}` | no |
| geo\_restriction | The restriction configuration for this distribution (geo\_restrictions) | `any` | `{}` | no |
| http\_version | The maximum HTTP version to support on the distribution. Allowed values are http1.1, http2, http2and3, and http3. The default is http2. | `string` | `"http2"` | no |
| is\_ipv6\_enabled | Whether the IPv6 is enabled for the distribution. | `bool` | `null` | no |
| key\_groups | Map of CloudFront Key Groups to create. Map key is used as the group name. Required: items (list of public key IDs or inline public key names). Optional: comment (string). | `any` | `{}` | no |
| key\_value\_stores | Map of CloudFront Key-Value Stores to create. Map key is used as the store name. Supports: comment (string). | `any` | `{}` | no |
| logging\_config | The logging configuration that controls how logs are written to your distribution (maximum one). Strongly recommended for production distributions. Set to null (default) to disable logging | <pre>object({<br/>    bucket          = string<br/>    prefix          = optional(string)<br/>    include_cookies = optional(bool)<br/>  })</pre> | `null` | no |
| ordered\_cache\_behavior | An ordered list of cache behaviors for this distribution, evaluated top to bottom (the topmost behavior has precedence 0). Same shape as `default_cache_behavior` plus the required `path_pattern`. A cache policy (`cache_policy_id` or `cache_policy_name`) is mandatory per behavior; legacy `forwarded_values` is not supported. | <pre>list(object({<br/>    path_pattern              = string<br/>    target_origin_id          = string<br/>    viewer_protocol_policy    = optional(string, "redirect-to-https")<br/>    allowed_methods           = optional(list(string), ["GET", "HEAD", "OPTIONS"])<br/>    cached_methods            = optional(list(string), ["GET", "HEAD"])<br/>    compress                  = optional(bool, true)<br/>    field_level_encryption_id = optional(string)<br/>    smooth_streaming          = optional(bool)<br/>    trusted_signers           = optional(list(string))<br/>    trusted_key_groups        = optional(list(string))<br/><br/>    cache_policy_id              = optional(string)<br/>    cache_policy_name            = optional(string)<br/>    origin_request_policy_id     = optional(string)<br/>    origin_request_policy_name   = optional(string)<br/>    response_headers_policy_id   = optional(string)<br/>    response_headers_policy_name = optional(string)<br/><br/>    realtime_log_config_arn  = optional(string)<br/>    realtime_log_config_name = optional(string)<br/><br/>    function_association = optional(list(object({<br/>      event_type    = string<br/>      function_arn  = optional(string)<br/>      function_name = optional(string)<br/>    })), [])<br/><br/>    lambda_function_association = optional(list(object({<br/>      event_type   = string<br/>      lambda_arn   = string<br/>      include_body = optional(bool)<br/>    })), [])<br/><br/>    grpc_config = optional(object({<br/>      enabled = bool<br/>    }))<br/>  }))</pre> | `[]` | no |
| origin | Map of origins for this distribution. The map key is used as `origin_id` unless overridden. Exactly one of `custom_origin_config`, `s3_origin_config` (legacy OAI), `vpc_origin_config`, or `origin_access_control_id`/`origin_access_control` should be used per origin. `origin_access_control` and `s3_origin_config.origin_access_identity`/`vpc_origin_config.vpc_origin` accept names of OAC/OAI/VPC-origin resources created inline by this module. | <pre>map(object({<br/>    domain_name                 = string<br/>    origin_id                   = optional(string)<br/>    origin_path                 = optional(string, "")<br/>    connection_attempts         = optional(number)<br/>    connection_timeout          = optional(number)<br/>    response_completion_timeout = optional(number)<br/>    origin_access_control_id    = optional(string)<br/>    origin_access_control       = optional(string)<br/>    custom_headers              = optional(map(string), {})<br/>    custom_origin_config = optional(object({<br/>      http_port                = optional(number, 80)<br/>      https_port               = optional(number, 443)<br/>      origin_protocol_policy   = optional(string, "https-only")<br/>      origin_ssl_protocols     = optional(list(string), ["TLSv1.2"])<br/>      origin_keepalive_timeout = optional(number)<br/>      origin_read_timeout      = optional(number)<br/>      ip_address_type          = optional(string)<br/>    }))<br/>    s3_origin_config = optional(object({<br/>      cloudfront_access_identity_path = optional(string)<br/>      origin_access_identity          = optional(string)<br/>    }))<br/>    origin_shield = optional(object({<br/>      enabled              = optional(bool, true)<br/>      origin_shield_region = string<br/>    }))<br/>    vpc_origin_config = optional(object({<br/>      vpc_origin_id            = optional(string)<br/>      vpc_origin               = optional(string)<br/>      origin_keepalive_timeout = optional(number)<br/>      origin_read_timeout      = optional(number)<br/>      owner_account_id         = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
| origin\_access\_control | Map of CloudFront origin access control | <pre>map(object({<br/>    description      = string<br/>    origin_type      = string<br/>    signing_behavior = string<br/>    signing_protocol = string<br/>  }))</pre> | <pre>{<br/>  "s3": {<br/>    "description": "",<br/>    "origin_type": "s3",<br/>    "signing_behavior": "always",<br/>    "signing_protocol": "sigv4"<br/>  }<br/>}</pre> | no |
| origin\_access\_identities | Map of CloudFront origin access identities (value as a comment) | `map(string)` | `{}` | no |
| origin\_group | Map of origin groups for this distribution. The map key is used as `origin_id` unless overridden. | <pre>map(object({<br/>    origin_id                  = optional(string)<br/>    failover_status_codes      = list(number)<br/>    primary_member_origin_id   = string<br/>    secondary_member_origin_id = string<br/>  }))</pre> | `{}` | no |
| origin\_request\_policies | Map of CloudFront origin request policies to create. Map key is used as the policy name. Supports: comment, cookie\_behavior, cookies\_items, header\_behavior, headers\_items, query\_string\_behavior, query\_strings\_items. | `any` | `{}` | no |
| price\_class | The price class for this distribution. One of PriceClass\_All, PriceClass\_200, PriceClass\_100 | `string` | `null` | no |
| public\_keys | Map of CloudFront Public Keys to create. Map key is used as the key name. Required: encoded\_key (string, PEM-encoded public key). Optional: comment (string). | `any` | `{}` | no |
| realtime\_log\_configs | Map of CloudFront Real-time Log Configs to create. Map key is used as the config name. Required: sampling\_rate (number, 1-100), fields (list of strings), kinesis\_stream\_config (object with role\_arn and stream\_arn). Optional: stream\_type (string, default 'Kinesis'). | `any` | `{}` | no |
| realtime\_metrics\_subscription\_status | A flag that indicates whether additional CloudWatch metrics are enabled for a given CloudFront distribution. Valid values are `Enabled` and `Disabled`. | `string` | `"Enabled"` | no |
| response\_headers\_policies | Map of CloudFront response headers policies to create. Map key is used as the policy name. Supports: comment, cors (object), custom\_headers (list), remove\_headers (set), content\_security\_policy\_header, content\_type\_options\_header, frame\_options\_header, referrer\_policy\_header, strict\_transport\_security\_header, xss\_protection\_header, server\_timing\_header. | `any` | `{}` | no |
| retain\_on\_delete | Disables the distribution instead of deleting it when destroying the resource through Terraform. If this is set, the distribution needs to be deleted manually afterwards. | `bool` | `false` | no |
| staging | Whether the distribution is a staging distribution. | `bool` | `false` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| viewer\_certificate | The SSL configuration for this distribution. minimum\_protocol\_version defaults to TLSv1.2\_2021; override only if legacy clients require an older protocol | <pre>object({<br/>    acm_certificate_arn            = optional(string)<br/>    cloudfront_default_certificate = optional(bool)<br/>    iam_certificate_id             = optional(string)<br/>    minimum_protocol_version       = optional(string, "TLSv1.2_2021")<br/>    ssl_support_method             = optional(string)<br/>  })</pre> | <pre>{<br/>  "cloudfront_default_certificate": true<br/>}</pre> | no |
| viewer\_mtls\_config | Configuration for viewer mTLS authentication. Supports 'mode' (string) and 'trust\_store\_config' object with 'trust\_store\_id' (required), 'advertise\_trust\_store\_ca\_names' (bool), and 'ignore\_certificate\_expiry' (bool). | `any` | `null` | no |
| vpc\_origin | Map of CloudFront VPC origin | <pre>map(object({<br/>    name                   = string<br/>    arn                    = string<br/>    http_port              = number<br/>    https_port             = number<br/>    origin_protocol_policy = string<br/>    origin_ssl_protocols = object({<br/>      items    = list(string)<br/>      quantity = number<br/>    })<br/>  }))</pre> | `{}` | no |
| wait\_for\_deployment | If enabled, the resource will wait for the distribution status to change from InProgress to Deployed. Setting this to false will skip the process. | `bool` | `true` | no |
| web\_acl\_id | If you're using AWS WAF to filter CloudFront requests, the Id of the AWS WAF web ACL that is associated with the distribution. The WAF Web ACL must exist in the WAF Global (CloudFront) region and the credentials configuring this argument must have waf:GetWebACL permissions assigned. If using WAFv2, provide the ARN of the web ACL. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| cloudfront\_cache\_policy\_ids | Map of cache policy name to ID for policies created by this module. |
| cloudfront\_continuous\_deployment\_policy\_arns | Map of Continuous Deployment Policy key to ARN for policies created by this module. |
| cloudfront\_continuous\_deployment\_policy\_ids | Map of Continuous Deployment Policy key to ID for policies created by this module. |
| cloudfront\_distribution\_arn | The ARN (Amazon Resource Name) for the distribution. |
| cloudfront\_distribution\_caller\_reference | Internal value used by CloudFront to allow future updates to the distribution configuration. |
| cloudfront\_distribution\_domain\_name | The domain name corresponding to the distribution. |
| cloudfront\_distribution\_etag | The current version of the distribution's information. |
| cloudfront\_distribution\_hosted\_zone\_id | The CloudFront Route 53 zone ID that can be used to route an Alias Resource Record Set to. |
| cloudfront\_distribution\_id | The identifier for the distribution. |
| cloudfront\_distribution\_in\_progress\_validation\_batches | The number of invalidation batches currently in progress. |
| cloudfront\_distribution\_last\_modified\_time | The date and time the distribution was last modified. |
| cloudfront\_distribution\_status | The current status of the distribution. Deployed if the distribution's information is fully propagated throughout the Amazon CloudFront system. |
| cloudfront\_distribution\_tags | Tags of the distribution's |
| cloudfront\_distribution\_trusted\_signers | List of nested attributes for active trusted signers, if the distribution is set up to serve private content with signed URLs |
| cloudfront\_function\_arns | Map of CloudFront Function name to ARN for functions created by this module. |
| cloudfront\_function\_statuses | Map of CloudFront Function name to status for functions created by this module. |
| cloudfront\_key\_group\_etags | Map of Key Group name to ETag for key groups created by this module. |
| cloudfront\_key\_group\_ids | Map of Key Group name to ID for key groups created by this module. |
| cloudfront\_key\_value\_store\_arns | Map of Key-Value Store name to ARN for stores created by this module. |
| cloudfront\_key\_value\_store\_ids | Map of Key-Value Store name to ID for stores created by this module. |
| cloudfront\_monitoring\_subscription\_id | The ID of the CloudFront monitoring subscription, which corresponds to the `distribution_id`. |
| cloudfront\_origin\_access\_controls | The origin access controls created |
| cloudfront\_origin\_access\_controls\_ids | The IDS of the origin access identities created |
| cloudfront\_origin\_access\_identities | The origin access identities created |
| cloudfront\_origin\_access\_identity\_iam\_arns | The IAM arns of the origin access identities created |
| cloudfront\_origin\_access\_identity\_ids | The IDS of the origin access identities created |
| cloudfront\_origin\_request\_policy\_ids | Map of origin request policy name to ID for policies created by this module. |
| cloudfront\_public\_key\_etags | Map of Public Key name to ETag for public keys created by this module. |
| cloudfront\_public\_key\_ids | Map of Public Key name to ID for public keys created by this module. |
| cloudfront\_realtime\_log\_config\_arns | Map of Real-time Log Config name to ARN for configs created by this module. |
| cloudfront\_response\_headers\_policy\_ids | Map of response headers policy name to ID for policies created by this module. |
| cloudfront\_vpc\_origin\_ids | The IDS of the VPC origin created |
<!-- END_TF_DOCS -->

</details>
