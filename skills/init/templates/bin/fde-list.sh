#!/usr/bin/env bash
# fde-list.sh — list engagements and how many deliverables each has. No LLM.
set -euo pipefail
ENG_ROOT="${ENG_ROOT:-engagements}"

printf '%-22s %-8s %s\n' "ENGAGEMENT" "STATUS" "DELIVERABLES"
found=0
for d in "$ENG_ROOT"/*/; do
  [ -d "$d" ] || continue
  found=1
  slug=$(basename "$d")
  status=$(awk '/^status:/{print $2; exit}' "$d/engagement.yml" 2>/dev/null || echo "?")
  count=$(find "$d/deliverables" -name '*.slots.yml' 2>/dev/null | wc -l | tr -d ' ')
  printf '%-22s %-8s %s\n' "$slug" "$status" "$count"
done
[ "$found" -eq 0 ] && echo "(no engagements yet — run /fde:new \"<Client>\")"
