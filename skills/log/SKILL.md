---
name: log
description: Use when the user wants to record what happened on a given day — a daily log, end-of-day wrap-up, standup note, or "日報" (e.g. "log today", "what did we do today", "write up today for Acme", "daily log"). Rolls up the day's captured notes into one dated journal entry. Distinct from /fde:capture (a single atomic note); this is the day's summary.
allowed-tools: Bash, Read, Write, Glob
---

# fde-log — the daily journal entry

One entry per day per engagement, under `engagements/<client>/journal/<YYYY-MM-DD>.md`.
Where `/fde:capture` logs *atomic events as they happen*, `/fde:log` is the
*end-of-day rollup*: it reads everything captured today and turns it into the
record a returning FDE (or the next person on the account) can skim to know what
actually happened. It feeds `/fde:status` (weekly) and `/fde:handoff` (closeout).

Structure anchors on the daily standup three questions (Scrum — Schwaber &
Sutherland): what moved, what's next, what's blocked.

## Steps
1. Resolve `<client>` (ask, or most recent in `.fde/index.yml`). Resolve today's
   date from a `date +%F` shell call — never invent it.
2. Gather the day's raw material:
   ```bash
   d=$(date +%F)
   ls engagements/<client>/notes/${d}-*.md 2>/dev/null   # today's captures
   ```
   Read those note files. If there are none, ask the user what happened (don't
   fabricate activity).
3. Write `engagements/<client>/journal/<YYYY-MM-DD>.md` (overwrite if re-run the
   same day — it's one canonical entry per day):
   ```markdown
   # <YYYY-MM-DD> — <client display name>

   **Summary:** <one line — the day in a sentence>

   ## Done today
   - <concrete progress, pulled from today's notes/decisions/findings>

   ## Decisions
   - <decision> → <why> (link the capture if relevant)

   ## Blockers / waiting on
   - <blocker> — owner, and what unblocks it

   ## Next
   - <the one or two things that move first tomorrow>

   ## Against the schedule
   - <on track / slipping — name the milestone from the Delivery Schedule>
   ```
   Leave a section out if there's genuinely nothing for it; don't pad.
4. If a decision/risk/finding surfaced today that isn't captured yet, offer to
   `/fde:capture` it so it reaches the deliverable slots too.

## Hard rules
- Raw and confidential. Lives under `engagements/<client>/journal/`, alongside
  `notes/`. Never copied into `.fde/corpus/` and never pushed to a remote.
- Summarize from real captured notes (or what the user tells you now). Do not
  invent meetings, names, or progress that isn't grounded in this session.
