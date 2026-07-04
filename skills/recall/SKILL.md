---
name: recall
description: Use when the user wants to apply lessons from past engagements to the current one (e.g. "what did we learn about pilots like this", "any priors for findings reports", "how have we handled this risk before"). Reads the anonymized corpus and surfaces relevant priors, weighted by how often they recurred — without exposing any past client.
allowed-tools: Bash, Read, Glob
---

# fde-recall — pull relevant priors from the corpus

The read side of compounding. Lets the current engagement benefit from every
past one, while the corpus stays client-anonymous.

## Steps

1. Take the user's question or the current deliverable `<type>` as the query.
2. Read `.fde/corpus/<type>.yml` (or all of `.fde/corpus/*.yml` for a broad
   question). Every entry is already anonymized (`<CLIENT>`, `$<REDACTED>`,
   `<N>%`) and carries `sightings` and `paved`.
3. Surface the 3-5 most relevant priors as **patterns**, not verbatim dumps,
   and weight them by tier: a `paved` entry is hardened practice ("this held
   across 3+ engagements"), a ×2 is recurring, a ×1 candidate is one
   engagement's opinion — say which is which.
4. Hand off: suggest `/fde:draft` to fold these into the current deliverable
   (where paved entries pre-fill and candidates become
   `[candidate ×n — confirm]` suggestions).

## Hard rules
- Priors come from `.fde/corpus/` only. Never read another engagement's
  `engagements/<other-client>/` to answer a recall question — the corpus is
  the only legitimate cross-engagement source, because it is the only layer
  the anonymization gate guards.
- If the corpus is empty (early days), say so honestly — there are no priors
  yet, and the first `/fde:promote` is how that changes.
