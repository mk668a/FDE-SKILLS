---
name: research
description: Use when the user wants to research a topic on the web and keep the result — a market, technology, vendor, standard, or domain question (e.g. "research the HL7 FHIR standard", "look into Snowflake vs Databricks", "what's the regulatory landscape for X", "save research on Y"). Writes a cited research brief into the workspace-level research/ library, which is shared across all engagements — not tied to one client.
allowed-tools: WebSearch, WebFetch, Bash, Read, Write, Glob
---

# fde-research — the shared, cross-engagement research library

FDEs re-research the same things across clients: a data standard, a vendor
trade-off, an industry's regulatory shape. That knowledge isn't client-specific,
so it doesn't belong under any one `engagements/<client>/`. It lives once at the
**workspace level in `research/`** and every engagement draws on it — the same
compounding idea as the corpus, but for *external* reference rather than
anonymized deliverable structure.

Method discipline: frame the **research question** around the decision it informs
(start from "what will we do differently depending on the answer"), then
**triangulate** — corroborate each claim across independent sources, prefer
primary/authoritative sources (specs, vendor docs, regulators) over secondary
commentary, and note recency because this kind of fact decays.

## Steps
1. Sharpen the question with the user if it's vague. Slugify it for the filename
   (lowercase, spaces → `-`). Resolve the date with `date +%F`.
2. Delegate the web sweep to the **fde-researcher** subagent (shared with
   `/fde:answer`). Hand it the sharpened, **client-agnostic** question; it
   searches, fetches, and triangulates in its own context and returns a cited
   brief, so the verbose search output never fills this conversation. Never pass
   it a client name or confidential figure.
3. Write `research/<slug>.md` from the brief it returns, adding the front-matter
   and the "Implications for engagements" section (local to this library):
   ```markdown
   ---
   topic: <the question>
   date: <YYYY-MM-DD>
   tags: [<domain>, <tech>, ...]
   ---

   # <Topic>

   **Question:** <the decision this informs>

   ## Key findings
   - <finding> [<n>]      ← bracket-cite the source number

   ## Detail
   <the substance, organized so a future you can reuse it cold>

   ## Implications for engagements
   - <how this changes a recommendation, a risk, an integration choice>

   ## Open questions
   - <what's still unresolved or source-thin>

   ## Sources
   1. <title> — <url> (<accessed YYYY-MM-DD>)
   ```
4. Tell the user the brief is saved and reusable from any engagement (e.g.
   `/fde:draft` and `/fde:recall` can lean on it).

## Hard rules
- `research/` is **shared and commit-safe**, like `.fde/corpus/`. Keep it
  **client-agnostic**: never write a client name, slug, or confidential figure
  into a research brief. If a finding is only meaningful with client specifics,
  that belongs in `engagements/<client>/notes/` via `/fde:capture`, not here.
- Ground every claim in a fetched source and cite it. Mark anything you could not
  corroborate as unverified rather than asserting it.
- `fde-validate.sh` scans `research/` for client identifiers too — run it before
  you commit.
