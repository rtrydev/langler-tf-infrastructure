mock_provider "aws" {}

variables {
  name                    = "langler-prod"
  lambda_package_path     = "../../../langler-backend/build/api.zip"
  authorizer_package_path = "../../../langler-backend/build/authorizer.zip"
  jwt_issuer              = "https://cognito-idp.eu-central-1.amazonaws.com/eu-central-1_example"
  jwt_audience            = "exampleclientid"
  allowed_origin          = "https://langler.example.com"
  table_name              = "langler-prod"
  table_arn               = "arn:aws:dynamodb:eu-central-1:111111111111:table/langler-prod"
  stage                   = "prod"
  embeddings_urls = {
    ja = "https://assets.example.com/embeddings/ja-vocab.embed"
    pl = "https://assets.example.com/embeddings/pl-vocab.embed"
  }
  embed_model_id = "cohere.embed-multilingual-v3"
}

run "plans_authenticated_arm64_api" {
  command = plan

  assert {
    condition     = aws_lambda_function.api.runtime == "provided.al2023" && contains(aws_lambda_function.api.architectures, "arm64")
    error_message = "The Lambda must use the arm64 AL2023 OS-only runtime."
  }

  assert {
    condition     = aws_lambda_function.authorizer.runtime == "provided.al2023" && contains(aws_lambda_function.authorizer.architectures, "arm64")
    error_message = "The machine authorizer must use the arm64 AL2023 OS-only runtime."
  }

  assert {
    condition     = aws_lambda_function.api.memory_size == 2048 && aws_lambda_function.api.timeout == 29
    error_message = "The API Lambda must have 2,048 MB of memory and a 29-second timeout."
  }

  assert {
    condition     = aws_apigatewayv2_integration.api.timeout_milliseconds == 30000 && aws_apigatewayv2_integration.machine.timeout_milliseconds == 30000
    error_message = "Both API Gateway integrations must allow 30 seconds."
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
    condition     = length(aws_apigatewayv2_api.api.cors_configuration[0].allow_origins) == 1 && contains(aws_apigatewayv2_api.api.cors_configuration[0].allow_origins, "https://langler.example.com")
    error_message = "CORS must allow only the primary frontend origin when no extras are set."
  }
}

run "plans_cors_with_additional_origins" {
  command = plan

  variables {
    additional_allowed_origins = ["http://localhost:3000"]
  }

  assert {
    condition     = length(aws_apigatewayv2_api.api.cors_configuration[0].allow_origins) == 2 && contains(aws_apigatewayv2_api.api.cors_configuration[0].allow_origins, "https://langler.example.com") && contains(aws_apigatewayv2_api.api.cors_configuration[0].allow_origins, "http://localhost:3000")
    error_message = "CORS must append additional_allowed_origins to the primary origin."
  }
}

run "plans_reference_routes_with_scoped_permissions" {
  command = plan

  assert {
    condition     = keys(aws_apigatewayv2_route.authenticated) == ["agent_tokens_create", "agent_tokens_list", "agent_tokens_revoke", "assessment_answers_create", "assessments_create", "assessments_get", "assessments_list", "hello", "lesson_results_create", "lessons_delete", "lessons_get", "lessons_import", "lessons_list", "lessons_prompt", "lessons_topics", "profile_levels", "progress_summary", "reference_grammar", "reference_readings", "reference_scripts", "reference_vocab", "reviews_due", "reviews_grade"]
    error_message = "The route map must contain the authenticated status, reference, lesson, review, progress, assessment, and token routes."
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

  assert {
    condition     = tomap(jsondecode(aws_lambda_function.api.environment[0].variables["EMBEDDINGS_URLS"])) == var.embeddings_urls
    error_message = "The Lambda must receive every language-specific embedding index URL."
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
    condition     = local.human_routes["lessons_get"].permission_path == "GET/lessons/*" && local.human_routes["lessons_delete"].permission_path == "DELETE/lessons/*" && local.human_routes["lesson_results_create"].permission_path == "POST/lessons/*/results"
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

run "plans_progress_and_review_routes" {
  command = plan

  assert {
    condition     = aws_apigatewayv2_route.authenticated["reviews_due"].route_key == "GET /reviews/due" && aws_apigatewayv2_route.authenticated["reviews_grade"].route_key == "POST /reviews/grade"
    error_message = "The review queue must expose its due read and grade mutation routes."
  }

  assert {
    condition     = aws_apigatewayv2_route.authenticated["progress_summary"].route_key == "GET /progress"
    error_message = "The progress summary route must be GET /progress."
  }
}

run "plans_assessment_routes" {
  command = plan

  assert {
    condition     = aws_apigatewayv2_route.authenticated["assessments_create"].route_key == "POST /assessments" && aws_apigatewayv2_route.authenticated["assessments_list"].route_key == "GET /assessments"
    error_message = "Placement assessments must expose their start and history routes."
  }

  assert {
    condition     = aws_apigatewayv2_route.authenticated["assessments_get"].route_key == "GET /assessments/{id}" && aws_apigatewayv2_route.authenticated["assessment_answers_create"].route_key == "POST /assessments/{id}/answers"
    error_message = "Assessment detail and answer submission must use the parameterised routes."
  }

  assert {
    condition     = local.human_routes["assessments_get"].permission_path == "GET/assessments/*" && local.human_routes["assessment_answers_create"].permission_path == "POST/assessments/*/answers"
    error_message = "Parameterised assessment routes must use wildcard invoke permissions that match request paths."
  }

  assert {
    condition     = aws_apigatewayv2_route.authenticated["profile_levels"].route_key == "GET /profile/levels"
    error_message = "The profile level defaults route must be GET /profile/levels."
  }
}

run "plans_separate_uncached_machine_authorizer" {
  command = plan

  assert {
    condition     = keys(aws_apigatewayv2_route.machine) == ["lessons_import", "reference_grammar", "reference_readings", "reference_scripts", "reference_vocab"]
    error_message = "The machine API must expose only reference reads and lesson import."
  }

  assert {
    condition     = alltrue([for route in aws_apigatewayv2_route.machine : route.authorization_type == "CUSTOM"])
    error_message = "Every machine route must use the machine-token Lambda authorizer."
  }

  assert {
    condition     = aws_apigatewayv2_authorizer.machine.authorizer_result_ttl_in_seconds == 0 && aws_apigatewayv2_authorizer.machine.enable_simple_responses
    error_message = "Machine authorization must be uncached so revocation takes effect immediately."
  }

}
