#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -ne 1 ]]; then
  printf 'usage: %s email@example.com\n' "$0" >&2
  exit 2
fi

INFRA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$INFRA_ROOT/environments/prod"
USER_POOL_ID="$(terraform -chdir="$TF_DIR" output -raw cognito_user_pool_id)"
INVITED_EMAIL="$1"

aws cognito-idp admin-create-user \
  --user-pool-id "$USER_POOL_ID" \
  --username "$INVITED_EMAIL" \
  --user-attributes "Name=email,Value=$INVITED_EMAIL" "Name=email_verified,Value=true"
