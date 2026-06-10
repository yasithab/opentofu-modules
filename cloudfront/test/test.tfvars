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
  # AWS managed CachingOptimized policy
  cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
}
ordered_cache_behavior = [
  {
    path_pattern           = "/static/*"
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    # AWS managed CachingOptimized policy
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }
]
