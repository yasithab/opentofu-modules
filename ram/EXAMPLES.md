# RAM Module - Examples

## Basic Usage

Share a Transit Gateway with the entire AWS Organisation (no explicit principals required).

```hcl
module "tgw_ram_share" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//ram?depth=1&ref=v2.0.0"

  enabled = true

  ram_resource_share_name = "transit-gateway-share"
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
  source = "git::https://github.com/yasithab/opentofu-modules.git//ram?depth=1&ref=v2.0.0"

  enabled = true

  ram_resource_share_name = "shared-subnets"
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
  source = "git::https://github.com/yasithab/opentofu-modules.git//ram?depth=1&ref=v2.0.0"

  enabled = true

  ram_resource_share_name = "dns-resolver-rules"
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
  source = "git::https://github.com/yasithab/opentofu-modules.git//ram?depth=1&ref=v2.0.0"

  enabled = false

  ram_resource_share_name = "future-tgw-share"
  ram_resource_arn        = "arn:aws:ec2:eu-west-1:123456789012:transit-gateway/tgw-0abc123def456789"

  tags = {
    Environment = "staging"
    Team        = "network"
  }
}
```
