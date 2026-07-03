---
name: capture
description: Use whenever the user wants to log something into the current engagement — a meeting note, a decision, an observation, a finding (e.g. "capture this", "log a note for Acme", "save this decision"). Appends a timestamped, tagged markdown note to the engagement's notes/.
allowed-tools: Bash, Read, Write
---

# fde-capture — append a note to the engagement

The cheap, frequent action that feeds everything downstream. Notes accumulate;
`/fde:draft` later reads them to fill deliverable slots.

## Steps
1. Identify the engagement (ask, or use the most recent in `.fde/index.yml`).
2. Classify the note so it's findable later. Front-matter tags:
   `kind: meeting | decision | finding | risk | todo | observation`.
3. Append to `engagements/<client>/notes/<YYYY-MM-DD>-<kind>.md` (create if absent),
   each entry as:
   ```markdown
   ## <HH:MM> — <one-line summary>
   kind: <kind>
   <the note body, verbatim where it matters>
   ```
   Use the date/time from `date` (a shell call) — do not invent timestamps.
4. If the note is a `decision`, `risk`, or `finding`, tell the user which
   deliverable slot it likely fills (e.g. a risk → Risk Register `top_risks`) so
   they know coverage moved.

## Hard rules
- Raw and confidential. Stays under `engagements/<client>/notes/`. Never copy a
  note into the corpus.
