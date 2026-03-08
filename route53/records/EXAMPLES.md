# Route53 Records Module - Examples

## Basic Usage

Create simple A and CNAME records for a public hosted zone by name.

```hcl
module "records" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/records?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/records?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/records?depth=1&ref=v2.0.0"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//route53/records?depth=1&ref=v2.0.0"

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
