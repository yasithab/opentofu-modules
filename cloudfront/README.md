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

## Policy Name Resolution

Policies can be referenced in cache behaviors in three ways (tried in order):

1. **Direct ID** - pass `cache_policy_id`, `origin_request_policy_id`, or `response_headers_policy_id`
2. **Inline name** - pass `cache_policy_name` matching a key in `cache_policies` (created in this module call)
3. **AWS-managed name** - pass `cache_policy_name` not found in `cache_policies` (looked up via data source)

The same three-tier resolution applies to `realtime_log_config_arn`/`realtime_log_config_name`
and `function_association.function_arn`/`function_association.function_name`.

## Usage

```hcl
module "cloudfront" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//cloudfront?depth=1&ref=v1.0.0"

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

See [EXAMPLES.md](./EXAMPLES.md) for complete usage scenarios.

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
| `enabled` | Create the CloudFront distribution | `bool` | `true` |
| `comment` | Distribution comment | `string` | `null` |
| `aliases` | Alternate domain names (CNAMEs) | `list(string)` | `null` |
| `default_root_object` | Default root object (e.g. `index.html`) | `string` | `null` |
| `price_class` | `PriceClass_All`, `PriceClass_200`, or `PriceClass_100` | `string` | `null` |
| `http_version` | `http2`, `http2and3`, `http3`, `http1.1` | `string` | `"http2"` |
| `is_ipv6_enabled` | Enable IPv6 | `bool` | `null` |
| `web_acl_id` | WAFv2 web ACL ARN | `string` | `null` |
| `staging` | Mark as a staging distribution | `bool` | `false` |
| `continuous_deployment_policy_id` | Continuous deployment policy ID (production only) | `string` | `null` |
| `anycast_ip_list_id` | Anycast static IP list ID | `string` | `null` |
| `retain_on_delete` | Disable instead of delete on destroy | `bool` | `false` |
| `wait_for_deployment` | Wait for `Deployed` status after changes | `bool` | `true` |
| `tags` | Tags applied to all taggable resources | `map(string)` | `{}` |

### Origins

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `origin` | Map of origins. Key is used as `origin_id`. Each entry supports: `domain_name` (required), `origin_path`, `origin_access_control` (OAC name), `custom_origin_config`, `s3_origin_config`, `custom_header` (list), `origin_shield`, `vpc_origin_config`, `connection_attempts`, `connection_timeout`, `response_completion_timeout` | `any` | `null` |
| `origin_group` | Map of origin groups. Each entry requires `failover_status_codes`, `primary_member_origin_id`, `secondary_member_origin_id` | `any` | `{}` |

### Cache Behaviors

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `default_cache_behavior` | Default cache behavior. Supports all standard attributes plus `cache_policy_name`, `origin_request_policy_name`, `response_headers_policy_name`, `realtime_log_config_name`, `function_association` (list with `function_name` for inline functions), `lambda_function_association`, `grpc_config` | `any` | `null` |
| `ordered_cache_behavior` | List of ordered cache behaviors, same attributes as `default_cache_behavior` plus `path_pattern` | `any` | `[]` |

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
| `viewer_certificate` | SSL configuration. Supports: `cloudfront_default_certificate`, `acm_certificate_arn`, `iam_certificate_id`, `ssl_support_method`, `minimum_protocol_version` | `any` | CloudFront default cert |
| `viewer_mtls_config` | mTLS configuration. Supports: `mode`, `trust_store_config` (object with `trust_store_id`, `advertise_trust_store_ca_names`, `ignore_certificate_expiry`) | `any` | `null` |

### Other Distribution Settings

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `geo_restriction` | Geo restriction config. Supports: `restriction_type` (`whitelist`/`blacklist`/`none`), `locations` (list of ISO 3166-1 alpha-2 codes) | `any` | `{}` |
| `custom_error_response` | List of custom error response objects. Each supports: `error_code`, `response_code`, `response_page_path`, `error_caching_min_ttl` | `any` | `{}` |
| `logging_config` | Access log config. Supports: `bucket` (required), `prefix`, `include_cookies` | `any` | `{}` |
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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.11.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.39.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.39.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aliases"></a> [aliases](#input\_aliases) | Extra CNAMEs (alternate domain names), if any, for this distribution. | `list(string)` | `null` | no |
| <a name="input_anycast_ip_list_id"></a> [anycast\_ip\_list\_id](#input\_anycast\_ip\_list\_id) | ID of the Anycast static IP list to associate with the CloudFront distribution | `string` | `null` | no |
| <a name="input_cache_policies"></a> [cache\_policies](#input\_cache\_policies) | Map of CloudFront cache policies to create. Map key is used as the policy name. Supports: comment, default\_ttl, max\_ttl, min\_ttl, cookie\_behavior, cookies\_items, header\_behavior, headers\_items, query\_string\_behavior, query\_strings\_items, enable\_accept\_encoding\_brotli, enable\_accept\_encoding\_gzip. | `any` | `{}` | no |
| <a name="input_comment"></a> [comment](#input\_comment) | Any comments you want to include about the distribution. | `string` | `null` | no |
| <a name="input_connection_function_association_id"></a> [connection\_function\_association\_id](#input\_connection\_function\_association\_id) | ID of the CloudFront connection-level function to associate with the distribution (v6.28+) | `string` | `null` | no |
| <a name="input_continuous_deployment_policies"></a> [continuous\_deployment\_policies](#input\_continuous\_deployment\_policies) | Map of CloudFront Continuous Deployment Policies to create. Map key is used as the policy identifier. Required: policy\_enabled (bool). Optional: staging\_distribution\_dns\_names (object with items and quantity), traffic\_config (object with type and one of single\_weight\_config or single\_header\_config). | `any` | `{}` | no |
| <a name="input_continuous_deployment_policy_id"></a> [continuous\_deployment\_policy\_id](#input\_continuous\_deployment\_policy\_id) | Identifier of a continuous deployment policy. This argument should only be set on a production distribution. | `string` | `null` | no |
| <a name="input_create_monitoring_subscription"></a> [create\_monitoring\_subscription](#input\_create\_monitoring\_subscription) | If enabled, the resource for monitoring subscription will created. | `bool` | `false` | no |
| <a name="input_create_origin_access_control"></a> [create\_origin\_access\_control](#input\_create\_origin\_access\_control) | Controls if CloudFront origin access control should be created | `bool` | `false` | no |
| <a name="input_create_origin_access_identity"></a> [create\_origin\_access\_identity](#input\_create\_origin\_access\_identity) | Controls if CloudFront origin access identity should be created | `bool` | `false` | no |
| <a name="input_create_vpc_origin"></a> [create\_vpc\_origin](#input\_create\_vpc\_origin) | If enabled, the resource for VPC origin will be created. | `bool` | `false` | no |
| <a name="input_custom_error_response"></a> [custom\_error\_response](#input\_custom\_error\_response) | One or more custom error response elements | `any` | `{}` | no |
| <a name="input_default_cache_behavior"></a> [default\_cache\_behavior](#input\_default\_cache\_behavior) | The default cache behavior for this distribution | `any` | `null` | no |
| <a name="input_default_root_object"></a> [default\_root\_object](#input\_default\_root\_object) | The object that you want CloudFront to return (for example, index.html) when an end user requests the root URL. | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Controls if CloudFront distribution should be created | `bool` | `true` | no |
| <a name="input_functions"></a> [functions](#input\_functions) | Map of CloudFront Functions to create. Map key is used as the function name. Required: runtime (string, e.g. 'cloudfront-js-2.0'), code (string, JS source). Optional: comment (string), publish (bool, default true), key\_value\_store\_associations (list of KVS ARNs or inline KVS names). | `any` | `{}` | no |
| <a name="input_geo_restriction"></a> [geo\_restriction](#input\_geo\_restriction) | The restriction configuration for this distribution (geo\_restrictions) | `any` | `{}` | no |
| <a name="input_http_version"></a> [http\_version](#input\_http\_version) | The maximum HTTP version to support on the distribution. Allowed values are http1.1, http2, http2and3, and http3. The default is http2. | `string` | `"http2"` | no |
| <a name="input_is_ipv6_enabled"></a> [is\_ipv6\_enabled](#input\_is\_ipv6\_enabled) | Whether the IPv6 is enabled for the distribution. | `bool` | `null` | no |
| <a name="input_key_groups"></a> [key\_groups](#input\_key\_groups) | Map of CloudFront Key Groups to create. Map key is used as the group name. Required: items (list of public key IDs or inline public key names). Optional: comment (string). | `any` | `{}` | no |
| <a name="input_key_value_stores"></a> [key\_value\_stores](#input\_key\_value\_stores) | Map of CloudFront Key-Value Stores to create. Map key is used as the store name. Supports: comment (string). | `any` | `{}` | no |
| <a name="input_logging_config"></a> [logging\_config](#input\_logging\_config) | The logging configuration that controls how logs are written to your distribution (maximum one). | `any` | `{}` | no |
| <a name="input_ordered_cache_behavior"></a> [ordered\_cache\_behavior](#input\_ordered\_cache\_behavior) | An ordered list of cache behaviors resource for this distribution. List from top to bottom in order of precedence. The topmost cache behavior will have precedence 0. | `any` | `[]` | no |
| <a name="input_origin"></a> [origin](#input\_origin) | One or more origins for this distribution (multiples allowed). | `any` | `null` | no |
| <a name="input_origin_access_control"></a> [origin\_access\_control](#input\_origin\_access\_control) | Map of CloudFront origin access control | <pre>map(object({<br/>    description      = string<br/>    origin_type      = string<br/>    signing_behavior = string<br/>    signing_protocol = string<br/>  }))</pre> | <pre>{<br/>  "s3": {<br/>    "description": "",<br/>    "origin_type": "s3",<br/>    "signing_behavior": "always",<br/>    "signing_protocol": "sigv4"<br/>  }<br/>}</pre> | no |
| <a name="input_origin_access_identities"></a> [origin\_access\_identities](#input\_origin\_access\_identities) | Map of CloudFront origin access identities (value as a comment) | `map(string)` | `{}` | no |
| <a name="input_origin_group"></a> [origin\_group](#input\_origin\_group) | One or more origin\_group for this distribution (multiples allowed). | `any` | `{}` | no |
| <a name="input_origin_request_policies"></a> [origin\_request\_policies](#input\_origin\_request\_policies) | Map of CloudFront origin request policies to create. Map key is used as the policy name. Supports: comment, cookie\_behavior, cookies\_items, header\_behavior, headers\_items, query\_string\_behavior, query\_strings\_items. | `any` | `{}` | no |
| <a name="input_price_class"></a> [price\_class](#input\_price\_class) | The price class for this distribution. One of PriceClass\_All, PriceClass\_200, PriceClass\_100 | `string` | `null` | no |
| <a name="input_public_keys"></a> [public\_keys](#input\_public\_keys) | Map of CloudFront Public Keys to create. Map key is used as the key name. Required: encoded\_key (string, PEM-encoded public key). Optional: comment (string). | `any` | `{}` | no |
| <a name="input_realtime_log_configs"></a> [realtime\_log\_configs](#input\_realtime\_log\_configs) | Map of CloudFront Real-time Log Configs to create. Map key is used as the config name. Required: sampling\_rate (number, 1-100), fields (list of strings), kinesis\_stream\_config (object with role\_arn and stream\_arn). Optional: stream\_type (string, default 'Kinesis'). | `any` | `{}` | no |
| <a name="input_realtime_metrics_subscription_status"></a> [realtime\_metrics\_subscription\_status](#input\_realtime\_metrics\_subscription\_status) | A flag that indicates whether additional CloudWatch metrics are enabled for a given CloudFront distribution. Valid values are `Enabled` and `Disabled`. | `string` | `"Enabled"` | no |
| <a name="input_response_headers_policies"></a> [response\_headers\_policies](#input\_response\_headers\_policies) | Map of CloudFront response headers policies to create. Map key is used as the policy name. Supports: comment, cors (object), custom\_headers (list), remove\_headers (set), content\_security\_policy\_header, content\_type\_options\_header, frame\_options\_header, referrer\_policy\_header, strict\_transport\_security\_header, xss\_protection\_header, server\_timing\_header. | `any` | `{}` | no |
| <a name="input_retain_on_delete"></a> [retain\_on\_delete](#input\_retain\_on\_delete) | Disables the distribution instead of deleting it when destroying the resource through Terraform. If this is set, the distribution needs to be deleted manually afterwards. | `bool` | `false` | no |
| <a name="input_staging"></a> [staging](#input\_staging) | Whether the distribution is a staging distribution. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_viewer_certificate"></a> [viewer\_certificate](#input\_viewer\_certificate) | The SSL configuration for this distribution | `any` | <pre>{<br/>  "cloudfront_default_certificate": true,<br/>  "minimum_protocol_version": "TLSv1"<br/>}</pre> | no |
| <a name="input_viewer_mtls_config"></a> [viewer\_mtls\_config](#input\_viewer\_mtls\_config) | Configuration for viewer mTLS authentication. Supports 'mode' (string) and 'trust\_store\_config' object with 'trust\_store\_id' (required), 'advertise\_trust\_store\_ca\_names' (bool), and 'ignore\_certificate\_expiry' (bool). | `any` | `null` | no |
| <a name="input_vpc_origin"></a> [vpc\_origin](#input\_vpc\_origin) | Map of CloudFront VPC origin | <pre>map(object({<br/>    name                   = string<br/>    arn                    = string<br/>    http_port              = number<br/>    https_port             = number<br/>    origin_protocol_policy = string<br/>    origin_ssl_protocols = object({<br/>      items    = list(string)<br/>      quantity = number<br/>    })<br/>  }))</pre> | `{}` | no |
| <a name="input_wait_for_deployment"></a> [wait\_for\_deployment](#input\_wait\_for\_deployment) | If enabled, the resource will wait for the distribution status to change from InProgress to Deployed. Setting this to false will skip the process. | `bool` | `true` | no |
| <a name="input_web_acl_id"></a> [web\_acl\_id](#input\_web\_acl\_id) | If you're using AWS WAF to filter CloudFront requests, the Id of the AWS WAF web ACL that is associated with the distribution. The WAF Web ACL must exist in the WAF Global (CloudFront) region and the credentials configuring this argument must have waf:GetWebACL permissions assigned. If using WAFv2, provide the ARN of the web ACL. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudfront_cache_policy_ids"></a> [cloudfront\_cache\_policy\_ids](#output\_cloudfront\_cache\_policy\_ids) | Map of cache policy name to ID for policies created by this module. |
| <a name="output_cloudfront_continuous_deployment_policy_arns"></a> [cloudfront\_continuous\_deployment\_policy\_arns](#output\_cloudfront\_continuous\_deployment\_policy\_arns) | Map of Continuous Deployment Policy key to ARN for policies created by this module. |
| <a name="output_cloudfront_continuous_deployment_policy_ids"></a> [cloudfront\_continuous\_deployment\_policy\_ids](#output\_cloudfront\_continuous\_deployment\_policy\_ids) | Map of Continuous Deployment Policy key to ID for policies created by this module. |
| <a name="output_cloudfront_distribution_arn"></a> [cloudfront\_distribution\_arn](#output\_cloudfront\_distribution\_arn) | The ARN (Amazon Resource Name) for the distribution. |
| <a name="output_cloudfront_distribution_caller_reference"></a> [cloudfront\_distribution\_caller\_reference](#output\_cloudfront\_distribution\_caller\_reference) | Internal value used by CloudFront to allow future updates to the distribution configuration. |
| <a name="output_cloudfront_distribution_domain_name"></a> [cloudfront\_distribution\_domain\_name](#output\_cloudfront\_distribution\_domain\_name) | The domain name corresponding to the distribution. |
| <a name="output_cloudfront_distribution_etag"></a> [cloudfront\_distribution\_etag](#output\_cloudfront\_distribution\_etag) | The current version of the distribution's information. |
| <a name="output_cloudfront_distribution_hosted_zone_id"></a> [cloudfront\_distribution\_hosted\_zone\_id](#output\_cloudfront\_distribution\_hosted\_zone\_id) | The CloudFront Route 53 zone ID that can be used to route an Alias Resource Record Set to. |
| <a name="output_cloudfront_distribution_id"></a> [cloudfront\_distribution\_id](#output\_cloudfront\_distribution\_id) | The identifier for the distribution. |
| <a name="output_cloudfront_distribution_in_progress_validation_batches"></a> [cloudfront\_distribution\_in\_progress\_validation\_batches](#output\_cloudfront\_distribution\_in\_progress\_validation\_batches) | The number of invalidation batches currently in progress. |
| <a name="output_cloudfront_distribution_last_modified_time"></a> [cloudfront\_distribution\_last\_modified\_time](#output\_cloudfront\_distribution\_last\_modified\_time) | The date and time the distribution was last modified. |
| <a name="output_cloudfront_distribution_status"></a> [cloudfront\_distribution\_status](#output\_cloudfront\_distribution\_status) | The current status of the distribution. Deployed if the distribution's information is fully propagated throughout the Amazon CloudFront system. |
| <a name="output_cloudfront_distribution_tags"></a> [cloudfront\_distribution\_tags](#output\_cloudfront\_distribution\_tags) | Tags of the distribution's |
| <a name="output_cloudfront_distribution_trusted_signers"></a> [cloudfront\_distribution\_trusted\_signers](#output\_cloudfront\_distribution\_trusted\_signers) | List of nested attributes for active trusted signers, if the distribution is set up to serve private content with signed URLs |
| <a name="output_cloudfront_function_arns"></a> [cloudfront\_function\_arns](#output\_cloudfront\_function\_arns) | Map of CloudFront Function name to ARN for functions created by this module. |
| <a name="output_cloudfront_function_statuses"></a> [cloudfront\_function\_statuses](#output\_cloudfront\_function\_statuses) | Map of CloudFront Function name to status for functions created by this module. |
| <a name="output_cloudfront_key_group_etags"></a> [cloudfront\_key\_group\_etags](#output\_cloudfront\_key\_group\_etags) | Map of Key Group name to ETag for key groups created by this module. |
| <a name="output_cloudfront_key_group_ids"></a> [cloudfront\_key\_group\_ids](#output\_cloudfront\_key\_group\_ids) | Map of Key Group name to ID for key groups created by this module. |
| <a name="output_cloudfront_key_value_store_arns"></a> [cloudfront\_key\_value\_store\_arns](#output\_cloudfront\_key\_value\_store\_arns) | Map of Key-Value Store name to ARN for stores created by this module. |
| <a name="output_cloudfront_key_value_store_ids"></a> [cloudfront\_key\_value\_store\_ids](#output\_cloudfront\_key\_value\_store\_ids) | Map of Key-Value Store name to ID for stores created by this module. |
| <a name="output_cloudfront_monitoring_subscription_id"></a> [cloudfront\_monitoring\_subscription\_id](#output\_cloudfront\_monitoring\_subscription\_id) | The ID of the CloudFront monitoring subscription, which corresponds to the `distribution_id`. |
| <a name="output_cloudfront_origin_access_controls"></a> [cloudfront\_origin\_access\_controls](#output\_cloudfront\_origin\_access\_controls) | The origin access controls created |
| <a name="output_cloudfront_origin_access_controls_ids"></a> [cloudfront\_origin\_access\_controls\_ids](#output\_cloudfront\_origin\_access\_controls\_ids) | The IDS of the origin access identities created |
| <a name="output_cloudfront_origin_access_identities"></a> [cloudfront\_origin\_access\_identities](#output\_cloudfront\_origin\_access\_identities) | The origin access identities created |
| <a name="output_cloudfront_origin_access_identity_iam_arns"></a> [cloudfront\_origin\_access\_identity\_iam\_arns](#output\_cloudfront\_origin\_access\_identity\_iam\_arns) | The IAM arns of the origin access identities created |
| <a name="output_cloudfront_origin_access_identity_ids"></a> [cloudfront\_origin\_access\_identity\_ids](#output\_cloudfront\_origin\_access\_identity\_ids) | The IDS of the origin access identities created |
| <a name="output_cloudfront_origin_request_policy_ids"></a> [cloudfront\_origin\_request\_policy\_ids](#output\_cloudfront\_origin\_request\_policy\_ids) | Map of origin request policy name to ID for policies created by this module. |
| <a name="output_cloudfront_public_key_etags"></a> [cloudfront\_public\_key\_etags](#output\_cloudfront\_public\_key\_etags) | Map of Public Key name to ETag for public keys created by this module. |
| <a name="output_cloudfront_public_key_ids"></a> [cloudfront\_public\_key\_ids](#output\_cloudfront\_public\_key\_ids) | Map of Public Key name to ID for public keys created by this module. |
| <a name="output_cloudfront_realtime_log_config_arns"></a> [cloudfront\_realtime\_log\_config\_arns](#output\_cloudfront\_realtime\_log\_config\_arns) | Map of Real-time Log Config name to ARN for configs created by this module. |
| <a name="output_cloudfront_response_headers_policy_ids"></a> [cloudfront\_response\_headers\_policy\_ids](#output\_cloudfront\_response\_headers\_policy\_ids) | Map of response headers policy name to ID for policies created by this module. |
| <a name="output_cloudfront_vpc_origin_ids"></a> [cloudfront\_vpc\_origin\_ids](#output\_cloudfront\_vpc\_origin\_ids) | The IDS of the VPC origin created |
<!-- END_TF_DOCS -->
