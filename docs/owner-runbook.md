# Owner runbook

Everything a Langler owner needs to operate the deployed system, without reading
the application source. Run every command from a machine with the AWS CLI
authenticated to the account named by `LANGLER_AWS_ACCOUNT_ID`, Go, Node, and
Python available, and this repository plus `langler-backend` and `langler-ui`
checked out as siblings (the layout `scripts/deploy.sh` and `etl/README.md`
assume).

## Deploying a change

```sh
export LANGLER_AWS_ACCOUNT_ID=<12-digit account id>
./scripts/deploy.sh
```

This runs `scripts/check.sh` (backend build/tests/lint, UI lint/tests, all
Terraform checks), confirms the active AWS identity matches the expected
account, produces a Terraform plan, prints it, and waits for you to type
`apply` before doing anything to real infrastructure. After apply it builds
the UI static export with the fresh Terraform outputs, syncs it to the
frontend S3 bucket with split cache headers, and invalidates CloudFront.
Anything short of typing `apply` at the prompt exits with no changes made.

Deploy the frontend alone (no Terraform apply, e.g. after a UI-only change
with no infrastructure diff) by exporting the five `NEXT_PUBLIC_*` variables
from `terraform -chdir=environments/prod output` yourself, running
`npm run build` in `langler-ui`, then the two `aws s3 sync` commands and the
`aws cloudfront create-invalidation` call — see `scripts/deploy.sh` for the
exact invocations if reconstructing this by hand.

## Rolling back a bad deploy

There are no Lambda aliases/versions and no blue-green switch — a rollback is
a forward deploy of the last-known-good commit:

1. In `langler-backend`, `git checkout <last-good-sha>` (or `git revert` the
   bad commit on `main`) and rebuild: `make build`.
2. In `langler-tf-infrastructure`, run `./scripts/deploy.sh` again from `main`
   at the point that references the good backend build. Terraform's plan
   output will show exactly what it intends to change back; review it before
   typing `apply` as with any other deploy.
3. If the bad change also touched the UI, `git checkout <last-good-sha>` in
   `langler-ui` before the deploy script's `npm run build` step runs.

Terraform state itself is versioned in the S3 state bucket (`global/`
provisions it with versioning enabled); a state-level rollback — restoring an
older object version of `root/terraform.tfstate` — is a last resort for a
corrupted state file, not a normal rollback path, and should only be done
after confirming that no other apply has happened since bad state.

## Provisioning an invited user

```sh
./scripts/create-user.sh learner@example.com
```

Cognito emails the address a temporary password; the user must set a
permanent password on first sign-in. There is no self-service signup — every
account is invited this way. To remove access, disable or delete the user
directly in the Cognito console or via `aws cognito-idp admin-disable-user`
(no wrapper script exists for this yet; use the pool id from
`terraform -chdir=environments/prod output -raw cognito_user_pool_id`).

## Provisioning the end-to-end test user

The browser suite in `langler-e2e-playwright` signs in as a dedicated Cognito
user created entirely by Terraform — no console step, no invite email. Set the
address and apply:

```sh
export TF_VAR_e2e_user_email="e2e@rtrydev.com"
./scripts/deploy.sh            # or: terraform -chdir=environments/prod apply
```

`modules/auth` then creates an `aws_cognito_user` with a permanent 24-char
`random_password` (`message_action = SUPPRESS`, `email_verified = true`), so it
lands directly in `CONFIRMED` — signing in through the UI works immediately.
Leaving `e2e_user_email` empty (the default) creates no user. Hand the runner
its credentials from the outputs:

```sh
terraform -chdir=environments/prod output -raw e2e_user_email
terraform -chdir=environments/prod output -raw e2e_user_password   # sensitive
```

The password lives in Terraform state (readable by anyone with state access) —
an accepted trade-off for a user that owns only throwaway `e2e-`-prefixed data.
Rotate it with a targeted replace:

```sh
terraform -chdir=environments/prod apply -replace='module.auth.random_password.e2e[0]'
```

After a deploy, run the suite against `https://langler.rtrydev.com` per
`langler-e2e-playwright/README.md` (it reads `e2e_user_email`,
`e2e_user_password`, `api_url`, `machine_api_url`, and `cognito_client_id` from
these outputs). A full run creates and deletes its own data; nothing
`e2e-`-prefixed should remain afterward.

## Refreshing reference data (ETL)

Reference vocabulary, grammar, scripts, and readings for each language are
loaded by the Python ETL in `langler-backend/etl`, not written by hand. Full
detail lives in `langler-backend/etl/README.md`; the short version:

```sh
cd langler-backend/etl
python3 -m venv .venv && .venv/bin/pip install -e ".[dev]"
.venv/bin/langler-etl download --language <ja|my|pl|all>
.venv/bin/langler-etl build --language <ja|my|pl|all>
.venv/bin/langler-etl load --language <ja|my|pl|all> \
  --table <table-name-from-terraform-output> \
  --assets-bucket <reference-assets-bucket-from-terraform-output>
```

Get `<table-name>` from `terraform -chdir=environments/prod output -raw
table_name` and `<assets-bucket>` from `... output -raw
reference_assets_bucket_name`. `load` is throttled to a default 20 items/sec
and safe to re-run — every write is a keyed overwrite, never an append. Use
`--kind` to refresh only one record family (e.g. just `topics`) without
re-touching the rest of a language's data. A full Japanese reload is
~10 minutes at the default throttle.

The table runs on-demand (`PAY_PER_REQUEST`), so there is no provisioned
capacity to raise before a bulk load — DynamoDB scales to the write rate
automatically and bills per request. Raising `--write-rate` above the
default is a cost decision, not a capacity one: it costs proportionally
more per second but finishes faster. There is no separate "bulk-load
window" step to open or close.

If your AWS credentials come from `aws login` (the login credential
provider), also run `.venv/bin/pip install "botocore[crt]"` once per venv —
`load`'s S3 upload otherwise fails against that credential type.

## Rotating agent tokens

Agent (harness) tokens are created and revoked by their owner from the
in-app Settings page (`/settings/`), not through an owner-side script — the
whole point of the token model is that each user manages their own tokens.
As the account owner, you would only intervene directly in DynamoDB if a
token needed emergency revocation without app access; that means setting
`revokedAt` on both the `USER#<sub>` / `AGENTTOKEN#<id>` item and its
`AGENTTOKENHASH#<hash>` / `AGENTTOKEN` counterpart in the same table (see
`langler-backend/docs/agent-authoring.md` for the exact key shapes) — treat
this as a break-glass action, not a routine one.

Tokens otherwise self-expire: every token item carries `expiresAtUnix` (set
to its stated expiry plus a 30-day grace window) and DynamoDB's TTL sweep
deletes both copies automatically once that time passes. The in-band
`Authorize` check rejects an expired token immediately regardless of whether
the TTL sweep has run yet, so there is no security gap while an expired item
waits to be swept — the grace window exists purely so an owner can still see
a recently-expired token's `lastUsed` history in their token list before it's
gone.

## Watching for trouble

`environments/prod` provisions a `monitoring` module with CloudWatch alarms
and an AWS Budgets guardrail. Nothing here sends a notification — this is a
single-owner, invite-only app with no on-call, so every alarm and the budget
exist purely to be checked in the AWS console, not to page anyone:

- **CloudWatch → Alarms**: Lambda errors/throttles (api and machine-authorizer
  functions), 5xx responses from either HTTP API, DynamoDB read/write
  throttling events, and a DynamoDB consumed-capacity spike
  (`dynamodb_consumed_capacity_threshold`, default 1000 units summed over 5
  minutes — a cost/usage signal distinct from throttling, since the table
  runs on-demand). All alarms treat missing data as "not breaching," since no
  traffic is the expected steady state, not a failure.
- **AWS Budgets** (`monthly_budget_usd`, default $10): shows spend-to-date
  and forecast for the month, console-only.

CloudWatch Logs for both Lambdas retain 14 days; API Gateway access logs
(also 14 days) let you correlate a specific request across both log groups
by `requestId` — the Lambda's own structured log lines carry the same id.
X-Ray active tracing is enabled on both functions for latency
investigation. Revisit `dynamodb_consumed_capacity_threshold` and
`monthly_budget_usd` after a month of real usage data — the defaults are
starting points, not tuned figures.

## Setting up the agent harness

See `langler-ui/docs/harness-setup.md` for how a *user* connects their own AI
agent. As the owner you do not need to do anything for this to work per user
— each user creates their own token and downloads the harness assets (a
Claude Code skill, an OpenAPI 3.1 spec, and an optional MCP server) from the
in-app `/connect/` page, which is generated from `langler-ui/lib/harness.ts`.
