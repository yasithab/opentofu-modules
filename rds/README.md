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
| <a name="input_allocated_storage"></a> [allocated\_storage](#input\_allocated\_storage) | The allocated storage in gibibytes (GiB) | `number` | `null` | no |
| <a name="input_allow_major_version_upgrade"></a> [allow\_major\_version\_upgrade](#input\_allow\_major\_version\_upgrade) | Enable to allow major engine version upgrades when changing engine versions. Defaults to `false` | `bool` | `false` | no |
| <a name="input_apply_immediately"></a> [apply\_immediately](#input\_apply\_immediately) | Specifies whether any database modifications are applied immediately, or during the next maintenance window. Default is `false` | `bool` | `null` | no |
| <a name="input_auto_minor_version_upgrade"></a> [auto\_minor\_version\_upgrade](#input\_auto\_minor\_version\_upgrade) | Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window. Default `true` | `bool` | `null` | no |
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | The AZ for the RDS instance. If not set and multi\_az is false, a random AZ in the region will be selected | `string` | `null` | no |
| <a name="input_backup_retention_period"></a> [backup\_retention\_period](#input\_backup\_retention\_period) | The days to retain backups for. Must be between 0 and 35 | `number` | `7` | no |
| <a name="input_backup_window"></a> [backup\_window](#input\_backup\_window) | The daily time range during which automated backups are created if automated backups are enabled using the backup\_retention\_period parameter. Time in UTC | `string` | `"02:00-03:00"` | no |
| <a name="input_blue_green_update"></a> [blue\_green\_update](#input\_blue\_green\_update) | Enables low-downtime updates using RDS Blue/Green Deployments. See blue\_green\_update configuration below | `map(string)` | `{}` | no |
| <a name="input_ca_cert_identifier"></a> [ca\_cert\_identifier](#input\_ca\_cert\_identifier) | The identifier of the CA certificate for the DB instance | `string` | `null` | no |
| <a name="input_character_set_name"></a> [character\_set\_name](#input\_character\_set\_name) | The character set name to use for DB encoding in Oracle and Microsoft SQL instances (collation). This can't be changed. See Oracle Character Sets Supported in Amazon RDS or Server-Level Collation for Microsoft SQL Server for more information | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_class"></a> [cloudwatch\_log\_group\_class](#input\_cloudwatch\_log\_group\_class) | Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT\_ACCESS | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_kms_key_id"></a> [cloudwatch\_log\_group\_kms\_key\_id](#input\_cloudwatch\_log\_group\_kms\_key\_id) | The ARN of the KMS Key to use when encrypting log data | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_retention_in_days"></a> [cloudwatch\_log\_group\_retention\_in\_days](#input\_cloudwatch\_log\_group\_retention\_in\_days) | The number of days to retain CloudWatch logs for the DB instance | `number` | `7` | no |
| <a name="input_cloudwatch_log_group_skip_destroy"></a> [cloudwatch\_log\_group\_skip\_destroy](#input\_cloudwatch\_log\_group\_skip\_destroy) | Set to true if you do not wish the log group (and any logs it may contain) to be deleted at destroy time, and instead just remove the log group from the Terraform state | `bool` | `null` | no |
| <a name="input_cloudwatch_log_group_tags"></a> [cloudwatch\_log\_group\_tags](#input\_cloudwatch\_log\_group\_tags) | Additional tags for the CloudWatch log group(s) | `map(string)` | `{}` | no |
| <a name="input_copy_tags_to_snapshot"></a> [copy\_tags\_to\_snapshot](#input\_copy\_tags\_to\_snapshot) | Copy all instance tags to snapshots | `bool` | `null` | no |
| <a name="input_create_cloudwatch_log_group"></a> [create\_cloudwatch\_log\_group](#input\_create\_cloudwatch\_log\_group) | Determines whether a CloudWatch log group is created for each enabled\_cloudwatch\_logs\_exports | `bool` | `false` | no |
| <a name="input_create_db_option_group"></a> [create\_db\_option\_group](#input\_create\_db\_option\_group) | Determines whether to create a DB option group | `bool` | `false` | no |
| <a name="input_create_db_parameter_group"></a> [create\_db\_parameter\_group](#input\_create\_db\_parameter\_group) | Determines whether a DB parameter group should be created or use existing | `bool` | `false` | no |
| <a name="input_create_db_subnet_group"></a> [create\_db\_subnet\_group](#input\_create\_db\_subnet\_group) | Determines whether to create the database subnet group or use existing | `bool` | `false` | no |
| <a name="input_create_monitoring_role"></a> [create\_monitoring\_role](#input\_create\_monitoring\_role) | Determines whether to create the IAM role for RDS enhanced monitoring | `bool` | `true` | no |
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | Determines whether to create security group for RDS instance | `bool` | `true` | no |
| <a name="input_custom_iam_instance_profile"></a> [custom\_iam\_instance\_profile](#input\_custom\_iam\_instance\_profile) | The instance profile associated with the underlying Amazon EC2 instance of an RDS Custom DB instance | `string` | `null` | no |
| <a name="input_database_insights_mode"></a> [database\_insights\_mode](#input\_database\_insights\_mode) | The mode of Database Insights to enable for the DB instance. Valid values: standard, advanced | `string` | `null` | no |
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | The name of the database to create when the DB instance is created | `string` | `null` | no |
| <a name="input_db_option_group_description"></a> [db\_option\_group\_description](#input\_db\_option\_group\_description) | The description of the option group | `string` | `null` | no |
| <a name="input_db_option_group_engine_name"></a> [db\_option\_group\_engine\_name](#input\_db\_option\_group\_engine\_name) | Specifies the name of the engine that this option group should be associated with | `string` | `null` | no |
| <a name="input_db_option_group_major_engine_version"></a> [db\_option\_group\_major\_engine\_version](#input\_db\_option\_group\_major\_engine\_version) | Specifies the major version of the engine that this option group should be associated with | `string` | `null` | no |
| <a name="input_db_option_group_name"></a> [db\_option\_group\_name](#input\_db\_option\_group\_name) | The name of the option group. If omitted, defaults to var.name | `string` | `null` | no |
| <a name="input_db_option_group_options"></a> [db\_option\_group\_options](#input\_db\_option\_group\_options) | A list of options to apply to the option group | `any` | `[]` | no |
| <a name="input_db_option_group_use_name_prefix"></a> [db\_option\_group\_use\_name\_prefix](#input\_db\_option\_group\_use\_name\_prefix) | Determines whether the option group name is used as a prefix | `bool` | `true` | no |
| <a name="input_db_parameter_group_description"></a> [db\_parameter\_group\_description](#input\_db\_parameter\_group\_description) | The description of the DB parameter group | `string` | `null` | no |
| <a name="input_db_parameter_group_family"></a> [db\_parameter\_group\_family](#input\_db\_parameter\_group\_family) | The family of the DB parameter group | `string` | `null` | no |
| <a name="input_db_parameter_group_name"></a> [db\_parameter\_group\_name](#input\_db\_parameter\_group\_name) | Name of the DB parameter group to associate (existing, if not creating one) | `string` | `null` | no |
| <a name="input_db_parameter_group_parameters"></a> [db\_parameter\_group\_parameters](#input\_db\_parameter\_group\_parameters) | A list of DB parameters to apply. Note that parameters may differ from a family to an other | `list(map(string))` | `[]` | no |
| <a name="input_db_parameter_group_use_name_prefix"></a> [db\_parameter\_group\_use\_name\_prefix](#input\_db\_parameter\_group\_use\_name\_prefix) | Determines whether the DB parameter group name is used as a prefix | `bool` | `true` | no |
| <a name="input_db_subnet_group_name"></a> [db\_subnet\_group\_name](#input\_db\_subnet\_group\_name) | The name of the subnet group name (existing or created) | `string` | `null` | no |
| <a name="input_dedicated_log_volume"></a> [dedicated\_log\_volume](#input\_dedicated\_log\_volume) | Use a dedicated log volume (DLV) for the DB instance. Requires Provisioned IOPS storage types | `bool` | `null` | no |
| <a name="input_delete_automated_backups"></a> [delete\_automated\_backups](#input\_delete\_automated\_backups) | Specifies whether to remove automated backups immediately after the DB instance is deleted | `bool` | `null` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | If the DB instance should have deletion protection enabled. The database can't be deleted when this value is set to `true`. The default is `true` | `bool` | `true` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | The ID of the Directory Service Active Directory domain to create the instance in | `string` | `null` | no |
| <a name="input_domain_iam_role_name"></a> [domain\_iam\_role\_name](#input\_domain\_iam\_role\_name) | (Required if domain is provided) The name of the IAM role to be used when making API calls to the Directory Service | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_enabled_cloudwatch_logs_exports"></a> [enabled\_cloudwatch\_logs\_exports](#input\_enabled\_cloudwatch\_logs\_exports) | Set of log types to export to cloudwatch. Valid values depend on engine: MySQL/MariaDB: audit, error, general, slowquery. PostgreSQL: postgresql, upgrade. Oracle: alert, audit, listener, trace, oemagent. MSSQL: agent, error | `list(string)` | `[]` | no |
| <a name="input_engine"></a> [engine](#input\_engine) | The database engine to use. Valid values: mysql, postgres, mariadb, oracle-ee, oracle-se2, sqlserver-ee, sqlserver-se, sqlserver-ex, sqlserver-web | `string` | `null` | no |
| <a name="input_engine_lifecycle_support"></a> [engine\_lifecycle\_support](#input\_engine\_lifecycle\_support) | The life cycle type for this DB instance. Valid values: open-source-rds-extended-support, open-source-rds-extended-support-disabled | `string` | `null` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | The engine version to use. If auto\_minor\_version\_upgrade is enabled, you can provide a prefix of the version such as 8.0 (for 8.0.36) | `string` | `null` | no |
| <a name="input_final_snapshot_identifier"></a> [final\_snapshot\_identifier](#input\_final\_snapshot\_identifier) | The name of your final DB snapshot when this DB instance is deleted. Must be provided if skip\_final\_snapshot is set to false | `string` | `null` | no |
| <a name="input_iam_database_authentication_enabled"></a> [iam\_database\_authentication\_enabled](#input\_iam\_database\_authentication\_enabled) | Specifies whether mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled | `bool` | `null` | no |
| <a name="input_iam_role_description"></a> [iam\_role\_description](#input\_iam\_role\_description) | Description of the monitoring role | `string` | `null` | no |
| <a name="input_iam_role_force_detach_policies"></a> [iam\_role\_force\_detach\_policies](#input\_iam\_role\_force\_detach\_policies) | Whether to force detaching any policies the monitoring role has before destroying it | `bool` | `null` | no |
| <a name="input_iam_role_managed_policy_arns"></a> [iam\_role\_managed\_policy\_arns](#input\_iam\_role\_managed\_policy\_arns) | Set of exclusive IAM managed policy ARNs to attach to the monitoring role | `list(string)` | `null` | no |
| <a name="input_iam_role_max_session_duration"></a> [iam\_role\_max\_session\_duration](#input\_iam\_role\_max\_session\_duration) | Maximum session duration (in seconds) that you want to set for the monitoring role | `number` | `null` | no |
| <a name="input_iam_role_name"></a> [iam\_role\_name](#input\_iam\_role\_name) | Friendly name of the monitoring role | `string` | `null` | no |
| <a name="input_iam_role_path"></a> [iam\_role\_path](#input\_iam\_role\_path) | Path for the monitoring role | `string` | `null` | no |
| <a name="input_iam_role_permissions_boundary"></a> [iam\_role\_permissions\_boundary](#input\_iam\_role\_permissions\_boundary) | The ARN of the policy that is used to set the permissions boundary for the monitoring role | `string` | `null` | no |
| <a name="input_iam_role_use_name_prefix"></a> [iam\_role\_use\_name\_prefix](#input\_iam\_role\_use\_name\_prefix) | Determines whether to use iam\_role\_name as is or create a unique name beginning with the iam\_role\_name as the prefix | `bool` | `false` | no |
| <a name="input_instance_class"></a> [instance\_class](#input\_instance\_class) | The instance type of the RDS instance | `string` | `null` | no |
| <a name="input_instance_tags"></a> [instance\_tags](#input\_instance\_tags) | A map of tags to add to only the DB instance | `map(string)` | `{}` | no |
| <a name="input_instance_timeouts"></a> [instance\_timeouts](#input\_instance\_timeouts) | Create, update, and delete timeout configurations for the DB instance | `map(string)` | `{}` | no |
| <a name="input_iops"></a> [iops](#input\_iops) | The amount of provisioned IOPS. Setting this implies a storage\_type of io1 or io2 | `number` | `null` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | The ARN for the KMS encryption key. When specifying kms\_key\_id, storage\_encrypted needs to be set to true | `string` | `null` | no |
| <a name="input_license_model"></a> [license\_model](#input\_license\_model) | License model information for this DB instance. Optional, but required for some DB engines (e.g. Oracle) | `string` | `null` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | The window to perform maintenance in. Syntax: ddd:hh24:mi-ddd:hh24:mi | `string` | `"sun:05:00-sun:06:00"` | no |
| <a name="input_manage_master_user_password"></a> [manage\_master\_user\_password](#input\_manage\_master\_user\_password) | Set to true to allow RDS to manage the master user password in Secrets Manager. Cannot be set if master\_password\_wo is provided | `bool` | `true` | no |
| <a name="input_manage_master_user_password_rotation"></a> [manage\_master\_user\_password\_rotation](#input\_manage\_master\_user\_password\_rotation) | Whether to manage the master user password rotation. Setting this value to false after previously having been set to true will disable automatic rotation. | `bool` | `false` | no |
| <a name="input_master_password_wo"></a> [master\_password\_wo](#input\_master\_password\_wo) | Write-only password for the master DB user. Never stored in Terraform state. Required unless manage\_master\_user\_password is set to true or unless snapshot\_identifier is provided | `string` | `null` | no |
| <a name="input_master_password_wo_version"></a> [master\_password\_wo\_version](#input\_master\_password\_wo\_version) | Version counter for the master DB password. Increment to trigger a password rotation without storing the new value in state | `number` | `1` | no |
| <a name="input_master_user_password_rotate_immediately"></a> [master\_user\_password\_rotate\_immediately](#input\_master\_user\_password\_rotate\_immediately) | Specifies whether to rotate the secret immediately or wait until the next scheduled rotation window. | `bool` | `null` | no |
| <a name="input_master_user_password_rotation_automatically_after_days"></a> [master\_user\_password\_rotation\_automatically\_after\_days](#input\_master\_user\_password\_rotation\_automatically\_after\_days) | Specifies the number of days between automatic scheduled rotations of the secret | `number` | `null` | no |
| <a name="input_master_user_password_rotation_duration"></a> [master\_user\_password\_rotation\_duration](#input\_master\_user\_password\_rotation\_duration) | The length of the rotation window in hours. For example, 3h for a three hour window. | `string` | `null` | no |
| <a name="input_master_user_password_rotation_schedule_expression"></a> [master\_user\_password\_rotation\_schedule\_expression](#input\_master\_user\_password\_rotation\_schedule\_expression) | A cron() or rate() expression that defines the schedule for rotating your secret | `string` | `null` | no |
| <a name="input_master_user_secret_kms_key_id"></a> [master\_user\_secret\_kms\_key\_id](#input\_master\_user\_secret\_kms\_key\_id) | The Amazon Web Services KMS key identifier is the key ARN, key ID, alias ARN, or alias name for the KMS key | `string` | `null` | no |
| <a name="input_master_username"></a> [master\_username](#input\_master\_username) | Username for the master DB user. Required unless snapshot\_identifier or replicate\_source\_db is provided | `string` | `null` | no |
| <a name="input_max_allocated_storage"></a> [max\_allocated\_storage](#input\_max\_allocated\_storage) | The upper limit to which Amazon RDS can automatically scale the storage of the DB instance. Set to 0 to disable storage autoscaling | `number` | `0` | no |
| <a name="input_monitoring_interval"></a> [monitoring\_interval](#input\_monitoring\_interval) | The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. Set to 0 to disable. Valid values: 0, 1, 5, 10, 15, 30, 60 | `number` | `0` | no |
| <a name="input_monitoring_role_arn"></a> [monitoring\_role\_arn](#input\_monitoring\_role\_arn) | IAM role used by RDS to send enhanced monitoring metrics to CloudWatch | `string` | `null` | no |
| <a name="input_multi_az"></a> [multi\_az](#input\_multi\_az) | Specifies if the RDS instance is multi-AZ | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to use for resource naming and tagging. | `string` | `null` | no |
| <a name="input_network_type"></a> [network\_type](#input\_network\_type) | The type of network stack to use (IPV4 or DUAL) | `string` | `null` | no |
| <a name="input_option_group_name"></a> [option\_group\_name](#input\_option\_group\_name) | Name of the option group to associate (existing, if not creating one) | `string` | `null` | no |
| <a name="input_performance_insights_enabled"></a> [performance\_insights\_enabled](#input\_performance\_insights\_enabled) | Specifies whether Performance Insights is enabled or not | `bool` | `null` | no |
| <a name="input_performance_insights_kms_key_id"></a> [performance\_insights\_kms\_key\_id](#input\_performance\_insights\_kms\_key\_id) | The ARN for the KMS key to encrypt Performance Insights data | `string` | `null` | no |
| <a name="input_performance_insights_retention_period"></a> [performance\_insights\_retention\_period](#input\_performance\_insights\_retention\_period) | Amount of time in days to retain Performance Insights data. Either 7 (7 days) or 731 (2 years) | `number` | `null` | no |
| <a name="input_port"></a> [port](#input\_port) | The port on which the DB accepts connections | `number` | `null` | no |
| <a name="input_publicly_accessible"></a> [publicly\_accessible](#input\_publicly\_accessible) | Determines whether instances are publicly accessible. Default false | `bool` | `null` | no |
| <a name="input_read_replicas"></a> [read\_replicas](#input\_read\_replicas) | Map of read replicas and any specific/overriding attributes to be created. Each key becomes part of the identifier | `any` | `{}` | no |
| <a name="input_replica_mode"></a> [replica\_mode](#input\_replica\_mode) | Specifies whether the replica is in either mounted or open-read-only mode. Only supported for Oracle DB instances | `string` | `null` | no |
| <a name="input_replicate_source_db"></a> [replicate\_source\_db](#input\_replicate\_source\_db) | Specifies that this resource is a Read Replica, and to use the value as the source database identifier. This correlates to the identifier of another Amazon RDS Database to replicate (if replicating within a single region) or ARN of the Amazon RDS Database to replicate (if replicating cross-region) | `string` | `null` | no |
| <a name="input_restore_to_point_in_time"></a> [restore\_to\_point\_in\_time](#input\_restore\_to\_point\_in\_time) | Configuration block for restoring a DB instance to an arbitrary point in time. Requires the source\_db\_instance\_identifier or source\_dbi\_resource\_id argument | `map(string)` | `{}` | no |
| <a name="input_s3_import"></a> [s3\_import](#input\_s3\_import) | Configuration map used to restore from a Percona Xtrabackup in S3 (only MySQL is supported) | `map(string)` | `{}` | no |
| <a name="input_security_group_description"></a> [security\_group\_description](#input\_security\_group\_description) | The description of the security group. If value is set to empty string it will contain instance name in the description | `string` | `null` | no |
| <a name="input_security_group_name"></a> [security\_group\_name](#input\_security\_group\_name) | The security group name. Default value is (var.name) | `string` | `null` | no |
| <a name="input_security_group_rules"></a> [security\_group\_rules](#input\_security\_group\_rules) | Map of security group rules to add to the security group created | `any` | `{}` | no |
| <a name="input_security_group_tags"></a> [security\_group\_tags](#input\_security\_group\_tags) | Additional tags for the security group | `map(string)` | `{}` | no |
| <a name="input_security_group_use_name_prefix"></a> [security\_group\_use\_name\_prefix](#input\_security\_group\_use\_name\_prefix) | Determines whether the security group name (var.name) is used as a prefix | `bool` | `true` | no |
| <a name="input_skip_final_snapshot"></a> [skip\_final\_snapshot](#input\_skip\_final\_snapshot) | Determines whether a final snapshot is created before the DB instance is deleted. If true is specified, no snapshot is created | `bool` | `false` | no |
| <a name="input_snapshot_identifier"></a> [snapshot\_identifier](#input\_snapshot\_identifier) | Specifies whether or not to create this database from a snapshot | `string` | `null` | no |
| <a name="input_storage_encrypted"></a> [storage\_encrypted](#input\_storage\_encrypted) | Specifies whether the DB instance is encrypted. The default is true | `bool` | `true` | no |
| <a name="input_storage_throughput"></a> [storage\_throughput](#input\_storage\_throughput) | The storage throughput value for the DB instance. Applicable only for gp3 storage type. Cannot be specified if the storage\_type is not gp3 | `number` | `null` | no |
| <a name="input_storage_type"></a> [storage\_type](#input\_storage\_type) | The storage type for the DB instance. Valid values: gp2, gp3, io1, io2, standard (magnetic) | `string` | `"gp3"` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | List of subnet IDs used by database subnet group created | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_timezone"></a> [timezone](#input\_timezone) | Time zone of the DB instance. Only supported for Microsoft SQL Server | `string` | `null` | no |
| <a name="input_use_identifier_prefix"></a> [use\_identifier\_prefix](#input\_use\_identifier\_prefix) | Whether to use `name` as a prefix for the DB instance identifier | `bool` | `false` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC where to create security group | `string` | `null` | no |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | List of VPC security groups to associate to the instance in addition to the security group created | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_db_instance_address"></a> [db\_instance\_address](#output\_db\_instance\_address) | The hostname of the RDS instance |
| <a name="output_db_instance_arn"></a> [db\_instance\_arn](#output\_db\_instance\_arn) | The ARN of the RDS instance |
| <a name="output_db_instance_availability_zone"></a> [db\_instance\_availability\_zone](#output\_db\_instance\_availability\_zone) | The availability zone of the instance |
| <a name="output_db_instance_ca_cert_identifier"></a> [db\_instance\_ca\_cert\_identifier](#output\_db\_instance\_ca\_cert\_identifier) | Specifies the identifier of the CA certificate for the DB instance |
| <a name="output_db_instance_cloudwatch_log_groups"></a> [db\_instance\_cloudwatch\_log\_groups](#output\_db\_instance\_cloudwatch\_log\_groups) | Map of CloudWatch log groups created and their attributes |
| <a name="output_db_instance_endpoint"></a> [db\_instance\_endpoint](#output\_db\_instance\_endpoint) | The connection endpoint in address:port format |
| <a name="output_db_instance_engine_version_actual"></a> [db\_instance\_engine\_version\_actual](#output\_db\_instance\_engine\_version\_actual) | The running version of the database |
| <a name="output_db_instance_hosted_zone_id"></a> [db\_instance\_hosted\_zone\_id](#output\_db\_instance\_hosted\_zone\_id) | The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record) |
| <a name="output_db_instance_id"></a> [db\_instance\_id](#output\_db\_instance\_id) | The RDS instance identifier |
| <a name="output_db_instance_latest_restorable_time"></a> [db\_instance\_latest\_restorable\_time](#output\_db\_instance\_latest\_restorable\_time) | The latest point in time to which the database can be restored with point-in-time restore |
| <a name="output_db_instance_master_user_secret"></a> [db\_instance\_master\_user\_secret](#output\_db\_instance\_master\_user\_secret) | The master user secret when manage\_master\_user\_password is set to true |
| <a name="output_db_instance_multi_az"></a> [db\_instance\_multi\_az](#output\_db\_instance\_multi\_az) | Whether the RDS instance is multi-AZ |
| <a name="output_db_instance_name"></a> [db\_instance\_name](#output\_db\_instance\_name) | The database name |
| <a name="output_db_instance_port"></a> [db\_instance\_port](#output\_db\_instance\_port) | The database port |
| <a name="output_db_instance_resource_id"></a> [db\_instance\_resource\_id](#output\_db\_instance\_resource\_id) | The RDS Resource ID of this instance |
| <a name="output_db_instance_secretsmanager_secret_rotation_enabled"></a> [db\_instance\_secretsmanager\_secret\_rotation\_enabled](#output\_db\_instance\_secretsmanager\_secret\_rotation\_enabled) | Specifies whether automatic rotation is enabled for the secret |
| <a name="output_db_instance_status"></a> [db\_instance\_status](#output\_db\_instance\_status) | The RDS instance status |
| <a name="output_db_instance_username"></a> [db\_instance\_username](#output\_db\_instance\_username) | The master username for the database |
| <a name="output_db_option_group_arn"></a> [db\_option\_group\_arn](#output\_db\_option\_group\_arn) | The ARN of the DB option group created |
| <a name="output_db_option_group_id"></a> [db\_option\_group\_id](#output\_db\_option\_group\_id) | The ID of the DB option group created |
| <a name="output_db_parameter_group_arn"></a> [db\_parameter\_group\_arn](#output\_db\_parameter\_group\_arn) | The ARN of the DB parameter group created |
| <a name="output_db_parameter_group_id"></a> [db\_parameter\_group\_id](#output\_db\_parameter\_group\_id) | The ID of the DB parameter group created |
| <a name="output_db_subnet_group_name"></a> [db\_subnet\_group\_name](#output\_db\_subnet\_group\_name) | The db subnet group name |
| <a name="output_enhanced_monitoring_iam_role_arn"></a> [enhanced\_monitoring\_iam\_role\_arn](#output\_enhanced\_monitoring\_iam\_role\_arn) | The Amazon Resource Name (ARN) specifying the enhanced monitoring role |
| <a name="output_enhanced_monitoring_iam_role_name"></a> [enhanced\_monitoring\_iam\_role\_name](#output\_enhanced\_monitoring\_iam\_role\_name) | The name of the enhanced monitoring role |
| <a name="output_enhanced_monitoring_iam_role_unique_id"></a> [enhanced\_monitoring\_iam\_role\_unique\_id](#output\_enhanced\_monitoring\_iam\_role\_unique\_id) | Stable and unique string identifying the enhanced monitoring role |
| <a name="output_read_replicas"></a> [read\_replicas](#output\_read\_replicas) | A map of read replicas and their attributes |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | The security group ID of the RDS instance |
<!-- END_TF_DOCS -->
