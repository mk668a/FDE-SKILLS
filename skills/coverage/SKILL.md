---
name: coverage
description: Use when the user asks how complete a deliverable is, or wants to see fill progress across engagements (e.g. "how complete is the risk register", "coverage for Acme", "what's left to fill"). Reports the deterministic slot-fill rate and lists the gaps.
allowed-tools: Bash, Read
---

# fde-coverage — slot-fill status

## Steps
1. Resolve `<client>` and `<type>` (or loop over all deliverables of the
   engagement).
2. Run the deterministic counter:
   ```bash
   .fde/bin/fde-coverage.sh <client> <type>
   ```
   This prints `filled/total (pct)`. The number is computed by the script, not
   estimated — report it verbatim.
3. Open `engagements/<client>/deliverables/<type>.slots.yml` and list the empty
   slots by their schema label + `prompt`, so the user knows exactly what to
   capture next (`/fde:capture`) to move the number.
4. (Optional) Show the trend: if `.fde/corpus/<type>.md` has priors from N past
   engagements, note that those slots are the ones likely to inherit and start
   pre-filled next time — coverage compounds.

## Hard rules
- The fill rate is whatever `fde-coverage.sh` outputs. Do not recompute or
  round it yourself.
