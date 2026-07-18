#!/usr/bin/env bash

set -euo pipefail

INFRA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE_ROOT="$(cd "$INFRA_ROOT/.." && pwd)"
BACKEND_ROOT="$WORKSPACE_ROOT/langler-backend"
UI_ROOT="$WORKSPACE_ROOT/langler-ui"

make -C "$BACKEND_ROOT" build
(
  cd "$BACKEND_ROOT"
  go test ./...
  golangci-lint run
)

npm --prefix "$UI_ROOT" run lint
npm --prefix "$UI_ROOT" test

terraform -chdir="$INFRA_ROOT" fmt -check -recursive

for directory in global modules/api modules/auth modules/reference-assets modules/storage environments/prod; do
  terraform -chdir="$INFRA_ROOT/$directory" init -backend=false -input=false -reconfigure
  terraform -chdir="$INFRA_ROOT/$directory" validate
done

(
  cd "$INFRA_ROOT"
  tflint --recursive
  checkov -d .
)

for directory in global modules/api modules/auth modules/frontend modules/reference-assets modules/storage; do
  terraform -chdir="$INFRA_ROOT/$directory" test
done
