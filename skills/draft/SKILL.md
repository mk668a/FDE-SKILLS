---
name: draft
description: Use when the user wants to produce a client deliverable — a risk register, findings report, stakeholder map, etc. (e.g. "draft the risk register for Acme", "write up findings", "generate the stakeholder map"). This is the core skill: it fills the deliverable's typed schema from engagement notes AND pre-populates slots from what past engagements taught, so each client starts ahead.
allowed-tools: Bash, Read, Write, Glob
---

# fde-draft — draft a typed deliverable with schema inheritance

This is the compounding wedge. A deliverable is not a blank doc — it is a typed
schema of **slots**, and the schema persists across every engagement. Drafting
engagement N's risk register starts from everything engagements 1..N-1 taught.

## Steps

1. **Resolve** the engagement (`<client>`) and the deliverable `<type>` (one of
   the ids in `.fde/config.yml` → `deliverable_types`).
2. **Load the schema**: `.fde/schemas/<type>.schema.yml` (slot ids, labels,
   required flags, prompts, plus any `evolved_slots` from past engagements).
3. **Inherit priors**: read `.fde/corpus/<type>.md`. These are anonymized
   slot values from past engagements. Use them to:
   - pre-populate slots that are usually the same shape (e.g. a Risk Register
     almost always has an "SSO/auth integration" technical risk; an Integration
     Spec almost always needs an idempotency + retry/backoff reliability slot),
   - mark each pre-filled slot clearly as **[inherited — confirm]** so the user
     verifies it applies to *this* client.
4. **Fill from this engagement**: read `engagements/<client>/notes/*.md` and
   `onboard/context-map.md`. Fill slots from real, client-specific evidence.
   Client evidence **overrides** an inherited prior — never let a past client's
   detail leak into this draft as fact.
5. **Flag gaps**: list every `required` slot still empty, with the exact
   question the user should answer (from the slot's `prompt`).
6. **Detect novel slots**: if this engagement surfaced a recurring dimension the
   schema lacks, propose it as a new slot. Adding it is `/fde:promote`'s job
   (schema evolution) — here you just propose.
7. **Write two files** (the two-layer split):
   - `engagements/<client>/deliverables/<type>.md` — the human-readable draft.
   - `engagements/<client>/deliverables/<type>.slots.yml` — the machine state:
     ```yaml
     schema: <type>
     schema_version: <n>
     slots:
       <slot_id>: "<filled value, or empty for a gap>"
       ...
     ```
     Keep one line per slot so `fde-coverage.sh` can count fill rate.
8. **Report coverage** deterministically:
   ```bash
   .fde/bin/fde-coverage.sh <client> <type>
   ```
   Show the user `filled/total`. The whole point is watching this climb across
   engagements (e.g. 6/10 on the first client → 9/10 on the third, day one).

## Hard rules
- Inherited values are **suggestions to confirm**, never asserted as this
  client's facts. Anything carried from the corpus is generic by construction
  (it was anonymized on the way in) — re-ground it in this engagement's notes.
- Always write the `.slots.yml` alongside the `.md`; coverage and promotion both
  depend on it.
- No runtime cloud LLM, no external service. This skill runs on the user's own
  Claude Code; the spine scripts are plain shell.
