variable "aws_region" {
  description = "AWS region the state bucket lives in"
  type        = string
  default     = "eu-central-1"

  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-\\d$", var.aws_region))
    error_message = "aws_region must be a valid AWS region identifier, e.g. eu-central-1."
  }
}

variable "state_bucket_name" {
  description = "Globally unique name of the S3 bucket that stores Terraform state"
  type        = string
  default     = "langler-terraform-state"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.state_bucket_name))
    error_message = "state_bucket_name must be a valid S3 bucket name: 3-63 characters, lowercase letters, digits, dots, and hyphens."
  }
}
