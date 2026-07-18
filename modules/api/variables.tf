variable "name" {
  description = "Name prefix for API resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,64}$", var.name))
    error_message = "name must contain 3-64 lowercase letters, digits, or hyphens."
  }
}

variable "lambda_package_path" {
  description = "Path to a zip containing the arm64 bootstrap binary"
  type        = string

  validation {
    condition     = endswith(var.lambda_package_path, ".zip")
    error_message = "lambda_package_path must identify a zip archive."
  }
}

variable "jwt_issuer" {
  description = "Cognito JWT issuer URL"
  type        = string

  validation {
    condition     = startswith(var.jwt_issuer, "https://cognito-idp.")
    error_message = "jwt_issuer must be a Cognito HTTPS issuer URL."
  }
}

variable "jwt_audience" {
  description = "Cognito application client ID accepted as the JWT audience"
  type        = string

  validation {
    condition     = length(var.jwt_audience) >= 6
    error_message = "jwt_audience must be a non-empty Cognito application client ID."
  }
}

variable "allowed_origin" {
  description = "Single browser origin allowed by HTTP API CORS"
  type        = string

  validation {
    condition     = can(regex("^https://[^/]+$", var.allowed_origin))
    error_message = "allowed_origin must be one HTTPS origin without a trailing slash."
  }
}

variable "stage" {
  description = "Deployment stage exposed to the Lambda"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{2,32}$", var.stage))
    error_message = "stage must contain 2-32 lowercase letters, digits, or hyphens."
  }
}
