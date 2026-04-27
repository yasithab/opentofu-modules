name               = "terratest-plan"
engine             = "aurora-mysql"
engine_version     = "8.0.mysql_aurora.3.05.2"
instance_class     = "db.t3.medium"
instances          = { one = {} }
master_username    = "admin"
master_password_wo = "TerratestPlan123!"
vpc_id             = "vpc-12345678"
subnets            = ["subnet-12345678", "subnet-87654321"]
