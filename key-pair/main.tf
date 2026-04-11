locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  public_key = var.create_private_key ? trimspace(tls_private_key.this.public_key_openssh) : var.public_key
}

################################################################################
# Private Key (optional auto-generation)
################################################################################

resource "tls_private_key" "this" {
  algorithm = var.private_key_algorithm
  rsa_bits  = var.private_key_algorithm == "RSA" ? var.private_key_rsa_bits : null

  lifecycle {
    enabled = local.enabled && var.create_private_key
  }
}

################################################################################
# Key Pair
################################################################################

resource "aws_key_pair" "this" {
  key_name        = var.name
  key_name_prefix = var.name == null ? var.name_prefix : null
  public_key      = local.public_key

  tags = local.tags

  lifecycle {
    enabled = local.enabled
  }
}
