output "user_pool_id" {
  description = "Cognito user pool identifier used for owner provisioning"
  value       = aws_cognito_user_pool.users.id
}

output "user_pool_arn" {
  description = "Cognito user pool ARN"
  value       = aws_cognito_user_pool.users.arn
}

output "client_id" {
  description = "Public browser application client identifier"
  value       = aws_cognito_user_pool_client.browser.id
}

output "issuer" {
  description = "JWT issuer URL used by API Gateway"
  value       = "https://${aws_cognito_user_pool.users.endpoint}"
}

output "e2e_user_email" {
  description = "Username of the Terraform-managed E2E test user, or null when none is provisioned"
  value       = one(aws_cognito_user.e2e[*].username)
}

output "e2e_user_password" {
  description = "Permanent password for the Terraform-managed E2E test user, or null when none is provisioned"
  value       = one(random_password.e2e[*].result)
  sensitive   = true
}
