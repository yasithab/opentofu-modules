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
