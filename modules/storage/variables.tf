variable "table_name" {
  description = "Name of the DynamoDB single table"
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]{3,255}$", var.table_name))
    error_message = "table_name must be a valid DynamoDB table name."
  }
}

variable "read_capacity" {
  description = "Provisioned read capacity units"
  type        = number
  default     = 5

  validation {
    condition     = var.read_capacity >= 1 && var.read_capacity <= 25
    error_message = "read_capacity must remain between 1 and the Always Free allowance of 25."
  }
}

variable "write_capacity" {
  description = "Provisioned write capacity units; values above the Always Free allowance of 25 are billed and belong only to short-lived bulk-load windows"
  type        = number
  default     = 5

  validation {
    condition     = var.write_capacity >= 1 && var.write_capacity <= 1000
    error_message = "write_capacity must be between 1 and 1000; keep it at or below 25 (Always Free) outside bulk-load windows."
  }
}
