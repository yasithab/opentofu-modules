################################################################################
# User Pool
################################################################################

output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = try(aws_cognito_user_pool.this.id, null)
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = try(aws_cognito_user_pool.this.arn, null)
}

output "user_pool_endpoint" {
  description = "Cognito User Pool endpoint (use as OIDC issuer URL)"
  value       = try("https://${aws_cognito_user_pool.this.endpoint}", null)
}

output "oidc_issuer" {
  description = "OIDC issuer URL for this User Pool. Use this as the issuer in any OIDC-compatible application."
  value       = try("https://cognito-idp.${data.aws_region.current.id}.amazonaws.com/${aws_cognito_user_pool.this.id}", null)
}

################################################################################
# Domain
################################################################################

output "domain" {
  description = "Cognito hosted UI domain"
  value = try(
    var.custom_domain != "" ? var.custom_domain : "${var.domain}.auth.${data.aws_region.current.id}.amazoncognito.com",
    null,
  )
}

output "hosted_ui_url" {
  description = "Cognito hosted UI base URL for login"
  value = try(
    var.custom_domain != "" ? "https://${var.custom_domain}" : "https://${var.domain}.auth.${data.aws_region.current.id}.amazoncognito.com",
    null,
  )
}

################################################################################
# Clients
################################################################################

output "client_ids" {
  description = "Map of client name to client ID"
  value       = { for k, v in aws_cognito_user_pool_client.this : k => v.id }
}

output "client_secrets" {
  description = "Map of client name to client secret (sensitive)"
  value       = { for k, v in aws_cognito_user_pool_client.this : k => v.client_secret }
  sensitive   = true
}

################################################################################
# OIDC Config (convenience - first client)
################################################################################

output "oidc_config" {
  description = "Ready-to-use OIDC configuration for the first client. Contains issuer and client_id. Store client_secret in Secrets Manager separately for production use."
  value = length(var.clients) > 0 ? {
    issuer    = "https://cognito-idp.${data.aws_region.current.id}.amazonaws.com/${aws_cognito_user_pool.this.id}"
    client_id = try(values(aws_cognito_user_pool_client.this)[0].id, "")
  } : null
}

output "oidc_config_with_secret" {
  description = "OIDC configuration including client_secret for the first client. Use for development only - for production, store the secret in Secrets Manager instead."
  value = length(var.clients) > 0 ? {
    issuer        = "https://cognito-idp.${data.aws_region.current.id}.amazonaws.com/${aws_cognito_user_pool.this.id}"
    client_id     = try(values(aws_cognito_user_pool_client.this)[0].id, "")
    client_secret = try(values(aws_cognito_user_pool_client.this)[0].client_secret, "")
  } : null
  sensitive = true
}
