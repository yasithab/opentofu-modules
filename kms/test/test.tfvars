description             = "Terratest plan KMS key"
deletion_window_in_days = 7
enable_key_rotation     = true
aliases                 = ["terratest/plan"]

key_administrators = ["arn:aws:iam::123456789012:role/KMSAdminRole"]
key_users          = ["arn:aws:iam::123456789012:role/AppRole"]

tags = {
  Environment = "test"
}
