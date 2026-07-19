# storage

Creates the Langler DynamoDB single table with `PK` and `SK` string keys. Capacity uses on-demand billing so bulk reference-data loads can scale without manual capacity changes. DynamoDB TTL removes ephemeral per-token rate-limit windows through the numeric `expiresAtUnix` attribute.

## Inputs

| Name | Type | Description |
|---|---|---|
| `table_name` | `string` | DynamoDB table name |

## Outputs

| Name | Description |
|---|---|
| `table_name` | DynamoDB table name |
| `table_arn` | DynamoDB table ARN |
