variable "name" {
  description = "Name prefix for monitoring resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,64}$", var.name))
    error_message = "name must contain 3-64 lowercase letters, digits, or hyphens."
  }
}

variable "alarm_email" {
  description = "Email address subscribed to alarm and budget notifications"
  type        = string

  validation {
    condition     = can(regex("^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$", var.alarm_email))
    error_message = "alarm_email must be a valid email address."
  }
}

variable "monthly_budget_usd" {
  description = "Monthly AWS cost budget in USD; a notification fires at 85% actual and 100% forecasted spend"
  type        = string
  default     = "10"

  validation {
    condition     = can(tonumber(var.monthly_budget_usd)) && tonumber(var.monthly_budget_usd) > 0
    error_message = "monthly_budget_usd must be a positive number expressed as a string."
  }
}

variable "table_name" {
  description = "DynamoDB table name to alarm on"
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]{3,255}$", var.table_name))
    error_message = "table_name must be a valid DynamoDB table name."
  }
}

variable "dynamodb_consumed_capacity_threshold" {
  description = "Read or write capacity units consumed within a 5-minute window that indicates a usage spike worth a human look"
  type        = number
  default     = 1000

  validation {
    condition     = var.dynamodb_consumed_capacity_threshold > 0
    error_message = "dynamodb_consumed_capacity_threshold must be positive."
  }
}

variable "api_function_name" {
  description = "Deployed API Lambda function name"
  type        = string

  validation {
    condition     = length(var.api_function_name) > 0
    error_message = "api_function_name must not be empty."
  }
}

variable "authorizer_function_name" {
  description = "Deployed machine-token authorizer Lambda function name"
  type        = string

  validation {
    condition     = length(var.authorizer_function_name) > 0
    error_message = "authorizer_function_name must not be empty."
  }
}

variable "http_api_id" {
  description = "Browser HTTP API id"
  type        = string

  validation {
    condition     = length(var.http_api_id) > 0
    error_message = "http_api_id must not be empty."
  }
}

variable "machine_api_id" {
  description = "Machine-token HTTP API id"
  type        = string

  validation {
    condition     = length(var.machine_api_id) > 0
    error_message = "machine_api_id must not be empty."
  }
}

variable "stage_name" {
  description = "API Gateway stage name shared by both HTTP APIs"
  type        = string
  default     = "$default"
}
