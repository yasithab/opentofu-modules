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
| access\_logs | Map containing access logging configuration for load balancer | `map(string)` | `{}` | no |
| additional\_target\_group\_attachments | Map of additional target group attachments to create. Use `target_group_key` to attach to the target group created in `target_groups` | <pre>map(object({<br/>    target_group_key  = string<br/>    target_id         = string<br/>    port              = optional(number)<br/>    target_type       = optional(string)<br/>    availability_zone = optional(string)<br/>    quic_server_id    = optional(string)<br/>  }))</pre> | `{}` | no |
| associate\_web\_acl | Indicates whether a Web Application Firewall (WAF) ACL should be associated with the load balancer | `bool` | `false` | no |
| client\_keep\_alive | Client keep alive value in seconds. The valid range is 60-604800 seconds. The default is 3600 seconds. | `number` | `null` | no |
| connection\_logs | Map containing connection logging configuration for load balancer (ALB only) | `map(string)` | `{}` | no |
| create\_security\_group | Determines if a security group is created | `bool` | `true` | no |
| customer\_owned\_ipv4\_pool | The ID of the customer owned ipv4 pool to use for this load balancer | `string` | `null` | no |
| default\_port | Default port used across the listener and target group | `number` | `80` | no |
| default\_protocol | Default protocol used across the listener and target group | `string` | `"HTTP"` | no |
| desync\_mitigation\_mode | Determines how the load balancer handles requests that might pose a security risk to an application due to HTTP desync. Valid values are `monitor`, `defensive` (default), `strictest` | `string` | `null` | no |
| dns\_record\_client\_routing\_policy | Indicates how traffic is distributed among the load balancer Availability Zones. Possible values are any\_availability\_zone (default), availability\_zone\_affinity, or partial\_availability\_zone\_affinity. Only valid for network type load balancers. | `string` | `null` | no |
| drop\_invalid\_header\_fields | Indicates whether HTTP headers with header fields that are not valid are removed by the load balancer (`true`) or routed to targets (`false`). The default is `true`. Elastic Load Balancing requires that message header names contain only alphanumeric characters and hyphens. Only valid for Load Balancers of type `application` | `bool` | `true` | no |
| enable\_cross\_zone\_load\_balancing | If `true`, cross-zone load balancing of the load balancer will be enabled. For application load balancer this feature is always enabled (`true`) and cannot be disabled. Defaults to `true` | `bool` | `true` | no |
| enable\_deletion\_protection | If `true`, deletion of the load balancer will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer. Defaults to `true` | `bool` | `true` | no |
| enable\_http2 | Indicates whether HTTP/2 is enabled in application load balancers. Defaults to `true` | `bool` | `null` | no |
| enable\_tls\_version\_and\_cipher\_suite\_headers | Indicates whether the two headers (`x-amzn-tls-version` and `x-amzn-tls-cipher-suite`), which contain information about the negotiated TLS version and cipher suite, are added to the client request before sending it to the target. Only valid for Load Balancers of type `application`. Defaults to `false` | `bool` | `null` | no |
| enable\_waf\_fail\_open | Indicates whether to allow a WAF-enabled load balancer to route requests to targets if it is unable to forward the request to AWS WAF. Defaults to `false` | `bool` | `null` | no |
| enable\_xff\_client\_port | Indicates whether the X-Forwarded-For header should preserve the source port that the client used to connect to the load balancer in `application` load balancers. Defaults to `false` | `bool` | `null` | no |
| enable\_zonal\_shift | Indicates whether zonal shift is enabled for the load balancer. Only valid for load balancers of type application or network. | `bool` | `null` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| enforce\_security\_group\_inbound\_rules\_on\_private\_link\_traffic | Indicates whether inbound security group rules are enforced for traffic originating from a PrivateLink. Only valid for Load Balancers of type network. The possible values are on and off. | `string` | `null` | no |
| health\_check\_logs | Map containing health check logging configuration for load balancer (ALB only). Requires `bucket`, optional `enabled` and `prefix` | `map(string)` | `{}` | no |
| idle\_timeout | The time in seconds that the connection is allowed to be idle. Only valid for Load Balancers of type `application`. Default: `60` | `number` | `null` | no |
| internal | If true, the LB will be internal. Defaults to `true` so load balancers are not internet-facing unless explicitly requested; set to `false` for a public load balancer | `bool` | `true` | no |
| ip\_address\_type | The type of IP addresses used by the subnets for your load balancer. Possible values are `ipv4`, `dualstack`, and `dualstack-without-public-ipv4` | `string` | `null` | no |
| ipam\_pools | Map containing IPAM pool configuration for load balancer (ALB only). Requires `ipv4_ipam_pool_id` | `map(string)` | `{}` | no |
| listener\_auth\_oidc\_client\_secrets | Map of OIDC client secrets for `authenticate-oidc` actions, keyed by listener key (for listener default actions) or `<listener_key>/<rule_key>` (for listener rule actions). This is the only way to supply OIDC client secrets - inline `client_secret` values in `listeners` are rejected. Every `authenticate-oidc` action must have a matching entry here | `map(string)` | `{}` | no |
| listeners | Map of listener configurations to create. Each listener defines exactly one default action (`forward`, `weighted_forward`, `redirect`, `fixed_response`, `authenticate_cognito`, `authenticate_oidc`, or `jwt_validation`) and an optional map of `rules`. OIDC client secrets must be provided via `listener_auth_oidc_client_secrets` - inline `client_secret` values are rejected | <pre>map(object({<br/>    alpn_policy                 = optional(string)<br/>    certificate_arn             = optional(string)<br/>    additional_certificate_arns = optional(list(string), [])<br/>    port                        = optional(number)<br/>    protocol                    = optional(string)<br/>    ssl_policy                  = optional(string)<br/>    tcp_idle_timeout_seconds    = optional(number)<br/>    tags                        = optional(map(string), {})<br/><br/>    # Default action - exactly one of the following must be set<br/>    forward = optional(object({<br/>      arn              = optional(string)<br/>      target_group_key = optional(string)<br/>      order            = optional(number)<br/>    }))<br/>    weighted_forward = optional(object({<br/>      target_groups = list(object({<br/>        arn              = optional(string)<br/>        target_group_key = optional(string)<br/>        weight           = optional(number)<br/>      }))<br/>      stickiness = optional(object({<br/>        duration = optional(number, 60)<br/>        enabled  = optional(bool)<br/>      }))<br/>      order = optional(number)<br/>    }))<br/>    redirect = optional(object({<br/>      host        = optional(string)<br/>      path        = optional(string)<br/>      port        = optional(string)<br/>      protocol    = optional(string)<br/>      query       = optional(string)<br/>      status_code = string<br/>      order       = optional(number)<br/>    }))<br/>    fixed_response = optional(object({<br/>      content_type = string<br/>      message_body = optional(string)<br/>      status_code  = optional(string)<br/>      order        = optional(number)<br/>    }))<br/>    authenticate_cognito = optional(object({<br/>      authentication_request_extra_params = optional(map(string))<br/>      on_unauthenticated_request          = optional(string)<br/>      scope                               = optional(string)<br/>      session_cookie_name                 = optional(string)<br/>      session_timeout                     = optional(number)<br/>      user_pool_arn                       = string<br/>      user_pool_client_id                 = string<br/>      user_pool_domain                    = string<br/>      order                               = optional(number)<br/>    }))<br/>    authenticate_oidc = optional(object({<br/>      authentication_request_extra_params = optional(map(string))<br/>      authorization_endpoint              = string<br/>      client_id                           = string<br/>      client_secret                       = optional(string) # rejected by validation - use listener_auth_oidc_client_secrets<br/>      issuer                              = string<br/>      on_unauthenticated_request          = optional(string)<br/>      scope                               = optional(string)<br/>      session_cookie_name                 = optional(string)<br/>      session_timeout                     = optional(number)<br/>      token_endpoint                      = string<br/>      user_info_endpoint                  = string<br/>      order                               = optional(number)<br/>    }))<br/>    jwt_validation = optional(object({<br/>      issuer        = string<br/>      jwks_endpoint = string<br/>      additional_claims = optional(list(object({<br/>        format = string<br/>        name   = string<br/>        values = list(string)<br/>      })), [])<br/>      order = optional(number)<br/>    }))<br/><br/>    mutual_authentication = optional(object({<br/>      mode                             = string<br/>      trust_store_arn                  = optional(string)<br/>      trust_store_key                  = optional(string)<br/>      advertise_trust_store_ca_names   = optional(string)<br/>      ignore_client_certificate_expiry = optional(bool)<br/>    }))<br/><br/>    routing_http_request_x_amzn_mtls_clientcert_header_name               = optional(string)<br/>    routing_http_request_x_amzn_mtls_clientcert_issuer_header_name        = optional(string)<br/>    routing_http_request_x_amzn_mtls_clientcert_leaf_header_name          = optional(string)<br/>    routing_http_request_x_amzn_mtls_clientcert_serial_number_header_name = optional(string)<br/>    routing_http_request_x_amzn_mtls_clientcert_subject_header_name       = optional(string)<br/>    routing_http_request_x_amzn_mtls_clientcert_validity_header_name      = optional(string)<br/>    routing_http_request_x_amzn_tls_cipher_suite_header_name              = optional(string)<br/>    routing_http_request_x_amzn_tls_version_header_name                   = optional(string)<br/>    routing_http_response_access_control_allow_credentials_header_value   = optional(string)<br/>    routing_http_response_access_control_allow_headers_header_value       = optional(string)<br/>    routing_http_response_access_control_allow_methods_header_value       = optional(string)<br/>    routing_http_response_access_control_allow_origin_header_value        = optional(string)<br/>    routing_http_response_access_control_expose_headers_header_value      = optional(string)<br/>    routing_http_response_access_control_max_age_header_value             = optional(string)<br/>    routing_http_response_content_security_policy_header_value            = optional(string)<br/>    routing_http_response_server_enabled                                  = optional(bool)<br/>    routing_http_response_strict_transport_security_header_value          = optional(string)<br/>    routing_http_response_x_content_type_options_header_value             = optional(string)<br/>    routing_http_response_x_frame_options_header_value                    = optional(string)<br/><br/>    rules = optional(map(object({<br/>      listener_arn = optional(string)<br/>      priority     = optional(number)<br/>      tags         = optional(map(string), {})<br/><br/>      actions = list(object({<br/>        type  = string<br/>        order = optional(number)<br/><br/>        # forward<br/>        target_group_arn = optional(string)<br/>        target_group_key = optional(string)<br/><br/>        # weighted-forward<br/>        target_groups = optional(list(object({<br/>          arn              = optional(string)<br/>          target_group_key = optional(string)<br/>          weight           = optional(number)<br/>        })))<br/>        stickiness = optional(object({<br/>          duration = optional(number, 60)<br/>          enabled  = optional(bool)<br/>        }))<br/><br/>        # redirect<br/>        host        = optional(string)<br/>        path        = optional(string)<br/>        port        = optional(string)<br/>        protocol    = optional(string)<br/>        query       = optional(string)<br/>        status_code = optional(string)<br/><br/>        # fixed-response<br/>        content_type = optional(string)<br/>        message_body = optional(string)<br/><br/>        # authenticate-cognito<br/>        authentication_request_extra_params = optional(map(string))<br/>        on_unauthenticated_request          = optional(string)<br/>        scope                               = optional(string)<br/>        session_cookie_name                 = optional(string)<br/>        session_timeout                     = optional(number)<br/>        user_pool_arn                       = optional(string)<br/>        user_pool_client_id                 = optional(string)<br/>        user_pool_domain                    = optional(string)<br/><br/>        # authenticate-oidc<br/>        authorization_endpoint = optional(string)<br/>        client_id              = optional(string)<br/>        client_secret          = optional(string) # rejected by validation - use listener_auth_oidc_client_secrets<br/>        issuer                 = optional(string)<br/>        token_endpoint         = optional(string)<br/>        user_info_endpoint     = optional(string)<br/><br/>        # jwt-validation<br/>        jwks_endpoint = optional(string)<br/>        additional_claims = optional(list(object({<br/>          format = string<br/>          name   = string<br/>          values = list(string)<br/>        })))<br/>      }))<br/><br/>      conditions = optional(list(object({<br/>        host_header = optional(object({<br/>          values       = optional(list(string))<br/>          regex_values = optional(list(string))<br/>        }))<br/>        http_header = optional(object({<br/>          http_header_name = string<br/>          values           = optional(list(string))<br/>          regex_values     = optional(list(string))<br/>        }))<br/>        http_request_method = optional(object({<br/>          values = list(string)<br/>        }))<br/>        path_pattern = optional(object({<br/>          values       = optional(list(string))<br/>          regex_values = optional(list(string))<br/>        }))<br/>        query_string = optional(object({<br/>          key   = optional(string)<br/>          value = string<br/>        }))<br/>        source_ip = optional(object({<br/>          values = list(string)<br/>        }))<br/>      })), [])<br/><br/>      transforms = optional(list(object({<br/>        type = string<br/>        url_rewrite_config = optional(object({<br/>          rewrite = optional(object({<br/>            regex   = string<br/>            replace = string<br/>          }))<br/>        }))<br/>        host_header_rewrite_config = optional(object({<br/>          rewrite = optional(object({<br/>            regex   = string<br/>            replace = string<br/>          }))<br/>        }))<br/>      })), [])<br/>    })), {})<br/>  }))</pre> | `{}` | no |
| load\_balancer\_type | The type of load balancer to create. Possible values are `application`, `gateway`, or `network`. The default value is `application` | `string` | `"application"` | no |
| minimum\_load\_balancer\_capacity | Pre-warm capacity for the load balancer. Requires `capacity_units` (number). Billing applies during the pre-warming period | `any` | `{}` | no |
| name | Name to use for resource naming and tagging. | `string` | `null` | no |
| name\_prefix | Creates a unique name beginning with the specified prefix. Conflicts with `name` | `string` | `null` | no |
| preserve\_host\_header | Indicates whether the Application Load Balancer should preserve the Host header in the HTTP request and send it to the target without any change. Defaults to `false` | `bool` | `null` | no |
| route53\_records | Map of Route53 records to create. Each record map should contain `zone_id`, `name`, and `type` | `any` | `{}` | no |
| secondary\_ips\_auto\_assigned\_per\_subnet | Number of secondary private IPv4 addresses to automatically assign to each NLB network interface. Valid values are 0-7. NLB only | `number` | `null` | no |
| security\_group\_description | Description of the security group created | `string` | `null` | no |
| security\_group\_egress\_rules | Security group egress rules to add to the security group created | `any` | `{}` | no |
| security\_group\_ingress\_rules | Security group ingress rules to add to the security group created | `any` | `{}` | no |
| security\_group\_name | Name to use on security group created | `string` | `null` | no |
| security\_group\_tags | A map of additional tags to add to the security group created | `map(string)` | `{}` | no |
| security\_group\_use\_name\_prefix | Determines whether the security group name (`security_group_name`) is used as a prefix | `bool` | `true` | no |
| security\_groups | A list of security group IDs to assign to the LB | `list(string)` | `[]` | no |
| subnet\_mapping | A list of subnet mapping blocks describing subnets to attach to load balancer | `list(map(string))` | `[]` | no |
| subnets | A list of subnet IDs to attach to the LB. Subnets cannot be updated for Load Balancers of type `network`. Changing this value for load balancers of type `network` will force a recreation of the resource | `list(string)` | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| target\_groups | Map of target group configurations to create. Set `create_attachment = false` to skip the target group attachment (e.g. when targets register themselves via autoscaling) | <pre>map(object({<br/>    connection_termination             = optional(bool)<br/>    deregistration_delay               = optional(number)<br/>    ip_address_type                    = optional(string)<br/>    lambda_multi_value_headers_enabled = optional(bool)<br/>    load_balancing_algorithm_type      = optional(string)<br/>    load_balancing_anomaly_mitigation  = optional(string)<br/>    load_balancing_cross_zone_enabled  = optional(string)<br/>    name                               = optional(string)<br/>    name_prefix                        = optional(string)<br/>    port                               = optional(number)<br/>    preserve_client_ip                 = optional(bool)<br/>    protocol                           = optional(string)<br/>    protocol_version                   = optional(string)<br/>    proxy_protocol_v2                  = optional(bool)<br/>    slow_start                         = optional(number)<br/>    target_control_port                = optional(number)<br/>    target_type                        = optional(string)<br/>    vpc_id                             = optional(string)<br/>    tags                               = optional(map(string), {})<br/><br/>    health_check = optional(object({<br/>      enabled             = optional(bool)<br/>      healthy_threshold   = optional(number)<br/>      interval            = optional(number)<br/>      matcher             = optional(string)<br/>      path                = optional(string)<br/>      port                = optional(string)<br/>      protocol            = optional(string)<br/>      timeout             = optional(number)<br/>      unhealthy_threshold = optional(number)<br/>    }))<br/><br/>    stickiness = optional(object({<br/>      cookie_duration = optional(number)<br/>      cookie_name     = optional(string)<br/>      enabled         = optional(bool, true)<br/>      type            = optional(string)<br/>    }))<br/><br/>    target_failover = optional(list(object({<br/>      on_deregistration = string<br/>      on_unhealthy      = string<br/>    })), [])<br/><br/>    target_group_health = optional(object({<br/>      dns_failover = optional(object({<br/>        minimum_healthy_targets_count      = optional(string)<br/>        minimum_healthy_targets_percentage = optional(string)<br/>      }))<br/>      unhealthy_state_routing = optional(object({<br/>        minimum_healthy_targets_count      = optional(number)<br/>        minimum_healthy_targets_percentage = optional(string)<br/>      }))<br/>    }))<br/><br/>    target_health_state = optional(object({<br/>      enable_unhealthy_connection_termination = optional(bool, true)<br/>      unhealthy_draining_interval             = optional(number)<br/>    }))<br/><br/>    # Attachment<br/>    create_attachment = optional(bool, true)<br/>    target_id         = optional(string)<br/>    availability_zone = optional(string)<br/>    quic_server_id    = optional(string)<br/><br/>    # Lambda permission (when the target is a Lambda function)<br/>    attach_lambda_permission  = optional(bool, false)<br/>    lambda_qualifier          = optional(string)<br/>    lambda_statement_id       = optional(string, "AllowExecutionFromLb")<br/>    lambda_action             = optional(string, "lambda:InvokeFunction")<br/>    lambda_principal          = optional(string)<br/>    lambda_source_account     = optional(string)<br/>    lambda_event_source_token = optional(string)<br/>  }))</pre> | `{}` | no |
| timeouts | Create, update, and delete timeout configurations for the load balancer | `map(string)` | `{}` | no |
| trust\_store\_revocations | Map of trust store revocation configurations. Each entry requires `revocations_s3_bucket`, `revocations_s3_key`, and either `trust_store_arn` (existing) or `trust_store_key` (references a key in `trust_stores`) | `any` | `{}` | no |
| trust\_stores | Map of trust store configurations to create for mTLS mutual authentication. Each entry requires `ca_certificates_bundle_s3_bucket` and `ca_certificates_bundle_s3_key`. Use `trust_store_key` in listener `mutual_authentication.trust_store_arn` to reference created stores | `any` | `{}` | no |
| vpc\_id | Identifier of the VPC where the security group will be created | `string` | `null` | no |
| web\_acl\_arn | Web Application Firewall (WAF) ARN of the resource to associate with the load balancer | `string` | `null` | no |
| xff\_header\_processing\_mode | Determines how the load balancer modifies the X-Forwarded-For header in the HTTP request before sending the request to the target. The possible values are `append`, `preserve`, and `remove`. Only valid for Load Balancers of type `application`. The default is `append` | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| arn | The ID and ARN of the load balancer we created |
| arn\_suffix | ARN suffix of our load balancer - can be used with CloudWatch |
| dns\_name | The DNS name of the load balancer |
| id | The ID and ARN of the load balancer we created |
| listener\_rules | Map of listener rules created and their attributes. Marked sensitive because rule actions can contain OIDC client secrets |
| listeners | Map of listeners created and their attributes. Marked sensitive because listener default actions can contain OIDC client secrets |
| name | The name of the load balancer we created |
| route53\_records | The Route53 records created and attached to the load balancer |
| security\_group\_arn | Amazon Resource Name (ARN) of the security group |
| security\_group\_id | ID of the security group |
| target\_groups | Map of target groups created and their attributes |
| trust\_store\_revocations | Map of trust store revocations created and their attributes |
| trust\_stores | Map of trust stores created and their attributes |
| zone\_id | The zone\_id of the load balancer to assist with creating DNS records |
<!-- END_TF_DOCS -->

</details>
