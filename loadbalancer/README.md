# Load Balancer

OpenTofu module for creating and managing AWS Elastic Load Balancers (ALB, NLB, and GWLB) with integrated listeners, target groups, security groups, Route53 records, WAF association, and mTLS trust stores.

## Features

- **All load balancer types** - Application (ALB), Network (NLB), and Gateway (GWLB) load balancers
- **Listeners and rules** - flexible listener configuration with support for forward, redirect, fixed-response, and weighted target group actions
- **Target groups** - instance, IP, Lambda, and ALB target types with configurable health checks and stickiness
- **Security group management** - optionally create a security group with custom ingress and egress rules
- **Route53 DNS records** - automatically create alias records pointing to the load balancer
- **WAF integration** - associate a WAFv2 Web ACL with the load balancer
- **mTLS trust stores** - create trust stores and revocations for mutual TLS authentication on ALBs
- **Access and connection logs** - configure S3 bucket logging for access logs, connection logs, and health check logs (strongly recommended for production load balancers)
- **Deletion protection** - enabled by default to prevent accidental destruction

> [!NOTE]
> Behavioral and security notes:
>
> - `internal` defaults to `true` — load balancers are private unless you explicitly set `internal = false`.
> - Additional listener certificates (`additional_certificate_arns`) are addressed by certificate ARN (`aws_lb_listener_certificate.additional["<listener_key>/<cert_arn>"]`), so adding or removing a certificate mid-list does not detach and reattach the remaining ones. Certificate ARNs must be known at plan time.
> - The `listeners` and `listener_rules` outputs are marked `sensitive = true` because listener actions can carry OIDC client secrets. Downstream usage in non-sensitive contexts must be wrapped accordingly.
> - `listeners`, `target_groups`, and `additional_target_group_attachments` are fully typed (`map(object)` with `optional()` attributes); unknown attributes are rejected. See `variables.tf` for the complete schemas. Each listener must define **exactly one** default action key (`forward`, `weighted_forward`, `redirect`, `fixed_response`, `authenticate_cognito`, `authenticate_oidc`, or `jwt_validation`).
> - Inline OIDC `client_secret` values inside `listeners` (default actions or rule actions) are **rejected** with a validation error. OIDC client secrets must be supplied via the sensitive `listener_auth_oidc_client_secrets` map, and every `authenticate-oidc` action must have a matching entry (validated at plan time).
> - Route53 alias records support a per-record `evaluate_target_health` override (defaults to `true`).

### OIDC client secrets

OIDC client secrets are provided exclusively via the `listener_auth_oidc_client_secrets` variable — a `sensitive` map keyed by listener key (default actions) or `<listener_key>/<rule_key>` (rule actions). Inline `client_secret` values inside `listeners` are rejected at plan time so secrets never appear in non-sensitive plan output:

```hcl
module "alb" {
  # ...

  listeners = {
    https = {
      port     = 443
      protocol = "HTTPS"
      authenticate_oidc = {
        authorization_endpoint = "https://idp.example.com/authorize"
        client_id              = "my-client"
        issuer                 = "https://idp.example.com"
        token_endpoint         = "https://idp.example.com/token"
        user_info_endpoint     = "https://idp.example.com/userinfo"
        # inline client_secret is rejected - use listener_auth_oidc_client_secrets
      }
      rules = {
        admin = {
          priority = 10
          actions = [
            {
              type                   = "authenticate-oidc"
              authorization_endpoint = "https://idp.example.com/authorize"
              client_id              = "my-client"
              issuer                 = "https://idp.example.com"
              token_endpoint         = "https://idp.example.com/token"
              user_info_endpoint     = "https://idp.example.com/userinfo"
            },
            { type = "forward", target_group_key = "app" }
          ]
          conditions = [{ path_pattern = { values = ["/admin/*"] } }]
        }
      }
    }
  }

  listener_auth_oidc_client_secrets = {
    "https"       = var.oidc_client_secret # listener default action
    "https/admin" = var.oidc_client_secret # listener rule action
  }
}
```

## Usage

```hcl
module "alb" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//loadbalancer?depth=1&ref=master"

  name               = "api-alb"
  load_balancer_type = "application"
  vpc_id             = "vpc-0abc123"
  subnets            = ["subnet-0aa111", "subnet-0bb222"]

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward  = { target_group_key = "api" }
    }
  }

  target_groups = {
    api = {
      name        = "api-tg"
      target_type = "instance"
      port        = 80
      protocol    = "HTTP"
      target_id   = "i-0abc123"
    }
  }

  tags = {
    Environment = "production"
  }
}
```


## Examples

## Basic Usage

An internet-facing Application Load Balancer with HTTP listener forwarding to an EC2 target group.

```hcl
module "alb" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//loadbalancer?depth=1&ref=master"

  enabled            = true
  name               = "api-alb"
  load_balancer_type = "application"
  internal           = false
  vpc_id             = "vpc-0abc123def456789"
  subnets            = ["subnet-0aa111bbb222", "subnet-0cc333ddd444"]

  security_group_ingress_rules = {
    http_public = {
      from_port  = 80
      to_port    = 80
      ip_protocol = "tcp"
      cidr_ipv4  = "0.0.0.0/0"
      description = "Allow HTTP from internet"
    }
  }

  security_group_egress_rules = {
    all_outbound = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "api_servers"
      }
    }
  }

  target_groups = {
    api_servers = {
      name        = "api-servers"
      target_type = "instance"
      port        = 80
      protocol    = "HTTP"
      target_id   = "i-0abc123def456789a"
      health_check = {
        path                = "/health"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        interval            = 30
      }
    }
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## With HTTPS and Redirect

HTTPS ALB with TLS termination, an HTTP-to-HTTPS redirect listener, and ACM certificate.

```hcl
module "alb_https" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//loadbalancer?depth=1&ref=master"

  enabled            = true
  name               = "web-alb"
  load_balancer_type = "application"
  internal           = false
  vpc_id             = "vpc-0abc123def456789"
  subnets            = ["subnet-0aa111bbb222", "subnet-0cc333ddd444"]

  security_group_ingress_rules = {
    http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
    https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  security_group_egress_rules = {
    all_outbound = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  listeners = {
    http_redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc12345-1234-1234-1234-abc123456789"
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
      forward = {
        target_group_key = "web_servers"
      }
    }
  }

  target_groups = {
    web_servers = {
      name        = "web-servers"
      target_type = "instance"
      port        = 8080
      protocol    = "HTTP"
      target_id   = "i-0def456abc789012b"
      health_check = {
        path     = "/health"
        matcher  = "200-299"
        interval = 15
        timeout  = 5
      }
    }
  }

  route53_records = {
    api = {
      zone_id = "Z1234567890ABCDEFGHIJ"
      name    = "api.example.com"
      type    = "A"
    }
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Internal NLB for Microservices

Internal Network Load Balancer for service-to-service traffic within a VPC.

```hcl
module "nlb_internal" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//loadbalancer?depth=1&ref=master"

  enabled                   = true
  name                      = "services-nlb"
  load_balancer_type        = "network"
  internal                  = true
  vpc_id                    = "vpc-0abc123def456789"
  subnets                   = ["subnet-0aa111bbb222", "subnet-0cc333ddd444"]
  create_security_group     = false
  enable_deletion_protection = true
  enable_cross_zone_load_balancing = true

  listeners = {
    tcp = {
      port     = 5432
      protocol = "TCP"
      forward = {
        target_group_key = "postgres"
      }
    }
  }

  target_groups = {
    postgres = {
      name        = "postgres-tg"
      target_type = "instance"
      port        = 5432
      protocol    = "TCP"
      target_id   = "i-0abc123def456789c"
      health_check = {
        protocol = "TCP"
        interval = 10
      }
    }
  }

  tags = {
    Environment = "production"
    Team        = "data"
  }
}
```

## ALB with WAF and Access Logs

Production ALB with WAF association, S3 access logging, and mTLS trust store.

```hcl
module "alb_production" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//loadbalancer?depth=1&ref=master"

  enabled            = true
  name               = "prod-alb"
  load_balancer_type = "application"
  internal           = false
  vpc_id             = "vpc-0abc123def456789"
  subnets            = ["subnet-0aa111bbb222", "subnet-0cc333ddd444", "subnet-0ee555fff666"]

  access_logs = {
    bucket  = "my-alb-access-logs-123456789012"
    prefix  = "prod-alb"
    enabled = true
  }

  connection_logs = {
    bucket  = "my-alb-access-logs-123456789012"
    prefix  = "prod-alb-connections"
    enabled = true
  }

  associate_web_acl = true
  web_acl_arn       = "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/prod-waf/abc12345-1234-1234-1234-abc123456789"

  enable_deletion_protection = true
  idle_timeout               = 60

  security_group_ingress_rules = {
    https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  security_group_egress_rules = {
    all_outbound = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  listeners = {
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc12345-1234-1234-1234-abc123456789"
      forward = {
        target_group_key = "app"
      }
    }
  }

  target_groups = {
    app = {
      name        = "prod-app"
      target_type = "instance"
      port        = 8080
      protocol    = "HTTP"
      target_id   = "i-0aaa111bbb222333c"
      health_check = {
        path                = "/health"
        matcher             = "200"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        interval            = 30
        timeout             = 5
      }
    }
  }

  tags = {
    Environment = "production"
    Team        = "platform"
    CostCenter  = "engineering"
  }
}
```
