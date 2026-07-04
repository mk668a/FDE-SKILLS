#!/usr/bin/env bash
# fde-coverage.sh — deterministic slot-fill coverage for one deliverable. No LLM.
# usage: fde-coverage.sh <client-slug> <deliverable-type>
#
# Counts slots under the 'slots:' map whose value is non-empty (not "").
# FORMAT CONTRACT (enforced by /fde:draft): one slot per line, flat scalars —
#   slots:
#     top_risks: "Integration throttling under pilot load; ..."
#     residual_risk: ""
# Multi-line YAML (lists/maps under a slot key) is NOT counted; keep each
# slot's value on its own single line.
#
# If the file carries a 'sources:' block (slot -> inherited|engagement), a
# provenance breakdown is printed, and the corpus (if present) contributes a
# paved-slot count for this deliverable type.
set -euo pipefail
FDE_ROOT="${FDE_ROOT:-.fde}"
ENG_ROOT="${ENG_ROOT:-engagements}"

client="${1:-}"; type="${2:-}"
{ [ -z "$client" ] || [ -z "$type" ]; } && {
  echo "usage: fde-coverage.sh <client-slug> <deliverable-type>" >&2; exit 1; }

f="$ENG_ROOT/$client/deliverables/$type.slots.yml"
[ -f "$f" ] || { echo "no such deliverable: $f" >&2; exit 1; }

# one awk pass over slots: (filled/total) and sources: (inherited count)
read -r total filled inherited has_sources <<EOF
$(awk '
  function trim(s){ gsub(/^[[:space:]]+|[[:space:]]+$/,"",s); return s }
  /^slots:/   { blk="slots"; next }
  /^sources:/ { blk="sources"; has=1; next }
  /^[^[:space:]]/ { blk="" }
  blk=="" { next }
  $0 ~ /^  [^ ][^:]*:/ {
    key=$0; sub(/:.*/,"",key); key=trim(key)
    val=$0; sub(/^[^:]*:/,"",val); val=trim(val)
    if (blk=="slots") {
      total++
      if (val != "" && val != "\"\"" && val != "'"'"''"'"'") filled++
    } else if (blk=="sources") {
      gsub(/"/,"",val)
      if (val=="inherited") inh++
    }
  }
  END { printf "%d %d %d %d\n", total, filled, inh, has }
' "$f")
EOF

pct=0; [ "$total" -gt 0 ] && pct=$(( filled * 100 / total ))
if [ "$has_sources" -eq 1 ]; then
  new=$(( filled - inherited )); [ "$new" -lt 0 ] && new=0
  printf '%s: %s  ·  %s/%s slots filled (%s%%) · %s inherited · %s new\n' \
    "$client" "$type" "$filled" "$total" "$pct" "$inherited" "$new"
else
  printf '%s: %s  ·  %s/%s slots filled (%s%%)\n' "$client" "$type" "$filled" "$total" "$pct"
fi

corpus="$FDE_ROOT/corpus/$type.yml"
if [ -f "$corpus" ]; then
  entries=$(grep -c '^  - key:' "$corpus" 2>/dev/null || true)
  paved=$(grep -c '^    paved: true' "$corpus" 2>/dev/null || true)
  printf 'corpus[%s]: %s priors · paved: %s\n' "$type" "${entries:-0}" "${paved:-0}"
fi
