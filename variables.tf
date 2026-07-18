variable "aws_region" {
  description = "Primary AWS region for all non-CloudFront resources"
  type        = string
  default     = "eu-central-1"
}

variable "domain_name" {
  description = "Fully qualified domain the app is served from"
  type        = string
  default     = "langler.rtrydev.com"
}

variable "hosted_zone_name" {
  description = "Route 53 hosted zone the domain record is created in"
  type        = string
  default     = "rtrydev.com"
}

variable "backend_build_dir" {
  description = "Path to the langler-backend build artifacts (zipped bootstrap binaries)"
  type        = string
  default     = "../langler-backend/build"
}

variable "frontend_out_dir" {
  description = "Path to the langler-ui static export output"
  type        = string
  default     = "../langler-ui/out"
}
