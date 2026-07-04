---
name: init
description: Use when the user wants to set up an FDE-SKILLS workspace or start a new client engagement (e.g. "set up fde", "scaffold fde here", "new engagement with Acme", "start the Globex engagement"). First run creates the .fde/ deterministic spine (config, schemas, bin scripts, empty corpus); with a client name it also creates the per-client engagement directory.
allowed-tools: Bash, Read, Write
---

# fde-init — scaffold the workspace and open engagements

Creates the `.fde/` spine in the current directory (once), and one directory
per client engagement (any time). A workspace is **personal and spans all
clients** so knowledge compounds across them; isolation between clients is by
directory.

## Steps

1. **Scaffold the spine** — skip this whole step if `.fde/config.yml` already
   exists (don't clobber; say it's already initialized). The templates ride
   inside this skill, so `${CLAUDE_SKILL_DIR}` points at them no matter how the
   pack was installed:
   ```bash
   src="${CLAUDE_SKILL_DIR}/templates"
   mkdir -p .fde/bin .fde/schemas .fde/corpus engagements
   cp "$src/config.yml"           .fde/config.yml
   cp "$src"/schemas/*.schema.yml .fde/schemas/
   cp "$src"/bin/*.sh             .fde/bin/
   chmod +x .fde/bin/*.sh
   ```
2. **Gitignore the confidential layer** — if the workspace is a git repo, add
   to `.gitignore`:
   ```
   engagements/
   .fde/dashboard.html
   ```
   Everything under `engagements/` is raw client material and must never be
   committed; the dashboard contains client slugs. The shared `.fde/corpus/`
   (anonymized) and `.fde/schemas/` are commit-safe.
3. **Open the engagement** — if the user named a client:
   ```bash
   .fde/bin/fde-new.sh "<Client Display Name>"
   ```
   This creates `engagements/<slug>/{notes,deliverables}/`, writes
   `engagement.yml`, and registers the slug in `.fde/index.yml`.
4. Print the layout and point at `/fde:draft` for the first deliverable.

## The workspace layout

```
.fde/
  config.yml      deliverable types + paving threshold + extra identifiers
  schemas/        <type>.schema.yml — slot defs that evolve across engagements
  corpus/         <type>.yml — anonymized priors with sighting counters
  bin/            deterministic scripts (no LLM): new, coverage, promote,
                  validate, identifiers, dashboard
  index.yml       registry of engagements (created by fde-new.sh)
  dashboard.html  the compounding wall (fde-dashboard.sh; never commit)
engagements/
  <client>/       one dir per client — CONFIDENTIAL, never cross-read
    engagement.yml, notes/, deliverables/
```

## Hard rules
- Never write client-identifying content into `.fde/corpus/`. Only
  `/fde:promote` moves knowledge up, and it anonymizes on the way.
- The spine scripts are the source of truth for counting/redaction/paving.
  Don't reimplement their logic in prose — call them.
