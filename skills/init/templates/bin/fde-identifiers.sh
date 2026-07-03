#!/usr/bin/env bash
# fde-identifiers.sh — print the identifying tokens for an engagement, one per
# line. Single source of truth shared by fde-promote.sh (what to redact) and
# fde-validate.sh (what must never appear in the corpus). No LLM.
#
#   usage: fde-identifiers.sh <client-slug>          # one engagement
#          fde-identifiers.sh --all                  # every engagement
#
# Tokens = the slug, the full display_name, and each display_name word of length
# >= 4 that is not a generic company suffix. Length>=4 + the stoplist keep
# generic words ("Corp", "Inc", "Group") from triggering false redactions.
set -euo pipefail
ENG_ROOT="${ENG_ROOT:-engagements}"

# generic words that are not identifying on their own
STOP=" corp corporation inc incorporated llc ltd limited co company gmbh group holdings the and of for "

emit_for() {
  local slug="$1" eng="$ENG_ROOT/$1/engagement.yml"
  [ -f "$eng" ] || return 0
  printf '%s\n' "$slug"
  local name
  name=$(awk -F'"' '/^display_name:/{print $2; exit}' "$eng" 2>/dev/null || true)
  [ -n "$name" ] || return 0
  printf '%s\n' "$name"
  # split display_name into words; keep word if len>=4 and not generic
  printf '%s\n' "$name" | tr ' ' '\n' | while IFS= read -r w; do
    w=$(printf '%s' "$w" | tr -cd '[:alnum:]')
    [ "${#w}" -ge 4 ] || continue
    case "$STOP" in *" $(printf '%s' "$w" | tr '[:upper:]' '[:lower:]') "*) continue ;; esac
    printf '%s\n' "$w"
  done
}

if [ "${1:-}" = "--all" ]; then
  for d in "$ENG_ROOT"/*/; do
    [ -d "$d" ] && emit_for "$(basename "$d")"
  done | awk 'NF && !seen[$0]++'
else
  client="${1:-}"
  [ -z "$client" ] && { echo "usage: fde-identifiers.sh <client-slug>|--all" >&2; exit 1; }
  emit_for "$client" | awk 'NF && !seen[$0]++'
fi
