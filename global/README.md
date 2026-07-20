# global

Account-level resources that are not per-environment. This module manages the S3 state bucket and the account-wide API Gateway CloudWatch logging role.

## State bucket

`aws_s3_bucket.terraform_state` (`langler-terraform-state` by default) with:

- **Versioning** — every state write is recoverable; noncurrent versions expire after 90 days.
- **SSE-S3 encryption** (AES256) and a bucket policy denying non-TLS access.
- **All public access blocked.**
- **Native S3 state locking** — consumers set `use_lockfile = true` in their backend. There is deliberately no DynamoDB lock table; that mechanism is deprecated.
- `prevent_destroy` — the bucket holds the source of truth for the whole account.

## API Gateway CloudWatch role

`aws_api_gateway_account.this` is a singleton per account/region: it tells API Gateway (both REST and HTTP APIs, across every environment) which IAM role to assume when writing access logs to CloudWatch Logs. It belongs here rather than in `modules/api` so that a future second environment does not fight over the same account-wide setting from two separate Terraform states.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `aws_region` | `string` | `eu-central-1` | AWS region the state bucket lives in |
| `state_bucket_name` | `string` | `langler-terraform-state` | Globally unique name of the state bucket |

## Outputs

| Name | Description |
|------|-------------|
| `state_bucket_name` | Bucket name for backend configurations |
| `state_bucket_arn` | Bucket ARN for IAM policies granting state access |

## Bootstrap (chicken-and-egg)

This root module *creates* the bucket the rest of the repo stores state in, so its own state starts out local:

1. `terraform init && terraform plan -out=tfplan` in this directory; a human reviews and applies.
2. Other root modules can now `terraform init` against their `backend "s3"` blocks (existing local state migrates with `terraform init -migrate-state`).
3. Optionally migrate this module's own state into the bucket later by adding a `backend "s3"` block (key `global/terraform.tfstate`) and running `terraform init -migrate-state`. Until then its local `terraform.tfstate` stays on the machine that applied it — it is gitignored and must never be committed.

## Tests

`terraform test` — unit tests run with `command = plan` against a mocked AWS provider; no credentials or infrastructure needed.
