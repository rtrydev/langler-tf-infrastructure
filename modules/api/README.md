# api

Deploys an arm64 Go Lambda on the `provided.al2023` OS-only runtime behind an API Gateway HTTP API. `GET /hello` requires a Cognito access token carrying the SDK authentication scope. CORS is configured only on the HTTP API and permits one frontend origin.

## Inputs

| Name | Type | Description |
|---|---|---|
| `name` | `string` | Resource name prefix |
| `lambda_package_path` | `string` | Zip containing `bootstrap` |
| `jwt_issuer` | `string` | Cognito JWT issuer |
| `jwt_audience` | `string` | Cognito client ID |
| `allowed_origin` | `string` | Browser origin allowed by CORS |
| `stage` | `string` | Runtime stage label |

## Outputs

| Name | Description |
|---|---|
| `api_url` | HTTP API base URL |
| `hello_url` | Authenticated hello endpoint |
| `lambda_name` | Lambda function name |
