---
name: onboard
description: Use at the start of an engagement when the user drops in raw materials (call transcripts, docs, emails, an SOW) and wants them turned into a structured context map — who/what/why/scope/constraints. Writes engagements/<client>/onboard/context-map.md.
allowed-tools: Bash, Read, Write, Glob
---

# fde-onboard — build the engagement context map

Turns first-week raw materials into a structured starting point. This is the
LLM layer reading messy input and producing one organized artifact; it does NOT
yet touch the cross-engagement corpus.

## Steps
1. Identify the engagement (ask, or infer from the most recently created one in
   `.fde/index.yml`).
2. Read whatever the user points you at — files they paste, or everything under
   `engagements/<client>/onboard/` and `engagements/<client>/notes/`.
3. Write `engagements/<client>/onboard/context-map.md` with these sections:
   - **Who** — client, sponsor, our role, team
   - **Why** — the business outcome they're paying for
   - **Scope** — in / out, explicitly
   - **Constraints** — timeline, budget signals, tech, compliance
   - **Unknowns** — what you still need to learn (feed these to `/fde:capture`)
   Capture the **operational** problem in the customer's own words — the broken
   workflow or decision, not a guessed technical solution. Frame it as a
   Job-To-Be-Done (Christensen), use Five Whys (Toyoda) to reach root cause, and
   record the outcome the way Amazon's Working-Backwards would (start from the
   result, not the build). Translating that into spec is the build's job
   (`/fde:draft discovery-doc`, then `integration-spec`), and it goes better when
   the operational truth is recorded unflattened here.
4. Tell the user which deliverables are now draftable (`/fde:draft`) and that
   `/fde:recall` can pull relevant patterns from past engagements before they start.

## Hard rules
- Everything you write here lives under `engagements/<client>/` and is
  confidential. Do not summarize it into the corpus — that is `/fde:promote`'s job
  and only after anonymization.
