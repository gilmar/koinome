#!/usr/bin/env bash
# The full gate. Exit 0 means the work counts. Nothing else does.
set -uo pipefail

fail() {
  echo "GATE FAIL: $1" >&2
  exit 1
}
step() {
  echo
  echo "== $* =="
}

cd "$(git rev-parse --show-toplevel)" || fail "not in a git worktree"

# Stale bytecode is a correctness hazard, not a performance one (§9.1).
export PYTHONDONTWRITEBYTECODE=1
export PYTHONHASHSEED=0
find . -name '__pycache__' -type d -prune -exec rm -rf {} + 2>/dev/null || true
find . -name '*.pyc' -delete 2>/dev/null || true

step "0. provenance: the code under test is the code on disk"
uv run python - <<'PY' || fail "bytecode provenance"
import pathlib, koinome
root = pathlib.Path.cwd().resolve()
p = pathlib.Path(koinome.__file__).resolve()
assert root in p.parents, f"koinome imported from outside worktree: {p}"
print(f"koinome imported from {p}")
PY

step "1. unit tests"
uv run pytest -q -p no:cacheprovider || fail "pytest"

step "2. lint"
uv run ruff check . || fail "ruff"
[ -x scripts/lint-shell.sh ] && { ./scripts/lint-shell.sh || fail "lint-shell"; }

step "3. repository invariants (existing tooling)"
[ -x scripts/check_repo.sh ] && { ./scripts/check_repo.sh || fail "check_repo"; }

step "4. committed examples pass check WITHOUT rebuilding"
# This is the check that would have caught the date bug. Do not rebuild first.
# Detect corpora by marker file: examples/ also holds build_references.py and
# non-corpus directories, and each corpus carries .koinome/{snapshot,backups}
# copies that would otherwise be checked as corpora in their own right.
git diff --quiet examples/ || fail "examples/ is dirty; commit or discard before gating"
found=0
while IFS= read -r cfg; do
  c="$(dirname "$(dirname "$cfg")")"
  found=$((found + 1))
  echo "-- $c"
  uv run ./koinome-cli check "$c" || fail "check $c (committed state)"
done < <(find examples -maxdepth 3 -path '*/.scripts/koinome.config.json' -not -path '*/.koinome/*')
# A loop over an empty list exits 0 and proves nothing — Rule 1 applied to the gate itself.
[ "$found" -gt 0 ] || fail "no reference corpora found under examples/ — has the layout changed?"
echo "checked $found committed corpora"

step "5. end-to-end: create a corpus, then let the product validate it"
E2E="$(mktemp -d)"
trap 'rm -rf "$E2E"' EXIT
uv run ./koinome-cli new --name gate-corpus --path "$E2E/gate-corpus" \
  --domain 10-projects=projects --domain 20-governance=governance ||
  fail "koinome new"
uv run ./koinome-cli check "$E2E/gate-corpus" || fail "koinome check (fresh corpus)"

step "6. no cache artifacts left behind"
if find . -name '*.pyc' -o -name '__pycache__' -type d | grep -q .; then
  fail "bytecode written during the run; PYTHONDONTWRITEBYTECODE not propagated"
fi

echo
echo "GATE PASS"
