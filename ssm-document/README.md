# ssm-document

OpenTofu module to create and manage an AWS SSM document (`aws_ssm_document`) — Command,
Session, Automation, Policy, Package, etc. Supports custom content, attachments, and
cross-account sharing.

## Usage

### Command document

```hcl
module "ssm_command" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ssm-document?depth=1&ref=master"

  name          = "run-health-check"
  document_type = "Command"
  target_type   = "/AWS::EC2::Instance"

  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Run the application health check"
    mainSteps = [{
      action = "aws:runShellScript"
      name   = "healthCheck"
      inputs = { runCommand = ["/opt/app/bin/health-check.sh"] }
    }]
  })

  tags = { Environment = "production" }
}
```

### Host-locked Session document (single-host port-forward)

A Session document whose target `host`/`port` are baked in at creation. A principal granted
`ssm:StartSession` on its ARN can port-forward **only** to that host:port — unlike the
AWS-managed `AWS-StartPortForwardingSessionToRemoteHost`, which lets the caller pick any host
(and cannot be constrained by IAM).

```hcl
module "ssm_port_forward" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ssm-document?depth=1&ref=master"

  name            = "internal-port-forward"
  document_type   = "Session"
  document_format = "YAML"

  content = yamlencode({
    schemaVersion = "1.0"
    description   = "Port-forward to db.internal.example.com:5432 only (host locked)"
    sessionType   = "Port"
    parameters = {
      portNumber      = { type = "String", default = "5432", allowedPattern = "^5432$" }
      localPortNumber = { type = "String", default = "0", allowedPattern = "^[0-9]{1,5}$" }
    }
    properties = {
      host            = "db.internal.example.com" # hardcoded — caller cannot override
      portNumber      = "{{ portNumber }}"
      localPortNumber = "{{ localPortNumber }}"
    }
  })

  tags = { Environment = "production" }
}
```

### Shared document (cross-account)

```hcl
module "ssm_shared" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ssm-document?depth=1&ref=master"

  name          = "shared-automation"
  document_type = "Automation"
  content       = file("${path.module}/automation.yaml")

  permissions = {
    type        = "Share"
    account_ids = "111111111111,222222222222"
  }

  tags = { Environment = "production" }
}
```

## Notes

- **Build `content` with `jsonencode()`/`yamlencode()`** (not raw heredocs). AWS normalizes
  stored document content, so unencoded/hand-formatted strings can produce perpetual plan
  diffs.
- **`version_name`**: if you set a static `version_name` and later change `content` without
  changing `version_name`, AWS rejects the update (the version name already exists). Either
  bump `version_name` on every content change, or leave it `null` and let SSM auto-version.
- Changing `name` or `document_type` forces resource replacement.
- `content` is required when `enabled = true` (validated).

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
| attachments\_source | Attachment sources for the document (e.g. ZIP packages, scripts). Each entry: key (SourceUrl \| S3FileUrl \| AttachmentReference), values (list), and an optional name. | <pre>list(object({<br/>    key    = string<br/>    values = list(string)<br/>    name   = optional(string)<br/>  }))</pre> | `[]` | no |
| content | Content of the SSM document, in the format set by document\_format (JSON, YAML or TEXT). Build it with jsonencode()/yamlencode() or templatefile(). Required when enabled. | `string` | `null` | no |
| document\_format | Format of the document content. Valid values: JSON, YAML, TEXT. | `string` | `"JSON"` | no |
| document\_type | Type of the document. Valid values: Command, Policy, Automation, Session, Package, ChangeCalendar, CloudFormation, ConformancePackTemplate, DeploymentStrategy, ProblemAnalysis, ProblemAnalysisTemplate, QuickSetup. | `string` | `"Command"` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| name | Name of the SSM document. 3-128 chars; letters, digits, and \_ . - only; must not start with the reserved prefixes aws, amazon, or amzn. | `string` | n/a | yes |
| permissions | Sharing permissions for the document. Map with keys `type` ("Share") and `account_ids` (comma-separated account IDs, or "all"). Null keeps the document private. | `map(string)` | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| target\_type | Types of resources the document can run on, e.g. /AWS::EC2::Instance, or / for all resource types. | `string` | `null` | no |
| version\_name | Friendly name of the document version. Can be set when creating or updating the document. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| arn | ARN of the SSM document. |
| default\_version | Default version of the document. |
| document\_version | Document version created by this resource. |
| hash | Sha1 or Sha256 hash of the document content. |
| hash\_type | Hash type used for the document hash (Sha1 or Sha256). |
| latest\_version | Latest version of the document. |
| name | Name of the SSM document. |
| owner | AWS account that owns the document. |
| status | Status of the document (Creating, Active, Updating, Deleting, Failed). |
| tags\_all | All tags applied to the document, including provider default\_tags. |
<!-- END_TF_DOCS -->
