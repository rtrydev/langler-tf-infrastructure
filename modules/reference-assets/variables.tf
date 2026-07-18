variable "name" {
  description = "Name prefix for reference asset resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,40}$", var.name))
    error_message = "name must contain 3-40 lowercase letters, digits, or hyphens."
  }
}
