---
name: new
description: Use when the user starts work with a new client or project and wants to track it (e.g. "new engagement with Globex", "start a project for Acme", "add a client"). Creates an isolated engagement directory and registers it.
allowed-tools: Bash, Read
---

# fde-new — start a new engagement

## Steps
1. Get the client display name from the user (e.g. "Globex Industries").
2. Run the deterministic scaffolder:
   ```bash
   .fde/bin/fde-new.sh "<Client Display Name>"
   ```
   It slugifies the name, creates `engagements/<slug>/{onboard,notes,deliverables,status}/`,
   writes `engagement.yml`, and registers the engagement in `.fde/index.yml`.
3. Confirm to the user and suggest next steps:
   - drop initial materials → `/fde:onboard`
   - capture a meeting note → `/fde:capture`
   - draft a deliverable (inherits priors from past clients) → `/fde:draft`

## Notes
- One workspace holds many engagements; each is isolated by directory. This is
  what makes the corpus compound while keeping client data separate.
- If the engagement already exists the script refuses — pick a distinct name or
  continue in the existing one.
