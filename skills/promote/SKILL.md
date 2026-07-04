---
name: promote
description: Use when a deliverable taught something reusable and the user wants it to benefit future engagements (e.g. "promote these learnings", "save this to the corpus", "make this reusable across clients"). Anonymizes the learnings, stages them with stable pattern keys, and runs the deterministic promote script — which counts sightings and, at the third, paves the pattern into the schema.
allowed-tools: Bash, Read, Write
---

# fde-promote — count sightings, pave at three

The write side of compounding, and the only path by which anything leaves an
engagement's confidential boundary. Rule of Three (Fowler, *Refactoring*),
made mechanical: a pattern enters the corpus as a **candidate** (×1), becomes
**recurring** (×2), and at the third sighting is **paved** into the schema —
`evolved_slots` gains the slot, `version` bumps, and `git diff .fde/schemas/`
shows exactly what three engagements taught you. Two-layer by design: you
(LLM) decide *what* is durable and paraphrase out the client; the script
counts, redacts, gates, and paves.

## Steps

1. Resolve `<client>` and `<type>`. Read the deliverable's `.md` and
   `.slots.yml`.
2. **Read the corpus first**: `.fde/corpus/<type>.yml`. Sighting counting
   works by **key reuse** — if a learning matches an existing entry's meaning,
   you MUST reuse that entry's `key` (that's what increments the counter). Only
   mint a new kebab-case key for a genuinely new pattern.
3. **Semantic anonymization (LLM)**: rewrite each learning you want to keep as
   a *generalizable pattern*, not this client's situation. Strip names, people,
   internal system names, industries-if-identifying, specific figures. If a
   learning is too client-specific to generalize, drop it. If it names a person
   or system the scripts can't know about, also add that token to
   `anonymization.extra_identifiers` in `.fde/config.yml` so the gate can
   enforce it forever.
4. **Stage** the patterns as
   `engagements/<client>/deliverables/<type>.promote.yml`:
   ```yaml
   schema: <type>
   patterns:
     - key: sso-auth-integration     # reused key -> sighting +1
       slot: technical_risks         # existing slot id, or a proposed new one
       label: ""                     # label+prompt only for NEW-slot proposals
       prompt: ""
       pattern: "one-line generalized learning, already anonymized"
   ```
5. **Run the deterministic promote**:
   ```bash
   .fde/bin/fde-promote.sh <client> <type>
   ```
   The script redacts figures + identifiers, merges into the corpus with
   sighting counters, refuses to touch the corpus if the merged result would
   leak an identifier, paves anything that hit the threshold, and re-runs
   `fde-validate.sh`. Report its output verbatim — especially `PAVED:` lines
   and `LEAK BLOCKED:` failures.
6. If something paved, refresh the wall (`.fde/bin/fde-dashboard.sh`) and show
   the user the schema diff (`git diff .fde/schemas/` if the workspace is a
   repo). That diff is the payoff.

## Hard rules
- The script's redaction is a *backstop*, not the primary control. Do the
  semantic anonymization first; never rely on regex to catch a client name you
  could have paraphrased away.
- If the script prints `LEAK BLOCKED`, treat it as a hard failure: fix the
  staged pattern text, don't work around the gate.
- Promote *patterns*, not client deliverables. The corpus is a library of
  reusable structure, not a copy of past clients' documents.
- Never edit `.fde/corpus/*.yml` or a schema's `evolved_slots` by hand — the
  script is the only writer, so the counters stay trustworthy.
