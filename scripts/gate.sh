#!/usr/bin/env bash
# The gate. Exit 0 means the work counts. Nothing else does.
set -uo pipefail

fail() {
  echo "GATE FAIL: $1" >&2
  exit 1
}

echo "== 1/4 unit tests =="
uv run pytest -q || fail "pytest"

echo "== 2/4 lint =="
uv run ruff check . || fail "ruff"

echo "== 3/4 end-to-end: corpus creation =="
E2E="$(mktemp -d)"
trap 'rm -rf "$E2E"' EXIT
./koinome-cli new --name gate-corpus --path "$E2E/gate-corpus" \
  --domain 10-projects=projects \
  --domain 20-governance=governance ||
  fail "koinome new"

echo "== 4/4 end-to-end: the product validates its own output =="
./koinome-cli check "$E2E/gate-corpus" || fail "koinome check"

echo "GATE PASS"
