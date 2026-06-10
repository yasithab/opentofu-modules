name           = "terratest-plan"
enabled        = true
admin_username = "admin"
namespace_name = "terratest"
workgroup_name = "terratest-workgroup"
subnet_ids     = ["subnet-12345678", "subnet-23456789", "subnet-34567890"]
vpc_id         = "vpc-12345678"
iam_role_name  = "terratest-redshift-role"

# keep the plan fixture minimal - namespace + workgroup only
endpoint_enabled = false
