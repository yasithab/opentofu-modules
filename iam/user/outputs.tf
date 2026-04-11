# --- IAM User ---

output "name" {
  description = "The name of the IAM user."
  value       = try(aws_iam_user.this.name, "")
}

output "arn" {
  description = "The ARN assigned by AWS for this user."
  value       = try(aws_iam_user.this.arn, "")
}

output "unique_id" {
  description = "The unique ID assigned by AWS."
  value       = try(aws_iam_user.this.unique_id, "")
}

output "tags_all" {
  description = "A map of tags assigned to the user, including those inherited from the provider."
  value       = try(aws_iam_user.this.tags_all, {})
}

# --- Login Profile ---

output "login_profile_password" {
  description = "The encrypted password, base64 encoded. Only available if pgp_key is supplied."
  value       = try(aws_iam_user_login_profile.this.encrypted_password, "")
  sensitive   = true
}

output "login_profile_key_fingerprint" {
  description = "The fingerprint of the PGP key used to encrypt the password."
  value       = try(aws_iam_user_login_profile.this.key_fingerprint, "")
}

# --- Access Key ---

output "access_key_id" {
  description = "The access key ID."
  value       = try(aws_iam_access_key.this.id, "")
}

output "access_key_secret" {
  description = "The access key secret. Only available when pgp_key is not supplied."
  value       = try(aws_iam_access_key.this.secret, "")
  sensitive   = true
}

output "access_key_encrypted_secret" {
  description = "The encrypted secret, base64 encoded. Only available if pgp_key is supplied."
  value       = try(aws_iam_access_key.this.encrypted_secret, "")
  sensitive   = true
}

output "access_key_encrypted_ses_smtp_password_v4" {
  description = "The encrypted SES SMTP password, base64 encoded. Only available if pgp_key is supplied."
  value       = try(aws_iam_access_key.this.encrypted_ses_smtp_password_v4, "")
  sensitive   = true
}

output "access_key_ses_smtp_password_v4" {
  description = "The SES SMTP password. Only available when pgp_key is not supplied."
  value       = try(aws_iam_access_key.this.ses_smtp_password_v4, "")
  sensitive   = true
}

output "access_key_key_fingerprint" {
  description = "The fingerprint of the PGP key used to encrypt the secret."
  value       = try(aws_iam_access_key.this.key_fingerprint, "")
}

output "access_key_status" {
  description = "The status of the access key (Active or Inactive)."
  value       = try(aws_iam_access_key.this.status, "")
}

# --- SSH Public Key ---

output "ssh_key_id" {
  description = "The unique identifier for the SSH public key."
  value       = try(aws_iam_user_ssh_key.this.ssh_public_key_id, "")
}

output "ssh_key_fingerprint" {
  description = "The MD5 message digest of the SSH public key."
  value       = try(aws_iam_user_ssh_key.this.fingerprint, "")
}

# --- Virtual MFA Device ---

output "virtual_mfa_device_arn" {
  description = "The ARN of the virtual MFA device."
  value       = try(aws_iam_virtual_mfa_device.this.arn, "")
}

output "virtual_mfa_device_base_32_string_seed" {
  description = "The base32 seed defined as specified in RFC 3548. Used to configure MFA applications."
  value       = try(aws_iam_virtual_mfa_device.this.base_32_string_seed, "")
  sensitive   = true
}

output "virtual_mfa_device_qr_code_png" {
  description = "A QR code PNG image that encodes the MFA seed. Base64 encoded."
  value       = try(aws_iam_virtual_mfa_device.this.qr_code_png, "")
  sensitive   = true
}

# --- Group Membership ---

output "group_membership" {
  description = "The list of groups the user belongs to."
  value       = try(aws_iam_user_group_membership.this.groups, [])
}
