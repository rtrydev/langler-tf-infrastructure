# langler-tf-infrastructure

Terraform for [Langler](https://langler.rtrydev.com) — an invitation-only, BYOAI language-learning app for Japanese, Burmese, and Polish.

All AWS infrastructure lives here, following the myangler-web pattern: Next.js static export on private S3 + CloudFront, Go Lambdas behind an API Gateway HTTP API, Cognito (invite-only), DynamoDB single table, ACM + Route 53. Design goal: near-zero idle cost — no always-on components.

## Layout

- `versions.tf` / `providers.tf` — provider setup; a `us_east_1` alias exists for the CloudFront ACM certificate.
- `variables.tf` — domain (`langler.rtrydev.com`), region, and paths to sibling repo build artifacts (`langler-backend/build`, `langler-ui/out`).
- `main.tf` — module composition (modules to be added per `langler/tasks/01-foundations-infrastructure.md`).

## Usage

```sh
terraform init
terraform plan -out=tfplan
```

A human reviews the plan and applies it; automation never runs `terraform apply`.

## State

State lives in the S3 bucket defined in `global/` (`langler-terraform-state`), with native S3 lockfile locking (`use_lockfile = true` — no DynamoDB lock table). `backend.tf` configures the root module's backend (key `root/terraform.tfstate`). See `global/README.md` for the one-time bootstrap: the bucket itself is created from `global/` with local state before any backend can point at it.

## Tooling

- `terraform fmt -recursive` / `terraform validate`
- `tflint --recursive` (config in `.tflint.hcl`)
- `checkov -d .`
- `terraform test` (unit tests under `*/tests/`, plan-only with mocked providers)
