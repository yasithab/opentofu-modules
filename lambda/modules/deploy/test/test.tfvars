alias_name            = "terratest"
function_name         = "terratest-function"
target_version        = "1"
current_version       = "1"
app_name              = "terratest-deploy"
deployment_group_name = "terratest-deploy-group"

# Exercise the CodeDeploy app + deployment group + IAM role paths so the
# plan creates real resources (plan-only; nothing is applied in CI).
enabled                 = true
create_app              = true
create_deployment_group = true
create_codedeploy_role  = true
create_deployment       = false
