# Install guide — per-host setup and the timed fifteen minutes

**Status:** Plan. Addresses: docs/USAGE.md (147 lines) is a walkthrough, not an install guide; there is no per-agent-host setup path, and the Windows work already paid for in CI is invisible to users.

## Context

Strategy §12.2 is a public judging criterion: *a new user reaches first agent-consumed context in under fifteen minutes.* Today that path is undocumented per host. The benchmark (claude-obsidian) ships a dedicated install guide, per-host instructions, and a Windows/WSL page. Koinome supports four agent clients in principle (Claude Code, Codex, Gemini CLI, Cursor) and has Windows CI (CRLF, Git Bash, PATH-python fixes in `1b2db4e`, `7cf627f`, `0be21ed`) — the knowledge exists in commit history and needs to become documentation.

## Proposal

New `docs/INSTALL.md` (USAGE.md keeps the day-2 walkthrough; README quick start links here).

1. **The fifteen-minute path** — a numbered checklist with a running clock budget:
   install (2 min) → `koinome new` (1 min) → open in agent (1 min) → run `koinome-init` (8 min) → agent answers a question from corpus context (3 min). Each step states the command, the expected output line, and the single most likely failure with its fix.
2. **Install methods**, in order of recommendation: `uv tool install .`, `pipx install .`, `./koinome-cli` in place. State Python ≥3.10 + PyYAML up front; show the version check.
3. **Per-host sections** — for each of Claude Code, Codex, Gemini CLI, Cursor: where the skills/instructions file lives for that host (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` — the template already ships all three), how to open the corpus, and a **verification step**: ask the agent "what is this corpus for?" and confirm it answers from `AGENTS.md`/MOC content rather than guessing.
4. **Windows page or section** — Git Bash requirement, CRLF guardrails (already enforced by `.gitattributes` + line-ending checks), PATH-python pitfalls. Source material: the three CI-fix commits and `scripts/windows_ci_smoke.sh`.
5. **Troubleshooting** — seeded from the friction log and CI history only (real failures, not imagined ones).

## Dependencies

Write after skills-hardening lands for `koinome-init` (the guide documents the hardened flow, not the current one). The README rewrite links here; land within the same release.

## Verification

- Two timed runs from a clean machine each: macOS and Windows (VM or CI-adjacent), following only INSTALL.md, stopwatch on. Both under fifteen minutes or the guide (or the tooling) gets fixed — §12.2 is the acceptance test.
- Each per-host verification step actually run once per host; note the model used.
- A wrong-Python and a CRLF failure deliberately induced; confirm the troubleshooting entry resolves each.
