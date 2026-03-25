<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.11.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.37.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.37.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_broker_name"></a> [broker\_name](#input\_broker\_name) | The name of the broker | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | The list of subnet IDs in which to launch the broker | `list(string)` | n/a | yes |
| <a name="input_users"></a> [users](#input\_users) | List of broker users | <pre>list(object({<br/>    username         = string<br/>    password         = string<br/>    console_access   = optional(bool, false)<br/>    groups           = optional(list(string))<br/>    replication_user = optional(bool, false)<br/>  }))</pre> | n/a | yes |
| <a name="input_apply_immediately"></a> [apply\_immediately](#input\_apply\_immediately) | Specifies whether any broker modifications are applied immediately, or during the next maintenance window | `bool` | `false` | no |
| <a name="input_authentication_strategy"></a> [authentication\_strategy](#input\_authentication\_strategy) | Authentication strategy for broker. Valid values: `simple`, `ldap`. `ldap` is not supported for engine\_type RabbitMQ | `string` | `null` | no |
| <a name="input_auto_minor_version_upgrade"></a> [auto\_minor\_version\_upgrade](#input\_auto\_minor\_version\_upgrade) | Enables automatic upgrades to new minor versions for brokers | `bool` | `false` | no |
| <a name="input_configuration"></a> [configuration](#input\_configuration) | The broker configuration. Applies to engine\_type of ActiveMQ and RabbitMQ only | <pre>object({<br/>    id       = string<br/>    revision = number<br/>  })</pre> | `null` | no |
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | Whether to create a security group for the MQ broker | `bool` | `false` | no |
| <a name="input_data_replication_mode"></a> [data\_replication\_mode](#input\_data\_replication\_mode) | Defines whether this broker is a part of a data replication pair. Valid values: `NONE`, `CRDR` | `string` | `null` | no |
| <a name="input_data_replication_primary_broker_arn"></a> [data\_replication\_primary\_broker\_arn](#input\_data\_replication\_primary\_broker\_arn) | The Amazon Resource Name (ARN) of the primary broker that is used to replicate data from in a data replication pair. Must be set when `data_replication_mode` is `CRDR` | `string` | `null` | no |
| <a name="input_deployment_mode"></a> [deployment\_mode](#input\_deployment\_mode) | The deployment mode of the broker. Valid values: `SINGLE_INSTANCE`, `ACTIVE_STANDBY_MULTI_AZ`, `CLUSTER_MULTI_AZ` | `string` | `"SINGLE_INSTANCE"` | no |
| <a name="input_egress_rules"></a> [egress\_rules](#input\_egress\_rules) | List of egress rules to add to the security group | <pre>list(object({<br/>    description      = optional(string)<br/>    from_port        = number<br/>    to_port          = number<br/>    protocol         = string<br/>    cidr_blocks      = optional(list(string))<br/>    ipv6_cidr_blocks = optional(list(string))<br/>    prefix_list_ids  = optional(list(string))<br/>    security_groups  = optional(list(string))<br/>    self             = optional(bool)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "cidr_blocks": [<br/>      "0.0.0.0/0"<br/>    ],<br/>    "description": "All outbound traffic",<br/>    "from_port": 0,<br/>    "protocol": "-1",<br/>    "to_port": 0<br/>  }<br/>]</pre> | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_encryption_options"></a> [encryption\_options](#input\_encryption\_options) | Encryption options for the broker | <pre>object({<br/>    kms_key_id        = optional(string)<br/>    use_aws_owned_key = optional(bool, true)<br/>  })</pre> | `null` | no |
| <a name="input_engine_type"></a> [engine\_type](#input\_engine\_type) | The type of broker engine. Valid values: `ActiveMQ`, `RabbitMQ` | `string` | `null` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | The version of the broker engine | `string` | `null` | no |
| <a name="input_host_instance_type"></a> [host\_instance\_type](#input\_host\_instance\_type) | The broker's instance type | `string` | `"mq.t3.micro"` | no |
| <a name="input_ingress_rules"></a> [ingress\_rules](#input\_ingress\_rules) | List of ingress rules to add to the security group | <pre>list(object({<br/>    description      = optional(string)<br/>    from_port        = number<br/>    to_port          = number<br/>    protocol         = string<br/>    cidr_blocks      = optional(list(string))<br/>    ipv6_cidr_blocks = optional(list(string))<br/>    prefix_list_ids  = optional(list(string))<br/>    security_groups  = optional(list(string))<br/>    self             = optional(bool)<br/>  }))</pre> | `null` | no |
| <a name="input_ldap_server_metadata"></a> [ldap\_server\_metadata](#input\_ldap\_server\_metadata) | LDAP server metadata for authentication (RabbitMQ only) | <pre>object({<br/>    hosts                    = optional(list(string))<br/>    role_base                = optional(string)<br/>    role_name                = optional(string)<br/>    role_search_matching     = optional(string)<br/>    role_search_subtree      = optional(bool)<br/>    service_account_password = optional(string)<br/>    service_account_username = optional(string)<br/>    user_base                = optional(string)<br/>    user_role_name           = optional(string)<br/>    user_search_matching     = optional(string)<br/>    user_search_subtree      = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_logs"></a> [logs](#input\_logs) | Logging configuration | <pre>object({<br/>    audit   = optional(bool, false)<br/>    general = optional(bool, false)<br/>  })</pre> | `null` | no |
| <a name="input_maintenance_window_start_time"></a> [maintenance\_window\_start\_time](#input\_maintenance\_window\_start\_time) | Maintenance window start time configuration | <pre>object({<br/>    day_of_week = string<br/>    time_of_day = string<br/>    time_zone   = string<br/>  })</pre> | `null` | no |
| <a name="input_publicly_accessible"></a> [publicly\_accessible](#input\_publicly\_accessible) | Whether to enable connections from applications outside of the VPC that hosts the broker's subnets | `bool` | `false` | no |
| <a name="input_security_group_description"></a> [security\_group\_description](#input\_security\_group\_description) | Description for the created security group | `string` | `"Security group for AWS MQ broker"` | no |
| <a name="input_security_group_name"></a> [security\_group\_name](#input\_security\_group\_name) | Name for the created security group (auto-generated if not provided) | `string` | `null` | no |
| <a name="input_security_group_name_prefix"></a> [security\_group\_name\_prefix](#input\_security\_group\_name\_prefix) | Name prefix for the created security group (auto-generated if not provided) | `string` | `null` | no |
| <a name="input_security_group_tags"></a> [security\_group\_tags](#input\_security\_group\_tags) | Additional tags for the security group | `map(string)` | `{}` | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | List of existing security group IDs to use (ignored if create\_security\_group is true) | `list(string)` | `[]` | no |
| <a name="input_storage_type"></a> [storage\_type](#input\_storage\_type) | The storage type of the broker. Valid values: `efs`, `ebs` | `string` | `"ebs"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the broker | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC where to create security group | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the broker |
| <a name="output_configuration_id"></a> [configuration\_id](#output\_configuration\_id) | The ID of the broker configuration |
| <a name="output_configuration_revision"></a> [configuration\_revision](#output\_configuration\_revision) | The revision of the broker configuration |
| <a name="output_id"></a> [id](#output\_id) | The ID of the broker |
| <a name="output_instances"></a> [instances](#output\_instances) | List of information about allocated brokers (if deployment\_mode is CLUSTER\_MULTI\_AZ) |
| <a name="output_primary_console_url"></a> [primary\_console\_url](#output\_primary\_console\_url) | The URL of the broker's ActiveMQ Web Console |
| <a name="output_primary_endpoints"></a> [primary\_endpoints](#output\_primary\_endpoints) | The broker's wire-level protocol endpoints |
| <a name="output_primary_ip_address"></a> [primary\_ip\_address](#output\_primary\_ip\_address) | The IP Address of the broker |
| <a name="output_security_group_arn"></a> [security\_group\_arn](#output\_security\_group\_arn) | ARN of the created security group (if created) |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the created security group (if created) |
| <a name="output_security_group_name"></a> [security\_group\_name](#output\_security\_group\_name) | Name of the created security group (if created) |
| <a name="output_security_groups"></a> [security\_groups](#output\_security\_groups) | The list of security groups assigned to the broker |
<!-- END_TF_DOCS -->