# Vendor the claude-obsidian transaction engine

**Status:** Plan. Adopts hardened atomic-apply machinery from claude-obsidian (MIT) as the deterministic executor beneath the Phase 4 proposal flow, instead of writing it from scratch.

## Context

The corpus-format-v0 proposal (Phase 4) requires a proposal → approval → apply flow. The apply step — multi-file changes that either fully land or fully roll back, surviving crashes — is the hardest undifferentiated engineering on the roadmap. claude-obsidian (github.com/AgriciDaniel/claude-obsidian, MIT, inspected 2026-08-01) has already built and tested it: process-held mutation lock, precondition hashes, durable journal, atomic per-file replace, deterministic rollback/recovery, path confinement (dirfd where supported), all pure stdlib Python. Core suites pass locally (`test_transaction.py`, 2,594 lines). The module is nearly format-agnostic: it operates on paths, hashes, and JSON journals; Obsidian appears only in protected-path constants and schema names.

Vendoring means copying the files into this repo under our maintenance, with attribution — not a dependency (it is not on PyPI) and not a fork (we take ~5K of 40K lines).

## Scope

**In:** `claude_obsidian/transaction.py` (4,680 ln), `paths.py`, `json_utils.py`, plus `tests/test_transaction.py`. **Out:** everything else — lint engine (Obsidian-dialect), ledgers (different provenance design; study for RFC 3, do not vendor), capture, release machinery, skills.

## Steps

1. **Pin the baseline.** Record the upstream commit hash in the attribution entry; keep a copy of the pristine files (or the hash alone) so future upstream diffs are possible.
2. **Copy** into `koinome/_vendor/claude_obsidian/` with a `VENDORED.md` stating: upstream URL, commit, licence, list of local modifications (append-only divergence log).
3. **Attribution.** Add the MIT notice to `NOTICE` (Apache-2.0 permits MIT inclusion; retain their copyright line). Model: claude-obsidian's own `ATTRIBUTION.md`.
4. **Adapt, minimally and loggedly:**
   - Rename journal/bundle schema IDs `claude-obsidian.transaction.*` → `koinome.transaction.*`.
   - Lift the Obsidian protected-path constants (`.obsidian/*`, `.claude-obsidian.json`) into caller-supplied configuration; Koinome injects its own (`.koinome/*`, `koinome.corpus.yaml`).
   - Keep their test file running against the adapted module under our pytest harness (they run tests standalone; wrap, don't rewrite).
5. **Integration point (Phase 4, not before):** the MCP proposal flow's approve step emits a transaction plan; the vendored engine executes it. The validator remains the decision point; this engine is only the enforcement mechanics. Until Phase 4, the module ships inert (no CLI surface) — mirroring the "primitives stabilised early, enforced later" pattern from strategy §8.
6. **Divergence hygiene:** every local edit appends one line to `VENDORED.md`. Once per release, diff upstream `transaction.py` against the pinned baseline for security-relevant fixes; port deliberately or decline explicitly.

## Risks

- **Silent upstream fixes missed** — mitigated by the pinned baseline + per-release diff (step 6). Accepted trade-off of vendoring.
- **Windows semantics** — the engine feature-detects dirfd confinement and falls back; must be proven on the existing Windows CI job, not assumed.
- **Licence hygiene** — MIT→Apache is clean, but the NOTICE entry must land in the same PR as the code; no window where vendored code exists unattributed.

## Verification

- Vendored test suite green in CI on macOS, Linux, Windows.
- Crash-recovery demo against the example corpus: apply a two-file plan, kill the process between file writes (their tests show the injection points), rerun `transaction recover`, corpus is bit-for-bit either pre- or post-state — never mixed — and `koinome check` passes in both.
- `koinome doctor`/`check` behaviour unchanged (module is inert until Phase 4).
