# langler-tf-infrastructure

Terraform for [Langler](https://langler.rtrydev.com) — an invitation-only, BYOAI language-learning app for Japanese, Burmese, and Polish.

All AWS infrastructure lives here, following the myangler-web pattern: Next.js static export on private S3 + CloudFront, Go Lambdas behind an API Gateway HTTP API, Cognito (invite-only), DynamoDB single table, ACM + Route 53. Design goal: near-zero idle cost — no always-on components.

## Layout

- `modules/frontend` — private S3, CloudFront OAC and rewrite function, ACM, and Route 53.
- `modules/auth` — invitation-only Cognito pool and browser client.
- `modules/api` — Cognito browser API, scoped-token machine API, and arm64 API/authorizer Lambdas.
- `modules/storage` — on-demand DynamoDB single table.
- `modules/monitoring` — CloudWatch alarms and an AWS Budgets cost guardrail.
- `environments/prod` — production composition and S3 backend.
- `global` — Terraform state bucket and the account-wide API Gateway CloudWatch logging role.

## Usage

```sh
make -C ../langler-backend build
terraform -chdir=environments/prod init
terraform -chdir=environments/prod plan -out=tfplan
```

A human runs the checks locally, reviews the saved plan, and applies it from the same machine.

## Deploy

From this repository, log in with the AWS CLI, set `LANGLER_AWS_ACCOUNT_ID` to the expected 12-digit account and `LANGLER_ALARM_EMAIL` to the address that should receive CloudWatch alarm and AWS Budgets notifications, and run `./scripts/deploy.sh`. The AWS CLI and Terraform use the active shared profile directly. The script runs `./scripts/check.sh`, verifies the active AWS account, produces a private temporary Terraform plan, pauses for explicit human review, applies that exact plan, builds and uploads the frontend, and invalidates CloudFront. The temporary plan is cleared on every exit path.

Provision an invited account after the first deploy with `./scripts/create-user.sh learner@example.com`. Cognito emails the temporary credential and requires the user to choose a permanent password on first sign-in.

See `docs/owner-runbook.md` for the full set of owner operations: deploying, rolling back, provisioning users, refreshing reference data, rotating agent tokens, and reading the alarms.

## State

State lives in the S3 bucket defined in `global/` (`langler-terraform-state`), with native S3 lockfile locking (`use_lockfile = true` — no DynamoDB lock table). Production preserves the existing `root/terraform.tfstate` key. See `global/README.md` for the one-time bootstrap.

## Tooling

- `./scripts/check.sh` — backend build/tests/lint, UI lint/tests, and all Terraform checks
- `terraform fmt -recursive` / `terraform validate`
- `tflint --recursive` (config in `.tflint.hcl`)
- `checkov -d .`
- `terraform test` (unit tests under `*/tests/`, plan-only with mocked providers)
