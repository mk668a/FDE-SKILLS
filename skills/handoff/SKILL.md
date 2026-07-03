---
name: handoff
description: Use at the end of an engagement when the user needs a handoff or closeout document (e.g. "write the handoff for Acme", "close out this engagement", "summary for the client team to take over"). Assembles the deliverables into one closeout and prompts to promote learnings.
allowed-tools: Bash, Read, Write, Glob
---

# fde-handoff — engagement closeout

## Steps
1. Resolve `<client>`. Read all `deliverables/*.md`, `onboard/context-map.md`,
   and the latest few `status/*.md`.
2. Write `engagements/<client>/handoff.md`:
   - **What we did** — scope delivered vs. original context map
   - **State at handoff** — each deliverable + its final coverage number
   - **Open items** — unfinished slots / risks still live
   - **Run-it-yourself** — what the client team owns going forward
   - **Contacts & artifacts** — where everything lives
3. Mark the engagement closed:
   ```bash
   # set status: closed in engagements/<client>/engagement.yml (and index.yml)
   ```
   Edit those two files' `status:` line to `closed`.
4. **Prompt to compound**: ask the user which deliverables taught something
   reusable and offer `/fde:promote` for each. The end of an engagement is the
   highest-value moment to lift learnings into the corpus.

## Hard rules
- The handoff is a client artifact (stays in the engagement dir). Promotion to
  the corpus is a separate, explicit, anonymizing step (`/fde:promote`).
