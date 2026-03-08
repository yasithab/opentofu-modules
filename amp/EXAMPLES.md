# AMP (Amazon Managed Prometheus) Module - Examples

## Basic Usage

Creates an Amazon Managed Prometheus workspace with default CloudWatch logging and a default alert manager configuration.

```hcl
module "amp" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//amp?depth=1&ref=v2.0.0"

  enabled = true

  workspace_alias = "my-prometheus"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//amp?depth=1&ref=v2.0.0"

  enabled = true

  workspace_alias = "platform-prometheus"
  kms_key_arn     = "arn:aws:kms:us-east-1:123456789012:key/mrk-1234abcd-12ab-34cd-56ef-1234567890ab"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//amp?depth=1&ref=v2.0.0"

  enabled = true

  workspace_alias = "platform-prometheus"
  kms_key_arn     = "arn:aws:kms:us-east-1:123456789012:key/mrk-1234abcd-12ab-34cd-56ef-1234567890ab"

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
  source = "git::https://github.com/yasithab/opentofu-modules.git//amp?depth=1&ref=v2.0.0"

  enabled = true

  workspace_alias = "eks-prometheus"

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
