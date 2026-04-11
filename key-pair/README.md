# EC2 Key Pair

OpenTofu module for creating and managing AWS EC2 key pairs with optional automatic TLS private key generation.

## Features

- **Key Pair Management** - Create EC2 key pairs from an existing public key or auto-generate a new key pair
- **Automatic Key Generation** - Optionally generate a TLS private key (RSA or ED25519) and derive the public key automatically
- **Configurable RSA Bits** - Choose key strength from 2048 to 4096 bits for RSA keys
- **Tags Support** - Full tagging support for the key pair resource

## Usage

```hcl
module "key_pair" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//key-pair?depth=1&ref=master"

  name       = "my-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ..."

  tags = {
    Environment = "production"
  }
}
```

## Examples

### Import Existing Public Key

Create a key pair by importing an existing SSH public key from a file.

```hcl
module "key_pair" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//key-pair?depth=1&ref=master"

  name       = "deployer-key"
  public_key = file("~/.ssh/id_rsa.pub")

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

### Auto-Generate Key Pair (RSA)

Automatically generate a 4096-bit RSA key pair. The private key is available as a sensitive output.

```hcl
module "key_pair" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//key-pair?depth=1&ref=master"

  name               = "auto-generated-key"
  create_private_key = true

  private_key_algorithm = "RSA"
  private_key_rsa_bits  = 4096

  tags = {
    Environment = "development"
  }
}

# Store the private key in SSM Parameter Store
resource "aws_ssm_parameter" "private_key" {
  name  = "/ec2/key-pairs/auto-generated-key"
  type  = "SecureString"
  value = module.key_pair.private_key_pem
}
```

### Auto-Generate ED25519 Key Pair

Generate an ED25519 key pair for improved security and performance.

```hcl
module "key_pair" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//key-pair?depth=1&ref=master"

  name               = "ed25519-key"
  create_private_key = true

  private_key_algorithm = "ED25519"

  tags = {
    Environment = "staging"
  }
}
```

### With Specific Key Name and Prefix

Use a name prefix to let OpenTofu generate a unique key name, avoiding collisions.

```hcl
module "key_pair" {
  source = "git::https://github.com/yasithab/opentofu-modules.git//key-pair?depth=1&ref=master"

  name_prefix        = "web-server-"
  create_private_key = true

  tags = {
    Environment = "production"
    Service     = "web"
  }
}
```
