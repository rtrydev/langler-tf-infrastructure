# api

Deploys the arm64 Go API and machine-authorizer Lambdas on the `provided.al2023` OS-only runtime. Browser routes use a Cognito JWT authorizer. A separate machine HTTP API exposes only reference reads and lesson import through an uncached Lambda authorizer, so token revocation takes effect on the next call. DynamoDB access is limited to the item, query, transaction, and counter operations needed by lessons and agent tokens; neither function can scan the table. CORS is configured only on the browser API and permits one frontend origin.

## Inputs

| Name | Type | Description |
|---|---|---|
| `name` | `string` | Resource name prefix |
| `lambda_package_path` | `string` | Zip containing `bootstrap` |
| `authorizer_package_path` | `string` | Zip containing the machine-authorizer `bootstrap` |
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
| `machine_api_url` | Machine-token HTTP API base URL |
| `hello_url` | Authenticated hello endpoint |
| `lambda_name` | Lambda function name |
| `authorizer_lambda_name` | Machine-authorizer Lambda function name |
