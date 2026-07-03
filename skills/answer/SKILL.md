---
name: answer
description: Use when the user wants to answer a client's question by drawing on accumulated knowledge — a stakeholder asks something and you want a grounded, cited reply (e.g. "the client asked how we handle SSO failures — draft an answer", "answer Acme's question about data residency", "reply to this RFP question from the corpus"). Composes a client-facing answer that cites the knowledge base (this engagement's notes, the anonymized corpus, the shared research library), and routes any new durable lesson back into the knowledge base.
allowed-tools: Bash, Read, Write, Glob, Grep
---

# fde-answer — answer a client question from the accumulated knowledge base

The front door to everything the workspace has learned. A stakeholder asks a
question; this composes a grounded answer **with citations**, then closes the
loop by routing anything durable back into the knowledge base so the next answer
is stronger. It is the *ask* side of compounding, distinct from `/fde:recall`
(which only surfaces priors as draft material) and `/fde:research` (which goes to
the **web**, not to what you already know).

Method discipline: **answer from evidence, cite every claim, separate what you
know from what you infer.** If the knowledge base can't support a claim, say so
and route it to the skill that can fill the gap rather than inventing it
(retrieval-grounded answering, not free generation).

## Steps
1. **Resolve** the engagement (`<client>`) and capture the question verbatim.
   Slugify it for the filename (lowercase, spaces → `-`); resolve the date with
   `date +%F`.
2. **Retrieve the evidence** by delegating to the **fde-retriever** subagent (the
   shared read side of the knowledge base, also used by `/fde:recall`). Hand it
   the question and the engagement slug; it gathers, in its own context, across
   the three legitimate sources and returns a cited evidence pack:
   - **This client** (authoritative for client-specific facts): the engagement's
     `notes/`, `onboard/context-map.md`, `deliverables/`, `journal/`.
   - **The anonymized corpus** (`.fde/corpus/<type>.md`) — cross-engagement priors.
   - **The shared research library** (`research/*.md`) — external reference.
   The subagent enforces the confidentiality boundary (it never reads another
   client) and keeps the verbose file reading out of this conversation.
3. **Compose the answer** in `engagements/<client>/answers/<date>-<slug>.md`:
   ```markdown
   ---
   client: <slug>
   question: <the question, verbatim>
   date: <YYYY-MM-DD>
   ---

   # <short restatement of the question>

   **Short answer:** <the BLUF — one or two sentences a stakeholder can act on>

   ## Answer
   <the substance. Cite each claim inline: [client note], [corpus: <type>],
   [research: <slug>]. Keep client facts and reusable priors visibly sourced.>

   ## What we're inferring vs. what we know
   - **Known** (sourced above): <…>
   - **Inferred / needs confirming**: <…>

   ## Gaps
   - <anything the knowledge base couldn't answer — see write-back below>
   ```
   Mark every load-bearing claim with its source. An uncited assertion is a bug.
4. **Close the loop (accumulate)** — if answering surfaced something durable,
   route it to the right writer (don't write the shared KB yourself):
   - reusable, anonymizable lesson → suggest `/fde:promote` (into the corpus),
   - external fact worth keeping → suggest `/fde:research` (into `research/`),
   - client-specific fact not yet recorded → suggest `/fde:capture`.
   If the gap is an external/web question, you may delegate it to the
   **fde-researcher** subagent (shared with `/fde:research`) to fill in the
   answer — passing it only the client-agnostic question — then suggest
   `/fde:research` to save the brief. Only `/fde:promote` may move knowledge into
   a shared layer, and it anonymizes first — keep that boundary.
5. Tell the user where the answer is saved and which write-back (if any) you
   recommend.

## Hard rules
- **Cite or don't claim.** Every substantive statement ties back to a client
  note, a corpus entry, or a research brief. If nothing supports it, put it under
  "Inferred / needs confirming" or "Gaps" — never present it as fact.
- The answer file lives under `engagements/<client>/` and **is confidential**: it
  contains this client's specifics. Never promote it, never write it to
  `.fde/corpus/` or `research/`.
- Read only this client's `engagements/<client>/`, the anonymized corpus, and the
  shared research library. **Never read another `engagements/<other-client>/`** to
  answer — the corpus is the only legitimate cross-engagement source.
- Don't write the shared knowledge base from here. Route accumulation through
  `/fde:promote` / `/fde:research` / `/fde:capture` so anonymization and the
  deterministic boundary stay intact.
