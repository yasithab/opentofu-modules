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

## Reference

<details>
<summary>Requirements, providers, inputs and outputs (generated by terraform-docs)</summary>

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
| address\_allocation\_ids | List of Elastic IP allocation IDs for VPC endpoint. | `list(string)` | `[]` | no |
| certificate\_arn | ARN of the ACM certificate for FTPS protocol. | `string` | `null` | no |
| connectors | Map of outbound SFTP connectors used to transfer files to remote SFTP servers. `url` is the remote endpoint (sftp://...), `access_role` is the IAM role the connector assumes, `user_secret_id` is the Secrets Manager secret holding the SFTP credentials, and `trusted_host_keys` pins the remote server's public host keys. | <pre>map(object({<br/>    url                  = string<br/>    access_role          = string<br/>    logging_role         = optional(string)<br/>    security_policy_name = optional(string)<br/>    trusted_host_keys    = optional(list(string))<br/>    user_secret_id       = optional(string)<br/>  }))</pre> | `{}` | no |
| create\_logging\_role | Whether to create an IAM role for CloudWatch logging. | `bool` | `true` | no |
| directory\_id | Directory ID for AWS Directory Service identity provider. | `string` | `null` | no |
| domain | Storage domain. Valid values: `S3`, `EFS`. | `string` | `"S3"` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| endpoint\_type | Endpoint type. Valid values: `PUBLIC`, `VPC`. | `string` | `"PUBLIC"` | no |
| force\_destroy | Whether to force-destroy the server even if it contains users. | `bool` | `false` | no |
| host\_key | RSA, ECDSA, or ED25519 private key for the server. | `string` | `null` | no |
| identity\_provider\_function\_arn | ARN of the Lambda function for custom identity provider (AWS\_LAMBDA type). | `string` | `null` | no |
| identity\_provider\_invocation\_role\_arn | IAM role ARN for invoking the API Gateway identity provider. | `string` | `null` | no |
| identity\_provider\_type | Identity provider type. Valid values: `SERVICE_MANAGED`, `API_GATEWAY`, `AWS_DIRECTORY_SERVICE`, `AWS_LAMBDA`. | `string` | `"SERVICE_MANAGED"` | no |
| identity\_provider\_url | URL of the API Gateway for custom identity provider (API\_GATEWAY type). | `string` | `null` | no |
| logging\_role\_arn | ARN of an existing IAM role for CloudWatch logging. Used when `create_logging_role` is false. | `string` | `null` | no |
| name | Name used as a prefix for all Transfer Family resources. | `string` | n/a | yes |
| post\_authentication\_display\_banner | Banner message displayed after authentication. | `string` | `null` | no |
| pre\_authentication\_login\_banner | Banner message displayed before authentication. | `string` | `null` | no |
| protocol\_details | Protocol-specific settings including passive IP, SetStat option, TLS session resumption, and AS2 transports. | `any` | `null` | no |
| protocols | List of file transfer protocols. Valid values: `SFTP`, `FTPS`, `FTP`, `AS2`. | `list(string)` | <pre>[<br/>  "SFTP"<br/>]</pre> | no |
| route53\_records | Map of Route53 record configurations for custom hostnames. | `any` | `{}` | no |
| s3\_storage\_options | S3 storage options including directory listing optimization. | `any` | `null` | no |
| security\_group\_ids | List of security group IDs for VPC endpoint. | `list(string)` | `[]` | no |
| security\_policy\_name | Name of the security policy attached to the server. See AWS documentation for valid values. | `string` | `"TransferSecurityPolicy-2024-01"` | no |
| structured\_log\_destinations | List of CloudWatch Log Group ARNs for structured JSON logging. | `list(string)` | `[]` | no |
| subnet\_ids | List of subnet IDs for VPC endpoint. | `list(string)` | `[]` | no |
| tags | Map of tags to apply to all resources. | `map(string)` | `{}` | no |
| users | Map of Transfer Family user configurations including home directory, policy, and SSH keys. | <pre>map(object({<br/>    user_name           = string<br/>    role                = string<br/>    home_directory      = optional(string)<br/>    home_directory_type = optional(string)<br/>    policy              = optional(string)<br/>    home_directory_mappings = optional(list(object({<br/>      entry  = string<br/>      target = string<br/>    })), [])<br/>    posix_profile = optional(object({<br/>      gid            = number<br/>      uid            = number<br/>      secondary_gids = optional(list(number))<br/>    }))<br/>    ssh_public_key = optional(string)<br/>  }))</pre> | `{}` | no |
| vpc\_id | VPC ID for VPC endpoint type. Required when `endpoint_type` is `VPC`. | `string` | `null` | no |
| workflow\_on\_partial\_upload | Workflow configuration triggered on partial file upload. | <pre>object({<br/>    execution_role = string<br/>    workflow_id    = string<br/>  })</pre> | `null` | no |
| workflow\_on\_upload | Workflow configuration triggered on file upload. | <pre>object({<br/>    execution_role = string<br/>    workflow_id    = string<br/>  })</pre> | `null` | no |
| workflows | Map of workflow configurations with steps and exception handling. | `any` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| connector\_arns | Map of Transfer Family connector ARNs. |
| connector\_ids | Map of Transfer Family connector IDs. |
| logging\_role\_arn | The ARN of the Transfer Family logging IAM role. |
| route53\_record\_fqdns | Map of Route53 record FQDNs for custom hostnames. |
| server\_arn | The ARN of the Transfer Family server. |
| server\_endpoint | The endpoint of the Transfer Family server. |
| server\_host\_key\_fingerprint | The host key fingerprint of the Transfer Family server. |
| server\_id | The ID of the Transfer Family server. |
| server\_name | The name of the Transfer Family server. |
| user\_arns | Map of Transfer Family user ARNs. |
| user\_names | Map of Transfer Family user names. |
| workflow\_arns | Map of Transfer Family workflow ARNs. |
| workflow\_ids | Map of Transfer Family workflow IDs. |
<!-- END_TF_DOCS -->

</details>
