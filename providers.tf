provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "langler"
      ManagedBy = "terraform"
    }
  }
}

# CloudFront ACM certificates must live in us-east-1.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project   = "langler"
      ManagedBy = "terraform"
    }
  }
}
