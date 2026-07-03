---
name: validate
description: Use when the user wants to check the workspace is sound and confidential before committing or sharing (e.g. "validate the workspace", "is anything leaking into the corpus", "check confidentiality"). Runs the deterministic confidentiality + integrity guard.
allowed-tools: Bash, Read
---

# fde-validate — confidentiality + integrity guard

The safety net that makes "commit the corpus, keep engagements private" trustable.

## Steps
1. Run the guard:
   ```bash
   .fde/bin/fde-validate.sh
   ```
   It fails (non-zero) if any engagement identifier — slug, client name, or a
   significant name token — appears anywhere in `.fde/corpus/`.
2. **If it fails**: report exactly which identifier leaked into which corpus file.
   Find the offending entry, paraphrase the identifier out (or remove the entry),
   and re-run until clean. A leak is a hard stop — never commit a failing corpus.
3. **If it passes**: confirm the corpus is client-anonymous and therefore safe to
   commit, while everything under `engagements/` stays local/confidential.
4. (Optional) Remind the user to run this before any `git commit` that touches
   `.fde/corpus/`.

## Hard rules
- This is the source of truth for "is the corpus safe". Don't override its verdict
  with your own judgment — fix the data until the script passes.
