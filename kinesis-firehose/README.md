# Kinesis Firehose

Feature-rich Amazon Kinesis Data Firehose module that provisions delivery streams with support for a wide range of sources, destinations, and data transformation options. Handles IAM role creation, CloudWatch logging, VPC networking, and security group management automatically.

> **Note — encryption by default:** `enable_sse` defaults to `true`, so server-side encryption at rest (AWS-owned CMK by default) is enabled for delivery streams. SSE only applies to **Direct PUT** sources — it is ignored for Kinesis and MSK sources (Kinesis sources inherit the source stream's encryption). Set `enable_sse = false` to disable.

> **Note — Sumo Logic endpoint URL contains the access key:** for `destination = "sumologic"`, the HTTP endpoint URL embeds `http_endpoint_access_key`. Although the variable is marked sensitive, the composed URL is stored in the OpenTofu state — protect state access accordingly and rotate the key if state is exposed.

> **Note — Splunk/Redshift ingress on existing destination SGs:** `aws_vpc_security_group_ingress_rule.destination_existing_from_cidr` creates one rule per (security group, Firehose CIDR) pair for the region's published Firehose CIDRs; regions without a known Firehose CIDR fail with a precondition error.

## Features

- **Multiple Sources** - Ingest data via Direct Put, Kinesis Data Streams, WAF logs, or Amazon MSK
- **Extensive Destination Support** - Deliver to S3, Redshift, OpenSearch (managed and serverless), Elasticsearch, Splunk, Snowflake, Apache Iceberg, and HTTP endpoints including Datadog, Coralogix, New Relic, Dynatrace, Honeycomb, LogicMonitor, MongoDB, and Sumo Logic
- **Data Transformation** - Optional Lambda-based record transformation with configurable buffer size, interval, and retry settings
- **Data Format Conversion** - Convert JSON to Apache Parquet or ORC using AWS Glue Data Catalog schemas
- **Dynamic Partitioning** - Partition S3 data by extracted keys for efficient query patterns
- **Server-Side Encryption** - SSE at rest with AWS-owned or customer-managed KMS keys
- **S3 Backup** - Configurable backup to a secondary S3 bucket for all destination types
- **VPC Delivery** - Deploy Firehose into VPC subnets with managed security groups for OpenSearch and Elasticsearch destinations
- **Cross-Account Support** - Deliver to S3 buckets, OpenSearch domains, or Elasticsearch domains in different AWS accounts
- **CloudWatch Logging** - Automatic log group and stream creation for delivery and backup monitoring
- **IAM Role Management** - Auto-creates least-privilege IAM roles for the delivery stream and optional application source roles
- **Secrets Manager Integration** - Retrieve destination credentials from AWS Secrets Manager

## Usage

```hcl
module "firehose" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kinesis-firehose?depth=1&ref=master"

  name        = "app-logs-to-s3"
  destination = "extended_s3"

  s3_bucket_arn          = "arn:aws:s3:::my-logs-bucket"
  s3_prefix              = "firehose/year=!{timestamp:yyyy}/month=!{timestamp:MM}/"
  s3_compression_format  = "GZIP"
  buffering_size         = 64
  buffering_interval     = 300

  tags = {
    Environment = "production"
  }
}
```


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
| append\_delimiter\_to\_record | To configure your delivery stream to add a new line delimiter between records in objects that are delivered to Amazon S3. | `bool` | `false` | no |
| application\_role\_description | Description of IAM Application role to use for Kinesis Firehose Stream Source | `string` | `null` | no |
| application\_role\_force\_detach\_policies | Specifies to force detaching any policies the IAM Application role has before destroying it | `bool` | `true` | no |
| application\_role\_name | Name of IAM Application role to use for Kinesis Firehose Stream Source | `string` | `null` | no |
| application\_role\_path | Path of IAM Application role to use for Kinesis Firehose Stream Source | `string` | `null` | no |
| application\_role\_permissions\_boundary | The ARN of the policy that is used to set the permissions boundary for the IAM Application role used by Kinesis Firehose Stream Source | `string` | `null` | no |
| application\_role\_policy\_actions | List of Actions to Application Role Policy | `list(string)` | <pre>[<br/>  "firehose:PutRecord",<br/>  "firehose:PutRecordBatch"<br/>]</pre> | no |
| application\_role\_service\_principal | AWS Service Principal to assume application role | `string` | `null` | no |
| application\_role\_tags | A map of tags to assign to IAM Application role | `map(string)` | `{}` | no |
| associate\_role\_to\_redshift\_cluster | Set it to false if don't want the module associate the role to redshift cluster | `bool` | `true` | no |
| buffering\_interval | Buffer incoming data for the specified period of time, in seconds, before delivering it to the destination | `number` | `300` | no |
| buffering\_size | Buffer incoming data to the specified size, in MBs, before delivering it to the destination. | `number` | `5` | no |
| cloudwatch\_log\_group\_class | Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT\_ACCESS | `string` | `null` | no |
| cloudwatch\_log\_group\_deletion\_protection\_enabled | Set to true to protect the log group from accidental deletion. | `bool` | `true` | no |
| cloudwatch\_log\_group\_skip\_destroy | Set to true to prevent the log group from being deleted on module destroy. Preserves audit logs. | `bool` | `false` | no |
| configure\_existing\_application\_role | Set it to True if want use existing application role to add the firehose Policy | `bool` | `false` | no |
| coralogix\_endpoint\_location | Endpoint Location to coralogix destination | `string` | `"ireland"` | no |
| coralogix\_parameter\_application\_name | By default, your delivery stream arn will be used as applicationName. | `string` | `null` | no |
| coralogix\_parameter\_subsystem\_name | By default, your delivery stream name will be used as subsystemName. | `string` | `null` | no |
| coralogix\_parameter\_use\_dynamic\_values | To use dynamic values for applicationName and subsystemName. | `bool` | `false` | no |
| create\_application\_role | Set it to true to create role to be used by the source | `bool` | `false` | no |
| create\_application\_role\_policy | Set it to true to create policy to the role used by the source | `bool` | `false` | no |
| create\_destination\_cw\_log\_group | Enables or disables the cloudwatch log group creation to destination | `bool` | `true` | no |
| create\_role | Controls whether IAM role for Kinesis Firehose Stream should be created | `bool` | `true` | no |
| cw\_log\_retention\_in\_days | Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, and 3653. | `number` | `30` | no |
| cw\_tags | A map of tags to assign to the resource. | `map(string)` | `{}` | no |
| data\_format\_conversion\_block\_size | The Hadoop Distributed File System (HDFS) block size. This is useful if you intend to copy the data from Amazon S3 to HDFS before querying. The Value is in Bytes. | `number` | `268435456` | no |
| data\_format\_conversion\_glue\_catalog\_id | The ID of the AWS Glue Data Catalog. If you don't supply this, the AWS account ID is used by default. | `string` | `null` | no |
| data\_format\_conversion\_glue\_database | Name of the AWS Glue database that contains the schema for the output data. | `string` | `null` | no |
| data\_format\_conversion\_glue\_region | If you don't specify an AWS Region, the default is the current region. | `string` | `null` | no |
| data\_format\_conversion\_glue\_role\_arn | The role that Kinesis Data Firehose can use to access AWS Glue. This role must be in the same account you use for Kinesis Data Firehose. Cross-account roles aren't allowed. | `string` | `null` | no |
| data\_format\_conversion\_glue\_table\_name | Specifies the AWS Glue table that contains the column information that constitutes your data schema | `string` | `null` | no |
| data\_format\_conversion\_glue\_use\_existing\_role | Indicates if want use the kinesis firehose role to glue access. | `bool` | `true` | no |
| data\_format\_conversion\_glue\_version\_id | Specifies the table version for the output data schema. | `string` | `"LATEST"` | no |
| data\_format\_conversion\_hive\_timestamps | A list of how you want Kinesis Data Firehose to parse the date and time stamps that may be present in your input data JSON. To specify these format strings, follow the pattern syntax of JodaTime's DateTimeFormat format strings. | `list(string)` | `[]` | no |
| data\_format\_conversion\_input\_format | Specifies which deserializer to use. You can choose either the Apache Hive JSON SerDe or the OpenX JSON SerDe | `string` | `"OpenX"` | no |
| data\_format\_conversion\_openx\_case\_insensitive | When set to true, Kinesis Data Firehose converts JSON keys to lowercase before deserializing them. | `bool` | `true` | no |
| data\_format\_conversion\_openx\_column\_to\_json\_key\_mappings | A map of column names to JSON keys that aren't identical to the column names. This is useful when the JSON contains keys that are Hive keywords. | `map(string)` | `null` | no |
| data\_format\_conversion\_openx\_convert\_dots\_to\_underscores | Specifies that the names of the keys include dots and that you want Kinesis Data Firehose to replace them with underscores. This is useful because Apache Hive does not allow dots in column names. | `bool` | `false` | no |
| data\_format\_conversion\_orc\_bloom\_filter\_columns | A list of column names for which you want Kinesis Data Firehose to create bloom filters. | `list(string)` | `[]` | no |
| data\_format\_conversion\_orc\_bloom\_filter\_false\_positive\_probability | The Bloom filter false positive probability (FPP). The lower the FPP, the bigger the Bloom filter. | `number` | `0.05` | no |
| data\_format\_conversion\_orc\_compression | The compression code to use over data blocks. | `string` | `"SNAPPY"` | no |
| data\_format\_conversion\_orc\_dict\_key\_threshold | A float that represents the fraction of the total number of non-null rows. To turn off dictionary encoding, set this fraction to a number that is less than the number of distinct keys in a dictionary. To always use dictionary encoding, set this threshold to 1. | `number` | `0` | no |
| data\_format\_conversion\_orc\_enable\_padding | Set this to true to indicate that you want stripes to be padded to the HDFS block boundaries. This is useful if you intend to copy the data from Amazon S3 to HDFS before querying. | `bool` | `false` | no |
| data\_format\_conversion\_orc\_format\_version | The version of the file to write. | `string` | `"V0_12"` | no |
| data\_format\_conversion\_orc\_padding\_tolerance | A float between 0 and 1 that defines the tolerance for block padding as a decimal fraction of stripe size. | `number` | `0.05` | no |
| data\_format\_conversion\_orc\_row\_index\_stripe | The number of rows between index entries. | `number` | `10000` | no |
| data\_format\_conversion\_orc\_stripe\_size | he number of bytes in each strip. | `number` | `67108864` | no |
| data\_format\_conversion\_output\_format | Specifies which serializer to use. You can choose either the ORC SerDe or the Parquet SerDe | `string` | `"PARQUET"` | no |
| data\_format\_conversion\_parquet\_compression | The compression code to use over data blocks. | `string` | `"SNAPPY"` | no |
| data\_format\_conversion\_parquet\_dict\_compression | Indicates whether to enable dictionary compression. | `bool` | `false` | no |
| data\_format\_conversion\_parquet\_max\_padding | The maximum amount of padding to apply. This is useful if you intend to copy the data from Amazon S3 to HDFS before querying. The value is in bytes | `number` | `0` | no |
| data\_format\_conversion\_parquet\_page\_size | Column chunks are divided into pages. A page is conceptually an indivisible unit (in terms of compression and encoding). The value is in bytes | `number` | `1048576` | no |
| data\_format\_conversion\_parquet\_writer\_version | Indicates the version of row format to output. | `string` | `"V1"` | no |
| datadog\_endpoint\_type | Endpoint type to datadog destination | `string` | `"logs_us"` | no |
| destination | This is the destination to where the data is delivered | `string` | n/a | yes |
| destination\_cross\_account | Indicates if destination is in a different account. Only supported to Elasticsearch and OpenSearch | `bool` | `false` | no |
| destination\_log\_group\_name | The CloudWatch group name for destination logs | `string` | `null` | no |
| destination\_log\_stream\_name | The CloudWatch log stream name for destination logs | `string` | `null` | no |
| dynamic\_partition\_enable\_record\_deaggregation | Data deaggregation is the process of parsing through the records in a delivery stream and separating the records based either on valid JSON or on the specified delimiter | `bool` | `false` | no |
| dynamic\_partition\_metadata\_extractor\_query | Dynamic Partition JQ query. | `string` | `null` | no |
| dynamic\_partition\_record\_deaggregation\_delimiter | Specifies the delimiter to be used for parsing through the records in the delivery stream and deaggregating them | `string` | `null` | no |
| dynamic\_partition\_record\_deaggregation\_type | Data deaggregation is the process of parsing through the records in a delivery stream and separating the records based either on valid JSON or on the specified delimiter | `string` | `"JSON"` | no |
| dynamic\_partitioning\_retry\_duration | Total amount of seconds Firehose spends on retries | `number` | `300` | no |
| dynatrace\_api\_url | API URL to Dynatrace destination | `string` | `null` | no |
| dynatrace\_endpoint\_location | Endpoint Location to Dynatrace destination | `string` | `"eu"` | no |
| elasticsearch\_cluster\_endpoint | The endpoint to use when communicating with the Elasticsearch cluster. Conflicts with elasticsearch\_domain\_arn. | `string` | `null` | no |
| elasticsearch\_domain\_arn | The ARN of the Amazon ES domain. The pattern needs to be arn:.*. Conflicts with elasticsearch\_cluster\_endpoint. | `string` | `null` | no |
| elasticsearch\_index\_name | The Elasticsearch index name | `string` | `null` | no |
| elasticsearch\_index\_rotation\_period | The Elasticsearch index rotation period. Index rotation appends a timestamp to the IndexName to facilitate expiration of old data | `string` | `"OneDay"` | no |
| elasticsearch\_retry\_duration | The length of time during which Firehose retries delivery after a failure, starting from the initial request and including the first attempt | `string` | `300` | no |
| elasticsearch\_type\_name | The Elasticsearch type name with maximum length of 100 characters | `string` | `null` | no |
| enable\_cloudwatch\_logs\_data\_message\_extraction | Cloudwatch Logs data message extraction | `bool` | `false` | no |
| enable\_cloudwatch\_logs\_decompression | Enables or disables Cloudwatch Logs decompression | `bool` | `false` | no |
| enable\_data\_format\_conversion | Set it to true if you want to disable format conversion. | `bool` | `false` | no |
| enable\_destination\_log | The CloudWatch Logging Options for the delivery stream | `bool` | `true` | no |
| enable\_dynamic\_partitioning | Enables or disables dynamic partitioning | `bool` | `false` | no |
| enable\_lambda\_transform | Set it to true to enable data transformation with lambda | `bool` | `false` | no |
| enable\_s3\_backup | The Amazon S3 backup mode | `bool` | `false` | no |
| enable\_s3\_encryption | Indicates if want use encryption in S3 bucket. | `bool` | `false` | no |
| enable\_secrets\_manager | Enables or disables the Secrets Manager configuration. | `bool` | `false` | no |
| enable\_sse | Whether to enable encryption at rest. Defaults to `true`. Only applies when the source is Direct PUT (ignored for Kinesis and MSK sources); set to `false` to opt out. | `bool` | `true` | no |
| enable\_vpc | Indicates if destination is configured in VPC. Supports Elasticsearch and Opensearch destinations. | `bool` | `false` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| firehose\_role | IAM role ARN attached to the Kinesis Firehose Stream. | `string` | `null` | no |
| honeycomb\_api\_host | If you use a Secure Tenancy or other proxy, put its schema://host[:port] here | `string` | `"https://api.honeycomb.io"` | no |
| honeycomb\_dataset\_name | Your Honeycomb dataset name to Honeycomb destination | `string` | `null` | no |
| http\_endpoint\_access\_key | The access key required for Kinesis Firehose to authenticate with the HTTP endpoint selected as the destination | `string` | `null` | no |
| http\_endpoint\_enable\_request\_configuration | The request configuration | `bool` | `false` | no |
| http\_endpoint\_name | The HTTP endpoint name | `string` | `null` | no |
| http\_endpoint\_request\_configuration\_common\_attributes | Describes the metadata sent to the HTTP endpoint destination. The variable is list. Each element is map with two keys , name and value, that corresponds to common attribute name and value | `list(map(string))` | `[]` | no |
| http\_endpoint\_request\_configuration\_content\_encoding | Kinesis Data Firehose uses the content encoding to compress the body of a request before sending the request to the destination | `string` | `"GZIP"` | no |
| http\_endpoint\_retry\_duration | Total amount of seconds Firehose spends on retries. This duration starts after the initial attempt fails, It does not include the time periods during which Firehose waits for acknowledgment from the specified destination after each attempt | `number` | `300` | no |
| http\_endpoint\_url | The HTTP endpoint URL to which Kinesis Firehose sends your data | `string` | `null` | no |
| iceberg\_append\_only | Set to true to enable append-only mode for the Iceberg destination (v6.8+). When enabled, Firehose delivers data as inserts only without updating existing records. | `bool` | `null` | no |
| iceberg\_catalog\_arn | The ARN of the AWS Glue catalog for the Iceberg destination | `string` | `null` | no |
| iceberg\_destination\_tables | List of destination table configuration blocks for the Iceberg destination. Each block requires database\_name and table\_name. | `any` | `[]` | no |
| iceberg\_retry\_duration | The period of time, in seconds, during which Firehose retries to deliver data to the Iceberg destination after a failure. Valid values between 0 and 7200. | `number` | `300` | no |
| input\_source | This is the kinesis firehose source | `string` | `"direct-put"` | no |
| kinesis\_source\_is\_encrypted | Indicates if Kinesis data stream source is encrypted | `bool` | `false` | no |
| kinesis\_source\_kms\_arn | Kinesis Source KMS Key to add Firehose role to decrypt the records. | `string` | `null` | no |
| kinesis\_source\_stream\_arn | The kinesis stream used as the source of the firehose delivery stream | `string` | `null` | no |
| logicmonitor\_account | Account to use in Logic Monitor destination | `string` | `null` | no |
| mongodb\_realm\_webhook\_url | Realm Webhook URL to use in MongoDB destination | `string` | `null` | no |
| msk\_source\_cluster\_arn | The ARN of the Amazon MSK cluster. | `string` | `null` | no |
| msk\_source\_connectivity\_type | The type of connectivity used to access the Amazon MSK cluster. Valid values: PUBLIC, PRIVATE. | `string` | `"PUBLIC"` | no |
| msk\_source\_read\_from\_timestamp | The start date and time in UTC for the offset position within the MSK topic from where Firehose begins to read. By default, this is set to timestamp when Firehose becomes Active. Set to Epoch (1970-01-01T00:00:00Z) for Earliest start position. | `string` | `null` | no |
| msk\_source\_topic\_name | The topic name within the Amazon MSK cluster. | `string` | `null` | no |
| name | Name to use for resource naming and tagging. | `string` | `null` | no |
| newrelic\_endpoint\_type | Endpoint type to New Relic destination | `string` | `"logs_eu"` | no |
| opensearch\_cluster\_endpoint | The endpoint to use when communicating with the OpenSearch cluster. Conflicts with opensearch\_domain\_arn. | `string` | `null` | no |
| opensearch\_document\_id\_options | The method for setting up document ID. | `string` | `"FIREHOSE_DEFAULT"` | no |
| opensearch\_domain\_arn | The ARN of the Amazon Opensearch domain. The pattern needs to be arn:.*. Conflicts with opensearch\_cluster\_endpoint. | `string` | `null` | no |
| opensearch\_index\_name | The Opensearch (And OpenSearch Serverless) index name. | `string` | `null` | no |
| opensearch\_index\_rotation\_period | The Opensearch index rotation period. Index rotation appends a timestamp to the IndexName to facilitate expiration of old data | `string` | `"OneDay"` | no |
| opensearch\_retry\_duration | After an initial failure to deliver to Amazon OpenSearch, the total amount of time, in seconds between 0 to 7200, during which Firehose re-attempts delivery (including the first attempt). After this time has elapsed, the failed documents are written to Amazon S3. The default value is 300s. There will be no retry if the value is 0. | `string` | `300` | no |
| opensearch\_type\_name | The opensearch type name with maximum length of 100 characters. Types are deprecated in OpenSearch\_1.1. TypeName must be empty. | `string` | `null` | no |
| opensearch\_vpc\_create\_service\_linked\_role | Set it to True if want create Opensearch Service Linked Role to Access VPC. | `bool` | `false` | no |
| opensearchserverless\_collection\_arn | The ARN of the Amazon Opensearch Serverless Collection. The pattern needs to be arn:.*. | `string` | `null` | no |
| opensearchserverless\_collection\_endpoint | The endpoint to use when communicating with the collection in the Serverless offering for Amazon OpenSearch Service. | `string` | `null` | no |
| policy\_path | Path of policies to that should be added to IAM role for Kinesis Firehose Stream | `string` | `null` | no |
| redshift\_cluster\_endpoint | The redshift endpoint | `string` | `null` | no |
| redshift\_cluster\_identifier | Redshift Cluster identifier. Necessary to associate the iam role to cluster | `string` | `null` | no |
| redshift\_copy\_options | Copy options for copying the data from the s3 intermediate bucket into redshift, for example to change the default delimiter | `string` | `null` | no |
| redshift\_data\_table\_columns | The data table columns that will be targeted by the copy command | `string` | `null` | no |
| redshift\_database\_name | The redshift database name | `string` | `null` | no |
| redshift\_password | The password for the redshift username above | `string` | `null` | no |
| redshift\_retry\_duration | The length of time during which Firehose retries delivery after a failure, starting from the initial request and including the first attempt | `string` | `3600` | no |
| redshift\_table\_name | The name of the table in the redshift cluster that the s3 bucket will copy to | `string` | `null` | no |
| redshift\_username | The username that the firehose delivery stream will assume. It is strongly recommended that the username and password provided is used exclusively for Amazon Kinesis Firehose purposes, and that the permissions for the account are restricted for Amazon Redshift INSERT permissions | `string` | `null` | no |
| region | Region where the resource(s) will be managed. Defaults to the region set in the provider configuration | `string` | `null` | no |
| role\_description | Description of IAM role to use for Kinesis Firehose Stream | `string` | `null` | no |
| role\_force\_detach\_policies | Specifies to force detaching any policies the IAM role has before destroying it | `bool` | `true` | no |
| role\_name | Name of IAM role to use for Kinesis Firehose Stream | `string` | `null` | no |
| role\_path | Path of IAM role to use for Kinesis Firehose Stream | `string` | `null` | no |
| role\_permissions\_boundary | The ARN of the policy that is used to set the permissions boundary for the IAM role used by Kinesis Firehose Stream | `string` | `null` | no |
| role\_tags | A map of tags to assign to IAM role | `map(string)` | `{}` | no |
| s3\_backup\_bucket\_arn | The ARN of the S3 backup bucket | `string` | `null` | no |
| s3\_backup\_buffering\_interval | Buffer incoming data for the specified period of time, in seconds, before delivering it to the destination. | `number` | `300` | no |
| s3\_backup\_buffering\_size | Buffer incoming data to the specified size, in MBs, before delivering it to the destination. | `number` | `5` | no |
| s3\_backup\_compression | The compression format | `string` | `"UNCOMPRESSED"` | no |
| s3\_backup\_create\_cw\_log\_group | Enables or disables the cloudwatch log group creation | `bool` | `true` | no |
| s3\_backup\_enable\_encryption | Indicates if want enable KMS Encryption in S3 Backup Bucket. | `bool` | `false` | no |
| s3\_backup\_enable\_log | Enables or disables the logging | `bool` | `true` | no |
| s3\_backup\_error\_output\_prefix | Prefix added to failed records before writing them to S3 | `string` | `null` | no |
| s3\_backup\_kms\_key\_arn | Specifies the KMS key ARN the stream will use to encrypt data. If not set, no encryption will be used. | `string` | `null` | no |
| s3\_backup\_log\_group\_name | he CloudWatch group name for logging | `string` | `null` | no |
| s3\_backup\_log\_stream\_name | The CloudWatch log stream name for logging | `string` | `null` | no |
| s3\_backup\_mode | Defines how documents should be delivered to Amazon S3. Used to elasticsearch, opensearch, splunk, http configurations. For S3 and Redshift use enable\_s3\_backup | `string` | `"FailedOnly"` | no |
| s3\_backup\_prefix | The YYYY/MM/DD/HH time format prefix is automatically used for delivered S3 files. You can specify an extra prefix to be added in front of the time format prefix. Note that if the prefix ends with a slash, it appears as a folder in the S3 bucket | `string` | `null` | no |
| s3\_backup\_role\_arn | The role that Kinesis Data Firehose can use to access S3 Backup. | `string` | `null` | no |
| s3\_backup\_use\_existing\_role | Indicates if want use the kinesis firehose role to s3 backup bucket access. | `bool` | `true` | no |
| s3\_bucket\_arn | The ARN of the S3 destination bucket | `string` | `null` | no |
| s3\_compression\_format | The compression format | `string` | `"UNCOMPRESSED"` | no |
| s3\_configuration\_buffering\_interval | Buffer incoming data for the specified period of time, in seconds, before delivering it to the destination. | `number` | `300` | no |
| s3\_configuration\_buffering\_size | Buffer incoming data to the specified size, in MBs, before delivering it to the destination. The default value is 5. We recommend setting SizeInMBs to a value greater than the amount of data you typically ingest into the delivery stream in 10 seconds. For example, if you typically ingest data at 1 MB/sec set SizeInMBs to be 10 MB or higher. | `number` | `5` | no |
| s3\_cross\_account | Indicates if S3 bucket destination is in a different account | `bool` | `false` | no |
| s3\_custom\_time\_zone | The time zone you prefer. UTC and all the IANA time zones are supported. Used in the extended\_s3 destination. | `string` | `null` | no |
| s3\_error\_output\_prefix | Prefix added to failed records before writing them to S3. This prefix appears immediately following the bucket name. | `string` | `null` | no |
| s3\_file\_extension | The file extension to override the default file extension (e.g., .json, .csv). Used in the extended\_s3 destination. | `string` | `null` | no |
| s3\_kms\_key\_arn | Specifies the KMS key ARN the stream will use to encrypt data. If not set, no encryption will be used | `string` | `null` | no |
| s3\_prefix | The YYYY/MM/DD/HH time format prefix is automatically used for delivered S3 files. You can specify an extra prefix to be added in front of the time format prefix. Note that if the prefix ends with a slash, it appears as a folder in the S3 bucket | `string` | `null` | no |
| secret\_arn | The ARN of the Secrets Manager secret. This value is required if enable\_secrets\_manager is true. | `string` | `null` | no |
| secret\_kms\_key\_arn | The ARN of the KMS Key to encrypt the Secret. This value is required if key used to encrypt the Secret is CMK and want the module generates the IAM Policy to access it. | `string` | `null` | no |
| snowflake\_account\_identifier | The Snowflake account identifier. | `string` | `null` | no |
| snowflake\_content\_column\_name | The name of the content column. | `string` | `null` | no |
| snowflake\_data\_loading\_option | The data loading option. | `string` | `null` | no |
| snowflake\_database | The Snowflake database name. | `string` | `null` | no |
| snowflake\_key\_passphrase | The Snowflake passphrase for the private key. | `string` | `null` | no |
| snowflake\_metadata\_column\_name | The name of the metadata column. | `string` | `null` | no |
| snowflake\_private\_key | The Snowflake private key for authentication. | `string` | `null` | no |
| snowflake\_private\_link\_vpce\_id | The VPCE ID for Firehose to privately connect with Snowflake. | `string` | `null` | no |
| snowflake\_retry\_duration | The length of time during which Firehose retries delivery after a failure, starting from the initial request and including the first attempt. | `string` | `60` | no |
| snowflake\_role\_configuration\_enabled | Whether the Snowflake role is enabled. | `bool` | `false` | no |
| snowflake\_role\_configuration\_role | The Snowflake role. | `string` | `null` | no |
| snowflake\_schema | The Snowflake schema name. | `string` | `null` | no |
| snowflake\_table | The Snowflake table name. | `string` | `null` | no |
| snowflake\_user | The user for authentication.. | `string` | `null` | no |
| source\_role\_arn | The ARN of the role that provides access to the source. Only Supported on Kinesis and MSK Sources | `string` | `null` | no |
| source\_use\_existing\_role | Indicates if want use the kinesis firehose role for sources access. Only Supported on Kinesis and MSK Sources | `bool` | `true` | no |
| splunk\_buffering\_interval | Buffer incoming data for the specified period of time, in seconds, before delivering it to the Splunk destination. Valid values between 0 and 60. | `number` | `null` | no |
| splunk\_buffering\_size | Buffer incoming data to the specified size, in MBs, before delivering it to the Splunk destination. Valid values between 1 and 5. | `number` | `null` | no |
| splunk\_hec\_acknowledgment\_timeout | The amount of time, that Kinesis Firehose waits to receive an acknowledgment from Splunk after it sends it data | `number` | `600` | no |
| splunk\_hec\_endpoint | The HTTP Event Collector (HEC) endpoint to which Kinesis Firehose sends your data | `string` | `null` | no |
| splunk\_hec\_endpoint\_type | The HEC endpoint type | `string` | `"Raw"` | no |
| splunk\_hec\_token | The GUID that you obtain from your Splunk cluster when you create a new HEC endpoint | `string` | `null` | no |
| splunk\_retry\_duration | After an initial failure to deliver to Splunk, the total amount of time, in seconds between 0 to 7200, during which Firehose re-attempts delivery (including the first attempt) | `number` | `300` | no |
| sse\_kms\_key\_arn | Amazon Resource Name (ARN) of the encryption key | `string` | `null` | no |
| sse\_kms\_key\_type | Type of encryption key. | `string` | `"AWS_OWNED_CMK"` | no |
| sumologic\_data\_type | Data Type to use in Sumo Logic destination | `string` | `"log"` | no |
| sumologic\_deployment\_name | Deployment Name to use in Sumo Logic destination | `string` | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| transform\_lambda\_arn | Lambda ARN to Transform source records | `string` | `null` | no |
| transform\_lambda\_buffer\_interval | The period of time during which Kinesis Data Firehose buffers incoming data before invoking the AWS Lambda function. The AWS Lambda function is invoked once the value of the buffer size or the buffer interval is reached. | `number` | `null` | no |
| transform\_lambda\_buffer\_size | The AWS Lambda function has a 6 MB invocation payload quota. Your data can expand in size after it's processed by the AWS Lambda function. A smaller buffer size allows for more room should the data expand after processing. | `number` | `null` | no |
| transform\_lambda\_number\_retries | Number of retries for AWS Transformation lambda | `number` | `null` | no |
| transform\_lambda\_role\_arn | The ARN of the role to execute the transform lambda. If null use the Firehose Stream role | `string` | `null` | no |
| vpc\_create\_destination\_security\_group | Indicates if want create destination security group to associate to firehose destinations | `bool` | `false` | no |
| vpc\_create\_security\_group | Indicates if want create security group to associate to kinesis firehose | `bool` | `false` | no |
| vpc\_role\_arn | The ARN of the IAM role to be assumed by Firehose for calling the Amazon EC2 configuration API and for creating network interfaces. Supports Elasticsearch and Opensearch destinations. | `string` | `null` | no |
| vpc\_security\_group\_destination\_configure\_existing | Indicates if want configure an existing destination security group with the necessary rules | `bool` | `false` | no |
| vpc\_security\_group\_destination\_ids | A list of security group IDs associated to destinations to allow firehose traffic | `list(string)` | `[]` | no |
| vpc\_security\_group\_destination\_vpc\_id | VPC ID to create the destination security group. Only supported to Redshift and splunk destinations | `string` | `null` | no |
| vpc\_security\_group\_firehose\_configure\_existing | Indicates if want configure an existing firehose security group with the necessary rules | `bool` | `false` | no |
| vpc\_security\_group\_firehose\_ids | A list of security group IDs to associate with Kinesis Firehose. | `list(string)` | `null` | no |
| vpc\_security\_group\_same\_as\_destination | Indicates if the firehose security group is the same as destination. | `bool` | `true` | no |
| vpc\_security\_group\_tags | A map of tags to assign to security group | `map(string)` | `{}` | no |
| vpc\_subnet\_ids | A list of subnet IDs to associate with Kinesis Firehose. Supports Elasticsearch and Opensearch destinations. | `list(string)` | `null` | no |
| vpc\_use\_existing\_role | Indicates if want use the kinesis firehose role to VPC access. Supports Elasticsearch and Opensearch destinations. | `bool` | `true` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| application\_role\_arn | The ARN of the IAM role created for Kinesis Firehose Stream Source |
| application\_role\_name | The Name of the IAM role created for Kinesis Firehose Stream Source Source |
| application\_role\_policy\_arn | The ARN of the IAM policy created for Kinesis Firehose Stream Source |
| application\_role\_policy\_name | The Name of the IAM policy created for Kinesis Firehose Stream Source Source |
| destination\_security\_group\_id | Security Group ID associated to destination |
| destination\_security\_group\_name | Security Group Name associated to destination |
| destination\_security\_group\_rule\_ids | Security Group Rules IDs created in Destination Security group |
| elasticsearch\_cross\_account\_service\_policy | Elasticsearch Service policy when the opensearch domain belongs to another account |
| firehose\_cidr\_blocks | Firehose stream cidr blocks to unblock on destination security group |
| firehose\_security\_group\_id | Security Group ID associated to Firehose Stream. Only Supported for elasticsearch destination |
| firehose\_security\_group\_name | Security Group Name associated to Firehose Stream. Only Supported for elasticsearch destination |
| firehose\_security\_group\_rule\_ids | Security Group Rules IDs created in Firehose Stream Security group. Only supported for elasticsearch/opensearch destination |
| kinesis\_firehose\_arn | The ARN of the Kinesis Firehose Stream |
| kinesis\_firehose\_cloudwatch\_log\_backup\_stream\_arn | The ARN of the created Cloudwatch Log Group Stream to backup |
| kinesis\_firehose\_cloudwatch\_log\_backup\_stream\_name | The name of the created Cloudwatch Log Group Stream to backup |
| kinesis\_firehose\_cloudwatch\_log\_delivery\_stream\_arn | The ARN of the created Cloudwatch Log Group Stream to delivery |
| kinesis\_firehose\_cloudwatch\_log\_delivery\_stream\_name | The name of the created Cloudwatch Log Group Stream to delivery |
| kinesis\_firehose\_cloudwatch\_log\_group\_arn | The ARN of the created Cloudwatch Log Group |
| kinesis\_firehose\_cloudwatch\_log\_group\_name | The name of the created Cloudwatch Log Group |
| kinesis\_firehose\_destination\_id | The Destination id of the Kinesis Firehose Stream |
| kinesis\_firehose\_name | The name of the Kinesis Firehose Stream |
| kinesis\_firehose\_role\_arn | The ARN of the IAM role created for Kinesis Firehose Stream |
| kinesis\_firehose\_version\_id | The Version id of the Kinesis Firehose Stream |
| opensearch\_cross\_account\_service\_policy | Opensearch Service policy when the opensearch domain belongs to another account |
| opensearch\_iam\_service\_linked\_role\_arn | The ARN of the Opensearch IAM Service linked role |
| opensearchserverless\_cross\_account\_service\_policy | Opensearch Serverless Service policy when the opensearch domain belongs to another account |
| opensearchserverless\_iam\_service\_linked\_role\_arn | The ARN of the Opensearch Serverless IAM Service linked role |
| s3\_cross\_account\_bucket\_policy | Bucket Policy to S3 Bucket Destination when the bucket belongs to another account |
<!-- END_TF_DOCS -->

## Examples

## Basic Usage - Direct Put to S3

Stream data directly from producers into an S3 bucket with GZIP compression.

```hcl
module "firehose_s3" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kinesis-firehose?depth=1&ref=master"

  enabled      = true
  name         = "app-events"
  destination  = "extended_s3"
  input_source = "direct-put"

  s3_bucket_arn          = "arn:aws:s3:::my-data-lake-bucket"
  s3_prefix              = "app-events/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
  s3_error_output_prefix = "app-events-errors/"
  s3_compression_format  = "GZIP"
  buffering_size         = 128
  buffering_interval     = 300

  tags = {
    Environment = "production"
    Team        = "data"
  }
}
```

## With Kinesis Stream Source and S3 Destination

Read from an existing Kinesis Data Stream and deliver to S3 with KMS encryption.

```hcl
module "firehose_from_kinesis" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kinesis-firehose?depth=1&ref=master"

  enabled      = true
  name         = "clickstream-delivery"
  destination  = "extended_s3"
  input_source = "kinesis"

  kinesis_source_stream_arn = "arn:aws:kinesis:us-east-1:123456789012:stream/clickstream"

  s3_bucket_arn         = "arn:aws:s3:::my-data-lake-bucket"
  s3_prefix             = "clickstream/"
  enable_s3_encryption  = true
  s3_kms_key_arn        = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"

  enable_destination_log = true

  tags = {
    Environment = "production"
    Source      = "kinesis"
  }
}
```

## With OpenSearch Destination

Deliver logs to an Amazon OpenSearch Service domain inside a VPC.

```hcl
module "firehose_opensearch" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kinesis-firehose?depth=1&ref=master"

  enabled      = true
  name         = "app-logs-opensearch"
  destination  = "opensearch"
  input_source = "direct-put"

  opensearch_domain_arn         = "arn:aws:es:us-east-1:123456789012:domain/app-logs"
  opensearch_index_name         = "app-logs"
  opensearch_index_rotation_period = "OneDay"
  opensearch_retry_duration     = 300

  s3_bucket_arn = "arn:aws:s3:::my-firehose-backup-bucket"

  enable_vpc         = true
  vpc_subnet_ids     = ["subnet-0abc123def456", "subnet-0def456abc123"]

  enable_destination_log = true

  tags = {
    Environment = "production"
    Destination = "opensearch"
  }
}
```

## WAF Logs to S3 with Dynamic Partitioning

Capture WAF logs (note: name is automatically prefixed with `aws-waf-logs-`) with dynamic partitioning.

```hcl
module "firehose_waf_logs" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//kinesis-firehose?depth=1&ref=master"

  enabled      = true
  name         = "prod-waf"
  destination  = "extended_s3"
  input_source = "waf"

  s3_bucket_arn          = "arn:aws:s3:::my-waf-logs-bucket"
  s3_prefix              = "waf-logs/region=us-east-1/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
  s3_error_output_prefix = "waf-logs-errors/!{firehose:error-output-type}/"
  s3_compression_format  = "GZIP"

  enable_dynamic_partitioning      = true
  dynamic_partitioning_retry_duration = 300

  enable_sse          = true
  sse_kms_key_type    = "CUSTOMER_MANAGED_CMK"
  sse_kms_key_arn     = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"

  enable_destination_log = true

  tags = {
    Environment = "production"
    Purpose     = "waf-logging"
  }
}
```
