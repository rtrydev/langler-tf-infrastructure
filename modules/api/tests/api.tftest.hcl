mock_provider "aws" {}

variables {
  name                = "langler-prod"
  lambda_package_path = "../../../langler-backend/build/api.zip"
  jwt_issuer          = "https://cognito-idp.eu-central-1.amazonaws.com/eu-central-1_example"
  jwt_audience        = "exampleclientid"
  allowed_origin      = "https://langler.example.com"
  table_name          = "langler-prod"
  table_arn           = "arn:aws:dynamodb:eu-central-1:111111111111:table/langler-prod"
  stage               = "prod"
}

run "plans_authenticated_arm64_api" {
  command = plan

  assert {
    condition     = aws_lambda_function.api.runtime == "provided.al2023" && contains(aws_lambda_function.api.architectures, "arm64")
    error_message = "The Lambda must use the arm64 AL2023 OS-only runtime."
  }

  assert {
    condition     = alltrue([for route in aws_apigatewayv2_route.authenticated : route.authorization_type == "JWT"])
    error_message = "Every route must require JWT authorization."
  }

  assert {
    condition     = alltrue([for route in aws_apigatewayv2_route.authenticated : contains(route.authorization_scopes, "aws.cognito.signin.user.admin")])
    error_message = "Every route must reject ID tokens by requiring an access-token scope."
  }

  assert {
    condition     = length(aws_apigatewayv2_api.api.cors_configuration[0].allow_origins) == 1
    error_message = "CORS must allow exactly one frontend origin."
  }
}

run "plans_reference_routes_with_scoped_permissions" {
  command = plan

  assert {
    condition     = keys(aws_apigatewayv2_route.authenticated) == ["hello", "lesson_results_create", "lessons_delete", "lessons_get", "lessons_import", "lessons_list", "lessons_prompt", "reference_grammar", "reference_scripts", "reference_vocab"]
    error_message = "The route map must contain the hello route, the three reference routes, and the lesson routes."
  }

  assert {
    condition     = aws_apigatewayv2_route.authenticated["reference_vocab"].route_key == "GET /reference/vocab"
    error_message = "The reference vocabulary route must be GET /reference/vocab."
  }

  assert {
    condition     = keys(aws_lambda_permission.api_gateway) == keys(aws_apigatewayv2_route.authenticated)
    error_message = "Each route must have exactly one matching Lambda permission."
  }

  assert {
    condition     = aws_lambda_permission.api_gateway["hello"].statement_id == "AllowApiGatewayInvoke"
    error_message = "The hello permission must keep its original statement ID so it is not replaced."
  }

  assert {
    condition     = aws_lambda_function.api.environment[0].variables["TABLE_NAME"] == var.table_name
    error_message = "The Lambda must receive the reference table name."
  }
}

run "plans_lesson_routes_and_write_access" {
  command = plan

  assert {
    condition     = aws_apigatewayv2_route.authenticated["lessons_import"].route_key == "POST /lessons/import"
    error_message = "The lesson import route must be POST /lessons/import."
  }

  assert {
    condition     = aws_apigatewayv2_route.authenticated["lessons_get"].route_key == "GET /lessons/{id}"
    error_message = "The lesson detail route must be GET /lessons/{id}."
  }

  assert {
    condition     = aws_apigatewayv2_route.authenticated["lesson_results_create"].route_key == "POST /lessons/{id}/results"
    error_message = "Lesson results must be stored through POST /lessons/{id}/results."
  }

  assert {
    condition     = local.routes["lessons_get"].permission_path == "GET/lessons/*" && local.routes["lessons_delete"].permission_path == "DELETE/lessons/*" && local.routes["lesson_results_create"].permission_path == "POST/lessons/*/results"
    error_message = "Parameterised lesson routes must use wildcard invoke permissions that match request paths."
  }

  assert {
    condition     = alltrue([for method in ["GET", "POST", "DELETE"] : contains(aws_apigatewayv2_api.api.cors_configuration[0].allow_methods, method)])
    error_message = "CORS must allow the lesson browser methods GET, POST, and DELETE."
  }

  assert {
    condition     = !strcontains(aws_iam_role_policy.lambda_lesson_store.policy, "dynamodb:Scan") && !strcontains(aws_iam_role_policy.lambda_lesson_store.policy, "*\"")
    error_message = "The lesson store policy must stay scoped to item operations on the application table."
  }
}
