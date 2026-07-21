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

variable "authorizer_package_path" {
  description = "Path to a zip containing the arm64 machine-authorizer bootstrap binary"
  type        = string

  validation {
    condition     = endswith(var.authorizer_package_path, ".zip")
    error_message = "authorizer_package_path must identify a zip archive."
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
  description = "Primary browser origin allowed by HTTP API CORS"
  type        = string

  validation {
    condition     = can(regex("^https://[^/]+$", var.allowed_origin))
    error_message = "allowed_origin must be one HTTPS origin without a trailing slash."
  }
}

variable "additional_allowed_origins" {
  description = "Extra browser origins allowed by HTTP API CORS, e.g. a local dev or e2e host (http permitted)"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for origin in var.additional_allowed_origins : can(regex("^https?://[^/]+$", origin))
    ])
    error_message = "Each additional origin must be an http(s) origin without a trailing slash."
  }
}

variable "table_name" {
  description = "DynamoDB table name exposed to the Lambda for reference queries"
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]{3,255}$", var.table_name))
    error_message = "table_name must be a valid DynamoDB table name."
  }
}

variable "table_arn" {
  description = "ARN of the DynamoDB table the Lambda may query"
  type        = string

  validation {
    condition     = startswith(var.table_arn, "arn:aws:dynamodb:")
    error_message = "table_arn must be a DynamoDB table ARN."
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

variable "embeddings_urls" {
  description = "HTTPS vocabulary embedding index URLs by language; empty disables semantic topic search"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for language, url in var.embeddings_urls :
      contains(["ja", "my", "pl"], language) && can(regex("^https://[^[:space:]]+$", url))
    ])
    error_message = "embeddings_urls keys must be supported language codes and values must be HTTPS URLs."
  }
}

variable "embed_model_id" {
  description = "Bedrock embedding model id used for semantic topic search; empty disables it"
  type        = string
  default     = ""
}
