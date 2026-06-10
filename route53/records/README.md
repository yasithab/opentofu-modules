# Route 53 Records

Manages AWS Route 53 DNS records with support for multiple routing policies, alias records, and health checks.

## Features

- **Multiple Record Types** - Supports A, AAAA, CNAME, MX, TXT, NS, SRV, and all other Route 53 record types
- **Alias Records** - Create alias records pointing to AWS resources such as load balancers, CloudFront distributions, and S3 buckets
- **Routing Policies** - Supports failover, latency-based, weighted, geolocation, geoproximity, CIDR-based, and multivalue answer routing policies
- **Health Checks** - Create and attach Route 53 health checks with HTTP, HTTPS, TCP, CloudWatch, and calculated check types
- **Zone Lookup** - Reference zones by ID or by domain name with automatic lookup
- **Private Zone Support** - Target records in both public and private hosted zones
- **Terragrunt Compatible** - Accepts records as JSON-encoded strings for use with Terragrunt

## Usage

```hcl
module "records" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/records?depth=1&ref=master"

  zone_name = "example.com"

  records = [
    {
      name    = "api"
      type    = "A"
      ttl     = 300
      records = ["203.0.113.10"]
    },
  ]

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
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| health\_checks | Map of Route53 health checks to create | <pre>map(object({<br/>    type                            = string<br/>    fqdn                            = optional(string)<br/>    ip_address                      = optional(string)<br/>    port                            = optional(number)<br/>    resource_path                   = optional(string)<br/>    failure_threshold               = optional(number, 3)<br/>    request_interval                = optional(number, 30)<br/>    regions                         = optional(list(string))<br/>    measure_latency                 = optional(bool, false)<br/>    invert_healthcheck              = optional(bool, false)<br/>    disabled                        = optional(bool, false)<br/>    enable_sni                      = optional(bool)<br/>    reference_name                  = optional(string)<br/>    child_health_threshold          = optional(number)<br/>    child_healthchecks              = optional(list(string))<br/>    cloudwatch_alarm_name           = optional(string)<br/>    cloudwatch_alarm_region         = optional(string)<br/>    insufficient_data_health_status = optional(string)<br/>    search_string                   = optional(string)<br/>    routing_control_arn             = optional(string)<br/>    triggers                        = optional(map(string))<br/>    tags                            = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| private\_zone | Whether Route53 zone is private or public | `bool` | `false` | no |
| records | List of objects of DNS records | <pre>list(object({<br/>    key                              = optional(string)<br/>    name                             = string<br/>    type                             = string<br/>    ttl                              = optional(number)<br/>    records                          = optional(list(string))<br/>    set_identifier                   = optional(string)<br/>    health_check_id                  = optional(string)<br/>    multivalue_answer_routing_policy = optional(bool)<br/>    allow_overwrite                  = optional(bool, false)<br/>    full_name_override               = optional(bool, false)<br/>    alias = optional(object({<br/>      name                   = string<br/>      zone_id                = optional(string)<br/>      evaluate_target_health = optional(bool, false)<br/>    }))<br/>    failover_routing_policy = optional(object({<br/>      type = string<br/>    }))<br/>    latency_routing_policy = optional(object({<br/>      region = string<br/>    }))<br/>    weighted_routing_policy = optional(object({<br/>      weight = number<br/>    }))<br/>    cidr_routing_policy = optional(object({<br/>      collection_id = string<br/>      location_name = string<br/>    }))<br/>    geolocation_routing_policy = optional(object({<br/>      continent   = optional(string)<br/>      country     = optional(string)<br/>      subdivision = optional(string)<br/>    }))<br/>    geoproximity_routing_policy = optional(object({<br/>      aws_region       = optional(string)<br/>      bias             = optional(number)<br/>      local_zone_group = optional(string)<br/>      coordinates = optional(object({<br/>        latitude  = string<br/>        longitude = string<br/>      }))<br/>    }))<br/>  }))</pre> | `[]` | no |
| records\_jsonencoded | List of map of DNS records (stored as jsonencoded string, for terragrunt) | `string` | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| zone\_id | ID of DNS zone | `string` | `null` | no |
| zone\_name | Name of DNS zone | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| health\_check\_arns | Map of health check names to their ARNs |
| health\_check\_ids | Map of health check names to their IDs |
| record\_fqdn | FQDN built using the zone domain and name |
| record\_name | The name of the record |
<!-- END_TF_DOCS -->

## Examples

## Basic Usage

Create simple A and CNAME records for a public hosted zone by name.

```hcl
module "records" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/records?depth=1&ref=master"

  enabled   = true
  zone_name = "example.com"

  records = [
    {
      name    = "api"
      type    = "A"
      ttl     = 300
      records = ["203.0.113.10"]
    },
    {
      name    = "www"
      type    = "CNAME"
      ttl     = 300
      records = ["api.example.com"]
    },
  ]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Alias Record Pointing to a Load Balancer

Route traffic to an ALB using an alias record, which avoids TTL limitations and is free of charge.

```hcl
module "records_alias" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/records?depth=1&ref=master"

  enabled  = true
  zone_id  = "Z0123456789ABCDEFGHIJ"

  records = [
    {
      name = "app"
      type = "A"
      alias = {
        name                   = "my-alb-1234567890.eu-west-1.elb.amazonaws.com"
        zone_id                = "Z32O12XQLNTSW2"
        evaluate_target_health = true
      }
    },
  ]

  tags = {
    Environment = "production"
  }
}
```

## Weighted Routing Policy

Split traffic between two backend targets using weighted routing - useful for canary deployments or A/B testing.

```hcl
module "records_weighted" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/records?depth=1&ref=master"

  enabled   = true
  zone_name = "example.com"

  records = [
    {
      name           = "service"
      type           = "A"
      set_identifier = "primary"
      ttl            = 60
      records        = ["10.0.1.10"]
      weighted_routing_policy = {
        weight = 90
      }
    },
    {
      name           = "service"
      type           = "A"
      set_identifier = "canary"
      ttl            = 60
      records        = ["10.0.2.10"]
      weighted_routing_policy = {
        weight = 10
      }
    },
  ]

  tags = {
    Environment = "production"
    Strategy    = "canary"
  }
}
```

## With Health Checks

Create HTTP health checks alongside records to enable DNS failover.

```hcl
module "records_with_health_checks" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/records?depth=1&ref=master"

  enabled   = true
  zone_name = "example.com"

  health_checks = {
    api_primary = {
      type              = "HTTPS"
      fqdn              = "api-primary.example.com"
      port              = 443
      resource_path     = "/health"
      failure_threshold = 3
      request_interval  = 30
      enable_sni        = true
      tags = {
        Name = "api-primary-health-check"
      }
    }
  }

  records = [
    {
      name           = "api"
      type           = "A"
      set_identifier = "primary"
      ttl            = 60
      records        = ["203.0.113.10"]
      failover_routing_policy = {
        type = "PRIMARY"
      }
    },
  ]

  tags = {
    Environment = "production"
  }
}
```
