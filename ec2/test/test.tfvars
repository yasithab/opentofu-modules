name          = "terratest-plan"
ami           = "ami-0c02fb55956c7d316"
instance_type = "t3.micro"
subnet_id     = "subnet-12345678"

create_iam_instance_profile = true
iam_role_name               = "terratest-plan"

root_block_device = [
  {
    volume_size = 20
    volume_type = "gp3"
  }
]

ebs_block_device = [
  {
    device_name = "/dev/sdf"
    volume_size = 10
    volume_type = "gp3"
  }
]
