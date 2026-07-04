---
name: draft
description: Use when the user wants to produce a client deliverable or check how complete one is — a risk register, findings report, stakeholder map, etc. (e.g. "draft the risk register for Acme", "write up findings", "how complete is the integration spec"). Fills the deliverable's typed schema from engagement notes AND pre-populates slots from what past engagements taught (candidate ×n priors, paved slots), then reports coverage and refreshes the dashboard.
allowed-tools: Bash, Read, Write, Glob
---

# fde-draft — draft a typed deliverable with schema inheritance

The compounding wedge. A deliverable is not a blank doc — it is a typed schema
of **slots**, and the schema is a versioned prior that hardens with evidence:
drafting engagement N's risk register starts from everything engagements
1..N-1 taught.

## Steps

1. **Resolve** the engagement (`<client>`) and the deliverable `<type>` (one of
   the ids in `.fde/config.yml` → `deliverable_types`).
2. **Load the schema**: `.fde/schemas/<type>.schema.yml` — slot ids, labels,
   required flags, prompts, plus any `evolved_slots` that past engagements
   paved in (each carries a `paved_from:` provenance line).
3. **Inherit priors** from `.fde/corpus/<type>.yml`. Every entry has a
   `sightings` counter and a `paved` flag — respect the tiering:
   - `paved: true` → **pre-fill the slot by default**; it earned that at 3+
     sightings. Still mark it `[paved: confirm]`.
   - `paved: false` → offer it as `[candidate ×<sightings>: confirm]`. A ×1
     candidate is one engagement's opinion; say so.
4. **Fill from this engagement**: read `engagements/<client>/notes/*.md`.
   Fill slots from real, client-specific evidence. Client evidence
   **overrides** an inherited prior — never let a past client's detail leak
   into this draft as fact.
5. **Flag gaps**: list every `required` slot still empty, with the exact
   question the user should answer (from the slot's `prompt`).
6. **Detect novel slots**: if this engagement surfaced a recurring dimension
   the schema lacks, propose it — `/fde:promote` will stage it as a candidate
   with a stable key; the schema only changes when the Rule-of-Three counter
   says so.
7. **Write two files** (the two-layer split):
   - `engagements/<client>/deliverables/<type>.md` — the human-readable draft.
   - `engagements/<client>/deliverables/<type>.slots.yml` — the machine state:
     ```yaml
     schema: <type>
     schema_version: <n>
     slots:
       <slot_id>: "<filled value, or empty for a gap>"
     sources:
       <slot_id>: inherited      # pre-filled from the corpus (confirmed)
       <slot_id>: engagement     # filled from this client's evidence
       # omit a slot here if it is still empty
     ```
     **Format contract**: one line per slot, flat scalars — the deterministic
     spine (`fde-coverage.sh`, `fde-dashboard.sh`) counts lines, not YAML
     trees. Fold list-ish content into one quoted line.
8. **Report coverage and refresh the wall** deterministically:
   ```bash
   .fde/bin/fde-coverage.sh <client> <type>
   .fde/bin/fde-dashboard.sh
   ```
   Show the user `filled/total — inherited · new`. Watching the inherited
   share climb across engagements is the whole product.

## Hard rules
- Inherited values are **suggestions to confirm**, never asserted as this
  client's facts. Everything in the corpus was anonymized on the way in —
  re-ground it in this engagement's notes.
- Always write `sources:` alongside `slots:`; the dashboard's colors and the
  coverage breakdown are only as honest as that block.
- No runtime cloud LLM, no external service. This skill runs on the user's own
  Claude Code; the spine scripts are plain shell.
