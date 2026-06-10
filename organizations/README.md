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
| accounts | Map of AWS accounts to create within the organization. Each key is a unique identifier and the value is an object with:<br/>- name: Friendly name for the account<br/>- email: Email address of the account owner (must be unique across all AWS accounts)<br/>- parent\_key: Key of the OU to place this account in (null for organization root)<br/>- iam\_user\_access\_to\_billing: ALLOW or DENY IAM user access to billing. Defaults to ALLOW.<br/>- role\_name: Name of the IAM role created for cross-account access. Defaults to OrganizationAccountAccessRole.<br/>- close\_on\_deletion: If true, closes the account on removal instead of just removing from org. Defaults to false (BREAKING: previously true - removing an account from configuration would CLOSE it).<br/>- tags: Optional map of tags for the account<br/><br/>Example:<br/>{<br/>  security = {<br/>    name       = "security-account"<br/>    email      = "aws+security@example.com"<br/>    parent\_key = "security"<br/>  }<br/>  prod = {<br/>    name       = "production-account"<br/>    email      = "aws+prod@example.com"<br/>    parent\_key = "prod"<br/>  }<br/>} | <pre>map(object({<br/>    name                       = string<br/>    email                      = string<br/>    parent_key                 = optional(string, null)<br/>    iam_user_access_to_billing = optional(string, "ALLOW")<br/>    role_name                  = optional(string, "OrganizationAccountAccessRole")<br/>    close_on_deletion          = optional(bool, false)<br/>    tags                       = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| aws\_service\_access\_principals | List of AWS service principal names for which you want to enable integration with your organization. | `list(string)` | `[]` | no |
| delegated\_administrators | Map of delegated administrators to register. Each key is a unique identifier and the value is an object with:<br/>- account\_id: AWS account ID to register as a delegated administrator<br/>- service\_principal: Service principal of the AWS service to delegate<br/><br/>Example:<br/>{<br/>  guardduty = {<br/>    account\_id        = "123456789012"<br/>    service\_principal = "guardduty.amazonaws.com"<br/>  }<br/>} | <pre>map(object({<br/>    account_id        = string<br/>    service_principal = string<br/>  }))</pre> | `{}` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| enabled\_policy\_types | List of organization policy types to enable. Valid values: AISERVICES\_OPT\_OUT\_POLICY, BACKUP\_POLICY, SERVICE\_CONTROL\_POLICY, TAG\_POLICY. | `list(string)` | <pre>[<br/>  "SERVICE_CONTROL_POLICY"<br/>]</pre> | no |
| feature\_set | Feature set of the organization. Valid values are ALL or CONSOLIDATED\_BILLING. | `string` | `"ALL"` | no |
| organizational\_units | Map of organizational units to create. Each key is a unique identifier and the value is an object with:<br/>- name: Display name of the OU<br/>- parent\_key: Key of the parent OU (null or omitted for root-level OUs)<br/>- tags: Optional map of tags for the OU<br/><br/>Example:<br/>{<br/>  security = { name = "Security", parent\_key = null }<br/>  workloads = { name = "Workloads", parent\_key = null }<br/>  prod = { name = "Production", parent\_key = "workloads" }<br/>  staging = { name = "Staging", parent\_key = "workloads" }<br/>} | <pre>map(object({<br/>    name       = string<br/>    parent_key = optional(string, null)<br/>    tags       = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| policies | Map of organization policies to create and optionally attach to targets. Each key is a unique identifier and the value is an object with:<br/>- name: Display name of the policy<br/>- description: Description of the policy<br/>- type: Policy type (AISERVICES\_OPT\_OUT\_POLICY, BACKUP\_POLICY, SERVICE\_CONTROL\_POLICY, TAG\_POLICY)<br/>- content: Policy content as a JSON string<br/>- tags: Optional map of tags for the policy<br/>- target\_keys: List of OU or account keys from organizational\_units/accounts to attach this policy to.<br/>               Use "\_\_root\_\_" to attach to the organization root.<br/><br/>Example:<br/>{<br/>  deny\_leave\_org = {<br/>    name        = "DenyLeaveOrganization"<br/>    description = "Prevents accounts from leaving the organization"<br/>    type        = "SERVICE\_CONTROL\_POLICY"<br/>    content     = jsonencode({<br/>      Version = "2012-10-17"<br/>      Statement = [{<br/>        Sid       = "DenyLeaveOrg"<br/>        Effect    = "Deny"<br/>        Action    = "organizations:LeaveOrganization"<br/>        Resource  = "*"<br/>      }]<br/>    })<br/>    target\_keys = ["\_\_root\_\_"]<br/>  }<br/>} | <pre>map(object({<br/>    name        = string<br/>    description = optional(string, "")<br/>    type        = optional(string, "SERVICE_CONTROL_POLICY")<br/>    content     = string<br/>    tags        = optional(map(string), {})<br/>    target_keys = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| resource\_policy | JSON string of the organization-level resource policy. Set to null to skip creation. | `string` | `null` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| account\_arns | Map of account keys to their ARNs. |
| account\_ids | Map of account keys to their IDs. |
| master\_account\_arn | ARN of the master (management) account. |
| master\_account\_email | Email address of the master (management) account. |
| master\_account\_id | ID of the master (management) account. |
| non\_master\_accounts | List of non-master accounts in the organization. |
| organization\_arn | ARN of the organization. |
| organization\_id | Identifier of the organization. |
| organizational\_unit\_arns | Map of OU keys to their ARNs. |
| organizational\_unit\_ids | Map of OU keys to their IDs. |
| policy\_arns | Map of policy keys to their ARNs. |
| policy\_ids | Map of policy keys to their IDs. |
| resource\_policy\_arn | ARN of the organization resource policy. |
| resource\_policy\_id | ID of the organization resource policy. |
| roots | List of organization roots with their IDs, ARNs, names, and policy types. |
<!-- END_TF_DOCS -->

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

## Notes

### `close_on_deletion` defaults to `false` (safety)

Removing an account from `accounts` only detaches it from OpenTofu management/the
organization; the AWS account itself is not closed. Set `close_on_deletion = true` per
account if closing on removal is genuinely intended.

### Unresolved `parent_key` / `target_key` fail the plan

- An account `parent_key` must match an `organizational_units` key; otherwise the plan fails
  with a precondition error.
- A child OU `parent_key` must reference a root-level OU; otherwise the plan fails with a
  precondition error.
- A policy `target_keys` entry must match `__root__`, an OU key, or an account key.
- Accounts and policy attachments can target child OUs by key.

### Two-level OU limit

The module supports exactly two OU levels: root-level OUs (`parent_key = null`) and child OUs
whose `parent_key` references a root-level OU. Deeper nesting (a child OU under another child
OU) is not supported and fails validation.
