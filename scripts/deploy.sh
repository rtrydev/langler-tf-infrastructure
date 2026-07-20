#!/usr/bin/env bash

set -euo pipefail
umask 077

INFRA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE_ROOT="$(cd "$INFRA_ROOT/.." && pwd)"
BACKEND_ROOT="$WORKSPACE_ROOT/langler-backend"
UI_ROOT="$WORKSPACE_ROOT/langler-ui"
TF_DIR="$INFRA_ROOT/environments/prod"
TF_PLAN_DIR=""
TF_PLAN=""

cleanup() {
  if [[ -n "$TF_PLAN" && -f "$TF_PLAN" ]]; then
    rm -f "$TF_PLAN"
  fi
  if [[ -n "$TF_PLAN_DIR" && -d "$TF_PLAN_DIR" ]]; then
    rmdir "$TF_PLAN_DIR"
  fi
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

"$INFRA_ROOT/scripts/check.sh"

if [[ ! "${LANGLER_AWS_ACCOUNT_ID:-}" =~ ^[0-9]{12}$ ]]; then
  printf 'Set LANGLER_AWS_ACCOUNT_ID to the expected 12-digit deployment account.\n' >&2
  exit 1
fi

if ! AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text 2>&1)"; then
  printf 'AWS authentication failed: %s\n' "$AWS_ACCOUNT_ID" >&2
  printf 'Complete your AWS login flow and try again.\n' >&2
  exit 1
fi

if [[ "$AWS_ACCOUNT_ID" != "$LANGLER_AWS_ACCOUNT_ID" ]]; then
  printf 'Refusing deployment to AWS account %s; expected %s.\n' "$AWS_ACCOUNT_ID" "$LANGLER_AWS_ACCOUNT_ID" >&2
  exit 1
fi

if ! AWS_IDENTITY="$(aws sts get-caller-identity --query Arn --output text 2>&1)"; then
  printf 'AWS authentication failed: %s\n' "$AWS_IDENTITY" >&2
  printf 'Complete your AWS login flow and try again.\n' >&2
  exit 1
fi
printf 'AWS identity: %s\n' "$AWS_IDENTITY"

export TF_VAR_expected_aws_account_id="$LANGLER_AWS_ACCOUNT_ID"
TF_PLAN_DIR="$(mktemp -d "${TMPDIR:-/tmp}/langler-tfplan.XXXXXX")"
TF_PLAN="$TF_PLAN_DIR/tfplan"
terraform -chdir="$TF_DIR" init -input=false
terraform -chdir="$TF_DIR" plan -input=false -out="$TF_PLAN"

printf 'Review the plan above. Type apply to deploy it: '
read -r DEPLOY_CONFIRMATION
if [[ "$DEPLOY_CONFIRMATION" != "apply" ]]; then
  printf 'Deployment cancelled.\n'
  exit 1
fi
terraform -chdir="$TF_DIR" apply -input=false "$TF_PLAN"

FRONTEND_BUCKET="$(terraform -chdir="$TF_DIR" output -raw frontend_bucket_name)"
DISTRIBUTION_ID="$(terraform -chdir="$TF_DIR" output -raw cloudfront_distribution_id)"
export NEXT_PUBLIC_API_URL="$(terraform -chdir="$TF_DIR" output -raw api_url)"
export NEXT_PUBLIC_MACHINE_API_URL="$(terraform -chdir="$TF_DIR" output -raw machine_api_url)"
export NEXT_PUBLIC_COGNITO_CLIENT_ID="$(terraform -chdir="$TF_DIR" output -raw cognito_client_id)"
export NEXT_PUBLIC_AWS_REGION="eu-central-1"
export NEXT_PUBLIC_REFERENCE_ASSETS_URL="https://$(terraform -chdir="$TF_DIR" output -raw reference_assets_cdn_domain)"

npm --prefix "$UI_ROOT" run build

UI_OUT="$UI_ROOT/out"
if [[ ! -d "$UI_OUT" ]]; then
  printf 'Expected static export at %s.\n' "$UI_OUT" >&2
  exit 1
fi

aws s3 sync "$UI_OUT" "s3://$FRONTEND_BUCKET" \
  --delete \
  --exclude ".DS_Store" \
  --exclude "_next/static/*" \
  --cache-control "public, max-age=60, must-revalidate"

aws s3 sync "$UI_OUT/_next/static" "s3://$FRONTEND_BUCKET/_next/static" \
  --delete \
  --cache-control "public, max-age=31536000, immutable"

aws cloudfront create-invalidation \
  --distribution-id "$DISTRIBUTION_ID" \
  --paths "/*" \
  >/dev/null

printf 'Langler deployment complete.\n'
