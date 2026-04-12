origin = {
  s3 = {
    domain_name = "terratest-bucket.s3.amazonaws.com"
    origin_id   = "s3-origin"
  }
}
default_cache_behavior = {
  target_origin_id       = "s3-origin"
  viewer_protocol_policy = "redirect-to-https"
  allowed_methods        = ["GET", "HEAD"]
  cached_methods         = ["GET", "HEAD"]
  use_forwarded_values   = false
  cache_policy_name      = "Managed-CachingOptimized"
}
