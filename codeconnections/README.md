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
| <a name="input_connection_timeouts"></a> [connection\_timeouts](#input\_connection\_timeouts) | Timeout configuration for the codeconnections connection resource. | <pre>object({<br/>    create = optional(string, "30m")<br/>    delete = optional(string, "30m")<br/>  })</pre> | `{}` | no |
| <a name="input_create_host"></a> [create\_host](#input\_create\_host) | Whether to create a codeconnections host (for self-hosted VCS like GitHub Enterprise Server). | `bool` | `false` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_github_organization_name"></a> [github\_organization\_name](#input\_github\_organization\_name) | The GitHub organization name | `string` | `null` | no |
| <a name="input_host_arn"></a> [host\_arn](#input\_host\_arn) | ARN of the codeconnections host to use for GitHubEnterpriseServer/GitLabSelfManaged connections. When set, provider\_type is derived from the host. | `string` | `null` | no |
| <a name="input_host_name"></a> [host\_name](#input\_host\_name) | Name of the codeconnections host. | `string` | `null` | no |
| <a name="input_host_provider_endpoint"></a> [host\_provider\_endpoint](#input\_host\_provider\_endpoint) | Endpoint of the infrastructure where the provider type is installed (e.g., https://my-github-enterprise.example.com). | `string` | `null` | no |
| <a name="input_host_provider_type"></a> [host\_provider\_type](#input\_host\_provider\_type) | Provider type for the host. Valid values: GitHubEnterpriseServer, GitLabSelfManaged. | `string` | `null` | no |
| <a name="input_host_timeouts"></a> [host\_timeouts](#input\_host\_timeouts) | Timeout configuration for the codeconnections host resource. | <pre>object({<br/>    create = optional(string, "30m")<br/>    delete = optional(string, "30m")<br/>  })</pre> | `{}` | no |
| <a name="input_host_vpc_configuration"></a> [host\_vpc\_configuration](#input\_host\_vpc\_configuration) | VPC configuration for the codeconnections host (required for VPC-hosted providers). | <pre>object({<br/>    security_group_ids = list(string)<br/>    subnet_ids         = list(string)<br/>    vpc_id             = string<br/>    tls_certificate    = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name for the codeconnections connection. Defaults to '<github\_organization\_name>-github' when not set. | `string` | `null` | no |
| <a name="input_provider_type"></a> [provider\_type](#input\_provider\_type) | The provider type | `string` | `"GitHub"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_connection_arn"></a> [connection\_arn](#output\_connection\_arn) | ARN of the codeconnections connection |
| <a name="output_connection_id"></a> [connection\_id](#output\_connection\_id) | ARN of the codeconnections connection (id is deprecated; arn is the canonical identifier) |
| <a name="output_connection_status"></a> [connection\_status](#output\_connection\_status) | Status of the codeconnections connection |
| <a name="output_host_arn"></a> [host\_arn](#output\_host\_arn) | ARN of the codeconnections host |
| <a name="output_host_id"></a> [host\_id](#output\_host\_id) | ARN of the codeconnections host (id is deprecated; arn is the canonical identifier) |
<!-- END_TF_DOCS -->
