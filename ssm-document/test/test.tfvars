name            = "terratest-plan-doc"
document_type   = "Command"
document_format = "JSON"

content = <<-EOT
{
  "schemaVersion": "2.2",
  "description": "terratest plan fixture",
  "mainSteps": [
    {
      "action": "aws:runShellScript",
      "name": "example",
      "inputs": { "runCommand": ["echo hello"] }
    }
  ]
}
EOT
