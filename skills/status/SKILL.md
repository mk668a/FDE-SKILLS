---
name: status
description: Use when the user needs a client-facing status update or weekly progress note (e.g. "write this week's status for Acme", "draft a status update", "progress note for the sponsor"). Generates a concise update from recent notes and deliverable coverage.
allowed-tools: Bash, Read, Write, Glob
---

# fde-status — client-facing status update

The recurring, outward artifact. Turns the week's captured notes + current
deliverable coverage into a short update a sponsor will actually read.

## Steps
1. Resolve `<client>`. Determine the window (default: since the last file in
   `engagements/<client>/status/`, else last 7 days).
2. Read notes in that window (`notes/*.md`) and current coverage:
   ```bash
   for t in $(awk '/^  - id:/{print $3}' .fde/config.yml); do
     .fde/bin/fde-coverage.sh <client> "$t" 2>/dev/null
   done
   ```
3. Write `engagements/<client>/status/<YYYY-MM-DD>.md`, opening **BLUF**
   (Bottom Line Up Front) — overall health as a RAG status (🟢 green / 🟡 amber /
   🔴 red) and the one thing the sponsor must know — then:
   - **Done this week** — concrete progress from notes/decisions
   - **In flight** — deliverables and their coverage (use the numbers above)
   - **Risks / blockers** — pulled from risk notes
   - **Next week** — the gaps still to fill
   - **Asks of the client** — anything blocking you
4. Keep it tight (a sponsor skims). Offer the user a paste-ready version.

## Hard rules
- This is shown to the client, so it may contain this client's specifics — it
  lives under the engagement dir and is never promoted to the corpus.
- Use real coverage numbers from the script, not estimates.
