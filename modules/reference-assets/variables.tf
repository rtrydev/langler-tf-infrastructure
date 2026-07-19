variable "name" {
  description = "Name prefix for reference asset resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,40}$", var.name))
    error_message = "name must contain 3-40 lowercase letters, digits, or hyphens."
  }
}

variable "allowed_origin" {
  description = "Browser origin allowed to fetch reference assets"
  type        = string

  validation {
    condition     = can(regex("^https://", var.allowed_origin))
    error_message = "allowed_origin must be an HTTPS origin."
  }
}
