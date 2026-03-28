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
| <a name="input_create_ecs_service_discovery_role"></a> [create\_ecs\_service\_discovery\_role](#input\_create\_ecs\_service\_discovery\_role) | Whether to create IAM role for ECS service discovery | `bool` | `false` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Whether to create an HTTP namespace | `bool` | `false` | no |
| <a name="input_create_private_dns_namespace"></a> [create\_private\_dns\_namespace](#input\_create\_private\_dns\_namespace) | Whether to create a private DNS namespace | `bool` | `false` | no |
| <a name="input_create_public_dns_namespace"></a> [create\_public\_dns\_namespace](#input\_create\_public\_dns\_namespace) | Whether to create a public DNS namespace | `bool` | `false` | no |
| <a name="input_dns_record_type"></a> [dns\_record\_type](#input\_dns\_record\_type) | Type of DNS record | `string` | `"A"` | no |
| <a name="input_dns_ttl"></a> [dns\_ttl](#input\_dns\_ttl) | TTL for DNS records | `number` | `10` | no |
| <a name="input_enable_dns_config"></a> [enable\_dns\_config](#input\_enable\_dns\_config) | Enable DNS configuration for the service. Set to false for HTTP namespaces or when using existing HTTP namespaces. | `bool` | `true` | no |
| <a name="input_enable_health_checks"></a> [enable\_health\_checks](#input\_enable\_health\_checks) | Enable health checks for the service. Set to false when using private IPs or unsupported instance types. | `bool` | `true` | no |
| <a name="input_enable_lambda_registration"></a> [enable\_lambda\_registration](#input\_enable\_lambda\_registration) | Enable registration of Lambda Function URL in CloudMap service discovery | `bool` | `false` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Controls if resources should be created. | `bool` | `true` | no |
| <a name="input_existing_namespace_id"></a> [existing\_namespace\_id](#input\_existing\_namespace\_id) | ID of an existing namespace to use | `string` | `null` | no |
| <a name="input_lambda_attributes"></a> [lambda\_attributes](#input\_lambda\_attributes) | Additional attributes for the Lambda instance in CloudMap | `map(string)` | `{}` | no |
| <a name="input_lambda_instance_id"></a> [lambda\_instance\_id](#input\_lambda\_instance\_id) | Unique identifier for the Lambda instance in CloudMap | `string` | `"lambda-function"` | no |
| <a name="input_lambda_ip_address"></a> [lambda\_ip\_address](#input\_lambda\_ip\_address) | IP address to use for Lambda A record in CloudMap. If not provided, uses a placeholder IP. | `string` | `null` | no |
| <a name="input_lambda_service_name"></a> [lambda\_service\_name](#input\_lambda\_service\_name) | Name of the CloudMap service for Lambda registration. If not specified, uses the first service name from var.services | `string` | `null` | no |
| <a name="input_lambda_url"></a> [lambda\_url](#input\_lambda\_url) | Lambda Function URL or API Gateway endpoint to register in CloudMap | `string` | `null` | no |
| <a name="input_namespace_description"></a> [namespace\_description](#input\_namespace\_description) | Description of the CloudMap namespace | `string` | `null` | no |
| <a name="input_namespace_name"></a> [namespace\_name](#input\_namespace\_name) | Name of the CloudMap namespace | `string` | `null` | no |
| <a name="input_routing_policy"></a> [routing\_policy](#input\_routing\_policy) | Routing policy for the service | `string` | `"MULTIVALUE"` | no |
| <a name="input_services"></a> [services](#input\_services) | Map of CloudMap services to create | <pre>map(object({<br/>    name            = string<br/>    description     = optional(string)<br/>    type            = optional(string)<br/>    force_destroy   = optional(bool, true)<br/>    dns_ttl         = optional(number, 10)<br/>    dns_record_type = optional(string, "A")<br/>    routing_policy  = optional(string, "MULTIVALUE")<br/>    health_check_config = optional(object({<br/>      resource_path     = string<br/>      type              = string<br/>      failure_threshold = optional(number, 3)<br/>    }))<br/>    health_check_custom_config            = optional(bool, false)<br/>    custom_health_check_failure_threshold = optional(number, 1)<br/>    tags                                  = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the resources | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID for private DNS namespace | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ecs_service_discovery_role_arn"></a> [ecs\_service\_discovery\_role\_arn](#output\_ecs\_service\_discovery\_role\_arn) | ARN of the ECS service discovery IAM role |
| <a name="output_ecs_service_discovery_role_name"></a> [ecs\_service\_discovery\_role\_name](#output\_ecs\_service\_discovery\_role\_name) | Name of the ECS service discovery IAM role |
| <a name="output_lambda_discovery_url"></a> [lambda\_discovery\_url](#output\_lambda\_discovery\_url) | CloudMap discovery URL for the Lambda function |
| <a name="output_lambda_instance_id"></a> [lambda\_instance\_id](#output\_lambda\_instance\_id) | ID of the registered Lambda instance in CloudMap |
| <a name="output_lambda_service_id"></a> [lambda\_service\_id](#output\_lambda\_service\_id) | ID of the CloudMap service where Lambda is registered |
| <a name="output_namespace_arn"></a> [namespace\_arn](#output\_namespace\_arn) | ARN of the created namespace |
| <a name="output_namespace_id"></a> [namespace\_id](#output\_namespace\_id) | ID of the created namespace |
| <a name="output_namespace_name"></a> [namespace\_name](#output\_namespace\_name) | Name of the created namespace |
| <a name="output_service_arns"></a> [service\_arns](#output\_service\_arns) | Map of service names to their ARNs for ECS integration |
| <a name="output_services"></a> [services](#output\_services) | Map of created services with their details |
<!-- END_TF_DOCS -->