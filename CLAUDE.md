# This is not the Terraform in your training data

<!-- Reviewed 2026-07-18 against Terraform 1.15.x. Re-check when we bump `required_version`. -->

Most Terraform material you have seen predates the patterns below. Before writing HCL, check that you are not reaching for a deprecated approach:

- **State locking is native to S3.** Set `use_lockfile = true` in the backend. Do not create a DynamoDB lock table; `dynamodb_table` is deprecated and slated for removal.
- **Tests are a first-class feature.** `.tftest.hcl` files run with `terraform test`. Do not propose Terratest or Go for anything we can express natively.
- **State surgery is declarative.** Use `moved`, `removed`, and `import` blocks in the configuration. Do not reach for `terraform state mv`, `terraform state rm`, or `terraform import` on the CLI.
- **Secrets can stay out of state.** Prefer ephemeral resources and write-only arguments for credentials, rather than a resource whose value lands in the state file.
- **`tfsec` is deprecated and Terrascan is archived.** We scan with the tools in Commands below; do not add either.

When unsure whether an API is current, say so and check the provider docs rather than guessing from memory. A confidently wrong resource argument costs more here than an admission of uncertainty.

# <repo name>

Terraform configuration for <org>'s <cloud> infrastructure. This repo is the source of truth: anything that exists in the account and is not described here is either a mistake or an explicitly documented exception.

## Commands

- Format: `terraform fmt -recursive`
- Validate: `terraform validate`
- Lint: `tflint --recursive`
- Security scan: `checkov -d .`
- Unit tests: `terraform test`
- Plan: `terraform plan -out=tfplan`

Run fmt, validate, lint, and scan before proposing any commit. All four must pass.

## What you must not do

These are hard limits, not preferences:

- **Never run `terraform apply`, `terraform destroy`, or `terraform state` subcommands.** Produce a plan and stop. A human reviews and applies.
- **Never edit `.tfstate` or `.tfstate.backup` by hand,** and never commit them.
- **Never commit `.tfvars` containing real values,** credentials, account IDs, or ARNs from production. `*.auto.tfvars` is gitignored; keep it that way.
- **Never hardcode a secret,** even as a variable default, even as a placeholder that "will be replaced."
- **Never widen an IAM policy, security group, or bucket policy to make something work.** If a permission is missing, say which one and why, and let a human decide.

If a task appears to require one of the above, stop and explain what you would need. Do not find a way around it.

## Layout

- `modules/` — reusable, provider-agnostic-where-possible building blocks. No hardcoded environment names, account IDs, or regions.
- `environments/dev/`, `environments/staging/`, `environments/prod/` — root modules, one state file each. These compose modules and supply environment-specific values. Almost no bare resources.
- `environments/*/backend.tf` — backend configuration, including `use_lockfile = true`
- `global/` — account-level resources that are not per-environment: state bucket, OIDC providers, org policies
- `policies/` — policy-as-code rules enforced in CI

Every module directory contains `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`, and `tests/`. Do not deviate from those filenames; people navigate by them.

## Using and writing modules

Reuse before you build, in this order:

1. An existing module in `modules/`.
2. A well-maintained public module from the registry, pinned to an exact version. Propose it and wait for agreement before adding a new external dependency.
3. A new module in `modules/`, written generically.

Only write bare resources in an `environments/` root module when the resource is genuinely a one-off for that environment. If you write the same resource block into two environments, that is the signal to extract a module instead.

A module is scoped to one logical unit — a VPC, a service, a database. Not an entire environment, and not a single tag. When a module needs a value it cannot derive, that is an input variable, not a hardcoded assumption about our accounts.

Every input variable declares a `type` and a `description`, and carries a `validation` block where the valid range is narrower than the type. Every output declares a `description`, and is marked `sensitive` when it carries one. Treat variables as the module's public API: renaming one is a breaking change.

## Conventions

- Pin `required_version` and every provider with a `~>` constraint in `versions.tf`. Commit `.terraform.lock.hcl`.
- Prefer `for_each` over `count`. `count` keys resources by index, so inserting an item in the middle destroys and recreates everything after it.
- Resource names are `snake_case` and describe the role, not the type: `aws_s3_bucket.user_uploads`, not `aws_s3_bucket.bucket_1`.
- Never interpolate a resource name where you can reference the resource: `aws_vpc.main.id`, not a rebuilt string. Implicit dependencies are how Terraform orders the graph.
- Use `depends_on` only when the dependency is real but invisible to Terraform, and comment why.
- Apply the standard tag set to every taggable resource via provider `default_tags`. Do not tag resources individually unless adding something beyond the defaults.
- Use `precondition` and `postcondition` blocks to assert what a module requires and guarantees. A failed plan is much cheaper than a failed apply.
- **No comments in Terraform code unless the case explicitly requires one.** HCL is declarative; well-named resources and variables with descriptions are the documentation. The required cases: a `depends_on` justification, a lint/scan suppression with its reason, and a constraint the code cannot express (an ordering quirk, an external contract). Never comment to narrate what a block does or to explain a change to a reviewer — that belongs in the PR description.
- **No hacks or workarounds.** No `null_resource`/`local-exec` glue where a real resource or data source exists, no `-target` or state gymnastics to dodge a dependency problem, no "temporary" duplication that will be cleaned up later. If the clean implementation is blocked, stop and say what blocks it; a workaround that works becomes permanent, and we are building this to last.

## Testing

- Unit tests use `command = plan` so no infrastructure is created. These should cover variable validation, conditional logic, and count/for_each behaviour.
- Integration tests use `command = apply` and are reserved for modules where the plan cannot tell us what we need to know. They cost real money and real time; add one only when asked.
- Use `mock_provider` to test module logic without provider credentials.
- Every module needs at least one test asserting it plans cleanly with only its required variables set.
- When fixing a bug, add the test first and confirm it fails against the unfixed configuration.

## Workflow

- Branch from `main`. Never push directly. CI runs plan on every PR and posts the output.
- Include the relevant plan output in the PR description. A reviewer should not have to run Terraform to know what will change.
- **Call out destructive changes explicitly.** If a plan shows any resource being destroyed or replaced, say so at the top of your summary, name the resources, and explain why the replacement is triggered. Never let a `-/+` slip through in a wall of plan output.
- Keep changes scoped to one environment per PR where possible, and promote dev → staging → prod rather than changing all three at once.
- Pin CI actions to a commit SHA, not a tag. IaC scanning actions have been a supply-chain target.
- Update the module `README.md` in the same commit as the interface change, not afterwards.
