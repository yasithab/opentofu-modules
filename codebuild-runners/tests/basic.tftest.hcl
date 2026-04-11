run "validate" {
  command = plan

  variables {
    enabled = false
    codebuild_subnets = []
  }
}
