locals {
  human_routes = {
    hello = {
      route_key       = "GET /hello"
      statement_id    = "AllowApiGatewayInvoke"
      permission_path = "GET/hello"
    }
    reference_vocab = {
      route_key       = "GET /reference/vocab"
      statement_id    = "AllowApiGatewayInvokeReferenceVocab"
      permission_path = "GET/reference/vocab"
    }
    reference_grammar = {
      route_key       = "GET /reference/grammar"
      statement_id    = "AllowApiGatewayInvokeReferenceGrammar"
      permission_path = "GET/reference/grammar"
    }
    reference_scripts = {
      route_key       = "GET /reference/scripts"
      statement_id    = "AllowApiGatewayInvokeReferenceScripts"
      permission_path = "GET/reference/scripts"
    }
    reference_readings = {
      route_key       = "GET /reference/readings"
      statement_id    = "AllowApiGatewayInvokeReferenceReadings"
      permission_path = "GET/reference/readings"
    }
    lessons_prompt = {
      route_key       = "POST /lessons/prompt"
      statement_id    = "AllowApiGatewayInvokeLessonsPrompt"
      permission_path = "POST/lessons/prompt"
    }
    lessons_import = {
      route_key       = "POST /lessons/import"
      statement_id    = "AllowApiGatewayInvokeLessonsImport"
      permission_path = "POST/lessons/import"
    }
    lessons_topics = {
      route_key       = "GET /lessons/topics"
      statement_id    = "AllowApiGatewayInvokeLessonsTopics"
      permission_path = "GET/lessons/topics"
    }
    lessons_list = {
      route_key       = "GET /lessons"
      statement_id    = "AllowApiGatewayInvokeLessonsList"
      permission_path = "GET/lessons"
    }
    lessons_get = {
      route_key       = "GET /lessons/{id}"
      statement_id    = "AllowApiGatewayInvokeLessonsGet"
      permission_path = "GET/lessons/*"
    }
    lessons_delete = {
      route_key       = "DELETE /lessons/{id}"
      statement_id    = "AllowApiGatewayInvokeLessonsDelete"
      permission_path = "DELETE/lessons/*"
    }
    lesson_results_create = {
      route_key       = "POST /lessons/{id}/results"
      statement_id    = "AllowApiGatewayInvokeLessonResultsCreate"
      permission_path = "POST/lessons/*/results"
    }
    reviews_due = {
      route_key       = "GET /reviews/due"
      statement_id    = "AllowApiGatewayInvokeReviewsDue"
      permission_path = "GET/reviews/due"
    }
    reviews_grade = {
      route_key       = "POST /reviews/grade"
      statement_id    = "AllowApiGatewayInvokeReviewsGrade"
      permission_path = "POST/reviews/grade"
    }
    progress_summary = {
      route_key       = "GET /progress"
      statement_id    = "AllowApiGatewayInvokeProgressSummary"
      permission_path = "GET/progress"
    }
    assessments_create = {
      route_key       = "POST /assessments"
      statement_id    = "AllowApiGatewayInvokeAssessmentsCreate"
      permission_path = "POST/assessments"
    }
    assessments_list = {
      route_key       = "GET /assessments"
      statement_id    = "AllowApiGatewayInvokeAssessmentsList"
      permission_path = "GET/assessments"
    }
    assessments_get = {
      route_key       = "GET /assessments/{id}"
      statement_id    = "AllowApiGatewayInvokeAssessmentsGet"
      permission_path = "GET/assessments/*"
    }
    assessment_answers_create = {
      route_key       = "POST /assessments/{id}/answers"
      statement_id    = "AllowApiGatewayInvokeAssessmentAnswersCreate"
      permission_path = "POST/assessments/*/answers"
    }
    profile_levels = {
      route_key       = "GET /profile/levels"
      statement_id    = "AllowApiGatewayInvokeProfileLevels"
      permission_path = "GET/profile/levels"
    }
    agent_tokens_create = {
      route_key       = "POST /agent-tokens"
      statement_id    = "AllowApiGatewayInvokeAgentTokensCreate"
      permission_path = "POST/agent-tokens"
    }
    agent_tokens_list = {
      route_key       = "GET /agent-tokens"
      statement_id    = "AllowApiGatewayInvokeAgentTokensList"
      permission_path = "GET/agent-tokens"
    }
    agent_tokens_revoke = {
      route_key       = "DELETE /agent-tokens/{id}"
      statement_id    = "AllowApiGatewayInvokeAgentTokensRevoke"
      permission_path = "DELETE/agent-tokens/*"
    }
  }
  machine_routes = {
    reference_vocab    = local.human_routes.reference_vocab
    reference_grammar  = local.human_routes.reference_grammar
    reference_scripts  = local.human_routes.reference_scripts
    reference_readings = local.human_routes.reference_readings
    lessons_import     = local.human_routes.lessons_import
  }
}

resource "aws_iam_role" "lambda" {
  name = "${var.name}-lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_logs" {
  name = "cloudwatch-logs"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ]
      Resource = "${aws_cloudwatch_log_group.api.arn}:*"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_reference_read" {
  name = "dynamodb-query"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:Query"]
      Resource = var.table_arn
    }]
  })
}

resource "aws_iam_role_policy" "lambda_lesson_store" {
  name = "dynamodb-lessons"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:BatchGetItem",
        "dynamodb:DeleteItem",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:TransactWriteItems",
        "dynamodb:UpdateItem",
      ]
      Resource = var.table_arn
    }]
  })
}

resource "aws_cloudwatch_log_group" "api" {
  #checkov:skip=CKV_AWS_158:KMS encryption has recurring request costs and logs contain no request bodies, tokens, or personal data
  #checkov:skip=CKV_AWS_338:Fourteen-day retention limits storage cost while retaining enough diagnostics for this personal application
  name              = "/aws/lambda/${var.name}-api"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "authorizer" {
  #checkov:skip=CKV_AWS_158:KMS encryption has recurring request costs and logs contain no request bodies, tokens, or personal data
  #checkov:skip=CKV_AWS_338:Fourteen-day retention limits storage cost while retaining enough diagnostics for this personal application
  name              = "/aws/lambda/${var.name}-machine-authorizer"
  retention_in_days = 14
}

resource "aws_iam_role" "authorizer" {
  name = "${var.name}-machine-authorizer"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "authorizer" {
  name = "token-auth"
  role = aws_iam_role.authorizer.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "${aws_cloudwatch_log_group.authorizer.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
        ]
        Resource = var.table_arn
      },
    ]
  })
}

data "aws_region" "current" {}

resource "aws_iam_role_policy" "lambda_bedrock_embed" {
  count = var.embed_model_id == "" || length(var.embeddings_urls) == 0 ? 0 : 1
  name  = "bedrock-embed"
  role  = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["bedrock:InvokeModel"]
      Resource = "arn:aws:bedrock:${data.aws_region.current.region}::foundation-model/${var.embed_model_id}"
    }]
  })
}

resource "aws_lambda_function" "api" {
  #checkov:skip=CKV_AWS_116:No dead-letter queue is needed for a synchronous HTTP endpoint
  #checkov:skip=CKV_AWS_117:The endpoint accesses only public AWS control planes and does not require a VPC
  #checkov:skip=CKV_AWS_173:Only the non-sensitive stage, table name, embedding index URLs, and model id are supplied as environment variables
  #checkov:skip=CKV_AWS_272:Code signing adds operational overhead that is disproportionate for this owner-built personal application
  #checkov:skip=CKV_AWS_50:X-Ray tracing adds cost and is deferred to the dedicated observability task
  function_name                  = "${var.name}-api"
  role                           = aws_iam_role.lambda.arn
  filename                       = var.lambda_package_path
  source_code_hash               = filebase64sha256(var.lambda_package_path)
  handler                        = "bootstrap"
  runtime                        = "provided.al2023"
  architectures                  = ["arm64"]
  memory_size                    = 2048
  timeout                        = 29
  reserved_concurrent_executions = 5

  environment {
    variables = {
      STAGE           = var.stage
      TABLE_NAME      = var.table_name
      EMBEDDINGS_URLS = jsonencode(var.embeddings_urls)
      EMBED_MODEL_ID  = var.embed_model_id
    }
  }

  depends_on = [aws_iam_role_policy.lambda_logs] # The policy attachment is required before Lambda validates the execution role.
}

resource "aws_lambda_function" "authorizer" {
  #checkov:skip=CKV_AWS_116:Authorizer failures deny synchronous requests and do not need a dead-letter queue
  #checkov:skip=CKV_AWS_117:The function accesses DynamoDB through the public AWS control plane and does not require a VPC
  #checkov:skip=CKV_AWS_173:The only environment value is a non-sensitive DynamoDB table name
  #checkov:skip=CKV_AWS_272:Code signing adds disproportionate operational overhead for this personal application
  #checkov:skip=CKV_AWS_50:X-Ray tracing is deferred to the dedicated observability task
  function_name                  = "${var.name}-machine-authorizer"
  role                           = aws_iam_role.authorizer.arn
  filename                       = var.authorizer_package_path
  source_code_hash               = filebase64sha256(var.authorizer_package_path)
  handler                        = "bootstrap"
  runtime                        = "provided.al2023"
  architectures                  = ["arm64"]
  memory_size                    = 128
  timeout                        = 5
  reserved_concurrent_executions = 5

  environment {
    variables = { TABLE_NAME = var.table_name }
  }

  depends_on = [aws_iam_role_policy.authorizer]
}

resource "aws_apigatewayv2_api" "api" {
  name          = "${var.name}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_credentials = false
    allow_headers     = ["authorization", "content-type", "idempotency-key"]
    allow_methods     = ["GET", "POST", "DELETE"]
    allow_origins     = [var.allowed_origin]
    max_age           = 3600
  }
}

resource "aws_apigatewayv2_api" "machine" {
  name          = "${var.name}-machine-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito"

  jwt_configuration {
    audience = [var.jwt_audience]
    issuer   = var.jwt_issuer
  }
}

resource "aws_apigatewayv2_authorizer" "machine" {
  api_id                            = aws_apigatewayv2_api.machine.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = aws_lambda_function.authorizer.invoke_arn
  authorizer_payload_format_version = "2.0"
  authorizer_result_ttl_in_seconds  = 0
  enable_simple_responses           = true
  identity_sources                  = ["$request.header.Authorization"]
  name                              = "machine-token"
}

resource "aws_apigatewayv2_integration" "api" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
  timeout_milliseconds   = 30000
}

resource "aws_apigatewayv2_integration" "machine" {
  api_id                 = aws_apigatewayv2_api.machine.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
  timeout_milliseconds   = 30000
}

resource "aws_apigatewayv2_route" "authenticated" {
  for_each = local.human_routes

  api_id               = aws_apigatewayv2_api.api.id
  route_key            = each.value.route_key
  target               = "integrations/${aws_apigatewayv2_integration.api.id}"
  authorization_type   = "JWT"
  authorizer_id        = aws_apigatewayv2_authorizer.cognito.id
  authorization_scopes = ["aws.cognito.signin.user.admin"]
}

resource "aws_apigatewayv2_route" "machine" {
  for_each = local.machine_routes

  api_id             = aws_apigatewayv2_api.machine.id
  route_key          = each.value.route_key
  target             = "integrations/${aws_apigatewayv2_integration.machine.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.machine.id
}

moved {
  from = aws_apigatewayv2_route.hello
  to   = aws_apigatewayv2_route.authenticated["hello"]
}

resource "aws_apigatewayv2_stage" "default" {
  #checkov:skip=CKV_AWS_76:API access logs add duplicate request logging and are deferred to the dedicated observability task
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 10
    throttling_rate_limit  = 5
  }
}

resource "aws_apigatewayv2_stage" "machine" {
  #checkov:skip=CKV_AWS_76:API access logs are deferred to the dedicated observability task
  api_id      = aws_apigatewayv2_api.machine.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 20
    throttling_rate_limit  = 10
  }
}

resource "aws_lambda_permission" "api_gateway" {
  for_each = local.human_routes

  statement_id  = each.value.statement_id
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/${each.value.permission_path}"
}

resource "aws_lambda_permission" "machine_api_gateway" {
  for_each = local.machine_routes

  statement_id  = "${each.value.statement_id}Machine"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.machine.execution_arn}/*/${each.value.permission_path}"
}

resource "aws_lambda_permission" "machine_authorizer" {
  statement_id  = "AllowApiGatewayInvokeMachineAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.machine.execution_arn}/authorizers/${aws_apigatewayv2_authorizer.machine.id}"
}

moved {
  from = aws_lambda_permission.api_gateway
  to   = aws_lambda_permission.api_gateway["hello"]
}
