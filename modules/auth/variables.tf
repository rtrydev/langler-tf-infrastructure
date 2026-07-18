variable "name" {
  description = "Name prefix for Cognito resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,64}$", var.name))
    error_message = "name must contain 3-64 lowercase letters, digits, or hyphens."
  }
}

variable "temporary_password_validity_days" {
  description = "Number of days an owner-provisioned temporary password remains valid"
  type        = number
  default     = 7

  validation {
    condition     = var.temporary_password_validity_days >= 1 && var.temporary_password_validity_days <= 30
    error_message = "temporary_password_validity_days must be between 1 and 30."
  }
}
