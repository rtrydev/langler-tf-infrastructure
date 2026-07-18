# storage

Creates the Langler DynamoDB single table with `PK` and `SK` string keys. Capacity is provisioned and constrained to the Always Free allowance. DynamoDB TTL removes ephemeral per-token rate-limit windows through the numeric `expiresAtUnix` attribute.

## Inputs

| Name | Type | Description |
|---|---|---|
| `table_name` | `string` | DynamoDB table name |
| `read_capacity` | `number` | Provisioned RCUs, from 1 through 25 |
| `write_capacity` | `number` | Provisioned WCUs, from 1 through 25 |

## Outputs

| Name | Description |
|---|---|
| `table_name` | DynamoDB table name |
| `table_arn` | DynamoDB table ARN |
