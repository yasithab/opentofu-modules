name   = "terratest-plan"
vpc_id = "vpc-0123456789abcdef0"

compute_resources = {
  type      = "FARGATE"
  max_vcpus = 4
  subnets   = ["subnet-12345678"]
}

job_queues = {
  default = {
    name     = "terratest-plan-default"
    priority = 1
  }
}

job_definitions = {
  hello = {
    name                 = "terratest-plan-hello"
    container_properties = "{\"image\":\"public.ecr.aws/amazonlinux/amazonlinux:latest\",\"command\":[\"echo\",\"hello\"],\"resourceRequirements\":[{\"type\":\"VCPU\",\"value\":\"0.25\"},{\"type\":\"MEMORY\",\"value\":\"512\"}]}"
  }
}
