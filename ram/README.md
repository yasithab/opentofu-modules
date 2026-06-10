# RAM

Manages AWS Resource Access Manager (RAM) resource shares for sharing AWS resources across accounts and organizational units.

## Features

- **Resource Sharing** - Create RAM resource shares and associate any shareable AWS resource by ARN
- **Flexible Principal Targeting** - Share with specific AWS account IDs, Organization ARNs, or OU ARNs; defaults to the entire Organization when no principals are specified
- **Organization-Wide Sharing** - Optionally enable RAM sharing with AWS Organizations to eliminate the need for individual share invitations
- **Custom Permissions** - Attach specific RAM permission ARNs to control the level of access granted to shared resources
- **Organization-Wide Sharing** - Set `enable_sharing_with_organization = true` to enable RAM sharing with AWS Organizations, eliminating the need for individual share invitations
- **Custom Permissions** - Attach specific RAM permission ARNs via `permission_arns` to control the level of access granted to shared resources
- **Feature Flag** - Disable all resource creation with a single `enabled` toggle

## Usage

```hcl
module "ram_share" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ram?depth=1&ref=master"

  name                    = "transit-gateway-share"
  ram_resource_arn        = "arn:aws:ec2:us-east-1:123456789012:transit-gateway/tgw-0abc123def456789"

  tags = {
    Environment = "shared"
    Team        = "network"
  }
}
```


## Examples

## Basic Usage

Share a Transit Gateway with the entire AWS Organisation (no explicit principals required).

```hcl
module "tgw_ram_share" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ram?depth=1&ref=master"

  enabled = true

  name                    = "transit-gateway-share"
  ram_resource_arn        = "arn:aws:ec2:us-east-1:123456789012:transit-gateway/tgw-0abc123def456789"

  tags = {
    Environment = "shared"
    Team        = "network"
  }
}
```

## Share with Specific Accounts

Share a resource with a list of specific AWS account IDs.

```hcl
module "subnet_ram_share" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ram?depth=1&ref=master"

  enabled = true

  name                    = "shared-subnets"
  ram_resource_arn        = "arn:aws:ec2:us-east-1:123456789012:subnet/subnet-0aa111bbb222ccc333"

  ram_principals = [
    "111122223333",
    "444455556666",
  ]

  tags = {
    Environment = "shared"
    Team        = "network"
  }
}
```

## Share with an Organisational Unit

Share a resource with a specific OU inside the AWS Organisation.

```hcl
module "resolver_rule_ram_share" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ram?depth=1&ref=master"

  enabled = true

  name                    = "dns-resolver-rules"
  ram_resource_arn        = "arn:aws:route53resolver:us-east-1:123456789012:resolver-rule/rslvr-rr-0abc123def456789"

  ram_principals = [
    "arn:aws:organizations::123456789012:ou/o-aa111bbb22/ou-aabb-11223344",
  ]

  allow_external_principals = false

  tags = {
    Environment = "shared"
    Team        = "network"
  }
}
```

## Disabled (Feature Flag)

Resource share defined in code but not created until the flag is enabled.

```hcl
module "tgw_ram_share_disabled" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ram?depth=1&ref=master"

  enabled = false

  name                    = "future-tgw-share"
  ram_resource_arn        = "arn:aws:ec2:eu-west-1:123456789012:transit-gateway/tgw-0abc123def456789"

  tags = {
    Environment = "staging"
    Team        = "network"
  }
}
```

## Notes

### Switching to/from organization-wide sharing recreates associations

When `ram_principals` is empty, the module shares with the entire organization by using the
Organization ARN as the principal. Later providing explicit `ram_principals` (or clearing them
again) changes the principal association keys, so OpenTofu **destroys and recreates** the
`aws_ram_principal_association` resources. During that replacement window, consumers briefly
lose access to the shared resource - plan such a change for a maintenance window if the share
backs live traffic (e.g. a shared Transit Gateway).

Also note `aws_ram_sharing_with_organization` is an organization-wide, account-level setting:
destroying it disables RAM sharing with AWS Organizations for the whole account, affecting
*all* resource shares, not only the one managed by this module.
