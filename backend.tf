terraform {
  backend "s3" {
    bucket       = "langler-terraform-state"
    key          = "root/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
