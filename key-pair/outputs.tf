################################################################################
# Key Pair
################################################################################

output "key_pair_id" {
  description = "The key pair ID"
  value       = try(aws_key_pair.this.key_pair_id, "")
}

output "key_pair_arn" {
  description = "The key pair ARN"
  value       = try(aws_key_pair.this.arn, "")
}

output "key_pair_name" {
  description = "The key pair name"
  value       = try(aws_key_pair.this.key_name, "")
}

output "key_pair_fingerprint" {
  description = "The MD5 public key fingerprint"
  value       = try(aws_key_pair.this.fingerprint, "")
}

output "key_pair_type" {
  description = "The key pair type"
  value       = try(aws_key_pair.this.key_type, "")
}

################################################################################
# Private Key
################################################################################

output "private_key_id" {
  description = "Unique identifier for the TLS private key"
  value       = try(tls_private_key.this.id, "")
}

output "private_key_pem" {
  description = "Private key data in PEM format. Sensitive."
  value       = try(tls_private_key.this.private_key_pem, "")
  sensitive   = true
}

output "private_key_openssh" {
  description = "Private key data in OpenSSH PEM format. Sensitive."
  value       = try(tls_private_key.this.private_key_openssh, "")
  sensitive   = true
}

output "public_key_pem" {
  description = "Public key data in PEM format"
  value       = try(tls_private_key.this.public_key_pem, "")
}

output "public_key_openssh" {
  description = "Public key data in OpenSSH authorized_keys format"
  value       = try(tls_private_key.this.public_key_openssh, "")
}

output "public_key_fingerprint_md5" {
  description = "MD5 fingerprint of the public key"
  value       = try(tls_private_key.this.public_key_fingerprint_md5, "")
}

output "public_key_fingerprint_sha256" {
  description = "SHA256 fingerprint of the public key"
  value       = try(tls_private_key.this.public_key_fingerprint_sha256, "")
}
