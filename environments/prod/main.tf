locals {
  name               = "langler-prod"
  frontend_origin    = "https://${var.domain_name}"
  cognito_api_origin = "https://cognito-idp.${var.aws_region}.amazonaws.com"
}

module "auth" {
  source = "../../modules/auth"

  name = local.name
}

module "storage" {
  source = "../../modules/storage"

  table_name = local.name
}

module "api" {
  source = "../../modules/api"

  name                    = local.name
  lambda_package_path     = var.lambda_package_path
  authorizer_package_path = var.authorizer_package_path
  jwt_issuer              = module.auth.issuer
  jwt_audience            = module.auth.client_id
  allowed_origin          = local.frontend_origin
  table_name              = module.storage.table_name
  table_arn               = module.storage.table_arn
  stage                   = "prod"
}

module "reference_assets" {
  source = "../../modules/reference-assets"

  name = local.name
}

module "frontend" {
  source = "../../modules/frontend"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  domain_name      = var.domain_name
  hosted_zone_name = var.hosted_zone_name
  connect_sources = [
    local.cognito_api_origin,
    module.api.api_url,
  ]
}
