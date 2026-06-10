# Amazon Managed Service for Prometheus (AMP)

Provisions an Amazon Managed Service for Prometheus workspace with alert manager definitions, rule group namespaces, CloudWatch logging, and EKS managed scrapers.

## Features

- **Workspace Management** - Create a new AMP workspace or reference an existing one, with optional KMS encryption at rest
- **Alert Manager** - Configure alert manager definitions for routing and receiving alerts (opt-in via `create_alert_manager_definition`)
- **Rule Group Namespaces** - Define Prometheus recording and alerting rules
- **CloudWatch Logging** - Automatic log group creation with configurable retention and encryption, or pass an existing log group via `cloudwatch_log_group_arn`
- **Managed Scrapers** - Configure Prometheus scrapers for EKS clusters with custom scrape configurations and role-based access

## Usage

```hcl
module "amp" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//amp?depth=1&ref=master"

  name = "my-prometheus-workspace"

  tags = {
    Environment = "production"
  }
}
```


## Examples

## Basic Usage

Creates an Amazon Managed Prometheus workspace with default CloudWatch logging.

```hcl
module "amp" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//amp?depth=1&ref=master"

  enabled = true

  name = "my-prometheus"

  tags = {
    Environment = "production"
    Team        = "observability"
  }
}
```

## With KMS Encryption and Custom Retention

Adds at-rest encryption via a customer-managed KMS key and sets a longer CloudWatch log retention period.

```hcl
module "amp_encrypted" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//amp?depth=1&ref=master"

  enabled = true

  name        = "platform-prometheus"
  kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mrk-1234abcd-12ab-34cd-56ef-1234567890ab"

  cloudwatch_log_group_retention_in_days = 90
  cloudwatch_log_group_kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/mrk-1234abcd-12ab-34cd-56ef-1234567890ab"
  cloudwatch_log_group_class             = "STANDARD"

  tags = {
    Environment = "production"
    Team        = "observability"
  }
}
```

## With Custom Alert Manager and Recording Rules

Configures a real Alertmanager routing tree and adds Prometheus recording rule namespaces for pre-computed metrics.

```hcl
module "amp_with_rules" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//amp?depth=1&ref=master"

  enabled = true

  name        = "platform-prometheus"
  kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mrk-1234abcd-12ab-34cd-56ef-1234567890ab"

  create_alert_manager_definition = true

  alert_manager_definition = <<-EOT
    alertmanager_config: |
      route:
        receiver: 'pagerduty'
        group_by: ['alertname', 'cluster']
        group_wait: 30s
        group_interval: 5m
        repeat_interval: 12h
      receivers:
        - name: 'pagerduty'
          pagerduty_configs:
            - service_key: '<pd-service-key>'
  EOT

  rule_group_namespaces = {
    recording = {
      name = "platform-recording-rules"
      data = <<-EOT
        groups:
          - name: example
            rules:
              - record: job:http_requests_total:rate5m
                expr: sum(rate(http_requests_total[5m])) by (job)
      EOT
    }
  }

  cloudwatch_log_group_retention_in_days = 30

  tags = {
    Environment = "production"
    Team        = "observability"
  }
}
```

## With EKS Scraper

Attaches a managed Prometheus scraper to an EKS cluster so AWS collects metrics without running a self-managed Prometheus agent.

```hcl
module "amp_with_scraper" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//amp?depth=1&ref=master"

  enabled = true

  name = "eks-prometheus"

  scrapers = {
    production_eks = {
      alias           = "prod-cluster-scraper"
      eks_cluster_arn = "arn:aws:eks:us-east-1:123456789012:cluster/production"
      subnet_ids      = ["subnet-0abc123def456gh01", "subnet-0abc123def456gh02"]
      security_group_ids = ["sg-0a1b2c3d4e5f67890"]

      scrape_configuration = <<-EOT
        global:
          scrape_interval: 30s
        scrape_configs:
          - job_name: kubernetes-pods
            kubernetes_sd_configs:
              - role: pod
      EOT
    }
  }

  cloudwatch_log_group_retention_in_days = 30

  tags = {
    Environment = "production"
    Team        = "observability"
    Cluster     = "production"
  }
}
```

## With an Existing CloudWatch Log Group

Sends workspace logs to a log group managed outside this module.

```hcl
module "amp_existing_log_group" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//amp?depth=1&ref=master"

  name = "my-prometheus"

  create_cloudwatch_log_group = false
  cloudwatch_log_group_arn    = "arn:aws:logs:us-east-1:123456789012:log-group:my-amp-logs"
}
```

## With an Existing Workspace

When `create_workspace = false`, `workspace_id` is required.

```hcl
module "amp_existing_workspace" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//amp?depth=1&ref=master"

  create_workspace = false
  workspace_id     = "ws-12345678-90ab-cdef-1234-567890abcdef"

  rule_group_namespaces = {
    recording = {
      name = "recording-rules"
      data = <<-EOT
        groups:
          - name: example
            rules:
              - record: job:http_requests_total:rate5m
                expr: sum(rate(http_requests_total[5m])) by (job)
      EOT
    }
  }
}
```
