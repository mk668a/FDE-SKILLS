#!/usr/bin/env bash
# fde-coverage.sh — deterministic slot-fill coverage for one deliverable. No LLM.
# usage: fde-coverage.sh <client-slug> <deliverable-type>
# Counts slots under the 'slots:' map whose value is non-empty (not "" ).
set -euo pipefail
ENG_ROOT="${ENG_ROOT:-engagements}"

client="${1:-}"; type="${2:-}"
{ [ -z "$client" ] || [ -z "$type" ]; } && {
  echo "usage: fde-coverage.sh <client-slug> <deliverable-type>" >&2; exit 1; }

f="$ENG_ROOT/$client/deliverables/$type.slots.yml"
[ -f "$f" ] || { echo "no such deliverable: $f" >&2; exit 1; }

total=0; filled=0; in_slots=0
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    slots:*) in_slots=1; continue ;;
  esac
  [ "$in_slots" -eq 1 ] || continue
  # a slot line is two-space indented "  key: value"; dedent ends the block
  case "$line" in
    "  "[!\ ]*:*)
      total=$((total + 1))
      val=${line#*:}
      val=$(printf '%s' "$val" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
      if [ -n "$val" ] && [ "$val" != '""' ] && [ "$val" != "''" ]; then
        filled=$((filled + 1))
      fi
      ;;
    "  "*) : ;;                 # nested/continuation line, ignore
    [!\ ]*) in_slots=0 ;;       # back to column 0 -> slots block ended
  esac
done < "$f"

pct=0; [ "$total" -gt 0 ] && pct=$(( filled * 100 / total ))
printf '%s: %s  —  %s/%s slots filled (%s%%)\n' "$client" "$type" "$filled" "$total" "$pct"
