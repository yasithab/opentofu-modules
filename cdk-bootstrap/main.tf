locals {
  enabled = var.enabled
}

data "aws_caller_identity" "this" {}

resource "null_resource" "cdk_bootstrap" {
  provisioner "local-exec" {
    command = format(
      "cdk bootstrap --termination-protection true aws://%s/%s %s %s",
      data.aws_caller_identity.this.account_id,
      var.region,
      var.cloudformation_execution_policy_arns != null ? "--cloudformation-execution-policies ${join(",", var.cloudformation_execution_policy_arns)}" : "",
      var.trust_account_ids != null ? "--trust ${join(",", var.trust_account_ids)}" : ""
    )
  }

  triggers = {
    region                              = var.region
    cloudformation_execution_policy_arn = var.cloudformation_execution_policy_arns != null ? join(",", var.cloudformation_execution_policy_arns) : ""
    trust_account_id                    = var.trust_account_ids != null ? "--trust ${join(",", var.trust_account_ids)}" : ""
  }

  lifecycle {
    enabled = local.enabled
  }
}
