#!/usr/bin/env bash
# fde-validate.sh — confidentiality + integrity guard. No LLM.
# Fails (exit 1) if any engagement identifier (slug, client name, or a
# significant name token) appears in a SHARED, commit-safe location — the corpus
# or the cross-engagement research/ library. Both must stay client-agnostic.
# Uses the same token set as fde-promote.sh via fde-identifiers.sh, so the two
# never disagree.
set -euo pipefail
FDE_ROOT="${FDE_ROOT:-.fde}"
ENG_ROOT="${ENG_ROOT:-engagements}"
RESEARCH_ROOT="${RESEARCH_ROOT:-research}"
fail=0

if [ -x "$FDE_ROOT/bin/fde-identifiers.sh" ]; then
  while IFS= read -r tok; do
    [ -n "$tok" ] || continue
    # case-insensitive fixed-string match; a hit in any shared dir is a leak
    for shared in "$FDE_ROOT/corpus" "$RESEARCH_ROOT"; do
      [ -d "$shared" ] || continue
      if grep -rilF -i -- "$tok" "$shared" 2>/dev/null | grep -q .; then
        echo "LEAK: identifier '$tok' appears in $shared/" >&2
        fail=1
      fi
    done
  done < <(FDE_ROOT="$FDE_ROOT" ENG_ROOT="$ENG_ROOT" "$FDE_ROOT/bin/fde-identifiers.sh" --all)
fi

if [ "$fail" -eq 0 ]; then
  echo "validate: OK: no client identifiers in corpus/ or research/"
fi
exit "$fail"
