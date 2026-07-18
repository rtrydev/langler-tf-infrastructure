mock_provider "aws" {
  alias = "us_east_1"
}

mock_provider "aws" {}

run "plans_with_required_inputs" {
  command = plan

  variables {
    domain_name      = "langler.example.com"
    hosted_zone_name = "example.com"
    connect_sources  = ["https://api.example.com"]
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.frontend.restrict_public_buckets
    error_message = "The static origin must block public access."
  }

  assert {
    condition     = aws_cloudfront_distribution.frontend.default_root_object == "index.html"
    error_message = "CloudFront must serve the exported root document."
  }
}
