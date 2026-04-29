#!/usr/bin/env bash
# Run golangci-lint with the Uber-recommended linter set.
# Source: https://github.com/uber-go/guide/blob/master/style.md#linting
#
# Usage:
#   scripts/lint.sh                 # lint ./...
#   scripts/lint.sh ./pkg/...       # lint a specific path
#   scripts/lint.sh --fix           # auto-fix where possible
#
# If a project-local .golangci.yml exists in the working directory or any
# parent, golangci-lint picks it up automatically. Otherwise this script
# falls back to a temporary config with the Uber-recommended linters.

set -euo pipefail

if ! command -v golangci-lint >/dev/null 2>&1; then
  echo "golangci-lint not found. Install: https://golangci-lint.run/usage/install/" >&2
  exit 1
fi

# If user already has a config, just run.
if find . -maxdepth 4 -name '.golangci.yml' -o -name '.golangci.yaml' -o -name '.golangci.toml' -o -name '.golangci.json' 2>/dev/null | grep -q .; then
  exec golangci-lint run "$@"
fi

# Otherwise, use the Uber-recommended base set.
TMP_CONFIG="$(mktemp -t golangci-uber.XXXXXX.yml)"
trap 'rm -f "$TMP_CONFIG"' EXIT

cat >"$TMP_CONFIG" <<'YAML'
# Uber Go Style Guide recommended linters
# https://github.com/uber-go/guide/blob/master/style.md#linting
run:
  timeout: 5m
  modules-download-mode: readonly

linters:
  enable:
    - errcheck      # ensures errors are handled
    - goimports     # formats and manages imports
    - revive        # successor to golint
    - govet         # standard analysis
    - staticcheck   # extensive static analysis

issues:
  exclude-use-default: false
  max-issues-per-linter: 0
  max-same-issues: 0
YAML

exec golangci-lint run --config "$TMP_CONFIG" "$@"
