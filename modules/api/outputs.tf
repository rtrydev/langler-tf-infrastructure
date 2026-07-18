output "api_url" {
  description = "Base URL of the HTTP API"
  value       = aws_apigatewayv2_api.api.api_endpoint
}

output "machine_api_url" {
  description = "Base URL of the machine-token HTTP API"
  value       = aws_apigatewayv2_api.machine.api_endpoint
}

output "hello_url" {
  description = "Authenticated hello-world endpoint URL"
  value       = "${aws_apigatewayv2_api.api.api_endpoint}/hello"
}

output "lambda_name" {
  description = "Deployed API Lambda function name"
  value       = aws_lambda_function.api.function_name
}

output "authorizer_lambda_name" {
  description = "Deployed machine-token authorizer Lambda function name"
  value       = aws_lambda_function.authorizer.function_name
}
