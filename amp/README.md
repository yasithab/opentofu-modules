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
| alert\_manager\_definition | The alert manager definition that you want to be applied. Required when `create_alert_manager_definition` is `true`. See more in the [AWS Docs](https://docs.aws.amazon.com/prometheus/latest/userguide/AMP-alert-manager.html) | `string` | `null` | no |
| cloudwatch\_log\_group\_arn | ARN of an existing CloudWatch log group to use for workspace logging when `create_cloudwatch_log_group` is `false`. Provide the plain log group ARN (without a trailing `:*`). | `string` | `null` | no |
| cloudwatch\_log\_group\_class | Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT\_ACCESS. | `string` | `"STANDARD"` | no |
| cloudwatch\_log\_group\_kms\_key\_id | If a KMS Key ARN is set, this key will be used to encrypt the corresponding log group. Please be sure that the KMS Key has an appropriate key policy (https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html) | `string` | `null` | no |
| cloudwatch\_log\_group\_name | Custom name of CloudWatch log group | `string` | `null` | no |
| cloudwatch\_log\_group\_retention\_in\_days | Number of days to retain log events. Default is 30 days | `number` | `30` | no |
| cloudwatch\_log\_group\_skip\_destroy | Set to true if you do not wish the log group (and any logs it may contain) to be deleted at destroy time, and instead just remove the log group from the Terraform state. | `bool` | `false` | no |
| cloudwatch\_log\_group\_use\_name\_prefix | Determines whether the log group name should be used as a prefix | `bool` | `false` | no |
| create\_alert\_manager\_definition | Determines whether an alert manager definition is created. Requires `alert_manager_definition` to be set. | `bool` | `false` | no |
| create\_cloudwatch\_log\_group | Determines whether a log group is created by this module | `bool` | `true` | no |
| create\_workspace | Determines whether a workspace will be created or to use an existing workspace | `bool` | `true` | no |
| enable\_cloudwatch\_logging | Determines whether CloudWatch logging is configured | `bool` | `true` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| kms\_key\_arn | The ARN of the KMS Key to for encryption at rest | `string` | `null` | no |
| name | The alias of the prometheus workspace. See more in the [AWS Docs](https://docs.aws.amazon.com/prometheus/latest/userguide/AMP-onboard-create-workspace.html) | `string` | `null` | no |
| region | Region where resources will be managed. Defaults to the Region set in the provider configuration. | `string` | `null` | no |
| rule\_group\_namespaces | A map of one or more rule group namespace definitions | <pre>map(object({<br/>    name = string<br/>    data = string<br/>  }))</pre> | `{}` | no |
| scrapers | Map of Prometheus scraper configurations. Each key is a unique scraper name. | <pre>map(object({<br/>    alias                = optional(string)<br/>    scrape_configuration = string<br/>    eks_cluster_arn      = string<br/>    security_group_ids   = optional(list(string), [])<br/>    subnet_ids           = list(string)<br/>    workspace_arn        = optional(string)<br/>    role_configuration = optional(object({<br/>      source_role_arn = optional(string)<br/>      target_role_arn = optional(string)<br/>    }))<br/>    timeouts = optional(object({<br/>      create = optional(string)<br/>      update = optional(string)<br/>      delete = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| workspace\_id | The ID of an existing workspace to use when `create_workspace` is `false` | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| cloudwatch\_log\_group\_arn | ARN of the CloudWatch log group created for workspace logging |
| cloudwatch\_log\_group\_name | Name of the CloudWatch log group created for workspace logging |
| rule\_group\_namespaces | Map of rule group namespace keys to their attributes |
| scraper\_arns | Map of scraper names to ARNs |
| scraper\_ids | Map of scraper names to IDs |
| workspace\_arn | Amazon Resource Name (ARN) of the workspace |
| workspace\_id | Identifier of the workspace |
| workspace\_prometheus\_endpoint | Prometheus endpoint available for this workspace |
<!-- END_TF_DOCS -->

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
