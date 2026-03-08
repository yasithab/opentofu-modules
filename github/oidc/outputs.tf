output "openid_provider_arns" {
  description = "Map of OpenID Connect Provider ARNs"
  value = {
    for key, provider in aws_iam_openid_connect_provider.this :
    key => provider.arn
  }
}
