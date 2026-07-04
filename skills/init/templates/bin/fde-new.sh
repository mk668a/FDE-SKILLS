#!/usr/bin/env bash
# fde-new.sh — create a new engagement directory and register it. No LLM.
# usage: fde-new.sh "<Client Display Name>"
set -euo pipefail
FDE_ROOT="${FDE_ROOT:-.fde}"
ENG_ROOT="${ENG_ROOT:-engagements}"

name="${1:-}"
[ -z "$name" ] && { echo "usage: fde-new.sh \"<Client Display Name>\"" >&2; exit 1; }

# Double quotes in the display name would break the engagement.yml quoting AND
# the awk -F'"' parse in fde-identifiers.sh — which silently under-redacts.
# Normalize them to single quotes up front.
name=$(printf '%s' "$name" | tr '"' "'")

# slugify: lowercase, spaces->-, strip non [a-z0-9-]
slug=$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')
# non-Latin names (e.g. 株式会社◯◯) strip to nothing — fall back to a stable
# checksum slug instead of refusing
if [ -z "$slug" ]; then
  slug="client-$(printf '%s' "$name" | cksum | cut -d' ' -f1)"
  echo "note: could not derive a latin slug from \"$name\"; using $slug" >&2
fi

dir="$ENG_ROOT/$slug"
[ -d "$dir" ] && { echo "engagement already exists: $dir" >&2; exit 1; }

mkdir -p "$dir/notes" "$dir/deliverables"
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
echo "next: draft a deliverable with /fde:draft"
