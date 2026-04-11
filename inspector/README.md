# Amazon Inspector

OpenTofu module for provisioning and managing Amazon Inspector vulnerability scanning with organization configuration, member associations, and suppression rules.

## Features

- **Multi-Resource Scanning** - Enable vulnerability scanning for EC2 instances, ECR container images, Lambda functions, and Lambda code
- **Organization Configuration** - Automatically enable Inspector scanning for new member accounts with per-resource-type granularity
- **Delegated Admin** - Designate a delegated administrator account for centralized Inspector management across the organization
- **Member Associations** - Associate member accounts for centralized vulnerability management and findings aggregation
- **Suppression Rules** - Filter and suppress findings based on account ID, severity, vulnerability ID, resource type, and other criteria

## Usage

```hcl
module "inspector" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//inspector?depth=1&ref=master"

  name        = "inspector-prod"
  account_ids = ["123456789012"]

  resource_types = ["EC2", "ECR", "LAMBDA"]

  tags = {
    Environment = "production"
  }
}
```

## Examples

### Basic Inspector Enablement

Enable Inspector for the current account with EC2, ECR, and Lambda scanning.

```hcl
module "inspector" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//inspector?depth=1&ref=master"

  name        = "inspector-prod"
  account_ids = [data.aws_caller_identity.current.account_id]

  resource_types = ["EC2", "ECR", "LAMBDA"]

  tags = {
    Environment = "production"
    Team        = "security"
  }
}
```

### Organization-Wide Inspector

Inspector with organization configuration and member account associations.

```hcl
module "inspector" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//inspector?depth=1&ref=master"

  name        = "inspector-org"
  account_ids = [data.aws_caller_identity.current.account_id]

  resource_types = ["EC2", "ECR", "LAMBDA"]

  delegated_admin_account_id = data.aws_caller_identity.current.account_id

  enable_organization_configuration = true
  auto_enable_ec2                   = true
  auto_enable_ecr                   = true
  auto_enable_lambda                = true

  member_account_ids = ["111111111111", "222222222222"]

  tags = {
    Environment = "production"
    Team        = "security"
  }
}
```

### Inspector with Suppression Rules

Inspector with suppression rules to filter out known acceptable vulnerabilities.

```hcl
module "inspector" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//inspector?depth=1&ref=master"

  name        = "inspector-prod"
  account_ids = [data.aws_caller_identity.current.account_id]

  resource_types = ["EC2", "ECR", "LAMBDA"]

  filters = {
    suppress-low-severity = {
      action = "SUPPRESS"
      reason = "Suppress low severity findings for non-production workloads"
      criteria = {
        severity = [
          {
            comparison = "EQUALS"
            value      = "LOW"
          }
        ]
        aws_account_id = [
          {
            comparison = "EQUALS"
            value      = "111111111111"
          }
        ]
      }
    }
  }

  tags = {
    Environment = "production"
    Team        = "security"
  }
}
```
