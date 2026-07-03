---
name: recall
description: Use when the user wants to apply lessons from past engagements to the current one (e.g. "what did we learn about pilots like this", "any priors for findings reports", "how have we handled this risk before"). Reads the anonymized corpus and surfaces relevant priors — without exposing any past client.
allowed-tools: Bash, Read, Glob
---

# fde-recall — pull relevant priors from the corpus

The read side of compounding. Lets the current engagement benefit from every
past one, while the corpus stays client-anonymous by construction.

## Steps
1. Take the user's question or the current deliverable `<type>` as the query.
2. Delegate the lookup to the **fde-retriever** subagent (the shared read side of
   the knowledge base, also used by `/fde:answer`). Ask it for the corpus priors
   relevant to the query; it scans `.fde/corpus/` in its own context and returns a
   cited evidence pack, so the file reading never fills this conversation. Every
   corpus entry is already anonymized (`<CLIENT>`, `$<REDACTED>`, `<N>%`).
3. From what it returns, surface the 3-5 most relevant `[corpus: …]` priors as
   **patterns**, not verbatim dumps: "Across past engagements, the auth/SSO
   integration risk recurred and the mitigation that worked was X." Tie each to
   the slot it tends to fill.
4. Hand off: suggest `/fde:draft` to fold these into the current deliverable
   (where they become **[inherited — confirm]** suggestions).

## Hard rules
- Priors come from `.fde/corpus/` only. The fde-retriever subagent enforces this:
  it never reads another engagement's `engagements/<other-client>/`, so no past
  client is exposed. The corpus is the *only* legitimate cross-engagement source.
- If the corpus is empty (early days), say so honestly — there are no priors yet.
