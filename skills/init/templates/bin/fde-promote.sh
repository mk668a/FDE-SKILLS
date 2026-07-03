#!/usr/bin/env bash
# fde-promote.sh — mechanically redact one deliverable's slots and append them
# to the shared corpus. No LLM. The /fde:promote skill does the *semantic*
# anonymization first; this is the deterministic backstop that strips figures
# and known client identifiers so nothing sensitive can slip through.
# usage: fde-promote.sh <client-slug> <deliverable-type>
set -euo pipefail
FDE_ROOT="${FDE_ROOT:-.fde}"
ENG_ROOT="${ENG_ROOT:-engagements}"

client="${1:-}"; type="${2:-}"
{ [ -z "$client" ] || [ -z "$type" ]; } && {
  echo "usage: fde-promote.sh <client-slug> <deliverable-type>" >&2; exit 1; }

src="$ENG_ROOT/$client/deliverables/$type.slots.yml"
[ -f "$src" ] || { echo "no such deliverable: $src" >&2; exit 1; }

name=$(awk -F'"' '/^display_name:/{print $2; exit}' "$ENG_ROOT/$client/engagement.yml" 2>/dev/null || true)

mkdir -p "$FDE_ROOT/corpus"
out="$FDE_ROOT/corpus/$type.md"
[ -f "$out" ] || printf '# Corpus: %s\n\nAnonymized cross-engagement priors. Never contains client identifiers.\n\n' "$type" > "$out"

# Redact figures + every identifying token (not just the full client string —
# tokens catch "Acme" when the client is "Acme Corp"). fde-identifiers.sh is the
# single source of which tokens are identifying; fde-validate.sh checks the very
# same set, so promote and validate can never disagree. perl (case-insensitive,
# \Q-quoted) is used for portability — BSD sed lacks the I flag / word boundaries.
ids=$(FDE_ROOT="$FDE_ROOT" ENG_ROOT="$ENG_ROOT" "$FDE_ROOT/bin/fde-identifiers.sh" "$client")

tmp=$(mktemp)
IDS="$ids" perl -pe '
  BEGIN { @toks = grep { length } split /\n/, ($ENV{IDS} // ""); }
  s/\$[0-9][0-9,.]*/\$<REDACTED>/g;
  s/[0-9]+%/<N>%/g;
  for my $t (@toks) { s/\Q$t\E/<CLIENT>/gi; }
' "$src" > "$tmp"

{
  printf '## prior — %s\n\n```yaml\n' "$(date +%F)"
  cat "$tmp"
  printf '```\n\n'
} >> "$out"
rm -f "$tmp"

echo "promoted $client/$type -> $out (figures + identifiers redacted)"

# Re-run the confidentiality guard; a leak here is a hard error.
if [ -x "$FDE_ROOT/bin/fde-validate.sh" ]; then
  "$FDE_ROOT/bin/fde-validate.sh"
fi
