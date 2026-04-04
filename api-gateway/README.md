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
| <a name="input_access_log_format"></a> [access\_log\_format](#input\_access\_log\_format) | The format of the access log file. | `string` | `"  {\n\t\"requestTime\": \"$context.requestTime\",\n\t\"requestId\": \"$context.requestId\",\n\t\"httpMethod\": \"$context.httpMethod\",\n\t\"path\": \"$context.path\",\n\t\"resourcePath\": \"$context.resourcePath\",\n\t\"status\": $context.status,\n\t\"responseLatency\": $context.responseLatency,\n  \"xrayTraceId\": \"$context.xrayTraceId\",\n  \"integrationRequestId\": \"$context.integration.requestId\",\n\t\"functionResponseStatus\": \"$context.integration.status\",\n  \"integrationLatency\": \"$context.integration.latency\",\n\t\"integrationServiceStatus\": \"$context.integration.integrationStatus\",\n  \"authorizeResultStatus\": \"$context.authorize.status\",\n\t\"authorizerServiceStatus\": \"$context.authorizer.status\",\n\t\"authorizerLatency\": \"$context.authorizer.latency\",\n\t\"authorizerRequestId\": \"$context.authorizer.requestId\",\n  \"ip\": \"$context.identity.sourceIp\",\n\t\"userAgent\": \"$context.identity.userAgent\",\n\t\"principalId\": \"$context.authorizer.principalId\",\n\t\"cognitoUser\": \"$context.identity.cognitoIdentityId\",\n  \"user\": \"$context.identity.user\"\n}\n"` | no |
| <a name="input_api_key_source"></a> [api\_key\_source](#input\_api\_key\_source) | Source of the API key for requests. Valid values are HEADER (default) and AUTHORIZER. | `string` | `null` | no |
| <a name="input_api_resources"></a> [api\_resources](#input\_api\_resources) | Map of API Gateway resource definitions to create. Each entry supports path\_part (required) and parent\_id (optional, defaults to the root resource id). | `map(map(string))` | `{}` | no |
| <a name="input_binary_media_types"></a> [binary\_media\_types](#input\_binary\_media\_types) | List of binary media types supported by the REST API. By default, the REST API supports only UTF-8-encoded text payloads. | `list(string)` | `null` | no |
| <a name="input_cache_cluster_enabled"></a> [cache\_cluster\_enabled](#input\_cache\_cluster\_enabled) | Whether a cache cluster is enabled for the stage. | `bool` | `null` | no |
| <a name="input_cache_cluster_size"></a> [cache\_cluster\_size](#input\_cache\_cluster\_size) | Size of the cache cluster for the stage, if enabled. Allowed values include 0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118 and 237. | `string` | `null` | no |
| <a name="input_cache_data_encrypted"></a> [cache\_data\_encrypted](#input\_cache\_data\_encrypted) | Whether the cached responses are encrypted. | `bool` | `null` | no |
| <a name="input_cache_ttl_in_seconds"></a> [cache\_ttl\_in\_seconds](#input\_cache\_ttl\_in\_seconds) | Time to live (TTL), in seconds, for cached responses. | `number` | `null` | no |
| <a name="input_caching_enabled"></a> [caching\_enabled](#input\_caching\_enabled) | Whether responses should be cached and returned for requests. | `bool` | `null` | no |
| <a name="input_canary_settings"></a> [canary\_settings](#input\_canary\_settings) | Configuration settings of a canary deployment. Supports deployment\_id, percent\_traffic, stage\_variable\_overrides, and use\_stage\_cache. | `any` | `null` | no |
| <a name="input_client_certificate_id"></a> [client\_certificate\_id](#input\_client\_certificate\_id) | Identifier of a client certificate for the stage. | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_class"></a> [cloudwatch\_log\_group\_class](#input\_cloudwatch\_log\_group\_class) | Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT\_ACCESS. | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_skip_destroy"></a> [cloudwatch\_log\_group\_skip\_destroy](#input\_cloudwatch\_log\_group\_skip\_destroy) | Set to true to prevent the log group from being deleted on module destroy. Preserves audit logs. | `bool` | `false` | no |
| <a name="input_create_rest_api_gateway_resource"></a> [create\_rest\_api\_gateway\_resource](#input\_create\_rest\_api\_gateway\_resource) | flag to control the rest api gateway resources creation | `bool` | `true` | no |
| <a name="input_data_trace_enabled"></a> [data\_trace\_enabled](#input\_data\_trace\_enabled) | Whether data trace logging is enabled for this method, which effects the log entries pushed to Amazon CloudWatch Logs. | `bool` | `false` | no |
| <a name="input_deployment_description"></a> [deployment\_description](#input\_deployment\_description) | Description of the deployment. | `string` | `null` | no |
| <a name="input_deployment_variables"></a> [deployment\_variables](#input\_deployment\_variables) | Map of key/value pairs that define the stage variables passed in the deployment. These are merged with stage variables at apply time. | `map(string)` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of the REST API. | `string` | `null` | no |
| <a name="input_disable_execute_api_endpoint"></a> [disable\_execute\_api\_endpoint](#input\_disable\_execute\_api\_endpoint) | Specifies whether clients can invoke your API by using the default execute-api endpoint. Defaults to false. | `bool` | `false` | no |
| <a name="input_documentation_version"></a> [documentation\_version](#input\_documentation\_version) | Version of the associated API documentation. | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_endpoint_ip_address_type"></a> [endpoint\_ip\_address\_type](#input\_endpoint\_ip\_address\_type) | IP address types that can invoke the API. Valid values are ipv4 and dualstack. | `string` | `null` | no |
| <a name="input_endpoint_type"></a> [endpoint\_type](#input\_endpoint\_type) | The type of the endpoint. One of - PUBLIC, PRIVATE, REGIONAL | `string` | `"REGIONAL"` | no |
| <a name="input_fail_on_warnings"></a> [fail\_on\_warnings](#input\_fail\_on\_warnings) | Whether warnings while API Gateway is creating or updating the resource should return an error or not. | `bool` | `null` | no |
| <a name="input_log_group_retention_in_days"></a> [log\_group\_retention\_in\_days](#input\_log\_group\_retention\_in\_days) | The number of days to retain log events in the CloudWatch log group | `number` | `30` | no |
| <a name="input_logging_level"></a> [logging\_level](#input\_logging\_level) | The logging level of the API. One of - OFF, INFO, ERROR | `string` | `"INFO"` | no |
| <a name="input_metrics_enabled"></a> [metrics\_enabled](#input\_metrics\_enabled) | A flag to indicate whether to enable metrics collection. | `bool` | `false` | no |
| <a name="input_minimum_compression_size"></a> [minimum\_compression\_size](#input\_minimum\_compression\_size) | Minimum response size to compress for the REST API. String containing an integer value between -1 and 10485760 (10MB). Setting to -1 disables compression, setting to 0 allows compression for responses of any size. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to use for resource naming and tagging. | `string` | `null` | no |
| <a name="input_openapi_config"></a> [openapi\_config](#input\_openapi\_config) | The OpenAPI specification for the API | `any` | `{}` | no |
| <a name="input_parameters"></a> [parameters](#input\_parameters) | Map of customizations for importing the specification in the body argument. | `map(string)` | `null` | no |
| <a name="input_private_link_target_arns"></a> [private\_link\_target\_arns](#input\_private\_link\_target\_arns) | A list of target ARNs for VPC Private Link | `list(string)` | `[]` | no |
| <a name="input_put_rest_api_mode"></a> [put\_rest\_api\_mode](#input\_put\_rest\_api\_mode) | Mode of the PutRestApi operation when importing an OpenAPI specification via the body argument. Valid values are merge and overwrite. | `string` | `null` | no |
| <a name="input_require_authorization_for_cache_control"></a> [require\_authorization\_for\_cache\_control](#input\_require\_authorization\_for\_cache\_control) | Whether authorization is required for a cache invalidation request. | `bool` | `null` | no |
| <a name="input_rest_api_inline_policy"></a> [rest\_api\_inline\_policy](#input\_rest\_api\_inline\_policy) | JSON formatted policy document set inline on the aws\_api\_gateway\_rest\_api resource. Alternative to rest\_api\_policy when a separate policy resource is not desired. | `string` | `null` | no |
| <a name="input_rest_api_policy"></a> [rest\_api\_policy](#input\_rest\_api\_policy) | The IAM policy document for the API. Used to create an aws\_api\_gateway\_rest\_api\_policy resource. | `string` | `null` | no |
| <a name="input_stage_description"></a> [stage\_description](#input\_stage\_description) | Description of the stage. | `string` | `null` | no |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | The name of the stage | `string` | `"default"` | no |
| <a name="input_stage_variables"></a> [stage\_variables](#input\_stage\_variables) | A map of variables to set on the stage. The vpc\_link\_id variable is automatically injected when a VPC Link is created. | `map(string)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_throttling_burst_limit"></a> [throttling\_burst\_limit](#input\_throttling\_burst\_limit) | Throttling burst limit. Default: -1 (throttling disabled). | `number` | `-1` | no |
| <a name="input_throttling_rate_limit"></a> [throttling\_rate\_limit](#input\_throttling\_rate\_limit) | Throttling rate limit. Default: -1 (throttling disabled). | `number` | `-1` | no |
| <a name="input_unauthorized_cache_control_header_strategy"></a> [unauthorized\_cache\_control\_header\_strategy](#input\_unauthorized\_cache\_control\_header\_strategy) | How to handle unauthorized requests for cache invalidation. Valid values: FAIL\_WITH\_403, SUCCEED\_WITH\_RESPONSE\_HEADER, SUCCEED\_WITHOUT\_RESPONSE\_HEADER. | `string` | `null` | no |
| <a name="input_vpc_endpoint_ids"></a> [vpc\_endpoint\_ids](#input\_vpc\_endpoint\_ids) | Set of VPC Endpoint identifiers. Only supported for PRIVATE endpoint type. | `list(string)` | `null` | no |
| <a name="input_xray_tracing_enabled"></a> [xray\_tracing\_enabled](#input\_xray\_tracing\_enabled) | A flag to indicate whether to enable X-Ray tracing. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the REST API |
| <a name="output_created_date"></a> [created\_date](#output\_created\_date) | The date the REST API was created |
| <a name="output_execution_arn"></a> [execution\_arn](#output\_execution\_arn) | The execution ARN part to be used in lambda\_permission's source\_arn when allowing API Gateway to invoke a Lambda <br/>    function, e.g., arn:aws:execute-api:eu-west-2:123456789012:z4675bid1j, which can be concatenated with allowed stage, <br/>    method and resource path.The ARN of the Lambda function that will be executed. |
| <a name="output_id"></a> [id](#output\_id) | The ID of the REST API |
| <a name="output_invoke_url"></a> [invoke\_url](#output\_invoke\_url) | The URL to invoke the REST API |
| <a name="output_root_resource_id"></a> [root\_resource\_id](#output\_root\_resource\_id) | The resource ID of the REST API's root |
| <a name="output_stage_arn"></a> [stage\_arn](#output\_stage\_arn) | The ARN of the gateway stage |
<!-- END_TF_DOCS -->