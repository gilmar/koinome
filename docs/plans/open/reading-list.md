# Koinome reading list

Built from Koinome's own documents: STRATEGY.md names the standards (PROV, ODRL, VC, ABAC, MCP) and the corpus-format-v0 proposal fixes an RFC order (identity manifest → record types → PROV/ODRL profile → MCP contracts → demo). The list has a **spine** of ten foundational reads, then a cluster per RFC for just-in-time reading while drafting each one, then a shelf for the cross-corpus design work that starts around month 6.

## The spine — read first, in this order

Roughly two months of part-time evenings. Items 2–5 are deliberately sequenced: RDF literacy is the prerequisite that makes PROV and ODRL readable instead of impenetrable — most people skip it and bounce off.

1. **Kleppmann, Wiggins, van Hardenberg & McGranaghan — "Local-first software: You own your data, in spite of the cloud"** (Ink & Switch, 2019 — inkandswitch.com/local-first). The seven ideals are the theoretical statement of the Commitments section; the turn-it-off test is their thesis. Also the gateway to what CRDTs promise and where they stop.
2. **W3C RDF 1.1 Primer** (w3.org/TR/rdf11-primer) **plus JSON-LD 1.1 §Basic Concepts**. Not because Koinome should become RDF — because `prov:wasDerivedFrom` in frontmatter is a namespaced claim of compatibility, and an RFC reviewer will test whether the keys actually map to the ontology. An hour or two of triple-thinking makes everything in items 3–4 legible.
3. **W3C PROV, in this exact order: PROV-Overview → PROV Primer → Moreau & Groth, *Provenance: An Introduction to PROV*** (short book, ~130 pp, 2013). Keep PROV-DM and PROV-O as reference, don't read them cover to cover. Entity/Activity/Agent plus Attribution, Derivation, and Delegation are the Phase 3 vocabulary — and `prov:actedOnBehalfOf` is exactly the owner-vs-steward distinction, already standardized.
4. **W3C ODRL Information Model 2.2 + ODRL Vocabulary 2.2**, then the **ODRL Community Group's Formal Semantics draft** (w3c.github.io/odrl/formal-semantics). The critical fact: ODRL is a W3C Recommendation for *expressing* policies but has no normative *evaluation* semantics. That validates the "inert until operations ship" stance and marks what the enforcement RFC will eventually have to pin down itself.
5. **NIST SP 800-162 (Guide to ABAC)** plus the data-flow/architecture section of **OASIS XACML 3.0**. Cited in strategy §3; reading the source gives the full PDP/PEP/PIP/PAP separation, so the validator, policy store, and context assembly get principled names in the RFCs.
6. **Saltzer & Schroeder — "The Protection of Information in Computer Systems"** (1975), the design-principles section (web.mit.edu/Saltzer/www/publications/protection). Fifty years old and reads like the strategy doc: complete mediation is the gate, least privilege is the scoped bundle, open design is the open format.
7. **The Model Context Protocol specification**, current revision, end to end — resources, tools, roots, elicitation — plus its security best-practices page (modelcontextprotocol.io). Phase 4 is a contract-design problem; the resources-vs-tools boundary chosen for scoped context vs. proposals is the whole design.
8. **Simon Willison — the prompt-injection series, ending with "The lethal trifecta"** (simonwillison.net/series/prompt-injection). The MCP server puts private corpus data and untrusted conversation-derived content in one context. The proposal flow's safety needs arguing in this literature's vocabulary, because reviewers will ask.
9. **Debenedetti et al. — "Defeating Prompt Injections by Design" (CaMeL)** (arXiv 2503.18813, 2025). The closest published architecture to "AI proposes, deterministic systems decide": an LLM plans, a deterministic policy engine gates every effect. Citing it strengthens strategy §3's claim that this is an implementable architecture, not a slogan.
10. **Hess & Ostrom (eds.) — *Understanding Knowledge as a Commons*** (MIT Press, 2007), at minimum the introduction and the framework chapter. The project's name points at an actual research field with thirty years of results on governing shared knowledge resources — common-pool resources, rules-in-use, nested governance — and the federation RFCs will need its vocabulary.

## RFC 1 — Corpus identity manifest

- **RO-Crate** (spec at w3id.org/ro/crate; paper "Packaging research artefacts with RO-Crate," 2022). The closest prior art to the manifest that exists: one metadata file that makes a folder of files an identifiable, attributable, licensable unit, built on schema.org and PROV. Read before naming `corpus.manifest.yaml`, and write down what's consciously different.
- **BagIt (RFC 8493)**. Libraries and archives solved "move a bundle of files across a boundary with integrity" minimally and durably. Doubles as the best model of a short, complete, independently implementable spec — imitate its shape.
- **OCFL — Oxford Common File Layout** (ocfl.io). Versioned objects on a plain filesystem with rebuildable state; their published design decisions (single inventory, content addressing, forward migration) are a community spending years on exactly the "durable unit on disk" problem.
- **Frictionless Data Package v2** (datapackage.org). The lightweight counterpoint; useful for scope discipline.
- **Identifier decision support**: RFC 9562 (UUIDs — note UUIDv7 is time-ordered, good for sortable IDs), RFC 4151 (`tag:` URIs — durable, human-readable IDs minted from an email or domain plus a date, zero infrastructure — a serious candidate for `corpus_id`), and Berners-Lee's "Cool URIs don't change." Optional if the whole space is of interest: the DID Core primer and Zooko's triangle.

## RFC 2 — Record types and schemas

- **Kunz & Rittel — "Issues as Elements of Information Systems"** (1970, ~9 pp) plus **Conklin's gIBIS/dialogue-mapping work**. The original typed-discourse records (issue/position/argument) — and the honest post-mortem literature on why capture-heavy typologies fail in practice. The "proportional governance" principle exists precisely because of this failure mode; know it by name.
- **Joel Chan — Discourse Graphs** (discoursegraphs.com and the associated papers). The living modern practice of question/claim/evidence typing for notes; the nearest cousin of the `claim` type.
- **Groth, Gibson & Velterop — "The anatomy of a nanopublication"** (2010). Assertion + provenance + publication-info as one unit: the strongest precedent for "no claim without provenance," and a sobering case study in adoption friction.
- **Toulmin's model of argument** (any good summary; *The Uses of Argument* itself is optional). Claim/data/warrant/qualifier/rebuttal indicates which fields a `claim` record has to carry — scope conditions, confidence, backing.
- **Nygard — "Documenting Architecture Decisions"** (2011) plus **MADR** (adr.github.io). `adr.md` is already shipped; reread these as type design — which fields earned their keep across a decade of use.
- **"Understanding JSON Schema"** (free, json-schema.org/understanding-json-schema), with the 2020-12 spec as reference. Get `$id`/`$ref`/dialect discipline right before six schemas exist and start cross-referencing.
- **Kleppmann — DDIA, the "Encoding and Evolution" chapter**, plus **Rich Hickey — "Spec-ulation"** (talk, 2016). Forward/backward compatibility rules and "accrete, never break" — the difference between v0 frontmatter that survives v1 and a migration nightmare.
- **The Norway Problem** (hitchdev.com/strictyaml/why/implicit-typing-removed). The deterministic gate parses YAML with PyYAML, which implements YAML 1.1 — know exactly where `no` becomes `False` and `3.10` becomes a float, because determinism claims die on these details.
- **The CommonMark spec's introduction and rationale**. Why "Markdown" is not one thing, and what pinning a dialect buys a validator.
- Optional foundation: **Glushko (ed.) — *The Discipline of Organizing*, ch. 1–4** — the academic frame for what resources, collections, and organizing principles are.

## RFC 3 — PROV/ODRL profile (beyond the spine)

- **Nissenbaum — "Privacy as Contextual Integrity"** (Washington Law Review, 2004; the book *Privacy in Context* if it lands). Context-relative informational norms are the theory of why work→personal and personal→work are *different* policies. The per-direction boundary policies are contextual integrity operationalized — this paper gives the argument.
- **Denning — "A Lattice Model of Secure Information Flow"** (CACM, 1976). Short, formal, foundational: the mathematical skeleton under direction-sensitive flow between differently-classified stores.
- **Park & Sandhu — "The UCON_ABC Usage Control Model"** (2004). Obligations, conditions, and continuity of enforcement — the theory behind what ODRL "duties" gesture at, needed the day rights stop being inert.
- **W3C Verifiable Credentials Data Model 2.0** — core data model and proofs sections, for the contribution-receipts RFC.
- **Hardy — "The Confused Deputy"** (1988, 3 pp). One person's agent operating across three principals' corpora is a confused-deputy generator; this is the classic statement of why ambient authority fails, and it's the sharpest framing available for the three-corpora scenario.
- Optional deep dive: **Buneman, Khanna & Tan — "Why and Where: A Characterization of Data Provenance"** (2001), for deciding how fine-grained `wasDerivedFrom` should be.

## RFC 4 — MCP contracts and the memory field

- **The systems the structural claim names**: MemGPT (arXiv 2310.08560), the Mem0 paper (arXiv 2504.19413), the Zep/Graphiti paper (arXiv 2501.13956), plus the Letta and LangMem docs. The claim is "checkable" — so be able to cite where each data model scopes memory to a single user/agent when writing the v0.1 essay.
- **Park et al. — "Generative Agents"** (arXiv 2304.03442). The canonical memory-stream/reflection design; what the agents literature means when it says "memory."
- **Beurer-Kellner et al. — "Design Patterns for Securing LLM Agents against Prompt Injections"** (arXiv 2506.08837, 2025). Six named patterns; the proposal flow is roughly plan-then-execute plus context minimization, and using their names in the Security Considerations section does a lot of work.
- **Anthropic — "Effective context engineering for AI agents"** (2025). Directly informs scoped-bundle design: what goes in a bundle, what gets summarized, how to think about token budgets for Phase 4 resources.
- **LongMemEval** (arXiv 2410.10813) **and LoCoMo** (arXiv 2402.17753). Benchmark prior art for the D11 harness — steal the task taxonomy (temporal reasoning, knowledge updates, abstention), not the leaderboards.

## The design-scope shelf — cross-corpus operations (months 6–9)

- **Shapiro et al. — "Conflict-free Replicated Data Types"** (2011), **crdt.tech**, and Kleppmann's **"CRDTs: The Hard Parts"** talk. What mechanical merge can and cannot promise — so the operations RFC can say precisely why semantic merge needs an agent, and where CRDTs could still carry the structural layer.
- **Pro Git, "Git Internals" chapter**, plus **Stolee — "Commits are snapshots, not diffs"** (GitHub blog, 2020). The substrate's actual data model; the limits of three-way merge are the argument for why operation receipts live above git rather than in it.
- **"Bluesky and the AT Protocol"** (arXiv 2402.03239, 2024). Self-certifying user data repositories, DID-anchored identity that survives host migration, federation without a canonical center — the closest deployed system to "portable corpus with durable identity."
- **The Solid Protocol** (solidproject.org). Personal data stores with access policies (WAC/ACP) — study both the design and, honestly, why adoption has been hard despite Berners-Lee's backing. There are lessons in it for a corpus product.
- **Dehghani's original data-mesh articles** (martinfowler.com, 2019–2020). "Federated computational governance" is corpus federation at enterprise scale; read for the vocabulary, filter out the enterprise framing.
- **Ostrom — *Governing the Commons*** (1990), especially the design-principles chapter; then the introduction to **Frischmann, Madison & Strandburg — *Governing Knowledge Commons*** (2014) if the field hooks. This is where "federation without centralisation" stops being an aspiration and becomes an institutional design problem with known solutions.
- Lineage, short and worth it for the essays: **Bush — "As We May Think"** (1945), **Engelbart — "Augmenting Human Intellect"** (1962, the framework section), and **Ted Nelson on transclusion** ("Xanalogical Structure, Needed Now More Than Ever," 1999). Provenance by reference instead of by copy is Xanadu's core thesis — and Koinome's.

## Process craft (thin slice)

- **RFC 7282 — "On Consensus and Humming in the IETF."** What RFC-first governance means as a practice, not a file-naming convention.
- **RFC 2119 / RFC 8174** — two pages that make normative language testable.
- Optional: **Eghbal — *Working in Public*** (2020), on the sustainability dynamics of exactly this kind of solo, part-time, high-craft open project.

## How to pace it

Spine now, in order — it's front-loaded so that items 1–6 change how everything after them reads. Then read each RFC cluster the week that RFC gets drafted; that timing lines up with the months 0–4 roadmap. The shelf waits until the operations RFC season unless something blocks sooner.
