variable "domain_name" {
  description = "Fully qualified domain name served by CloudFront"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+$", var.domain_name))
    error_message = "domain_name must be a valid lowercase fully qualified domain name."
  }
}

variable "hosted_zone_name" {
  description = "Public Route 53 hosted zone containing the application record"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9.-]+$", var.hosted_zone_name))
    error_message = "hosted_zone_name must contain only lowercase letters, digits, dots, and hyphens."
  }
}

variable "connect_sources" {
  description = "HTTPS origins the browser may contact under the CloudFront content security policy"
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for source in var.connect_sources : startswith(source, "https://")])
    error_message = "Every connect source must be an HTTPS origin."
  }
}
