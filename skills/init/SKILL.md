---
name: init
description: Use when the user wants to set up an FDE-SKILLS workspace for the first time (e.g. "set up fde", "init the engagement workspace", "scaffold fde here"). Creates the .fde/ deterministic spine — config, schemas, bin scripts, empty corpus — that every other fde skill builds on.
allowed-tools: Bash, Read, Write
---

# fde-init — scaffold the workspace

Creates the `.fde/` spine in the current directory. Run once per workspace. A
workspace is **personal and spans all clients** so knowledge compounds across
them; isolation between clients is by directory, enforced by the spine.

## Steps

1. Refuse if `.fde/config.yml` already exists (don't clobber). Tell the user it's
   already initialized and point them at `/fde:new`.
2. Copy the bundled spine into place. The templates ride inside this skill, so
   `${CLAUDE_SKILL_DIR}` points at them no matter how the pack was installed
   (plugin, `install.sh`, or a loose checkout):
   ```bash
   src="${CLAUDE_SKILL_DIR}/templates"
   mkdir -p .fde/bin .fde/schemas .fde/corpus engagements research
   cp "$src/config.yml"           .fde/config.yml
   cp "$src"/schemas/*.schema.yml .fde/schemas/
   cp "$src"/bin/*.sh             .fde/bin/
   chmod +x .fde/bin/*.sh
   ```
   `research/` is the workspace-level, cross-engagement library `/fde:research`
   writes into — shared like the corpus, not tied to any client.
3. If the workspace is a git repo, add the confidential per-client dirs to
   `.gitignore` — raw client material must never be committed:
   `engagements/*/onboard/`, `engagements/*/notes/`, `engagements/*/journal/`,
   `engagements/*/reports/`, `engagements/*/answers/`. The shared `.fde/corpus/`
   and `research/` are
   client-agnostic and safe to commit; everything under `engagements/` is
   confidential.
4. Run `.fde/bin/fde-validate.sh` to confirm the spine is wired up.
5. Print the layout and tell the user to start their first engagement with
   `/fde:new "<Client>"`.

## The workspace layout you just created

```
.fde/
  config.yml      deliverable types + anonymization rules
  schemas/        <type>.schema.yml — slot defs that persist across engagements
  corpus/         <type>.md — anonymized cross-engagement priors (commit-safe)
  bin/            deterministic scripts (no LLM): new, list, coverage, promote,
                  validate, identifiers, report
research/         shared web-research briefs — cross-engagement, commit-safe
engagements/
  <client>/       one dir per client — CONFIDENTIAL, never cross-read
    engagement.yml, onboard/, notes/, journal/, deliverables/, status/,
                    reports/, answers/
```

## Hard rules
- Never write client-identifying content into `.fde/corpus/`. Only `/fde:promote`
  moves knowledge up, and it anonymizes first.
- The spine scripts are the source of truth for counting/redaction. Don't
  reimplement their logic in prose — call them.
