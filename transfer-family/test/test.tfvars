name = "terratest-plan"

connectors = {
  partner = {
    url            = "sftp://sftp.partner.example.com"
    access_role    = "arn:aws:iam::123456789012:role/transfer-connector-access"
    user_secret_id = "arn:aws:secretsmanager:eu-west-1:123456789012:secret:transfer/partner-abc123"
  }
}
