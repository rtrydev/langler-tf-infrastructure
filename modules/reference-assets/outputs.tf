output "bucket_name" {
  description = "Private S3 bucket containing reference media assets"
  value       = aws_s3_bucket.assets.id
}

output "bucket_arn" {
  description = "ARN of the reference assets bucket"
  value       = aws_s3_bucket.assets.arn
}

output "distribution_domain_name" {
  description = "CloudFront domain name serving the reference assets"
  value       = aws_cloudfront_distribution.assets.domain_name
}

output "distribution_id" {
  description = "CloudFront distribution identifier used for invalidations"
  value       = aws_cloudfront_distribution.assets.id
}
