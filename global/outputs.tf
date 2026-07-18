output "state_bucket_name" {
  description = "Name of the Terraform state bucket, for use in backend configurations"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "state_bucket_arn" {
  description = "ARN of the Terraform state bucket, for IAM policies granting state access"
  value       = aws_s3_bucket.terraform_state.arn
}
