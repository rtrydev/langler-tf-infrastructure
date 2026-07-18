# api

Deploys an arm64 Go Lambda on the `provided.al2023` OS-only runtime behind an API Gateway HTTP API. Every route (`GET /hello`, `GET /reference/vocab`, `GET /reference/grammar`, `GET /reference/scripts`) requires a Cognito access token carrying the SDK authentication scope. The Lambda receives the application DynamoDB table name and may only `Query` that table. CORS is configured only on the HTTP API and permits one frontend origin.

## Inputs

| Name | Type | Description |
|---|---|---|
| `name` | `string` | Resource name prefix |
| `lambda_package_path` | `string` | Zip containing `bootstrap` |
| `jwt_issuer` | `string` | Cognito JWT issuer |
| `jwt_audience` | `string` | Cognito client ID |
| `allowed_origin` | `string` | Browser origin allowed by CORS |
| `table_name` | `string` | DynamoDB table name passed to the Lambda |
| `table_arn` | `string` | DynamoDB table ARN the Lambda may query |
| `stage` | `string` | Runtime stage label |

## Outputs

| Name | Description |
|---|---|
| `api_url` | HTTP API base URL |
| `hello_url` | Authenticated hello endpoint |
| `lambda_name` | Lambda function name |
