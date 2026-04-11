# AWS Organizations

OpenTofu module for provisioning and managing AWS Organizations with organizational units, accounts, service control policies, delegated administrators, and resource policies.

## Features

- **Organization** - Create and manage an AWS Organization with configurable feature set (ALL or CONSOLIDATED_BILLING)
- **Organizational Units** - Hierarchical OU structure with support for nested (parent/child) organizational units
- **Account Management** - Create and manage member accounts with configurable billing access, cross-account roles, and OU placement
- **Service Control Policies** - Create SCPs and attach them to the organization root, OUs, or individual accounts
- **Policy Types** - Enable multiple policy types including SCP, TAG_POLICY, BACKUP_POLICY, and AISERVICES_OPT_OUT_POLICY
- **Delegated Administrators** - Register member accounts as delegated administrators for supported AWS services
- **AWS Service Access** - Configure AWS service access principals for organization-level service integrations
- **Resource Policies** - Attach organization-level resource policies for cross-organization resource sharing controls

## Usage

```hcl
module "organizations" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//organizations?depth=1&ref=master"

  name        = "my-organization"
  feature_set = "ALL"

  enabled_policy_types = ["SERVICE_CONTROL_POLICY", "TAG_POLICY"]

  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "sso.amazonaws.com",
  ]

  organizational_units = {
    security  = { name = "Security" }
    workloads = { name = "Workloads" }
    prod      = { name = "Production", parent_key = "workloads" }
    staging   = { name = "Staging", parent_key = "workloads" }
  }

  accounts = {
    security = {
      name       = "security-account"
      email      = "aws+security@example.com"
      parent_key = "security"
    }
    prod = {
      name       = "production-account"
      email      = "aws+prod@example.com"
      parent_key = "prod"
    }
  }

  tags = {
    Environment = "management"
  }
}
```

## Examples

### Basic Organization with Consolidated Billing

Minimal organization setup with consolidated billing only.

```hcl
module "organizations" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//organizations?depth=1&ref=master"

  name        = "billing-org"
  feature_set = "CONSOLIDATED_BILLING"

  tags = {
    Environment = "management"
  }
}
```

### Full Organization with SCPs and Delegated Administrators

Production-grade organization with hierarchical OUs, service control policies, and delegated administrators for security services.

```hcl
module "organizations" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//organizations?depth=1&ref=master"

  name        = "acme-corp"
  feature_set = "ALL"

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY",
    "BACKUP_POLICY",
  ]

  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com",
    "sso.amazonaws.com",
    "tagpolicies.tag.amazonaws.com",
  ]

  organizational_units = {
    security   = { name = "Security" }
    infra      = { name = "Infrastructure" }
    workloads  = { name = "Workloads" }
    prod       = { name = "Production", parent_key = "workloads" }
    staging    = { name = "Staging", parent_key = "workloads" }
    sandbox    = { name = "Sandbox" }
  }

  accounts = {
    security = {
      name       = "security-tooling"
      email      = "aws+security@acme.com"
      parent_key = "security"
    }
    log_archive = {
      name       = "log-archive"
      email      = "aws+logs@acme.com"
      parent_key = "security"
    }
    network = {
      name       = "shared-networking"
      email      = "aws+network@acme.com"
      parent_key = "infra"
    }
    prod_app = {
      name              = "prod-application"
      email             = "aws+prod@acme.com"
      parent_key        = "prod"
      close_on_deletion = true
    }
  }

  policies = {
    deny_leave_org = {
      name        = "DenyLeaveOrganization"
      description = "Prevents member accounts from leaving the organization"
      type        = "SERVICE_CONTROL_POLICY"
      content     = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Sid       = "DenyLeaveOrg"
          Effect    = "Deny"
          Action    = "organizations:LeaveOrganization"
          Resource  = "*"
        }]
      })
      target_keys = ["__root__"]
    }
    deny_root_user = {
      name        = "DenyRootUserAccess"
      description = "Denies root user actions in member accounts"
      type        = "SERVICE_CONTROL_POLICY"
      content     = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Sid       = "DenyRootUser"
          Effect    = "Deny"
          Action    = "*"
          Resource  = "*"
          Condition = {
            StringLike = {
              "aws:PrincipalArn" = "arn:aws:iam::*:root"
            }
          }
        }]
      })
      target_keys = ["workloads", "sandbox"]
    }
  }

  delegated_administrators = {
    guardduty = {
      account_id        = "111111111111"
      service_principal = "guardduty.amazonaws.com"
    }
    securityhub = {
      account_id        = "111111111111"
      service_principal = "securityhub.amazonaws.com"
    }
  }

  tags = {
    Environment = "management"
    Team        = "platform"
  }
}
```

### Organization with Resource Policy

Organization with a resource policy for cross-organization access control.

```hcl
module "organizations" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//organizations?depth=1&ref=master"

  name        = "shared-org"
  feature_set = "ALL"

  enabled_policy_types = ["SERVICE_CONTROL_POLICY"]

  aws_service_access_principals = [
    "ram.amazonaws.com",
  ]

  resource_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowRAMSharing"
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::222222222222:root" }
      Action    = "organizations:DescribeOrganization"
      Resource  = "*"
    }]
  })

  tags = {
    Environment = "management"
  }
}
```
