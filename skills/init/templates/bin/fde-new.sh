#!/usr/bin/env bash
# fde-new.sh — create a new engagement directory and register it. No LLM.
# usage: fde-new.sh "<Client Display Name>"
set -euo pipefail
FDE_ROOT="${FDE_ROOT:-.fde}"
ENG_ROOT="${ENG_ROOT:-engagements}"

name="${1:-}"
[ -z "$name" ] && { echo "usage: fde-new.sh \"<Client Display Name>\"" >&2; exit 1; }

# slugify: lowercase, spaces->-, strip non [a-z0-9-]
slug=$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')
[ -z "$slug" ] && { echo "could not derive a slug from: $name" >&2; exit 1; }

dir="$ENG_ROOT/$slug"
[ -d "$dir" ] && { echo "engagement already exists: $dir" >&2; exit 1; }

mkdir -p "$dir/onboard" "$dir/notes" "$dir/journal" "$dir/deliverables" "$dir/status" "$dir/reports" "$dir/answers"
cat > "$dir/engagement.yml" <<EOF
client: "$slug"
display_name: "$name"
status: active
started: "$(date +%F)"
deliverables: []
EOF

idx="$FDE_ROOT/index.yml"
mkdir -p "$FDE_ROOT"
[ -f "$idx" ] || printf 'engagements:\n' > "$idx"
printf '  - slug: %s\n    status: active\n    started: "%s"\n' "$slug" "$(date +%F)" >> "$idx"

echo "created engagement: $dir"
echo "next: capture notes with /fde:capture, then draft with /fde:draft"
