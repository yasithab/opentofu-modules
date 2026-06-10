# AWS Global Accelerator

OpenTofu module for provisioning AWS Global Accelerator with standard and custom routing accelerators, listeners, endpoint groups, and flow logs.

## Features

- **Standard Accelerator** - Global Accelerator with configurable IP address type (IPv4/dual-stack) and optional static IP addresses
- **Listeners** - Multiple listeners with port ranges, protocol selection (TCP/UDP), and client affinity settings
- **Endpoint Groups** - Regional endpoint groups with health check configuration, traffic dial percentage, and port overrides
- **Custom Routing Accelerator** - Deterministic routing variant for use cases requiring traffic to be routed to specific EC2 instances
- **Custom Routing Listeners and Endpoints** - Full custom routing configuration with destination port ranges and protocol mappings
- **Flow Logs** - Accelerator flow logs to S3 for traffic analysis and auditing, enabled by default
- **Cross-Account Attachments** - Share endpoints across AWS accounts for multi-account architectures
- **Health Checks** - Configurable health check interval, path, port, protocol, and threshold for endpoint groups

## Usage

```hcl
module "global_accelerator" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//global-accelerator?depth=1&ref=master"

  name = "my-accelerator"

  listeners = {
    http = {
      protocol = "TCP"
      port_ranges = [
        { from_port = 80, to_port = 80 },
        { from_port = 443, to_port = 443 }
      ]
    }
  }

  endpoint_groups = {
    primary = {
      listener_key = "http"
      endpoint_configurations = [
        {
          endpoint_id = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/1234567890"
          weight      = 128
        }
      ]
    }
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
| accelerator\_enabled | Whether the accelerator is enabled. Even when disabled, it still incurs charges. | `bool` | `true` | no |
| create\_custom\_routing\_accelerator | Whether to create a custom routing accelerator instead of a standard accelerator. | `bool` | `false` | no |
| cross\_account\_attachments | Map of cross-account attachment configurations for sharing endpoints across AWS accounts. | <pre>map(object({<br/>    name       = string<br/>    principals = optional(list(string), [])<br/>    resources = optional(list(object({<br/>      endpoint_id = string<br/>      region      = optional(string)<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| custom\_routing\_endpoint\_groups | Map of custom routing endpoint group configurations with destination configurations. | <pre>map(object({<br/>    listener_key          = optional(string)<br/>    listener_arn          = optional(string)<br/>    endpoint_group_region = optional(string)<br/>    destination_configurations = optional(list(object({<br/>      from_port = number<br/>      to_port   = number<br/>      protocols = list(string)<br/>    })), [])<br/>    endpoint_configurations = optional(list(object({<br/>      endpoint_id = string<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| custom\_routing\_listeners | Map of custom routing listener configurations. | <pre>map(object({<br/>    port_ranges = optional(list(object({<br/>      from_port = number<br/>      to_port   = optional(number)<br/>    })), [{ from_port = 80, to_port = 80 }])<br/>  }))</pre> | `{}` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| endpoint\_groups | Map of endpoint group configurations including health checks and endpoint configurations. | <pre>map(object({<br/>    listener_key                  = optional(string)<br/>    listener_arn                  = optional(string)<br/>    endpoint_group_region         = optional(string)<br/>    health_check_interval_seconds = optional(number, 30)<br/>    health_check_path             = optional(string, "/")<br/>    health_check_port             = optional(number, 80)<br/>    health_check_protocol         = optional(string, "HTTP")<br/>    threshold_count               = optional(number, 3)<br/>    traffic_dial_percentage       = optional(number, 100)<br/>    endpoint_configurations = optional(list(object({<br/>      client_ip_preservation_enabled = optional(bool, true)<br/>      endpoint_id                    = string<br/>      weight                         = optional(number, 128)<br/>    })), [])<br/>    port_overrides = optional(list(object({<br/>      endpoint_port = number<br/>      listener_port = number<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| flow\_logs\_enabled | Whether flow logs are enabled for the accelerator. | `bool` | `false` | no |
| flow\_logs\_s3\_bucket | S3 bucket name for storing flow logs. | `string` | `null` | no |
| flow\_logs\_s3\_prefix | S3 key prefix for flow log objects. | `string` | `null` | no |
| ip\_address\_type | IP address type for the accelerator. Valid values: `IPV4`, `DUAL_STACK`. | `string` | `"IPV4"` | no |
| ip\_addresses | List of IP addresses to use as static addresses for the accelerator. Up to 2 addresses. | `list(string)` | `null` | no |
| listeners | Map of listener configurations. Each listener defines port ranges and protocol. | <pre>map(object({<br/>    client_affinity = optional(string, "NONE")<br/>    protocol        = optional(string, "TCP")<br/>    port_ranges = optional(list(object({<br/>      from_port = number<br/>      to_port   = optional(number)<br/>    })), [{ from_port = 80, to_port = 80 }])<br/>  }))</pre> | `{}` | no |
| name | Name of the Global Accelerator. | `string` | n/a | yes |
| region | AWS region override. Uses provider region when null. | `string` | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| accelerator\_arn | The ARN of the Global Accelerator. |
| accelerator\_dns\_name | The DNS name of the Global Accelerator. |
| accelerator\_hosted\_zone\_id | The Route 53 hosted zone ID for the Global Accelerator. |
| accelerator\_id | The ID of the Global Accelerator. |
| accelerator\_ip\_sets | The IP address sets associated with the Global Accelerator. |
| accelerator\_name | The name of the Global Accelerator. |
| custom\_routing\_endpoint\_group\_ids | Map of custom routing endpoint group IDs. |
| custom\_routing\_listener\_ids | Map of custom routing listener IDs. |
| endpoint\_group\_arns | Map of endpoint group ARNs. |
| endpoint\_group\_ids | Map of endpoint group IDs. |
| listener\_ids | Map of listener IDs. |
<!-- END_TF_DOCS -->

## Examples

### Multi-Region Load Balancing

Route traffic across multiple AWS regions with health checks and traffic dial control.

```hcl
module "global_accelerator" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//global-accelerator?depth=1&ref=master"

  name            = "multi-region-app"
  ip_address_type = "IPV4"

  flow_logs_enabled   = true
  flow_logs_s3_bucket = "my-flow-logs-bucket"
  flow_logs_s3_prefix = "global-accelerator/"

  listeners = {
    https = {
      protocol        = "TCP"
      client_affinity = "SOURCE_IP"
      port_ranges = [
        { from_port = 443, to_port = 443 }
      ]
    }
  }

  endpoint_groups = {
    us_east = {
      listener_key              = "https"
      endpoint_group_region     = "us-east-1"
      traffic_dial_percentage   = 70
      health_check_path         = "/health"
      health_check_protocol     = "HTTPS"
      health_check_port         = 443
      endpoint_configurations = [
        {
          endpoint_id                    = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/primary-alb/abc123"
          weight                         = 128
          client_ip_preservation_enabled = true
        }
      ]
    }
    eu_west = {
      listener_key            = "https"
      endpoint_group_region   = "eu-west-1"
      traffic_dial_percentage = 30
      health_check_path       = "/health"
      health_check_protocol   = "HTTPS"
      health_check_port       = 443
      endpoint_configurations = [
        {
          endpoint_id                    = "arn:aws:elasticloadbalancing:eu-west-1:123456789012:loadbalancer/app/secondary-alb/def456"
          weight                         = 128
          client_ip_preservation_enabled = true
        }
      ]
    }
  }

  tags = {
    Environment = "production"
    Service     = "web-frontend"
  }
}
```

### Custom Routing Accelerator

A custom routing accelerator for deterministic routing to specific EC2 instances behind a VPC subnet.

```hcl
module "custom_routing_accelerator" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//global-accelerator?depth=1&ref=master"

  name                              = "gaming-router"
  create_custom_routing_accelerator = true

  custom_routing_listeners = {
    game = {
      port_ranges = [
        { from_port = 10000, to_port = 20000 }
      ]
    }
  }

  custom_routing_endpoint_groups = {
    primary = {
      listener_key          = "game"
      endpoint_group_region = "us-east-1"
      destination_configurations = [
        {
          from_port = 10000
          to_port   = 20000
          protocols = ["UDP"]
        }
      ]
      endpoint_configurations = [
        { endpoint_id = "subnet-0abc123def456789a" }
      ]
    }
  }

  tags = {
    Environment = "production"
    Service     = "gaming"
  }
}
```

### Dual-Stack with Port Overrides

A dual-stack accelerator with port override mappings.

```hcl
module "dual_stack_accelerator" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//global-accelerator?depth=1&ref=master"

  name            = "api-gateway"
  ip_address_type = "DUAL_STACK"

  listeners = {
    api = {
      protocol = "TCP"
      port_ranges = [
        { from_port = 443, to_port = 443 },
        { from_port = 8443, to_port = 8443 }
      ]
    }
  }

  endpoint_groups = {
    primary = {
      listener_key          = "api"
      endpoint_group_region = "us-west-2"
      port_overrides = [
        { listener_port = 8443, endpoint_port = 443 }
      ]
      endpoint_configurations = [
        {
          endpoint_id = "arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/net/api-nlb/abc123"
          weight      = 128
        }
      ]
    }
  }

  tags = {
    Environment = "production"
    Service     = "api"
  }
}
```

## Notes

- `flow_logs_enabled` now defaults to `false`; when set to `true`, `flow_logs_s3_bucket` is required (validated at plan time).
- `listeners`, `endpoint_groups`, `custom_routing_listeners`, `custom_routing_endpoint_groups`, and `cross_account_attachments` use typed object schemas with optional attributes.
