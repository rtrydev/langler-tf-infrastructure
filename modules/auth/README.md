# auth

Creates an invitation-only Cognito user pool and a public browser client. Only administrators can create users. The client supports password authentication, Cognito's required password-change challenge for newly provisioned accounts, token revocation, and refresh-token rotation.

## Inputs

| Name | Type | Description |
|---|---|---|
| `name` | `string` | Resource name prefix |
| `temporary_password_validity_days` | `number` | Temporary-password lifetime |

## Outputs

| Name | Description |
|---|---|
| `user_pool_id` | Pool ID used by owner provisioning |
| `user_pool_arn` | Pool ARN |
| `client_id` | Public browser client ID |
| `issuer` | JWT issuer URL |
