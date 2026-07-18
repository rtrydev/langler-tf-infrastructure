output "api_url" {
  description = "Base URL of the HTTP API"
  value       = aws_apigatewayv2_api.api.api_endpoint
}

output "hello_url" {
  description = "Authenticated hello-world endpoint URL"
  value       = "${aws_apigatewayv2_api.api.api_endpoint}/hello"
}

output "lambda_name" {
  description = "Deployed API Lambda function name"
  value       = aws_lambda_function.api.function_name
}
