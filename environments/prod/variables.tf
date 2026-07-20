variable "aws_region" {
  description = "Primary AWS region for regional resources"
  type        = string
  default     = "eu-central-1"

  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-\\d$", var.aws_region))
    error_message = "aws_region must be a valid AWS region identifier."
  }
}

variable "expected_aws_account_id" {
  description = "AWS account allowed for production deployment"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.expected_aws_account_id))
    error_message = "expected_aws_account_id must be a 12-digit AWS account ID."
  }
}

variable "domain_name" {
  description = "Fully qualified domain serving Langler"
  type        = string
  default     = "langler.rtrydev.com"

  validation {
    condition     = can(regex("^[a-z0-9.-]+$", var.domain_name))
    error_message = "domain_name must be a lowercase fully qualified domain name."
  }
}

variable "hosted_zone_name" {
  description = "Public Route 53 hosted zone containing the application domain"
  type        = string
  default     = "rtrydev.com"

  validation {
    condition     = can(regex("^[a-z0-9.-]+$", var.hosted_zone_name))
    error_message = "hosted_zone_name must be a lowercase DNS zone name."
  }
}

variable "lambda_package_path" {
  description = "Path to the backend API deployment package"
  type        = string
  default     = "../../../langler-backend/build/api.zip"

  validation {
    condition     = endswith(var.lambda_package_path, ".zip")
    error_message = "lambda_package_path must identify a zip archive."
  }
}

variable "authorizer_package_path" {
  description = "Path to the machine authorizer deployment package"
  type        = string
  default     = "../../../langler-backend/build/authorizer.zip"

  validation {
    condition     = endswith(var.authorizer_package_path, ".zip")
    error_message = "authorizer_package_path must identify a zip archive."
  }
}

variable "monthly_budget_usd" {
  description = "Monthly AWS cost budget in USD, visible in the AWS Budgets console; no notification is sent"
  type        = string
  default     = "10"

  validation {
    condition     = can(tonumber(var.monthly_budget_usd)) && tonumber(var.monthly_budget_usd) > 0
    error_message = "monthly_budget_usd must be a positive number expressed as a string."
  }
}
