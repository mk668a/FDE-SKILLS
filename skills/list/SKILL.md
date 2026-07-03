---
name: list
description: Use when the user wants an overview of all their engagements and progress (e.g. "list my engagements", "what clients am I tracking", "show all projects and their status"). Prints the registry and per-engagement deliverable counts.
allowed-tools: Bash, Read
---

# fde-list — overview of all engagements

## Steps
1. Run the deterministic lister:
   ```bash
   .fde/bin/fde-list.sh
   ```
   Prints each engagement, its status, and how many deliverables it has.
2. If the user wants depth, for any engagement loop coverage across its
   deliverable types with `.fde/bin/fde-coverage.sh <client> <type>` and show a
   compact table (engagement × deliverable × fill rate).
3. Point at the natural next action: an active engagement with low coverage →
   `/fde:capture` then `/fde:draft`; a finished one → `/fde:handoff`.

## Hard rules
- Read-only. Report the script's output verbatim.
