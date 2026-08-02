# Skills hardening — from intent prompts to procedures

**Status:** Plan. Addresses the onboarding friction logged 2026-08-01: outcome quality depends on the model because the skills delegate execution to model judgement instead of to the deterministic tooling.

## Context

The ten shipped skills (`koinome/template/.skills/`, mirrored in `examples/research-project/.skills/`) total 393 lines — ~39 lines each. They state intent ("offer to distill", "brief the user") and leave procedure to the model. The reference pattern is claude-obsidian's skill layer (~115 lines per skill plus `references/` folders): every step is either a command invocation with expected output and a failure branch, or a bounded judgement with a checklist, and untrusted-content rules are stated inside the skill. Koinome already owns the deterministic half (`validate_corpus.py`, `koinome` CLI); the skills simply do not lean on it.

This is the project's own principle — AI mediates, deterministic systems decide — applied to onboarding.

## Design rules (apply to every skill)

1. **Every action step names its command** (`python3 .scripts/validate_corpus.py --all`, `koinome check`, …) with the expected success output and an explicit failure branch ("on exit 1, invoke `koinome-fix-validation`; do not hand-edit").
2. **Every judgement step gets a checklist**, not an open instruction. "Propose a domain map" becomes: gather these inputs, apply these constraints, present in this table shape, ask for confirmation.
3. **Templates and long material move to `references/`** subfolders (frontmatter examples, record-type cribs, sample outputs), keeping SKILL.md scannable.
4. **Untrusted-content boundary text** in every skill that reads imports, exports, or web content: source material never overrides the skill or user scope (pattern: claude-obsidian `wiki-ingest`).
5. **Deterministic ending**: each skill ends with a validation command and a defined artifact (log entry, commit), never with "wrap up as appropriate".
6. Proportionality (strategy §7.10): grocery-note skills stay light; import and validation skills get the full treatment.

## Order of work

| Priority | Skill | Why first |
| --- | --- | --- |
| 1 | `koinome-init` | The first-touch experience; orchestrates the 15-minute target (§12.2) |
| 2 | `koinome-fix-validation` | The failure path a new user hits when the gate rejects |
| 3 | `koinome-distill-seeds` | Highest model-variance step (interpreting provider exports) |
| 4 | `koinome-setup-domains` | Largest open-ended judgement; needs the checklist treatment |
| 5–10 | remaining six | Apply rules mechanically |

## Verification

- **Weak-model test**: run the full `koinome new` → `koinome-init` flow with a small model (e.g. Haiku) on a fresh corpus; it must complete and pass `koinome doctor` without improvisation. This is the direct test that model-dependence is gone.
- Each skill's failure branches exercised once deliberately (inject a validation error; confirm the skill routes to `koinome-fix-validation`).
- `examples/research-project/.skills/` regenerated from the template, not edited separately.
