# Tag Policy

OpenTofu module to create and attach AWS Organizations Tag Policies for enforcing consistent tagging standards across accounts.

## Features

- **Tag Key Enforcement** - Define required tag keys with exact casing to ensure consistent naming across all member accounts
- **Tag Value Restrictions** - Optionally restrict tag values to an approved list, preventing non-compliant values
- **Resource Type Enforcement** - Specify which AWS resource types (e.g., ec2:instance, s3:bucket) must comply with the tag policy
- **Child Policy Operators** - Control which operators child OUs can use to modify tag keys, values, and enforcement targets via `operators_allowed_for_child_policies`
- **Flexible Operators** - Use `@@assign`, `@@append`, or `@@remove` operators for tag keys, values, and enforced-for targets to build layered policies
- **Flexible Attachment** - Attach the tag policy to specific OUs or to the entire organization root
- **Skip Destroy** - Option to protect the policy from accidental deletion during destroy operations
- **Input Validation** - Built-in validation ensures OU IDs follow the correct format, tag keys are non-empty, and enforced-for targets use valid service:resource patterns

## Usage

```hcl
module "tag_policy" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//tag-policy?depth=1&ref=master"

  name        = "mandatory-tags"
  description = "Enforce mandatory tags across all accounts"

  tag_policy = {
    Environment = {
      tag_key      = "Environment"
      values       = ["production", "staging", "development"]
      enforced_for = ["ec2:instance", "s3:bucket"]
    }
    CostCenter = {
      tag_key      = "CostCenter"
      enforced_for = ["ec2:instance"]
    }
  }

  attach_ous = ["ou-abc1-12345678"]

  tags = {
    Environment = "organization"
  }
}
```


## Examples

## Basic Usage

Enforce a single `Environment` tag on all EC2 instances across a specific OU.

```hcl
module "tag_policy_environment" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//tag-policy?depth=1&ref=master"

  name        = "enforce-environment-tag"
  description = "Enforces the Environment tag on EC2 instances"

  attach_ous = ["ou-ab12-cd345678"]

  tag_policy = {
    Environment = {
      tag_key = "Environment"
      values  = ["production", "staging", "development"]
      enforced_for = [
        "ec2:instance",
      ]
    }
  }

  tags = {
    Team      = "platform"
    ManagedBy = "terraform"
  }
}
```

## Multiple Tag Rules on Multiple OUs

Enforce both `Environment` and `CostCenter` tags across two OUs.

```hcl
module "tag_policy_multi_ou" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//tag-policy?depth=1&ref=master"

  name        = "baseline-tag-policy"
  description = "Baseline tag policy enforcing Environment and CostCenter tags"

  attach_ous = [
    "ou-ab12-cd345678",
    "ou-ab12-ef901234",
  ]

  tag_policy = {
    Environment = {
      tag_key = "Environment"
      values  = ["production", "staging", "development", "sandbox"]
      enforced_for = [
        "ec2:instance",
        "rds:db",
        "s3:bucket",
      ]
    }
    CostCenter = {
      tag_key = "CostCenter"
      enforced_for = [
        "ec2:instance",
        "rds:db",
        "elasticache:cluster",
      ]
    }
  }

  tags = {
    Team      = "platform"
    ManagedBy = "terraform"
  }
}
```

## Attach to the Entire Organization

Apply a tag policy at the organization root, preventing accidental deletion with `skip_destroy`.

```hcl
module "tag_policy_org_wide" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//tag-policy?depth=1&ref=master"

  name        = "org-mandatory-tags"
  description = "Organization-wide mandatory tag policy"

  attach_to_org = true
  attach_ous    = ["ou-ab12-cd345678"] # satisfies the validation constraint even when attach_to_org = true
  skip_destroy  = true

  tag_policy = {
    Owner = {
      tag_key = "Owner"
      enforced_for = [
        "ec2:instance",
        "rds:db",
        "lambda:function",
        "s3:bucket",
        "elasticloadbalancing:loadbalancer",
      ]
    }
    Project = {
      tag_key = "Project"
    }
  }

  tags = {
    Team      = "platform"
    ManagedBy = "terraform"
  }
}
```

## Enforced Values with Child Policy Delegation

Allow child OUs to extend the `Environment` allowed values but lock down the tag key casing.

```hcl
module "tag_policy_delegated" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//tag-policy?depth=1&ref=master"

  name        = "environment-tag-delegated"
  description = "Enforces Environment tag with child policy delegation"

  attach_ous = ["ou-ab12-cd345678"]
  skip_destroy = true

  tag_policy = {
    Environment = {
      tag_key                                           = "Environment"
      tag_key_operator                                  = "@@assign"
      tag_key_operators_allowed_for_child_policies      = ["@@assign"]
      values                                            = ["production", "staging", "development"]
      values_operator                                   = "@@assign"
      values_operators_allowed_for_child_policies       = ["@@assign", "@@append", "@@remove"]
      enforced_for = [
        "ec2:instance",
        "rds:db",
      ]
    }
  }

  tags = {
    Team        = "platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```
