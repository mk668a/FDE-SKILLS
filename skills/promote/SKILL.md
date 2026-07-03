---
name: promote
description: Use when a deliverable taught something reusable and the user wants it to benefit future engagements (e.g. "promote these learnings", "save this to the corpus", "make this reusable across clients"). Anonymizes the deliverable, lifts its durable patterns into the shared corpus, and evolves the schema with any novel slots.
allowed-tools: Bash, Read, Write
---

# fde-promote — lift learnings into the corpus (anonymized)

The write side of compounding, and the only path by which anything leaves an
engagement's confidential boundary. This is the **gravel road → paved highway**
move: an engagement builds a fast, client-specific solution (the gravel road);
promote generalizes its durable structure into shared infrastructure the next
engagement drives on (the paved highway). Two-layer by design: you (LLM) decide
*what* is a durable, generalizable learning and paraphrase out the client
specifics; the script does the mechanical redaction backstop and the
confidentiality check.

## Steps
1. Resolve `<client>` and `<type>`. Read the deliverable's `.md` and `.slots.yml`.
2. **Semantic anonymization (LLM)**: rewrite each slot value you want to keep so
   it is a *generalizable pattern*, not this client's situation. Strip names,
   industries-if-identifying, specific figures, anything that fingerprints the
   client. If a learning is too client-specific to generalize, drop it.
3. **Schema evolution**: if drafting surfaced a recurring slot the schema lacks,
   append it to `.fde/schemas/<type>.schema.yml` under `evolved_slots` (id,
   label, prompt). Next engagement's `/fde:draft` will inherit it.
4. **Mechanical promote (deterministic backstop)**:
   ```bash
   .fde/bin/fde-promote.sh <client> <type>
   ```
   This redacts known identifiers + figures from the slot values, appends them to
   `.fde/corpus/<type>.md`, and **re-runs `fde-validate.sh`**. If validate fails,
   STOP — a client identifier slipped through; fix the slot text and re-run.
5. Confirm to the user what generalized into the corpus and what was dropped as
   too specific.

## Hard rules
- The script's redaction is a *backstop*, not the primary control. Do the
  semantic anonymization first; never rely on regex to catch a client name you
  could have paraphrased away.
- If `fde-validate.sh` exits non-zero after promote, treat it as a hard failure.
  Nothing identifying may remain in the corpus.
- Promote *patterns*, not client deliverables. The corpus is a library of
  reusable structure, not a copy of past clients' documents.
- **Rule of Three** (Don Roberts / Martin Fowler, *Refactoring*): don't pave a
  highway from a single engagement. A one-off is client-specific; promote a slot
  or framing as a durable pattern once it has recurred — generalize from the
  third sighting, not the first. (This is the "paved road" discipline — cf.
  Netflix's paved-road model — applied to engagement learnings.)
