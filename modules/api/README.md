# api

Deploys the arm64 Go API and machine-authorizer Lambdas on the `provided.al2023` OS-only runtime. The API Lambda receives 2,048 MB of memory and a 29-second timeout behind 30-second browser and machine API Gateway integrations. Browser routes use a Cognito JWT authorizer and expose lessons, review scheduling, progress summaries, placement assessments with profile level defaults, vocabulary, grammar, script, and leveled-reading reference data, and agent-token management. A separate machine HTTP API exposes only reference reads and lesson import through an uncached Lambda authorizer, so token revocation takes effect on the next call. DynamoDB access is limited to the item, query, transaction, and counter operations needed by lessons, progress, assessments, and agent tokens; neither function can scan the table. CORS is configured only on the browser API and permits one frontend origin.

Both Lambdas run with X-Ray active tracing. Both stages emit JSON access logs (request id, route, status, integration latency and error message) to their own log group — the access-log `requestId` is the same value the Lambda logs as its own `requestId`, so a request can be correlated across the API Gateway and Lambda log groups. This requires the account-wide API Gateway CloudWatch role provisioned in `global` (`aws_api_gateway_account`); without it, access-log delivery silently does nothing. `POST /lessons/import` gets a tighter per-route throttle (burst 5, rate 2) than the rest of its stage on both APIs, since it is the most abuse-prone, write-heavy route and the one most likely to be hammered by a leaked or compromised harness token.

## Inputs

| Name | Type | Description |
|---|---|---|
| `name` | `string` | Resource name prefix |
| `lambda_package_path` | `string` | Zip containing `bootstrap` |
| `authorizer_package_path` | `string` | Zip containing the machine-authorizer `bootstrap` |
| `jwt_issuer` | `string` | Cognito JWT issuer |
| `jwt_audience` | `string` | Cognito client ID |
| `allowed_origin` | `string` | Primary browser origin allowed by CORS |
| `additional_allowed_origins` | `list(string)` | Extra browser origins allowed by CORS (e.g. a local dev/e2e host); defaults to `[]` |
| `table_name` | `string` | DynamoDB table name passed to the Lambda |
| `table_arn` | `string` | DynamoDB table ARN the Lambda may query |
| `stage` | `string` | Runtime stage label |
| `embeddings_urls` | `map(string)` | Vocabulary embedding index URLs by language |
| `embed_model_id` | `string` | Bedrock embedding model ID used for semantic topic matching |

## Outputs

| Name | Description |
|---|---|
| `api_url` | HTTP API base URL |
| `machine_api_url` | Machine-token HTTP API base URL |
| `hello_url` | Authenticated hello endpoint |
| `lambda_name` | Lambda function name |
| `authorizer_lambda_name` | Machine-authorizer Lambda function name |
| `api_id` | Browser HTTP API id |
| `machine_api_id` | Machine-token HTTP API id |
