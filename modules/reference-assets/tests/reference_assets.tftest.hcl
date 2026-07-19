mock_provider "aws" {}

run "plans_with_required_inputs" {
  command = plan

  variables {
    name           = "langler-prod"
    allowed_origin = "https://langler.example.com"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.assets.restrict_public_buckets
    error_message = "The assets origin must block public access."
  }

  assert {
    condition     = toset(aws_cloudfront_distribution.assets.default_cache_behavior[0].allowed_methods) == toset(["GET", "HEAD"])
    error_message = "The distribution must allow only read methods."
  }

  assert {
    condition     = aws_cloudfront_distribution.assets.default_cache_behavior[0].viewer_protocol_policy == "redirect-to-https"
    error_message = "Viewers must be redirected to HTTPS."
  }

  assert {
    condition     = aws_cloudfront_origin_access_control.assets.signing_behavior == "always" && aws_cloudfront_origin_access_control.assets.signing_protocol == "sigv4"
    error_message = "Origin access control must always sign origin requests with SigV4."
  }

  assert {
    condition     = one(aws_cloudfront_response_headers_policy.assets.cors_config[0].access_control_allow_origins[0].items) == "https://langler.example.com"
    error_message = "The distribution must expose assets only to the configured browser origin."
  }

  assert {
    condition     = toset(aws_cloudfront_response_headers_policy.assets.cors_config[0].access_control_allow_methods[0].items) == toset(["GET", "HEAD"])
    error_message = "The response policy must allow only browser read methods."
  }
}

run "rejects_invalid_name" {
  command = plan

  variables {
    name           = "Langler_Prod"
    allowed_origin = "https://langler.example.com"
  }

  expect_failures = [var.name]
}
