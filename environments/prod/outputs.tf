output "api_url" {
  description = "HTTP API base URL"
  value       = module.api.api_url
}

output "machine_api_url" {
  description = "Machine-token API base URL"
  value       = module.api.machine_api_url
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

output "reference_assets_bucket_name" {
  description = "S3 bucket receiving reference media uploaded by the ETL"
  value       = module.reference_assets.bucket_name
}

output "reference_assets_cdn_domain" {
  description = "CloudFront domain serving reference media assets"
  value       = module.reference_assets.distribution_domain_name
}

output "site_url" {
  description = "Canonical Langler URL"
  value       = module.frontend.site_url
}

output "table_name" {
  description = "DynamoDB single-table name"
  value       = module.storage.table_name
}

output "alerts_topic_arn" {
  description = "SNS topic ARN carrying alarm and budget notifications"
  value       = module.monitoring.alerts_topic_arn
}
