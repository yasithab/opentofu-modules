user_group_id = "terratest"
engine        = "REDIS"
default_user = {
  user_id              = "default-terratest"
  no_password_required = true
  authentication_mode  = { type = "no-password-required" }
}
