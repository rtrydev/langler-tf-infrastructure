mock_provider "aws" {}

run "plans_authenticated_arm64_api" {
  command = plan

  variables {
    name                = "langler-prod"
    lambda_package_path = "../../../langler-backend/build/api.zip"
    jwt_issuer          = "https://cognito-idp.eu-central-1.amazonaws.com/eu-central-1_example"
    jwt_audience        = "exampleclientid"
    allowed_origin      = "https://langler.example.com"
    stage               = "prod"
  }

  assert {
    condition     = aws_lambda_function.api.runtime == "provided.al2023" && contains(aws_lambda_function.api.architectures, "arm64")
    error_message = "The Lambda must use the arm64 AL2023 OS-only runtime."
  }

  assert {
    condition     = aws_apigatewayv2_route.hello.authorization_type == "JWT"
    error_message = "The hello route must require JWT authorization."
  }

  assert {
    condition     = contains(aws_apigatewayv2_route.hello.authorization_scopes, "aws.cognito.signin.user.admin")
    error_message = "The hello route must reject ID tokens by requiring an access-token scope."
  }

  assert {
    condition     = length(aws_apigatewayv2_api.api.cors_configuration[0].allow_origins) == 1
    error_message = "CORS must allow exactly one frontend origin."
  }
}
