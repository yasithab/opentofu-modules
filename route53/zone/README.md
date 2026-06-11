# Route 53 Zone

Creates public and private AWS Route 53 hosted zones with support for VPC associations, delegation sets, accelerated recovery, DNSSEC signing, and DNS query logging.

## Features

- **Public and Private Zones** - Create public hosted zones or private zones associated with one or more VPCs
- **Multiple Zones** - Provision multiple hosted zones in a single module invocation using a map-based configuration
- **Delegation Sets** - Assign reusable delegation sets to zones for consistent name server assignments
- **Multi-VPC Association** - Associate private zones with one or more VPCs for cross-VPC DNS resolution
- **Accelerated Recovery** - Optionally enable accelerated recovery for faster failover
- **Force Destroy** - Set `force_destroy = true` on a zone to allow deleting it even when it contains records (defaults to false for safety)
- **DNSSEC Signing** - Opt-in DNSSEC signing per public zone with a key signing key backed by a customer-managed KMS key
- **Query Logging** - Opt-in DNS query logging per zone, to an existing log group or a module-created one with configurable retention

## Notes

### DNSSEC

- The KMS key used for the key signing key **must be in us-east-1**, regardless of where the rest of your infrastructure runs. It must be an asymmetric, customer-managed `ECC_NIST_P256` key with `SIGN_VERIFY` usage, and its key policy must allow the Route 53 DNSSEC service principal (`dnssec-route53.amazonaws.com`) to use it.
- DNSSEC signing is only supported on **public** hosted zones (the module rejects `dnssec` on zones with VPC associations).
- After signing is enabled, add the `key_signing_key_ds_record` output value as a DS record in the parent zone/registrar to complete the chain of trust.

### Query logging

- Route 53 delivers public DNS query logs **only to CloudWatch Logs log groups in us-east-1**. Module-created log groups (named `/aws/route53/<zone name>`) are created in the provider's region, so apply this module with a us-east-1 provider when using query logging, or pass an existing us-east-1 log group via `cloudwatch_log_group_arn`.
- Delivery requires an account-wide CloudWatch Logs resource policy allowing `route53.amazonaws.com` to write to `/aws/route53/*`. Set `create_query_log_resource_policy = true` to have the module manage it, or leave it false if it is already managed elsewhere (it is a singleton per account).

## Usage

```hcl
module "zone" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/zone?depth=1&ref=master"

  zones = {
    "example.com" = {
      comment = "Production public zone"
    }
    "internal.example.com" = {
      comment = "Private zone"
      vpc = {
        vpc_id     = "vpc-0123456789abcdef0"
        vpc_region = "us-east-1"
      }
    }
  }

  tags = {
    Environment = "production"
  }
}
```

## Examples

## Basic Public Hosted Zone

Create a public Route53 hosted zone for an internet-facing domain.

```hcl
module "zone_public" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/zone?depth=1&ref=master"

  enabled = true

  zones = {
    "example.com" = {
      comment = "Public zone managed by Terraform"
    }
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Private Hosted Zone Attached to a VPC

Create a private hosted zone for internal service discovery, visible only within the specified VPC.

```hcl
module "zone_private" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/zone?depth=1&ref=master"

  enabled = true

  zones = {
    "internal.example.com" = {
      comment = "Private zone for VPC internal resolution"
      vpc = {
        vpc_id     = "vpc-0abc123456def7890"
        vpc_region = "eu-west-1"
      }
    }
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Multiple Zones with Delegation Set

Create several public zones that share the same set of name servers using a reusable delegation set - useful for maintaining consistent NS records across domains.

```hcl
module "zones_multi" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/zone?depth=1&ref=master"

  enabled = true

  zones = {
    "example.com" = {
      comment           = "Primary domain"
      delegation_set_id = "N0123456789ABCDEFGHIJ"
    }
    "example.io" = {
      comment           = "Alternative TLD"
      delegation_set_id = "N0123456789ABCDEFGHIJ"
    }
    "example.co.uk" = {
      comment           = "UK regional domain"
      delegation_set_id = "N0123456789ABCDEFGHIJ"
    }
  }

  tags = {
    Environment = "production"
    ManagedBy   = "platform-team"
  }
}
```

## Private Zone with Multiple VPCs

Associate a private hosted zone with multiple VPCs so that resources across both VPCs can resolve the same internal domain.

```hcl
module "zone_multi_vpc" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/zone?depth=1&ref=master"

  enabled = true

  zones = {
    "services.internal" = {
      comment = "Shared internal zone for multi-VPC resolution"
      vpc = [
        {
          vpc_id     = "vpc-0abc123456def7890"
          vpc_region = "eu-west-1"
        },
        {
          vpc_id     = "vpc-0def987654321fedcb"
          vpc_region = "eu-west-1"
        },
      ]
    }
  }

  tags = {
    Environment = "production"
    Team        = "networking"
  }
}
```

## DNSSEC-Signed Public Zone

Enable DNSSEC signing for a public zone. The DS record output is then registered with the parent zone or domain registrar.

```hcl
# KMS key for the key signing key - must be in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

resource "aws_kms_key" "dnssec" {
  provider = aws.us_east_1

  description              = "Route 53 DNSSEC key signing key"
  customer_master_key_spec = "ECC_NIST_P256"
  key_usage                = "SIGN_VERIFY"
  deletion_window_in_days  = 7

  policy = data.aws_iam_policy_document.dnssec_kms.json # must allow dnssec-route53.amazonaws.com
}

module "zone_signed" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/zone?depth=1&ref=master"

  zones = {
    "example.com" = {
      comment = "DNSSEC-signed public zone"
      dnssec = {
        kms_key_arn = aws_kms_key.dnssec.arn
      }
    }
  }

  tags = {
    Environment = "production"
  }
}

# Register this DS record with the parent zone / registrar to complete the chain of trust
output "ds_record" {
  value = module.zone_signed.key_signing_key_ds_record["example.com"]
}
```

## Zone with DNS Query Logging

Log DNS queries to a module-created CloudWatch log group. Route 53 only delivers query logs to log groups in us-east-1, so apply with a us-east-1 provider.

```hcl
module "zone_logged" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/zone?depth=1&ref=master"

  zones = {
    "example.com" = {
      comment = "Public zone with query logging"
      query_logging = {
        log_group_retention_in_days = 90
      }
    }

    # Or deliver to an existing us-east-1 log group
    "example.io" = {
      query_logging = {
        cloudwatch_log_group_arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/route53/example.io"
      }
    }
  }

  # Account-wide resource policy allowing Route 53 to write query logs.
  # Leave false if already managed elsewhere.
  create_query_log_resource_policy = true

  tags = {
    Environment = "production"
  }
}
```

## Reference

<details>
<summary>Requirements, providers, inputs and outputs (generated by terraform-docs)</summary>

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
| create\_query\_log\_resource\_policy | Whether to create the account-wide CloudWatch Logs resource policy that allows Route 53 to deliver query logs to /aws/route53/* log groups. Required once per account - leave false if it is already managed elsewhere. | `bool` | `false` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| query\_log\_resource\_policy\_name | Name of the CloudWatch Logs resource policy created when create\_query\_log\_resource\_policy is true. | `string` | `"route53-query-logging"` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| zones | Map of Route53 zone parameters. Set `dnssec` to enable DNSSEC signing for a public zone<br/>(the KMS key must be an asymmetric ECC\_NIST\_P256 customer-managed key in us-east-1).<br/>Set `query_logging` to enable DNS query logging - either supply an existing log group ARN<br/>or let the module create one (log groups for Route 53 query logging must be in us-east-1). | <pre>map(object({<br/>    domain_name                 = optional(string)<br/>    comment                     = optional(string)<br/>    force_destroy               = optional(bool, false)<br/>    enable_accelerated_recovery = optional(bool)<br/>    delegation_set_id           = optional(string)<br/>    vpc = optional(list(object({<br/>      vpc_id     = string<br/>      vpc_region = optional(string)<br/>    })), [])<br/>    dnssec = optional(object({<br/>      kms_key_arn            = string<br/>      key_signing_key_name   = optional(string)<br/>      key_signing_key_status = optional(string, "ACTIVE")<br/>      signing_status         = optional(string, "SIGNING")<br/>    }))<br/>    query_logging = optional(object({<br/>      cloudwatch_log_group_arn    = optional(string)<br/>      log_group_retention_in_days = optional(number, 30)<br/>      log_group_kms_key_id        = optional(string)<br/>    }))<br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| dnssec\_signing\_status | Map of zone keys to the DNSSEC signing status of the hosted zone |
| key\_signing\_key\_ds\_record | Map of zone keys to the DS record to add to the parent zone to establish the DNSSEC chain of trust |
| key\_signing\_key\_public\_key | Map of zone keys to the key signing key public key |
| key\_signing\_key\_tag | Map of zone keys to the key signing key tag |
| name\_servers | Name servers of Route53 zone |
| query\_log\_group\_arns | Map of zone keys to the ARNs of module-created query log CloudWatch log groups |
| query\_log\_ids | Map of zone keys to the Route53 query log configuration IDs |
| static\_zone\_name | Name of Route53 zone created statically to avoid invalid count argument error when creating records and zones simmultaneously |
| zone\_arn | Zone ARN of Route53 zone |
| zone\_id | Zone ID of Route53 zone |
| zone\_name | Name of Route53 zone |
<!-- END_TF_DOCS -->

</details>
