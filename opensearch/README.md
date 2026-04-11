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
