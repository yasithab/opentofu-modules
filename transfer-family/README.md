# AWS Transfer Family

OpenTofu module for provisioning AWS Transfer Family servers with support for SFTP, FTPS, FTP, and AS2 protocols, multiple identity providers, and S3/EFS storage backends.

> **Security trade-off — `endpoint_type` defaults to `PUBLIC`:** a PUBLIC endpoint is reachable from the entire internet and offers no network-level access control (no security groups, no IP allowlisting) — access is gated only by authentication. To restrict client IPs, use `endpoint_type = "VPC"` with `security_group_ids` (and optionally `address_allocation_ids` for static Elastic IPs).

## Features

- **Multi-Protocol Support** - SFTP, FTPS, FTP, and AS2 protocol configuration on a single server
- **Identity Providers** - Service-managed, API Gateway, AWS Directory Service, and Lambda identity provider types
- **Endpoint Types** - Public and VPC endpoint types with configurable subnets, security groups, and Elastic IP allocation
- **User Management** - Transfer users with home directory mappings, session policies, POSIX profiles, and SSH key management
- **Workflows** - File processing workflows triggered on upload and partial upload with copy, custom, delete, and tag step types
- **Security Policies** - Configurable security policy selection for protocol cipher and key exchange algorithms
- **Structured Logging** - CloudWatch structured JSON logging with automatic IAM role creation
- **Storage Backends** - S3 and EFS domain support with S3 directory listing optimization
- **Custom Hostnames** - Route53 CNAME record creation for branded SFTP endpoints
- **Banner Messages** - Pre-authentication and post-authentication banner messages for compliance
- **SFTP Connectors** - Outbound connectors (`connectors`) for pushing files to remote SFTP servers with Secrets Manager credentials and trusted host key pinning

## Usage

```hcl
module "transfer" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//transfer-family?depth=1&ref=master"

  name      = "my-sftp-server"
  protocols = ["SFTP"]
  domain    = "S3"

  users = {
    data_team = {
      user_name      = "data-team"
      role           = "arn:aws:iam::123456789012:role/transfer-user-role"
      home_directory = "/my-bucket/data-team"
    }
  }

  tags = {
    Environment = "production"
  }
}
```

## Examples

### SFTP Server with VPC Endpoint

A private SFTP server accessible only within a VPC with multiple users and SSH key authentication.

```hcl
module "sftp_vpc" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//transfer-family?depth=1&ref=master"

  name          = "secure-sftp"
  protocols     = ["SFTP"]
  endpoint_type = "VPC"
  domain        = "S3"

  vpc_id             = "vpc-0abc123def456789a"
  subnet_ids         = ["subnet-0abc123def456789a", "subnet-0def456789abc123a"]
  security_group_ids = ["sg-0abc123def456789a"]

  security_policy_name = "TransferSecurityPolicy-2024-01"

  structured_log_destinations = [
    "arn:aws:logs:us-east-1:123456789012:log-group:/aws/transfer/secure-sftp:*"
  ]

  users = {
    vendor_a = {
      user_name           = "vendor-a"
      role                = "arn:aws:iam::123456789012:role/transfer-vendor-role"
      home_directory_type = "LOGICAL"
      home_directory_mappings = [
        { entry = "/", target = "/my-bucket/vendors/vendor-a" }
      ]
      ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAA... vendor-a@example.com"
    }
    vendor_b = {
      user_name           = "vendor-b"
      role                = "arn:aws:iam::123456789012:role/transfer-vendor-role"
      home_directory_type = "LOGICAL"
      home_directory_mappings = [
        { entry = "/", target = "/my-bucket/vendors/vendor-b" }
      ]
      ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAA... vendor-b@example.com"
    }
  }

  route53_records = {
    sftp = {
      zone_id = "Z0123456789ABCDEFGHIJ"
      name    = "sftp.example.com"
    }
  }

  tags = {
    Environment = "production"
    Compliance  = "pci-dss"
  }
}
```

### FTPS Server with EFS Backend

An FTPS server using EFS storage with POSIX profile user configuration.

```hcl
module "ftps_efs" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//transfer-family?depth=1&ref=master"

  name          = "ftps-efs-server"
  protocols     = ["FTPS"]
  domain        = "EFS"
  certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc-123"

  users = {
    app_user = {
      user_name      = "app-user"
      role           = "arn:aws:iam::123456789012:role/transfer-efs-role"
      home_directory = "/fs-0abc123def456789a/app"
      posix_profile = {
        uid = 1000
        gid = 1000
      }
    }
  }

  tags = {
    Environment = "production"
  }
}
```

### SFTP with Upload Workflow

An SFTP server with an automated file processing workflow triggered on upload.

```hcl
module "sftp_workflow" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//transfer-family?depth=1&ref=master"

  name      = "sftp-with-workflow"
  protocols = ["SFTP"]

  workflows = {
    process_uploads = {
      description = "Process uploaded files"
      steps = [
        {
          type = "COPY"
          copy_step_details = {
            name = "copy-to-archive"
            destination_file_location = {
              s3_file_location = {
                bucket = "my-archive-bucket"
                key    = "archive/"
              }
            }
          }
        },
        {
          type = "CUSTOM"
          custom_step_details = {
            name            = "validate-file"
            target          = "arn:aws:lambda:us-east-1:123456789012:function:validate-upload"
            timeout_seconds = 60
          }
        }
      ]
    }
  }

  tags = {
    Environment = "production"
  }
}
```

### Outbound SFTP Connectors

Connectors transfer files from your S3 storage to remote SFTP servers. Credentials live in Secrets Manager and the remote server's host keys can be pinned via `trusted_host_keys`.

```hcl
module "sftp_connectors" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//transfer-family?depth=1&ref=master"

  name      = "partner-exchange"
  protocols = ["SFTP"]

  connectors = {
    partner-bank = {
      url            = "sftp://sftp.partner-bank.example.com"
      access_role    = "arn:aws:iam::123456789012:role/transfer-connector-access"
      user_secret_id = "arn:aws:secretsmanager:us-east-1:123456789012:secret:transfer/partner-bank-abc123"
      trusted_host_keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQ..."
      ]
    }
    vendor-feed = {
      url                  = "sftp://feeds.vendor.example.com"
      access_role          = "arn:aws:iam::123456789012:role/transfer-connector-access"
      user_secret_id       = "arn:aws:secretsmanager:us-east-1:123456789012:secret:transfer/vendor-feed-def456"
      security_policy_name = "TransferSFTPConnectorSecurityPolicy-2024-03"
    }
  }

  tags = {
    Environment = "production"
  }
}
```
