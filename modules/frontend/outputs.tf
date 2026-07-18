output "bucket_name" {
  description = "Private S3 bucket containing the static export"
  value       = aws_s3_bucket.frontend.id
}

output "distribution_id" {
  description = "CloudFront distribution identifier used for invalidations"
  value       = aws_cloudfront_distribution.frontend.id
}

output "distribution_domain_name" {
  description = "CloudFront-assigned domain name"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "site_url" {
  description = "Canonical HTTPS URL of the frontend"
  value       = "https://${var.domain_name}"
}
