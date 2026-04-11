# AWS CodeConnections

Provisions AWS CodeConnections connections and hosts for integrating AWS services (CodeBuild, CodePipeline) with third-party source control providers such as GitHub, GitLab, and self-hosted GitHub Enterprise Server.

## Features

- **Multi-Provider Support** - Creates connections to GitHub, GitLab, Bitbucket, and other supported providers via the `provider_type` parameter
- **Self-Hosted VCS Hosts** - Optionally provisions a CodeConnections host for GitHub Enterprise Server or GitLab Self-Managed instances running in a VPC
- **VPC Configuration** - Connects to private VCS endpoints through VPC subnets and security groups, with optional TLS certificate validation
- **Existing Host Attachment** - Attaches a new connection to a pre-existing host ARN managed by a separate configuration
- **Configurable Timeouts** - Independent timeout settings for connection and host create/delete operations
- **Feature Flag** - Toggle all resource creation on or off with the `enabled` variable

## Usage

```hcl
module "codeconnections" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//codeconnections?depth=1&ref=master"

  github_organization_name = "MyOrganization"
  provider_type            = "GitHub"

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

> **Note:** After creation, the connection must be manually authorized in the AWS Console to transition from `PENDING` to `AVAILABLE`.


## Examples

## Basic Usage - GitHub Connection

Creates a CodeConnections connection to GitHub.com. After creation the connection must be manually authorised in the AWS Console to transition from `PENDING` to `AVAILABLE`.

```hcl
module "codeconnections_github" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//codeconnections?depth=1&ref=master"

  enabled = true

  github_organization_name = "MyOrganization"
  provider_type            = "GitHub"

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## GitLab Connection

Creates a connection to GitLab.com for pipelines that source code from GitLab repositories.

```hcl
module "codeconnections_gitlab" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//codeconnections?depth=1&ref=master"

  enabled = true

  # Works for any provider (GitHub, GitLab, Bitbucket) despite the variable name
  github_organization_name = "my-gitlab-group"
  provider_type            = "GitLab"

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## GitHub Enterprise Server (Self-Hosted) with VPC Configuration

Creates a CodeConnections host for a self-hosted GitHub Enterprise Server instance running inside a VPC, then connects to it. Use this when the GHE instance is not publicly reachable.

```hcl
module "codeconnections_ghe" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//codeconnections?depth=1&ref=master"

  enabled = true

  create_host           = true
  host_name             = "ghe-internal"
  host_provider_type    = "GitHubEnterpriseServer"
  host_provider_endpoint = "https://ghe.internal.example.com"

  host_vpc_configuration = {
    vpc_id             = "vpc-0abc1234def567890"
    subnet_ids         = ["subnet-0aaa111122223333", "subnet-0bbb444455556666"]
    security_group_ids = ["sg-0cc77788899900001"]
    tls_certificate    = "arn:aws:acm:us-east-1:123456789012:certificate/abc12345-1234-1234-1234-abcdef123456"
  }

  github_organization_name = "my-internal-org"

  host_timeouts = {
    create = "30m"
    delete = "30m"
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Existing Host - Attach Connection to Pre-Created Host

Attaches a new connection to an existing CodeConnections host ARN, for example when the host is managed by a separate Terraform configuration.

```hcl
module "codeconnections_existing_host" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//codeconnections?depth=1&ref=master"

  enabled = true

  github_organization_name = "MyOrganization"
  host_arn                 = "arn:aws:codeconnections:us-east-1:123456789012:host/ghe-internal-abc12345"

  connection_timeouts = {
    create = "30m"
    delete = "30m"
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```
