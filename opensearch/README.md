# OpenSearch

OpenTofu module for deploying and managing Amazon OpenSearch Service domains with comprehensive support for VPC networking, fine-grained access control, SAML authentication, and cross-cluster connectivity.

## Features

- **Cluster configuration** - configurable data nodes, dedicated master nodes, UltraWarm storage, cold storage, and multi-AZ with standby
- **Security** - fine-grained access control, encryption at rest (KMS), node-to-node encryption, and HTTPS enforcement with configurable TLS policies
- **VPC deployment** - deploy inside a VPC with auto-created or existing security groups and custom ingress/egress rules
- **Access policies** - build IAM access policies using statement blocks or provide pre-built policy documents
- **SAML authentication** - integrate with identity providers for single sign-on to OpenSearch Dashboards
- **Auto-Tune** - automatic performance tuning with configurable maintenance schedules and off-peak windows
- **CloudWatch logging** - publish index slow logs, search slow logs, and application logs with auto-created log groups and resource policies
- **Cross-cluster connectivity** - create outbound connections for cross-cluster search and replication
- **AI/ML options** - natural language query generation, S3 vectors engine, and serverless vector acceleration
- **VPC endpoints and packages** - associate custom packages and create VPC endpoints for the domain

## Notes

- **`master_user_password` is stored in OpenTofu state.** The AWS provider does not support a write-only attribute for the fine-grained access control master user password, so any password set via `advanced_security_options.master_user_options.master_user_password` ends up in the state file (the variable is marked `sensitive`, which only hides it from CLI output). Prefer IAM-based access via `master_user_arn` - by default, when neither a master user ARN nor an internal user name is provided, the module falls back to the current caller's IAM identity (`issuer_arn`) so fine-grained access control works out of the box without any credential in state.
- **TLS policy defaults to `Policy-Min-TLS-1-2-PFS-2023-10`.** Set `domain_endpoint_options.tls_security_policy` explicitly to use a different policy.

## Usage

```hcl
module "opensearch" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//opensearch?depth=1&ref=master"

  name                   = "search"
  opensearch_domain_name = "search-prod"
  opensearch_version     = "OpenSearch_2.13"

  cluster_config = {
    instance_type          = "r6g.large.search"
    instance_count         = 3
    zone_awareness_enabled = true
    zone_awareness_config  = { availability_zone_count = 3 }
  }

  ebs_options = {
    ebs_enabled = true
    volume_size = 100
    volume_type = "gp3"
  }

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
| access\_policies | IAM policy document specifying the access policies for the domain. Required if `create_access_policy` is `false` | `string` | `null` | no |
| access\_policy\_override\_policy\_documents | List of IAM policy documents that are merged together into the exported document. In merging, statements with non-blank `sid`s will override statements with the same `sid` | `list(string)` | `[]` | no |
| access\_policy\_source\_policy\_documents | List of IAM policy documents that are merged together into the exported document. Statements must have unique `sid`s | `list(string)` | `[]` | no |
| access\_policy\_statements | A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage | `any` | `{}` | no |
| advanced\_options | Key-value string pairs to specify advanced configuration options. Note that the values for these configuration options must be strings (wrapped in quotes) or they may be wrong and cause a perpetual diff, causing Terraform to want to recreate your Elasticsearch domain on every apply | `map(string)` | <pre>{<br/>  "indices.fielddata.cache.size": "40",<br/>  "indices.query.bool.max_clause_count": "1024",<br/>  "override_main_response_version": "false",<br/>  "rest.action.multi.allow_explicit_index": "true"<br/>}</pre> | no |
| advanced\_security\_options | Configuration block for [fine-grained access control](https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/fgac.html). Note: master\_user\_password, if provided, will be stored in state as the provider does not support write\_only for this field | `any` | <pre>{<br/>  "anonymous_auth_enabled": false,<br/>  "enabled": true<br/>}</pre> | no |
| aiml\_options | Configuration block for AI/ML options including natural language query generation, S3 vectors engine, and serverless vector acceleration | `any` | `{}` | no |
| auto\_tune\_options | Configuration block for the Auto-Tune options of the domain | `any` | <pre>{<br/>  "desired_state": "ENABLED",<br/>  "rollback_on_disable": "NO_ROLLBACK"<br/>}</pre> | no |
| cloudwatch\_log\_group\_class | Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT\_ACCESS | `string` | `null` | no |
| cloudwatch\_log\_group\_kms\_key\_id | If a KMS Key ARN is set, this key will be used to encrypt the corresponding log group. Please be sure that the KMS Key has an appropriate key policy (https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html) | `string` | `null` | no |
| cloudwatch\_log\_group\_retention\_in\_days | Number of days to retain log events | `number` | `7` | no |
| cloudwatch\_log\_group\_skip\_destroy | Set to true if you do not wish the log group (and any logs it may contain) to be deleted at destroy time, and instead just remove the log group from the Terraform state | `bool` | `null` | no |
| cloudwatch\_log\_resource\_policy\_name | Name of the resource policy for OpenSearch to log to CloudWatch | `string` | `null` | no |
| cluster\_config | Configuration block for the cluster of the domain | `any` | <pre>{<br/>  "dedicated_master_enabled": false,<br/>  "zone_awareness_config": {<br/>    "availability_zone_count": 3<br/>  }<br/>}</pre> | no |
| cognito\_options | Configuration block for authenticating Kibana with Cognito | `any` | `{}` | no |
| create\_access\_policy | Determines whether an access policy will be created | `bool` | `true` | no |
| create\_cloudwatch\_log\_groups | Determines whether log groups are created | `bool` | `true` | no |
| create\_cloudwatch\_log\_resource\_policy | Determines whether a resource policy will be created for OpenSearch to log to CloudWatch | `bool` | `true` | no |
| create\_saml\_options | Determines whether SAML options will be created | `bool` | `false` | no |
| create\_security\_group | Determines if a security group is created | `bool` | `true` | no |
| domain\_endpoint\_options | Configuration block for domain endpoint HTTP(S) related options | `any` | <pre>{<br/>  "enforce_https": true,<br/>  "tls_security_policy": "Policy-Min-TLS-1-2-PFS-2023-10"<br/>}</pre> | no |
| ebs\_options | Configuration block for EBS related options, may be required based on chosen [instance size](https://aws.amazon.com/elasticsearch-service/pricing/) | `any` | <pre>{<br/>  "ebs_enabled": true,<br/>  "volume_size": 30,<br/>  "volume_type": "gp3"<br/>}</pre> | no |
| enable\_access\_policy | Determines whether an access policy will be applied to the domain | `bool` | `true` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| encrypt\_at\_rest | Configuration block for encrypting at rest | `any` | <pre>{<br/>  "enabled": true<br/>}</pre> | no |
| identity\_center\_options | Configuration block for AWS IAM Identity Center options | `any` | `{}` | no |
| ip\_address\_type | The IP address type for the endpoint. Valid values are ipv4 and dualstack | `string` | `null` | no |
| log\_publishing\_options | Configuration block for publishing slow and application logs to CloudWatch Logs. This block can be declared multiple times, for each log\_type, within the same resource | `any` | <pre>[<br/>  {<br/>    "log_type": "INDEX_SLOW_LOGS"<br/>  },<br/>  {<br/>    "log_type": "SEARCH_SLOW_LOGS"<br/>  },<br/>  {<br/>    "log_type": "ES_APPLICATION_LOGS"<br/>  }<br/>]</pre> | no |
| name | Name to use for resource naming and tagging. | `string` | `null` | no |
| node\_to\_node\_encryption | Configuration block for node-to-node encryption options | `any` | <pre>{<br/>  "enabled": true<br/>}</pre> | no |
| off\_peak\_window\_options | Configuration to add Off Peak update options | `any` | <pre>{<br/>  "enabled": true,<br/>  "off_peak_window": {<br/>    "hours": 7<br/>  }<br/>}</pre> | no |
| opensearch\_domain\_name | Name of the opensearch domain | `string` | `null` | no |
| opensearch\_version | OpenSearch version | `string` | `"OpenSearch_2.13"` | no |
| outbound\_connections | Map of AWS OpenSearch outbound connections to create | `any` | `{}` | no |
| package\_associations | Map of package association IDs to associate with the domain | `map(string)` | `{}` | no |
| saml\_options | SAML authentication options for an AWS OpenSearch Domain | `any` | `{}` | no |
| security\_group\_description | Description of the security group created | `string` | `null` | no |
| security\_group\_name | Name to use on security group created | `string` | `null` | no |
| security\_group\_rules | Security group ingress and egress rules to add to the security group created | <pre>map(object({<br/>    type                         = optional(string, "ingress")<br/>    ip_protocol                  = optional(string, "tcp")<br/>    from_port                    = optional(number)<br/>    to_port                      = optional(number)<br/>    cidr_ipv4                    = optional(string)<br/>    cidr_ipv6                    = optional(string)<br/>    description                  = optional(string)<br/>    prefix_list_id               = optional(string)<br/>    referenced_security_group_id = optional(string)<br/>    tags                         = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| security\_group\_tags | A map of additional tags to add to the security group created | `map(string)` | `{}` | no |
| security\_group\_use\_name\_prefix | Determines whether the security group name (`security_group_name`) is used as a prefix | `bool` | `true` | no |
| snapshot\_options | Configuration block for automated daily snapshots. Note: deprecated for OpenSearch 5.3 and later which take hourly automated snapshots. Set `automated_snapshot_start_hour` (0-23) to configure | <pre>object({<br/>    automated_snapshot_start_hour = number<br/>  })</pre> | `null` | no |
| software\_update\_options | Software update options for the domain | `any` | <pre>{<br/>  "auto_software_update_enabled": false<br/>}</pre> | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| timeouts | Create and delete timeout configurations for the domain | `map(string)` | `{}` | no |
| vpc\_endpoints | Map of VPC endpoints to create for the domain | `any` | `{}` | no |
| vpc\_options | Configuration block for VPC related options. Adding or removing this configuration forces a new resource ([documentation](https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html#es-vpc-limitations)) | `any` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| cloudwatch\_logs | Map of CloudWatch log groups created and their attributes |
| domain\_arn | The Amazon Resource Name (ARN) of the domain |
| domain\_dashboard\_endpoint | Domain-specific endpoint for Dashboard without https scheme |
| domain\_dashboard\_endpoint\_v2 | V2 domain endpoint for Dashboard that works with both IPv4 and IPv6 addresses, without https scheme |
| domain\_endpoint | Domain-specific endpoint used to submit index, search, and data upload requests |
| domain\_endpoint\_v2 | V2 domain endpoint that works with both IPv4 and IPv6 addresses, used to submit index, search, and data upload requests |
| domain\_id | The unique identifier for the domain |
| outbound\_connections | Map of outbound connections created and their attributes |
| package\_associations | Map of package associations created and their attributes |
| security\_group\_arn | Amazon Resource Name (ARN) of the security group |
| security\_group\_id | ID of the security group |
| vpc\_endpoints | Map of VPC endpoints created and their attributes |
<!-- END_TF_DOCS -->

## Examples

## Basic Usage

A small OpenSearch domain with default security settings and three data nodes.

```hcl
module "opensearch" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//opensearch?depth=1&ref=master"

  enabled               = true
  name                  = "search"
  opensearch_domain_name = "search-prod"
  opensearch_version    = "OpenSearch_2.13"

  cluster_config = {
    instance_type          = "r6g.large.search"
    instance_count         = 3
    zone_awareness_enabled = true
    zone_awareness_config = {
      availability_zone_count = 3
    }
  }

  ebs_options = {
    ebs_enabled = true
    volume_size = 100
    volume_type = "gp3"
  }

  access_policy_statements = {
    allow_vpc = {
      effect  = "Allow"
      actions = ["es:ESHttp*"]
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::123456789012:role/search-app-role"]
      }]
      resource_paths = ["*"]
    }
  }

  tags = {
    Environment = "production"
    Team        = "search"
  }
}
```

## VPC-Deployed with Encryption

OpenSearch domain inside a VPC with KMS encryption and fine-grained access control.

```hcl
module "opensearch_vpc" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//opensearch?depth=1&ref=master"

  enabled               = true
  name                  = "listings-search"
  opensearch_domain_name = "listings-search-prod"
  opensearch_version    = "OpenSearch_2.13"

  cluster_config = {
    instance_type            = "r6g.xlarge.search"
    instance_count           = 3
    dedicated_master_enabled = true
    dedicated_master_type    = "r6g.large.search"
    dedicated_master_count   = 3
    zone_awareness_enabled   = true
    zone_awareness_config = {
      availability_zone_count = 3
    }
  }

  ebs_options = {
    ebs_enabled = true
    volume_size = 512
    volume_type = "gp3"
    throughput  = 250
  }

  encrypt_at_rest = {
    enabled    = true
    kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123def456789012345678901234ab"
  }

  node_to_node_encryption = {
    enabled = true
  }

  advanced_security_options = {
    enabled                        = true
    anonymous_auth_enabled         = false
    internal_user_database_enabled = false
    master_user_options = {
      master_user_arn = "arn:aws:iam::123456789012:role/opensearch-master-role"
    }
  }

  vpc_options = {
    subnet_ids = ["subnet-0aa111bbb222", "subnet-0cc333ddd444", "subnet-0ee555fff666"]
  }

  security_group_rules = {
    app_ingress = {
      type                         = "ingress"
      from_port                    = 443
      to_port                      = 443
      ip_protocol                  = "tcp"
      referenced_security_group_id = "sg-0abc123def456789a"
      description                  = "Allow HTTPS from app tier"
    }
  }

  cloudwatch_log_group_retention_in_days = 30

  tags = {
    Environment = "production"
    Team        = "search"
    DataClass   = "confidential"
  }
}
```

## With SAML Authentication

OpenSearch domain with SAML single-sign-on for Dashboards access via an IdP.

```hcl
module "opensearch_saml" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//opensearch?depth=1&ref=master"

  enabled               = true
  name                  = "analytics"
  opensearch_domain_name = "analytics-prod"
  opensearch_version    = "OpenSearch_2.13"

  cluster_config = {
    instance_type          = "m6g.large.search"
    instance_count         = 3
    zone_awareness_enabled = true
    zone_awareness_config = {
      availability_zone_count = 3
    }
  }

  ebs_options = {
    ebs_enabled = true
    volume_size = 200
    volume_type = "gp3"
  }

  advanced_security_options = {
    enabled                        = true
    anonymous_auth_enabled         = false
    internal_user_database_enabled = false
  }

  create_saml_options = true
  saml_options = {
    enabled = true
    idp = {
      entity_id        = "https://sso.example.com/saml2/entity"
      metadata_content = file("${path.module}/idp-metadata.xml")
    }
    master_backend_role     = "opensearch-admins"
    roles_key               = "roles"
    session_timeout_minutes = 60
  }

  access_policy_statements = {
    saml_access = {
      effect  = "Allow"
      actions = ["es:ESHttp*"]
      principals = [{
        type        = "AWS"
        identifiers = ["*"]
      }]
      resource_paths = ["*"]
    }
  }

  tags = {
    Environment = "production"
    Team        = "analytics"
  }
}
```

## Advanced - Multi-AZ with Dedicated Masters and AI/ML

Production-grade domain with dedicated masters, UltraWarm nodes, and AI/ML options enabled.

```hcl
module "opensearch_advanced" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//opensearch?depth=1&ref=master"

  enabled               = true
  name                  = "property-search"
  opensearch_domain_name = "property-search-prod"
  opensearch_version    = "OpenSearch_2.13"

  cluster_config = {
    instance_type            = "r6g.2xlarge.search"
    instance_count           = 6
    dedicated_master_enabled = true
    dedicated_master_type    = "r6g.large.search"
    dedicated_master_count   = 3
    zone_awareness_enabled   = true
    zone_awareness_config = {
      availability_zone_count = 3
    }
    warm_enabled = true
    warm_type    = "ultrawarm1.medium.search"
    warm_count   = 2
  }

  ebs_options = {
    ebs_enabled = true
    volume_size = 1024
    volume_type = "gp3"
    throughput  = 500
    iops        = 3000
  }

  encrypt_at_rest = {
    enabled    = true
    kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123def456789012345678901234ab"
  }

  aiml_options = {
    natural_language_query_generation_options = {
      desired_state = "ENABLED"
    }
    s3_vectors_engine = {
      enabled = true
    }
  }

  auto_tune_options = {
    desired_state       = "ENABLED"
    rollback_on_disable = "NO_ROLLBACK"
    use_off_peak_window = true
  }

  off_peak_window_options = {
    enabled = true
    off_peak_window = {
      window_start_time = {
        hours   = 2
        minutes = 0
      }
    }
  }

  vpc_options = {
    subnet_ids = ["subnet-0aa111bbb222", "subnet-0cc333ddd444", "subnet-0ee555fff666"]
  }

  cloudwatch_log_group_retention_in_days = 90

  tags = {
    Environment = "production"
    Team        = "search"
    CostCenter  = "product"
  }
}
```
