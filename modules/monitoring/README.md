# monitoring

Alarms and a cost guardrail for the Langler API stack, visible in the AWS console. This is a single-owner, invite-only app with no on-call rotation, so nothing here sends a notification — every resource exists to be *looked at* (CloudWatch Alarms console, AWS Budgets console), not to page anyone.

## Alarms

- **Lambda errors and throttles** for both the api and machine-token authorizer functions (`AWS/Lambda` `Errors`/`Throttles`, any occurrence in a 5-minute window).
- **API Gateway 5xx** for both the browser and machine HTTP APIs (any occurrence in a 5-minute window).
- **DynamoDB throttled requests** (`ReadThrottleEvents`/`WriteThrottleEvents`, any occurrence) — a real user-facing failure signal.
- **DynamoDB consumed capacity spike** (`ConsumedReadCapacityUnits`/`ConsumedWriteCapacityUnits` summed over 5 minutes, threshold `dynamodb_consumed_capacity_threshold`) — a cost/usage signal distinct from throttling, since the table is on-demand and has no provisioned ceiling to alarm against. The default threshold is a starting point; revisit it once a month of real usage data exists (see the owner runbook).

All alarms use `treat_missing_data = "notBreaching"`: no traffic is the expected steady state for a near-zero-idle-cost app, not an alarm condition. None declare `alarm_actions`/`ok_actions` — they exist purely as CloudWatch Alarms console state (green/red) to check in on, not to notify.

## Budget

`aws_budgets_budget.monthly` is a COST budget (`monthly_budget_usd`, default $10) with no notification blocks — it shows spend-to-date and forecast in the AWS Budgets console without emailing anyone.

## Inputs

| Name | Type | Description |
|---|---|---|
| `name` | `string` | Resource name prefix |
| `monthly_budget_usd` | `string` | Monthly cost budget in USD, console-visible only (default `10`) |
| `table_name` | `string` | DynamoDB table name to alarm on |
| `dynamodb_consumed_capacity_threshold` | `number` | Read/write capacity units per 5-minute window that indicate a spike (default `1000`) |
| `api_function_name` | `string` | Deployed API Lambda function name |
| `authorizer_function_name` | `string` | Deployed machine-authorizer Lambda function name |
| `http_api_id` | `string` | Browser HTTP API id |
| `machine_api_id` | `string` | Machine-token HTTP API id |
| `stage_name` | `string` | Shared API Gateway stage name (default `$default`) |

## Outputs

None — every resource in this module is a leaf, checked directly in the AWS console rather than composed by another module.
