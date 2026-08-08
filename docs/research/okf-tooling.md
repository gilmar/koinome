# Research: how OKF tooling consumes a local bundle

Resolves [#47](https://github.com/gilmar/koinome/issues/47), part of map [#45](https://github.com/gilmar/koinome/issues/45).

- **Source read:** [`GoogleCloudPlatform/knowledge-catalog`](https://github.com/GoogleCloudPlatform/knowledge-catalog) at HEAD
- **Commit SHA:** `afcd31c9f7ab0565bcc6ac60ec144efcd2e12dd6` (2026-08-07, "mdcode: add semantic-model scope and BigQuery Graph push (#270)")
- **Method:** full clone read locally; every claim cites a file path (and lines where load-bearing) at that SHA. Nothing here was executed against the Koinome corpus — per the ticket, this document is the recipe, not the verification.

## Repo orientation

Only the `okf/` subtree is about local OKF bundles. The top-level `samples/` (discovery + enrichment agents) and `toolbox/` (`mdcode`, enrichment harness) target the **Dataplex Knowledge Catalog cloud service** — they consume the `dataplex.googleapis.com` Search API and catalog entries, not local bundle directories (`samples/discovery/README.md`, `toolbox/README.md`). They are out of scope for corpus-as-bundle.

Inside `okf/`:

| Path | What it is |
|---|---|
| `okf/SPEC.md` | OKF v0.2 spec, incl. §11 Conformance |
| `okf/pyproject.toml` | Package `reference-agent` 0.1.0; **single console script** `reference-agent = reference_agent.cli:main` |
| `okf/src/reference_agent/` | CLI with exactly two subcommands: `enrich`, `visualize` (`cli.py`) |
| `okf/samples/{ga4_merch_store,stackoverflow,crypto_bitcoin}/` | Recipes: `README.md` + `seeds.txt` per sample |
| `okf/bundles/{ga4,stackoverflow,crypto_bitcoin,acme_retail}/` | Committed bundles produced by those recipes (`acme_retail` has no recipe) |
| `okf/tests/` | pytest suite for the package itself |

The package is also runnable without console-script install as `python -m reference_agent` (`okf/src/reference_agent/__main__.py`).

Requirements: Python `>=3.11` (`okf/pyproject.toml`; the README uses 3.13). Dependencies pulled in even if you only want the visualizer: `google-adk>=2.0`, `google-cloud-bigquery>=3.20`, `pyyaml`, `pydantic`, `markdownify`.

## Common setup (all recipes below assume this)

From `okf/README.md` §Install:

```bash
git clone https://github.com/GoogleCloudPlatform/knowledge-catalog
cd knowledge-catalog
git checkout afcd31c9f7ab0565bcc6ac60ec144efcd2e12dd6   # pin the SHA this research read
cd okf
python3.13 -m venv .venv        # any >=3.11 works per pyproject.toml
.venv/bin/pip install --index-url https://pypi.org/simple/ -e .[dev]
```

No credentials of any kind are needed for the visualizer, the conformance check, or the test suite. Credentials are needed only for `enrich` (BigQuery ADC + Gemini) — see Tool 3.

---

## Tool 1: static HTML visualizer (`visualize`) — the canonical local-bundle consumer

**Source:** `okf/src/reference_agent/cli.py` (subcommand wiring, lines 145–186), `okf/src/reference_agent/viewer/generator.py` (all consumption logic).

### Invocation

```bash
BUNDLE=/absolute/path/to/local/bundle   # e.g. the Koinome example corpus root
.venv/bin/python -m reference_agent visualize \
    --bundle "$BUNDLE" \
    --out /tmp/okf-viz.html \
    --name "Koinome example corpus"
```

Flags (`cli.py:145–160`): `--bundle` (required, bundle root dir), `--out` (default `<bundle>/viz.html` — pass an explicit `--out` to avoid writing into the corpus), `--name` (default: bundle directory name).

### Inputs required

A directory. That is all. The generator walks `bundle_root.rglob("*.md")` sorted, **skips every `index.md`** (reserved filename), and parses each remaining file as frontmatter + body (`generator.py:89–99`). Concept ids are the bundle-root-relative path minus `.md`. Edges come from relative markdown links matching `](…​.md)` (regex `\]\(([^)\s]+\.md)(?:#…)?\)`, `generator.py:18`); absolute (`/…`) and `scheme://` links are ignored, and links whose resolved target is outside the bundle root or not among the walked concepts are dropped silently (`generator.py:68–86`, `137–139`).

### What it rejects

- **Whole-bundle:** only a nonexistent `--bundle` directory → `FileNotFoundError` (`generator.py:184–185`). An empty directory "succeeds" with 0 concepts.
- **Per-file, silently skipped (never fatal):** unterminated frontmatter block, invalid YAML, or frontmatter that is not a YAML mapping → `OKFDocumentError` → the file is dropped from the graph (`generator.py:96–99`; error conditions in `bundle/document.py:24–49`).
- **Never rejected:** a file with *no* frontmatter at all parses as body-only and is included with `type: Unknown`; missing `type`/`title`/anything else falls back to defaults (`generator.py:110–126`). This matches SPEC §11: "consumers MUST NOT reject a bundle because of … missing optional frontmatter fields, unknown `type` values, unknown additional frontmatter keys, broken cross-links, missing `index.md` files" (`okf/SPEC.md:752–760`).

It also computes v0.2 trust/lifecycle signals per concept — `trust_tier` (unverified / machine-confirmed / human-reviewed) and `stale` from `verified`/`stale_after` frontmatter (`bundle/document.py:82–115`) — so a bundle carrying those fields gets them surfaced in the UI.

### What success looks like

Exit code 0 plus a stderr line (`cli.py:180–186`):

```
Wrote <N> concept(s), <M> edge(s), <K> bytes → /tmp/okf-viz.html
```

Sanity criteria for the prototype ticket: **N should equal the number of non-`index.md` `.md` files with parseable frontmatter** in the corpus, and M > 0 if the corpus cross-links records with relative `.md` links. N = 0 or N ≪ file count means files were silently skipped (frontmatter parse failures) — that, not an error message, is how conformance problems manifest here. The output is a single self-contained HTML file (bundle serialized in as JSON, `generator.py:194–202`); note it loads Cytoscape.js and marked **from a CDN at view time** (`okf/README.md:210–214`), so generation is offline but viewing the graph needs network.

## Tool 2: validator / test harness — no standalone bundle validator exists

There is **no `validate` subcommand and no CLI that checks an arbitrary bundle** at this SHA (`cli.py` defines only `enrich` and `visualize`). What exists instead:

1. **Document-level validation, importable.** `OKFDocument.parse()` raises `OKFDocumentError` on unterminated/invalid/non-mapping frontmatter; `OKFDocument.validate()` checks the *only* required key, `type` — `REQUIRED_FRONTMATTER_KEYS = ("type",)`, annotated "OKF v0.2 §11: `type` is the only always-required frontmatter key" (`okf/src/reference_agent/bundle/document.py:9–10, 58–63`).
2. **Write-time guards inside the agent tooling** (not reachable for read-only validation): `write_concept_doc` refuses docs missing `type`, and during the web pass refuses writes that shrink an existing BigQuery Table doc's `# Schema` field set or its `sources` list (`okf/src/reference_agent/tools/bundle_tools.py:126–183`). Concept-id path segments must match `[A-Za-z0-9_][A-Za-z0-9_.\-]*` (`bundle/paths.py:6`).
3. **The pytest suite** (`.venv/bin/pytest` from `okf/`; configured in `pyproject.toml` `[tool.pytest.ini_options]`) tests the *package* against synthetic bundles built in tmp dirs (`okf/tests/test_viewer.py`, `test_document.py`, `test_index.py`, `test_bundle_tools.py`, …). It does **not** take a bundle path; it validates the tooling, not your bundle. Success: all tests pass, no GCP calls made.

### Recipe: de-facto conformance check for a local bundle

SPEC §11 (`okf/SPEC.md:733–741`) defines conformance as: (1) every non-reserved `.md` has parseable YAML frontmatter, (2) every frontmatter has non-empty `type`, (3) reserved files (`index.md`, `log.md`) follow §8/§9 when present. Points 1–2 are mechanically checkable with the repo's own parser:

```bash
BUNDLE=/absolute/path/to/local/bundle
.venv/bin/python - "$BUNDLE" <<'EOF'
import sys
from pathlib import Path
from reference_agent.bundle.document import OKFDocument, OKFDocumentError

bundle = Path(sys.argv[1])
reserved = {"index.md", "log.md"}
failures = 0
checked = 0
for md in sorted(bundle.rglob("*.md")):
    if md.name in reserved:
        continue
    checked += 1
    rel = md.relative_to(bundle)
    try:
        doc = OKFDocument.parse(md.read_text(encoding="utf-8"))
        doc.validate()  # requires non-empty `type` (SPEC v0.2 §11)
    except OKFDocumentError as e:
        failures += 1
        print(f"FAIL {rel}: {e}")
print(f"{checked} concept doc(s) checked, {failures} failure(s)")
sys.exit(1 if failures else 0)
EOF
```

Success: exit 0 and `… 0 failure(s)`. Note this is stricter than the visualizer, which tolerates frontmatter-less files as `type: Unknown` — a corpus can render in the viewer yet fail §11.

## Tool 3: reference agent (`enrich`) — a producer that reads an existing local bundle, but cannot run bundle-only

**Source:** `okf/src/reference_agent/cli.py:59–214`, `runner.py`, `sources/bigquery.py`, `tools/bundle_tools.py`.

### Invocation (from `okf/samples/crypto_bitcoin/README.md`, the repo's own recipe form)

```bash
.venv/bin/python -m reference_agent enrich \
    --source bq \
    --dataset <project>.<dataset> \
    --web-seed-file samples/<name>/seeds.txt \
    --out "$BUNDLE"
```

Variants: `--concept tables/<name>` (repeatable, single-concept iteration), `--no-web` (skip web pass), `--web-max-pages N` (default 100), `--web-allowed-host` / `--web-allowed-path-prefix` / `--web-denied-path-substring` / `--web-max-depth` (crawl fencing), `--model` (default `gemini-flash-latest`, `agent.py:16`).

### Inputs required

- `--source bq` is the **only registered source**: `_SOURCES = ("bq",)` (`cli.py:14`), so a BigQuery dataset is mandatory — the agent cannot enrich from a local directory alone.
- BigQuery ADC credentials + billing project (`gcloud auth application-default login`; `okf/README.md:91–95`).
- Gemini credentials: `GEMINI_API_KEY`, or Vertex via `GOOGLE_GENAI_USE_VERTEXAI=true` + `GOOGLE_CLOUD_PROJECT` + `GOOGLE_CLOUD_LOCATION` (`okf/README.md:96–98`).

### How it consumes a local bundle

`--out` is the bundle root, and pointing it at an **existing** bundle is the supported incremental path: the agent's `read_existing_doc` tool reads what is on disk so the LLM refines rather than overwrites (`bundle_tools.py:73–87`), and the web-pass augmentation guard diffs new content against the existing doc (`bundle_tools.py:139–183`). After a run it regenerates every `index.md` (`runner.py` calls `regenerate_indexes`; directory descriptions are LLM-synthesized).

### What it rejects

`--source bq` without `--dataset` → `SystemExit` (`cli.py:19–20`); unknown `--source` → `SystemExit`; malformed `--concept` ids (segments must match `[A-Za-z0-9_][A-Za-z0-9_.\-]*`) → `ValueError` (`paths.py`); inside a run, tool-level refusals for missing `type` or schema/sources shrinkage (returned to the LLM as errors, not crashes).

### What success looks like

Exit 0 and stderr `Enriched <N> concept(s) into <out>; web pass used <k> seed(s)` (or `; web pass skipped`) (`cli.py:211–213`), with fresh `index.md` files at each level.

**Koinome implication:** `enrich` is not usable as a consumer of the example corpus per se — it requires a BigQuery dataset and paid LLM calls. For the prototype ticket, only its *incremental-read behavior* is relevant, and only if we want to test "OKF producer writing into a Koinome corpus"; that would need a real (or public) BQ dataset, e.g. the sample recipes' `bigquery-public-data.*` datasets.

## Tool 4 (found extra): index regeneration, importable but not CLI-exposed

`regenerate_indexes(bundle_root)` (`okf/src/reference_agent/bundle/index.py:49–103`) walks any local bundle and (re)writes `index.md` at every directory level, grouping entries by `type`. Directory descriptions for multi-child directories are synthesized via Gemini, but the synthesizer **degrades gracefully without credentials** — any exception falls back to a deterministic `Contains N entries: …` line with a logged warning (`bundle/synthesizer.py:21–24, 47–49`). So it can run fully offline:

```bash
# WARNING: overwrites every index.md under $BUNDLE — run against a copy.
BUNDLE=/absolute/path/to/copy/of/bundle
.venv/bin/python -c "
from pathlib import Path
from reference_agent.bundle.index import regenerate_indexes
written = regenerate_indexes(Path('$BUNDLE'))
print(f'{len(written)} index.md file(s) written')
"
```

Success: exit 0, count > 0, and each `index.md` matching SPEC §8's structure. Relevant to Koinome because `index.md`/`log.md` are **reserved filenames** that "MUST NOT be used for concept documents" (`okf/SPEC.md:134–151`) — a corpus-as-bundle mapping must keep Koinome records off those names and expect OKF tooling to feel entitled to overwrite `index.md`.

## Samples/recipes inventory (`okf/samples/`)

Each sample is a `README.md` (prerequisites + exact `enrich` command) plus `seeds.txt` (one seed URL per line, `#` comments allowed — parsed by `cli.py:27–34`), paired with its committed output bundle under `okf/bundles/<name>/`. The committed bundles double as **known-good fixtures**: the prototype ticket can first run `visualize` against `okf/bundles/crypto_bitcoin/` to establish a working baseline before pointing it at the Koinome corpus. Bundle layout observed there: `datasets/*.md`, `tables/*.md`, `references/{metrics,joins}/…`, `index.md` per directory, `viz.html` committed at the root.

## Summary table

| Tool | Invocation | Needs credentials? | Consumes arbitrary local bundle? | Rejects | Success signal |
|---|---|---|---|---|---|
| Visualizer | `python -m reference_agent visualize --bundle DIR` | No (CDN only at view time) | **Yes** — primary consumer | Only a missing dir; bad files silently skipped | `Wrote N concept(s), M edge(s), K bytes → out`, exit 0, N == expected |
| Conformance check | inline script above (uses `OKFDocument`) | No | **Yes** (de facto; no shipped CLI) | Unparseable frontmatter; missing/empty `type` | exit 0, `0 failure(s)` |
| pytest suite | `.venv/bin/pytest` (from `okf/`) | No | No — fixed synthetic fixtures | n/a | all tests pass |
| Reference agent | `python -m reference_agent enrich --source bq --dataset P.D --out DIR` | BigQuery ADC + Gemini | Reads/augments existing bundle at `--out`, but requires a BQ dataset | missing `--dataset`; unknown source; bad concept ids; guard refusals in-run | `Enriched N concept(s) into OUT…`, exit 0 |
| Index regen | `regenerate_indexes(Path(DIR))` (import) | No (LLM optional, falls back) | **Yes** — but overwrites `index.md` | nonexistent root → no-op `[]` | count > 0, §8-shaped `index.md` files |
