output "api_url" {
  description = "HTTP API base URL"
  value       = module.api.api_url
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID used by the deploy script"
  value       = module.frontend.distribution_id
}

output "cognito_client_id" {
  description = "Public Cognito browser client ID"
  value       = module.auth.client_id
}

output "cognito_user_pool_id" {
  description = "Cognito pool ID used to provision invited users"
  value       = module.auth.user_pool_id
}

output "frontend_bucket_name" {
  description = "S3 bucket receiving the static export"
  value       = module.frontend.bucket_name
}

output "site_url" {
  description = "Canonical Langler URL"
  value       = module.frontend.site_url
}

output "table_name" {
  description = "DynamoDB single-table name"
  value       = module.storage.table_name
}
