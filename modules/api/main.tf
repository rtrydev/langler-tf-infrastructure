locals {
  routes = {
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

resource "aws_lambda_function" "api" {
  #checkov:skip=CKV_AWS_116:No dead-letter queue is needed for a synchronous HTTP endpoint
  #checkov:skip=CKV_AWS_117:The endpoint accesses only public AWS control planes and does not require a VPC
  #checkov:skip=CKV_AWS_173:Only the non-sensitive deployment stage and DynamoDB table name are supplied as environment variables
  #checkov:skip=CKV_AWS_272:Code signing adds operational overhead that is disproportionate for this owner-built personal application
  #checkov:skip=CKV_AWS_50:X-Ray tracing adds cost and is deferred to the dedicated observability task
  function_name                  = "${var.name}-api"
  role                           = aws_iam_role.lambda.arn
  filename                       = var.lambda_package_path
  source_code_hash               = filebase64sha256(var.lambda_package_path)
  handler                        = "bootstrap"
  runtime                        = "provided.al2023"
  architectures                  = ["arm64"]
  memory_size                    = 128
  timeout                        = 10
  reserved_concurrent_executions = 5

  environment {
    variables = {
      STAGE      = var.stage
      TABLE_NAME = var.table_name
    }
  }

  depends_on = [aws_iam_role_policy.lambda_logs] # The policy attachment is required before Lambda validates the execution role.
}

resource "aws_apigatewayv2_api" "api" {
  name          = "${var.name}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_credentials = false
    allow_headers     = ["authorization", "content-type"]
    allow_methods     = ["GET", "POST", "DELETE"]
    allow_origins     = [var.allowed_origin]
    max_age           = 3600
  }
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

resource "aws_apigatewayv2_integration" "api" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
  timeout_milliseconds   = 10000
}

resource "aws_apigatewayv2_route" "authenticated" {
  for_each = local.routes

  api_id               = aws_apigatewayv2_api.api.id
  route_key            = each.value.route_key
  target               = "integrations/${aws_apigatewayv2_integration.api.id}"
  authorization_type   = "JWT"
  authorizer_id        = aws_apigatewayv2_authorizer.cognito.id
  authorization_scopes = ["aws.cognito.signin.user.admin"]
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

resource "aws_lambda_permission" "api_gateway" {
  for_each = local.routes

  statement_id  = each.value.statement_id
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/${each.value.permission_path}"
}

moved {
  from = aws_lambda_permission.api_gateway
  to   = aws_lambda_permission.api_gateway["hello"]
}
