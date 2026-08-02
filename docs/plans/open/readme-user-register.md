# README rewrite — user register, thesis stays in STRATEGY

**Status:** Plan. Addresses: the README addresses a reviewer of the thesis; it should address a first-time user. The thesis already has a home (docs/STRATEGY.md); the README currently duplicates its job.

## Context

The current README (81 lines) leads with the problem narrative and the governance argument, has one banner image, no jump navigation, no screenshots, and hands the payoff moment to a skill invocation. The register benchmark is claude-obsidian's README: one bold outcome sentence, the workflow as four verbs, screenshots of the result, badges, jump-nav — with equal rigour underneath, linked rather than inlined. Strategy §8 names a 90-second demo as the anchor for every build decision; the README shows none of it.

## Target structure

1. **Hero**: banner (exists) + one outcome sentence. Candidate: *"A knowledge corpus your AI agents read before acting and propose to after learning — plain files, your final say, forever portable."* Badges: licence, release, Python versions.
2. **Jump-nav line**: quick start · the loop · skills · docs · strategy.
3. **The loop in verbs** (replaces the Monday/Tuesday narrative, which moves to STRATEGY or an essay): capture → agent drafts → gate decides → you commit → still yours with the tooling deleted. One short paragraph per verb, present tense, second person.
4. **See it**: 2–3 visuals — (a) a corpus open in an editor with frontmatter visible, (b) the gate rejecting a proposal (`koinome doctor` output on a record missing sources) — this is the differentiator no other tool can screenshot, (c) short terminal recording (vhs or asciinema→gif) of `koinome new` → validated corpus.
5. **Quick start**: the three commands, verbatim, with the expected final line of output shown.
6. **Commands table** (exists; keep).
7. **Guarantees**: compress to the seven one-liners, each linking to the STRATEGY section that argues it. No inline argument.
8. **Status + licence** (exists; keep the honesty, tighten).

## Rules

- Every paragraph that argues rather than shows moves to STRATEGY.md and becomes a link.
- No sentence a first-time reader must reread. Terms like *principal*, *provenance*, *deterministic gate* appear only with an inline plain-language gloss or after the loop has shown the behaviour.
- The turn-it-off test stays — it is the most accessible idea in the doc — but stated in two sentences.

## Verification

- The 90-second read test: someone who has never seen the project reads only the README and can answer: what is it, what do I type first, what does the gate do for me, what do I lose if I quit. Test on one real person.
- Screenshot of the rejected proposal reproduces from the example corpus (documented command, not a staged mock).
- All STRATEGY links resolve; README line count target ≤ 120.
