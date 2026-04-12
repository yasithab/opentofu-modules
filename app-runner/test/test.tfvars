service_name = "terratest-plan"
source_configuration = {
  image_repository = {
    image_identifier      = "public.ecr.aws/nginx/nginx:latest"
    image_repository_type = "ECR_PUBLIC"
    image_configuration   = { port = "80" }
  }
}
