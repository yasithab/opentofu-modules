name = "terratest-plan"

create_log_streams = true

log_streams = {
  sample-stream = {}
  custom-named = {
    name = "terratest-plan-stream"
  }
}

data_protection_policy_document = <<EOT
{
  "Name": "terratest-plan-data-protection",
  "Version": "2021-06-01",
  "Statement": [
    {
      "Sid": "Audit",
      "DataIdentifier": ["arn:aws:dataprotection::aws:data-identifier/EmailAddress"],
      "Operation": {
        "Audit": {
          "FindingsDestination": {}
        }
      }
    },
    {
      "Sid": "Redact",
      "DataIdentifier": ["arn:aws:dataprotection::aws:data-identifier/EmailAddress"],
      "Operation": {
        "Deidentify": {
          "MaskConfig": {}
        }
      }
    }
  ]
}
EOT

anomaly_detector = {
  evaluation_frequency = "FIVE_MIN"
}
