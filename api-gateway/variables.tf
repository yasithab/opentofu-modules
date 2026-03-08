variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name to use for resource naming and tagging."
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

# See https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-swagger-extensions.html for additional
# configuration information.
variable "openapi_config" {
  description = "The OpenAPI specification for the API"
  type        = any
  default     = {}
}

variable "endpoint_type" {
  type        = string
  description = "The type of the endpoint. One of - PUBLIC, PRIVATE, REGIONAL"
  default     = "REGIONAL"

  validation {
    condition     = contains(["EDGE", "REGIONAL", "PRIVATE"], var.endpoint_type)
    error_message = "Valid values for var: endpoint_type are (EDGE, REGIONAL, PRIVATE)."
  }
}

variable "logging_level" {
  type        = string
  description = "The logging level of the API. One of - OFF, INFO, ERROR"
  default     = "INFO"

  validation {
    condition     = contains(["OFF", "INFO", "ERROR"], var.logging_level)
    error_message = "Valid values for var: logging_level are (OFF, INFO, ERROR)."
  }
}

variable "metrics_enabled" {
  description = "A flag to indicate whether to enable metrics collection."
  type        = bool
  default     = false
}

variable "xray_tracing_enabled" {
  description = "A flag to indicate whether to enable X-Ray tracing."
  type        = bool
  default     = false
}

variable "data_trace_enabled" {
  description = "Whether data trace logging is enabled for this method, which effects the log entries pushed to Amazon CloudWatch Logs."
  type        = bool
  default     = false
}

# See https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-logging.html for additional information
# on how to configure logging.
variable "access_log_format" {
  description = "The format of the access log file."
  type        = string
  default     = <<EOF
  {
	"requestTime": "$context.requestTime",
	"requestId": "$context.requestId",
	"httpMethod": "$context.httpMethod",
	"path": "$context.path",
	"resourcePath": "$context.resourcePath",
	"status": $context.status,
	"responseLatency": $context.responseLatency,
  "xrayTraceId": "$context.xrayTraceId",
  "integrationRequestId": "$context.integration.requestId",
	"functionResponseStatus": "$context.integration.status",
  "integrationLatency": "$context.integration.latency",
	"integrationServiceStatus": "$context.integration.integrationStatus",
  "authorizeResultStatus": "$context.authorize.status",
	"authorizerServiceStatus": "$context.authorizer.status",
	"authorizerLatency": "$context.authorizer.latency",
	"authorizerRequestId": "$context.authorizer.requestId",
  "ip": "$context.identity.sourceIp",
	"userAgent": "$context.identity.userAgent",
	"principalId": "$context.authorizer.principalId",
	"cognitoUser": "$context.identity.cognitoIdentityId",
  "user": "$context.identity.user"
}
  EOF
}

# See https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-resource-policies.html for additional
# information on how to configure resource policies.
#
# Example:
# {
#    "Version": "2012-10-17",
#    "Statement": [
#        {
#            "Effect": "Allow",
#            "Principal": "*",
#            "Action": "execute-api:Invoke",
#            "Resource": "arn:aws:execute-api:us-east-1:000000000000:*"
#        },
#        {
#            "Effect": "Deny",
#            "Principal": "*",
#            "Action": "execute-api:Invoke",
#            "Resource": "arn:aws:execute-api:region:account-id:*",
#            "Condition": {
#                "NotIpAddress": {
#                    "aws:SourceIp": "123.4.5.6/24"
#                }
#            }
#        }
#    ]
#}
variable "rest_api_policy" {
  description = "The IAM policy document for the API. Used to create an aws_api_gateway_rest_api_policy resource."
  type        = string
  default     = null
}

variable "rest_api_inline_policy" {
  description = "JSON formatted policy document set inline on the aws_api_gateway_rest_api resource. Alternative to rest_api_policy when a separate policy resource is not desired."
  type        = string
  default     = null
}

variable "private_link_target_arns" {
  type        = list(string)
  description = "A list of target ARNs for VPC Private Link"
  default     = []
}

variable "stage_name" {
  type        = string
  default     = "default"
  description = "The name of the stage"
}

variable "stage_variables" {
  type        = map(string)
  default     = {}
  description = "A map of variables to set on the stage. The vpc_link_id variable is automatically injected when a VPC Link is created."
}

variable "log_group_retention_in_days" {
  type        = number
  default     = 30
  description = "The number of days to retain log events in the CloudWatch log group"

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_group_retention_in_days)
    error_message = "log_group_retention_in_days must be one of the allowed CloudWatch Logs retention values: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653."
  }
}

variable "cloudwatch_log_group_skip_destroy" {
  description = "Set to true to prevent the log group from being deleted on module destroy. Preserves audit logs."
  type        = bool
  default     = false
}

variable "cloudwatch_log_group_class" {
  description = "Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT_ACCESS."
  type        = string
  default     = null
}

variable "create_rest_api_gateway_resource" {
  type        = bool
  default     = true
  description = "flag to control the rest api gateway resources creation"
}

variable "api_resources" {
  type        = map(map(string))
  default     = {}
  description = "Map of API Gateway resource definitions to create. Each entry supports path_part (required) and parent_id (optional, defaults to the root resource id)."
}

variable "description" {
  type        = string
  default     = null
  description = "Description of the REST API."
}

variable "binary_media_types" {
  type        = list(string)
  default     = null
  description = "List of binary media types supported by the REST API. By default, the REST API supports only UTF-8-encoded text payloads."
}

variable "minimum_compression_size" {
  type        = string
  default     = null
  description = "Minimum response size to compress for the REST API. String containing an integer value between -1 and 10485760 (10MB). Setting to -1 disables compression, setting to 0 allows compression for responses of any size."
}

variable "put_rest_api_mode" {
  type        = string
  default     = null
  description = "Mode of the PutRestApi operation when importing an OpenAPI specification via the body argument. Valid values are merge and overwrite."

  validation {
    condition     = var.put_rest_api_mode == null || contains(["merge", "overwrite"], var.put_rest_api_mode)
    error_message = "Valid values for put_rest_api_mode are: merge, overwrite."
  }
}

variable "disable_execute_api_endpoint" {
  type        = bool
  default     = false
  description = "Specifies whether clients can invoke your API by using the default execute-api endpoint. Defaults to false."
}

variable "endpoint_ip_address_type" {
  type        = string
  default     = null
  description = "IP address types that can invoke the API. Valid values are ipv4 and dualstack."

  validation {
    condition     = var.endpoint_ip_address_type == null || contains(["ipv4", "dualstack"], var.endpoint_ip_address_type)
    error_message = "Valid values for endpoint_ip_address_type are: ipv4, dualstack."
  }
}

variable "vpc_endpoint_ids" {
  type        = list(string)
  default     = null
  description = "Set of VPC Endpoint identifiers. Only supported for PRIVATE endpoint type."
}

variable "api_key_source" {
  type        = string
  default     = null
  description = "Source of the API key for requests. Valid values are HEADER (default) and AUTHORIZER."

  validation {
    condition     = var.api_key_source == null || contains(["HEADER", "AUTHORIZER"], var.api_key_source)
    error_message = "Valid values for api_key_source are: HEADER, AUTHORIZER."
  }
}

variable "fail_on_warnings" {
  type        = bool
  default     = null
  description = "Whether warnings while API Gateway is creating or updating the resource should return an error or not."
}

variable "parameters" {
  type        = map(string)
  default     = null
  description = "Map of customizations for importing the specification in the body argument."
}

variable "deployment_description" {
  type        = string
  default     = null
  description = "Description of the deployment."
}

variable "deployment_variables" {
  type        = map(string)
  default     = null
  description = "Map of key/value pairs that define the stage variables passed in the deployment. These are merged with stage variables at apply time."
}

variable "stage_description" {
  type        = string
  default     = null
  description = "Description of the stage."
}

variable "documentation_version" {
  type        = string
  default     = null
  description = "Version of the associated API documentation."
}

variable "client_certificate_id" {
  type        = string
  default     = null
  description = "Identifier of a client certificate for the stage."
}

variable "cache_cluster_enabled" {
  type        = bool
  default     = null
  description = "Whether a cache cluster is enabled for the stage."
}

variable "cache_cluster_size" {
  type        = string
  default     = null
  description = "Size of the cache cluster for the stage, if enabled. Allowed values include 0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118 and 237."
}

variable "canary_settings" {
  type        = any
  default     = null
  description = "Configuration settings of a canary deployment. Supports deployment_id, percent_traffic, stage_variable_overrides, and use_stage_cache."
}

variable "throttling_burst_limit" {
  type        = number
  default     = -1
  description = "Throttling burst limit. Default: -1 (throttling disabled)."
}

variable "throttling_rate_limit" {
  type        = number
  default     = -1
  description = "Throttling rate limit. Default: -1 (throttling disabled)."
}

variable "caching_enabled" {
  type        = bool
  default     = null
  description = "Whether responses should be cached and returned for requests."
}

variable "cache_ttl_in_seconds" {
  type        = number
  default     = null
  description = "Time to live (TTL), in seconds, for cached responses."
}

variable "cache_data_encrypted" {
  type        = bool
  default     = null
  description = "Whether the cached responses are encrypted."
}

variable "require_authorization_for_cache_control" {
  type        = bool
  default     = null
  description = "Whether authorization is required for a cache invalidation request."
}

variable "unauthorized_cache_control_header_strategy" {
  type        = string
  default     = null
  description = "How to handle unauthorized requests for cache invalidation. Valid values: FAIL_WITH_403, SUCCEED_WITH_RESPONSE_HEADER, SUCCEED_WITHOUT_RESPONSE_HEADER."

  validation {
    condition     = var.unauthorized_cache_control_header_strategy == null || contains(["FAIL_WITH_403", "SUCCEED_WITH_RESPONSE_HEADER", "SUCCEED_WITHOUT_RESPONSE_HEADER"], var.unauthorized_cache_control_header_strategy)
    error_message = "Valid values for unauthorized_cache_control_header_strategy are: FAIL_WITH_403, SUCCEED_WITH_RESPONSE_HEADER, SUCCEED_WITHOUT_RESPONSE_HEADER."
  }
}
