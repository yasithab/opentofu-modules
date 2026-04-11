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
- **Access and connection logs** - configure S3 bucket logging for access logs, connection logs, and health check logs
- **Deletion protection** - enabled by default to prevent accidental destruction

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
