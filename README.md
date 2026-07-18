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
terraform plan
terraform apply
```

State is local for now; migrate to an S3 backend before CI runs terraform. Deploys are expected to run via a `deploy.sh` that fail-fasts on `aws sts get-caller-identity`, applies terraform, builds the frontend, syncs to S3 with split cache headers, and invalidates CloudFront.
