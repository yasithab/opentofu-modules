# CloudFront Module - Examples

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudfront?depth=1&ref=v1.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudfront?depth=1&ref=v1.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudfront?depth=1&ref=v1.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudfront?depth=1&ref=v1.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudfront?depth=1&ref=v1.0.0"

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
        "viewer-request" = {
          function_name = "url-rewriter"
        }
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

Creates a public key and key group in the same module call for serving
private content with signed URLs or signed cookies.

```hcl
module "cloudfront" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudfront?depth=1&ref=v1.0.0"

  enabled = true

  comment     = "Private content distribution"
  price_class = "PriceClass_100"

  # Upload the RSA public key (PEM-encoded, 2048-bit minimum)
  public_keys = {
    "signing-key-2024" = {
      comment     = "RSA-2048 signing key - rotated annually"
      encoded_key = file("${path.module}/keys/cloudfront-public-key.pem")
    }
  }

  # Key group references one or more public keys by inline name or explicit ID
  key_groups = {
    "content-signing-group" = {
      comment = "Key group for signed URL enforcement"
      items   = ["signing-key-2024"] # inline public key name
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
    # Enforce signed URLs using the inline key group by ID
    trusted_key_groups = [module.cloudfront.cloudfront_key_group_ids["content-signing-group"]]
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
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudfront?depth=1&ref=v1.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudfront?depth=1&ref=v1.0.0"

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

# Step 2: Production distribution with continuous deployment policy
module "cloudfront_production" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudfront?depth=1&ref=v1.0.0"

  enabled = true

  comment     = "Production distribution"
  price_class = "PriceClass_100"

  # Define the continuous deployment policy inline
  continuous_deployment_policies = {
    "v2-canary" = {
      policy_enabled = true
      staging_distribution_dns_names = {
        items    = [module.cloudfront_staging.cloudfront_distribution_domain_name]
        quantity = 1
      }
      traffic_config = {
        type = "SingleWeight"
        single_weight_config = {
          weight = 0.15 # send 15% of traffic to staging
          session_stickiness_config = {
            idle_ttl    = 300
            maximum_ttl = 600
          }
        }
      }
    }
  }

  # Attach the continuous deployment policy to this distribution
  # (use the ID from the inline policy output)
  continuous_deployment_policy_id = module.cloudfront_production.cloudfront_continuous_deployment_policy_ids["v2-canary"]

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
